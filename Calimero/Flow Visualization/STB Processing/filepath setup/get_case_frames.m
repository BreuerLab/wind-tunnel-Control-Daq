function FR = get_case_frames(PIV_case_name, opts)
% GET_CASE_FRAMES  The .vc7 frames of a case in recording order, for
% trials processed in DaVis in batches as well as for a single combined
% binning folder.
%
%   FR = get_case_frames(PIV_case_name)
%   FR = get_case_frames(PIV_case_name, opts)
%
% BATCH LAYOUT (used when the case folder has particle sets with their
% own binning result):
%   <case folder>\ShakeTheBox 2-pulse.set
%   <case folder>\ShakeTheBox 2-pulse\<binning>\B00001.vc7 ...
%   <case folder>\ShakeTheBox 2-pulse_01.set
%   <case folder>\ShakeTheBox 2-pulse_01\<binning>\B00001.vc7 ...
% DaVis numbers the particle blocks and vc7 files from 1 in every batch.
% vc7 file k of a set's binning folder is that set's particle block k, and
% the block's LoadFile names its source image (...\B00601.im7), whose
% number is the image's index in the recording. The frames of all batches
% are put in recording-image order; the binned pipeline (loadpiv with
% FR.vc7) and the particle pipeline then share that order. Reading the
% LoadFile attributes needs lvpyio (Python), so the table is built once and
% cached in <case folder>\frame_table.mat (rebuilt when the vc7 folders
% change).
%
% SINGLE-FOLDER LAYOUT (older cases, or a combined folder): all .vc7 files
% of get_PIV_paths(case) in name order, image k = file k.
%
% opts.binning : name of the binning folder inside each Shake-the-Box
%                folder (default "Binning_48x48x48_75%ov_ord=1"; if it is
%                missing and there is exactly one folder of .vc7 files
%                there, that one is used)
% opts.rebuild : true = ignore the cached table
%
% FR fields (one row per frame, recording order):
%   vc7    full path of the .vc7 file            (string N x 1)
%   image  recording image number                (N x 1)
%   set    particle set of the frame ("" single-folder layout)
%   block  block of the frame in that set         (N x 1, 0 single-folder)
%   layout "batches" or "folder";  case_folder;  sets (string array)
%   folders  binning folder(s) used

    if nargin < 2, opts = struct(); end
    if ~isfield(opts, 'binning'), opts.binning = "Binning_48x48x48_75%ov_ord=1"; end
    if ~isfield(opts, 'rebuild'), opts.rebuild = false; end

    [bin_folder, case_folder] = get_PIV_paths(PIV_case_name);

    % ---- batch layout? ----------------------------------------------------
    batches = find_batches(case_folder, string(opts.binning));
    if isempty(batches)
        if strlength(bin_folder) == 0 || ~isfolder(bin_folder)
            error('get_case_frames:noData', ...
                'No binning folder for %s: neither %s nor per-batch binning folders in %s.', ...
                PIV_case_name, bin_folder, case_folder);
        end
        FR = single_folder(bin_folder, case_folder);
        return
    end

    % ---- cached table, valid if the vc7 folders are unchanged ------------
    sig = signature(batches);
    cache = fullfile(case_folder, "frame_table.mat");
    if ~opts.rebuild && isfile(cache)
        C = load(cache, 'FR', 'sig');
        if isequal(C.sig, sig)
            FR = C.FR;
            return
        end
    end

    % ---- build: image numbers of each batch from its particle blocks ------
    fprintf('Building the frame table of %s from %d batch(es)...\n', PIV_case_name, numel(batches));
    parts = cell(numel(batches), 1);
    for b = 1:numel(batches)
        B = batches(b);
        P = loadSTBParticles(B.set);                        % metadata only
        nBlk = P.info.n_blocks;
        if nBlk ~= numel(B.vc7)
            error('get_case_frames:count', ...
                '%s has %d particle blocks but its binning folder %s has %d vc7 files.', ...
                B.set, nBlk, B.folder, numel(B.vc7));
        end
        A = stbBlockAttributes(B.set, unique([1 nBlk]));
        n1 = file_number(A(1).attr, B.set, 1);
        nN = file_number(A(end).attr, B.set, nBlk);
        if nN - n1 ~= nBlk - 1
            error('get_case_frames:span', ...
                ['%s: blocks 1 and %d come from images %d and %d, which is not %d consecutive ' ...
                 'images; only contiguous image ranges per batch are supported.'], ...
                B.set, nBlk, n1, nN, nBlk);
        end
        img = (n1:nN)';
        parts{b} = table(B.vc7, img, repmat(B.set, nBlk, 1), (1:nBlk)', ...
                         'VariableNames', {'vc7', 'image', 'set', 'block'});
        fprintf('  %s: images %d-%d (%d frames)\n', B.set, n1, nN, nBlk);
    end
    T = sortrows(vertcat(parts{:}), 'image');
    dup = T.image(diff(T.image) == 0);
    if ~isempty(dup)
        error('get_case_frames:duplicates', ...
            'Images processed in more than one batch (e.g. %d). Remove the duplicate batch.', dup(1));
    end
    gaps = find(diff(T.image) > 1);
    if ~isempty(gaps) || T.image(1) ~= 1
        % the phase binning maps the k-th frame to the k-th image, so
        % missing images would shift every later frame's phase
        where = "";
        if ~isempty(gaps), where = sprintf(', first gap after image %d', T.image(gaps(1))); end
        error('get_case_frames:gaps', ...
            ['%s: the batches don''t cover images 1-%d contiguously (first image %d, ' ...
             '%d gap(s)%s). Process the missing images in DaVis.'], ...
            PIV_case_name, T.image(end), T.image(1), numel(gaps), where);
    end

    FR = struct('vc7', T.vc7, 'image', T.image, 'set', T.set, 'block', T.block, ...
                'layout', "batches", 'case_folder', case_folder, ...
                'sets', unique(T.set, 'stable'), 'folders', [batches.folder]');
    save(cache, 'FR', 'sig');
    fprintf('Frame table of %s: %d frames, images %d-%d (saved %s)\n', ...
            PIV_case_name, numel(FR.vc7), FR.image(1), FR.image(end), cache);
end

% -------------------------------------------------------------------------
function batches = find_batches(case_folder, binning)
% particle sets in the case folder whose Shake-the-Box folder holds a
% binning folder with .vc7 files
    batches = struct('set', {}, 'folder', {}, 'vc7', {});
    sets = dir(fullfile(case_folder, '*.set'));
    for i = 1:numel(sets)
        stb = fullfile(case_folder, erase(sets(i).name, '.set'));
        if ~isfolder(stb), continue; end
        cand = fullfile(stb, binning);
        if ~isfolder(cand) || isempty(dir(fullfile(cand, '*.vc7')))
            sub = dir(stb);
            sub = sub([sub.isdir] & ~startsWith({sub.name}, '.'));
            has = arrayfun(@(d) ~isempty(dir(fullfile(d.folder, d.name, '*.vc7'))), sub);
            if nnz(has) ~= 1, continue; end      % none, or ambiguous
            cand = fullfile(sub(has).folder, sub(has).name);
        end
        f = dir(fullfile(cand, '*.vc7'));
        batches(end+1) = struct('set', string(fullfile(sets(i).folder, sets(i).name)), ... %#ok<AGROW>
            'folder', string(cand), 'vc7', string(fullfile({f.folder}, {f.name}))');
    end
end

function FR = single_folder(bin_folder, case_folder)
    f = dir(fullfile(bin_folder, '*.vc7'));
    if isempty(f)
        error('get_case_frames:noVc7', 'No .vc7 files in %s.', bin_folder);
    end
    n = numel(f);
    FR = struct('vc7', string(fullfile({f.folder}, {f.name}))', 'image', (1:n)', ...
                'set', repmat("", n, 1), 'block', zeros(n, 1), 'layout', "folder", ...
                'case_folder', string(case_folder), 'sets', strings(0, 1), ...
                'folders', string(bin_folder));
end

function s = signature(batches)
% what the table depends on: each batch's set and vc7 files
    s = struct('set', {batches.set}, 'folder', {batches.folder}, ...
               'n', num2cell(arrayfun(@(b) numel(b.vc7), batches)), ...
               'first', arrayfun(@(b) b.vc7(1), batches, 'UniformOutput', false), ...
               'last',  arrayfun(@(b) b.vc7(end), batches, 'UniformOutput', false));
end

function n = file_number(attr, setPath, block)
% image number from a block's LoadFile (...\B00601.im7 -> 601)
    if ~isfield(attr, 'LoadFile')
        error('get_case_frames:noLoadFile', 'Block %d of %s has no LoadFile attribute.', block, setPath);
    end
    [~, name] = fileparts(char(attr.LoadFile));
    tok = regexp(name, '(\d+)\D*$', 'tokens', 'once');
    if isempty(tok)
        error('get_case_frames:loadFile', 'No image number in LoadFile "%s" (%s block %d).', ...
              attr.LoadFile, setPath, block);
    end
    n = str2double(tok{1});
end
