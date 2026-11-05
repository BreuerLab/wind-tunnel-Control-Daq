function cacheParticleFrames(setPath, frameIndex, cacheDir, blocksPerRead)
% CACHEPARTICLEFRAMES  One-time conversion of DaVis particle sets into one
% MAT-file per vc7 frame, so later runs read particles without lvpyio.
%
%   cacheParticleFrames(setPath, frameIndex, cacheDir)
%   cacheParticleFrames(setPath, frameIndex, cacheDir, blocksPerRead)
%
%   setPath    : string array of particle sets (resolveParticleSets)
%   frameIndex : cell array, vc7 file index of every block of each set
%                (matchParticleBlocksToVc7)
%   cacheDir   : folder for frame_00001.mat ... (created if needed)
%   blocksPerRead : blocks per lvpyio call (default 50)
%
% Each file holds D (single, N x 9: x y z u v w I1 I2 trackID, analysis
% frame, mm and m/s, as loadSTBParticles) and the source set and block.
% Frames already in the cache are skipped, so an interrupted run resumes.
% Size: ~3.6 MB per frame for ~100k tracks (~11 GB for 3000 frames).
% Delete the folder to rebuild (e.g. after reprocessing in DaVis).

    if nargin < 4 || isempty(blocksPerRead), blocksPerRead = 50; end
    setPath = string(setPath(:));
    if ~iscell(frameIndex), frameIndex = {frameIndex}; end
    if ~isfolder(cacheDir), mkdir(cacheDir); end

    t0 = tic;  nNew = 0;
    for s = 1:numel(setPath)
        fi = frameIndex{s}(:);
        todo = find(~arrayfun(@(f) isfile(cacheFile(cacheDir, f)), fi));
        if isempty(todo), continue; end
        fprintf('Caching %d image pairs from %s\n', numel(todo), setPath(s));
        for c0 = 1:blocksPerRead:numel(todo)
            blk = todo(c0 : min(c0 + blocksPerRead - 1, numel(todo)));
            P = loadSTBParticles(setPath(s), blk);
            Dall = P.data;
            for b = blk(:)'
                D = single(Dall(Dall(:, 10) == b, 1:9)); %#ok<NASGU>
                src_set = setPath(s);  src_block = b;    %#ok<NASGU>
                save(cacheFile(cacheDir, fi(b)), 'D', 'src_set', 'src_block', '-v6');
            end
            nNew = nNew + numel(blk);
            fprintf('  %d / %d (%.0f s)\n', min(c0 + blocksPerRead - 1, numel(todo)), numel(todo), toc(t0));
        end
        mod = stbPyModule();  mod.close();
    end
    if nNew > 0, fprintf('Cached %d image pairs in %.1f min\n', nNew, toc(t0) / 60); end
end

function f = cacheFile(cacheDir, frame)
    f = fullfile(cacheDir, sprintf('frame_%05d.mat', frame));
end
