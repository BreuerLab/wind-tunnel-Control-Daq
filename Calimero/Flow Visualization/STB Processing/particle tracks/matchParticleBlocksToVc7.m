function [frameIndex, info] = matchParticleBlocksToVc7(setPath, vc7Folder)
% MATCHPARTICLEBLOCKSTOVC7  Find which vc7 files (recording images) the
% blocks of a DaVis particle set came from, by matching acquisition time
% stamps rather than block numbers (DaVis numbers the particle blocks from 1
% in every processing session, so images 601-1200 also give blocks 1-600).
%
%   frameIndex = matchParticleBlocksToVc7(setPath, vc7Folder)
%   [frameIndex, info] = ...
%
% frameIndex(k) = vc7 file (1-based, in name order) of particle block k,
% ready for opts.frameIndex of particlePhaseAverage. Needs readimx on the
% path (configureReadimxPath, as loadpiv).
%
% Method: pick a time attribute that both the particle blocks and the vc7
% files carry and that changes from image to image (AcqTimeSeries first,
% then other time-like attributes), binary-search the vc7 files for the
% first block's time, and check that the last block lines up with the
% contiguous range. Errors (with what it found) if anything doesn't match.

    vc7Folder = char(vc7Folder);              % get_PIV_paths returns a string
    files = dir(fullfile(vc7Folder, '*.vc7'));
    if isempty(files), error('matchParticleBlocksToVc7:noFiles', 'No .vc7 files in %s.', vc7Folder); end
    nF = numel(files);
    configureReadimxPath();

    P0 = loadSTBParticles(setPath);
    nB = P0.info.n_blocks;
    PA = stbBlockAttributes(setPath, unique([1 2 nB]));
    pa1 = PA(1).attr;  pa2 = PA(min(2, end)).attr;  paN = PA(end).attr;

    % ---- choose a shared, image-varying time attribute -------------------
    v1 = vc7Attributes(fullfile(vc7Folder, files(1).name));
    prio = ["AcqTimeSeries", "AcqTime", "x_Time", "FastStorageStartTime", "TimeStamp", "Time"];
    shared = intersect(string(fieldnames(pa1)), string(fieldnames(v1)), 'stable');
    cand = [prio(ismember(prio, shared)), setdiff(shared(contains(shared, "Time", 'IgnoreCase', true)), prio, 'stable')'];
    key = "";
    for c = cand
        t1 = parseTime(pa1.(char(c)));  t2 = parseTime(pa2.(char(c)));
        if isfinite(t1) && isfinite(t2) && (nB == 1 || t2 ~= t1)
            key = c;  break
        end
    end
    if key == ""
        error('matchParticleBlocksToVc7:noKey', ...
            ['No time attribute shared by the particle blocks and the vc7 files changes between ' ...
             'images.\nParticle block attributes: %s\nvc7 attributes: %s'], ...
            strjoin(string(fieldnames(pa1)), ', '), strjoin(string(fieldnames(v1)), ', '));
    end
    key = char(key);
    tP1 = parseTime(pa1.(key));  tPN = parseTime(paN.(key));

    % ---- binary search over vc7 files (times increase with file order) ---
    cache = containers.Map('KeyType', 'double', 'ValueType', 'double');
    tv = @(k) vc7Time(files, vc7Folder, k, key, cache);
    lo = 1;  hi = nF;
    if tP1 < tv(lo) || tP1 > tv(hi)
        error('matchParticleBlocksToVc7:range', ...
            'First block %s = %g is outside the vc7 range [%g, %g].', key, tP1, tv(1), tv(nF));
    end
    while hi - lo > 1
        mid = floor((lo + hi) / 2);
        if tv(mid) <= tP1, lo = mid; else, hi = mid; end
    end
    if abs(tv(hi) - tP1) < abs(tv(lo) - tP1), k0 = hi; else, k0 = lo; end

    % ---- verify ------------------------------------------------------------
    dtv = abs(tv(min(k0 + 1, nF)) - tv(max(k0 - 1, 1))) / 2;     % ~ one image interval
    tol = 0.25 * dtv;
    kN = k0 + nB - 1;
    ok1 = abs(tv(k0) - tP1) <= tol;
    okN = kN <= nF && abs(tv(kN) - tPN) <= tol;
    info = struct('key', key, 'firstVc7', k0, 'lastVc7', kN, 'nVc7', nF, ...
                  'tParticle', [tP1 tPN], 'tVc7', [tv(k0), tv(min(kN, nF))], 'tol', tol);
    if ~(ok1 && okN)
        error('matchParticleBlocksToVc7:mismatch', ...
            ['Blocks 1 and %d do not line up with a contiguous vc7 range using %s ' ...
             '(block 1 ~ vc7 %d: %g vs %g; block %d -> vc7 %d: %g vs %g).'], ...
            nB, key, k0, tP1, tv(k0), nB, kN, tPN, tv(min(kN, nF)));
    end
    frameIndex = (k0:kN)';
    fprintf('Particle blocks 1-%d = vc7 files %d-%d (matched on %s)\n', nB, k0, kN, key);
end

% -------------------------------------------------------------------------
function t = vc7Time(files, folder, k, key, cache)
    if isKey(cache, k), t = cache(k); return; end
    a = vc7Attributes(fullfile(folder, files(k).name));
    if ~isfield(a, key), t = NaN; else, t = parseTime(a.(key)); end
    cache(k) = t; %#ok<NASGU>  (handle object, stored)
end

function s = vc7Attributes(filePath)
% buffer and first-frame attributes of a vc7 file, names made MATLAB-valid
    raw = readimx(char(filePath));          % MEX needs a char path, not a string
    s = struct();
    lists = {};
    if isfield(raw, 'Attributes'), lists{end+1} = raw.Attributes; end
    if isfield(raw, 'Frames') && ~isempty(raw.Frames) && isfield(raw.Frames{1}, 'Attributes')
        lists{end+1} = raw.Frames{1}.Attributes;
    end
    for L = 1:numel(lists)
        A = lists{L};
        for i = 1:numel(A)
            nm = matlab.lang.makeValidName(char(A{i}.Name));
            if ~isfield(s, nm), s.(nm) = char(string(A{i}.Value)); end
        end
    end
end

function t = parseTime(str)
% '1530749 µs' -> s; '17:34:36.906' -> s since midnight; plain number -> as is
    str = strtrim(char(str));
    tok = regexp(str, '^(\d+):(\d+):(\d+(?:\.\d+)?)', 'tokens', 'once');
    if ~isempty(tok)
        t = 3600 * str2double(tok{1}) + 60 * str2double(tok{2}) + str2double(tok{3});
        return
    end
    tok = regexp(str, '^\s*([-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*(\S*)', 'tokens', 'once');
    if isempty(tok), t = NaN; return; end
    t = str2double(tok{1});
    switch lower(tok{2})
        case {'µs', 'us', char([194 181 115])}, t = t * 1e-6;
        case 'ms', t = t * 1e-3;
    end
end
