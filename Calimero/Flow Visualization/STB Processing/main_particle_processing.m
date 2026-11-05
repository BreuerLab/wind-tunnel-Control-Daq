% main_particle_processing.m
% Phase-averaged velocity and vorticity computed directly from the STB
% particle tracks (particleGradientFit / particlePhaseAverage), using the
% SAME phase binning as the binned-vector phase averages: bin_ind_arr and
% num_bins are read from the phase-avg .mat that main_processing ->
% phase_avg_STB saved. Image pair k = vc7 file k = particle block k.
%
% Run main_processing for the case first (it saves the binning). Then run
% main_particle_integrals to get the integral quantities for the GUIs.

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path (as main_processing)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ----------------------- Parameter Selection ------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name = 'x2_wings_20deg_8Hz';           % as in main_processing
version       = "";                             % bools.version used there (RPCA files not handled)
% particle set(s) of the trial: one .set, a list of batch sets (images
% 1-600, 601-1200, ...), or a wildcard. Non-particle sets are skipped.
setPath       = "F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\*.set";

save_filepath_local = "F:\Processed Results\";
save_results  = true;
% optional tag for this run's settings, so runs don't overwrite each other,
% e.g. "o5" -> ..._particle_pool_o5_phase_avg.mat (use the same tag in
% main_particle_integrals; avoid "deg" and "Hz")
run_tag       = "";

% particleGradientFit options
fitOpts = struct();
fitOpts.depthAxis    = 1;      % slab normal (analysis frame)
fitOpts.depthOrder   = 3;      % 3 = cubic; 5 for vortices more compact than ~10 mm along x
fitOpts.inPlaneSigma = 1.5;    % mm
fitOpts.gridSpacing  = 1.5;    % mm (~sigma; 1 mm oversamples)
fitOpts.minParticles = 20;
fitOpts.maxResid     = 0.5;    % m/s
fitOpts.mask         = "auto"; % per pair (average) or per bin (pool)

% particlePhaseAverage options
opts = struct();
opts.mode          = "average";   % "average" (fit pairs, then average) or "pool"
opts.bins          = [];          % [] = all bins; e.g. 1:10 for a quick test
opts.numWorkers    = 8;          % i9-13900K: 24 cores; lower if memory runs out
opts.binsPerChunk  = 32;          % bins held in memory at once
opts.saveGradients = true;        % needed by main_particle_integrals
% vc7 file of each particle block (cell array, one vector per set).
% [] = found automatically for every set (matchParticleBlocksToVc7), or
% block k = vc7 file k for a single set covering the whole recording.
opts.frameIndex    = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ---- phase binning from the phase-avg file ---------------------------
phase_name = string(PIV_case_name) + version_suffix(version) + "_phase_avg.mat";
cands = [fullfile(save_filepath_local, "phase_avg", phase_name), fullfile(save_filepath_local, phase_name)];
k = find(arrayfun(@isfile, cands), 1);
if isempty(k)
    error("No %s in %s or its phase_avg folder. Run main_processing for this case first.", ...
          phase_name, save_filepath_local);
end
phase_file = cands(k);
vars = who('-file', char(phase_file));
if ~all(ismember({'bin_ind_arr', 'num_bins'}, vars))
    error("%s has no bin_ind_arr/num_bins; rerun main_processing.", phase_file);
end
Sb = load(phase_file, 'bin_ind_arr', 'num_bins');
fprintf('%d image pairs in %d phase bins (median %d pairs per bin)\n', ...
        numel(Sb.bin_ind_arr), Sb.num_bins, ...
        median(accumarray(Sb.bin_ind_arr(:), 1, [double(Sb.num_bins) 1])));

% ---- which recording images does each particle set cover? -------------
% DaVis numbers particle blocks from 1 in every processing session, so the
% blocks of each set are matched to vc7 files by their source images.
sets = resolveParticleSets(setPath);
nAll = numel(Sb.bin_ind_arr);
fprintf('%d particle set(s):\n', numel(sets));
if isempty(opts.frameIndex)
    P1 = loadSTBParticles(sets(1));            % metadata only
    nBlk1 = P1.info.n_blocks;
    if isscalar(sets) && nBlk1 == nAll
        opts.frameIndex = {(1:nAll)'};
    else
        opts.frameIndex = cell(numel(sets), 1);
        vc7Folder = get_PIV_paths(PIV_case_name);
        for s = 1:numel(sets)
            fprintf('  %s: ', sets(s));
            opts.frameIndex{s} = matchParticleBlocksToVc7(sets(s), vc7Folder);
        end
    end
end
cov = false(nAll, 1);
for s = 1:numel(opts.frameIndex), cov(opts.frameIndex{s}) = true; end
gaps = find(diff([0; ~cov; 0]) == 1);  gapEnd = find(diff([0; ~cov; 0]) == -1) - 1;
fprintf('vc7 files with particle data: %d of %d', nnz(cov), nAll);
if ~isempty(gaps)
    fprintf('; missing: %s', strjoin(arrayfun(@(a, b) sprintf('%d-%d', a, b), gaps, gapEnd, ...
            'UniformOutput', false), ', '));
end
fprintf('\n');

% ---- particle phase average ------------------------------------------
tic
R = particlePhaseAverage(sets, Sb.bin_ind_arr, fitOpts, opts);
R.num_bins = double(Sb.num_bins);
R.PIV_case_name = string(PIV_case_name);
fprintf('Particle phase average (%s mode) done in %.1f min\n', R.mode, toc/60);

if save_results
    out = fullfile(save_filepath_local, string(PIV_case_name) + version_suffix(version) + ...
                   "_particle_" + R.mode + tag_suffix(run_tag) + "_phase_avg.mat");
    save(out, '-struct', 'R', '-v7.3');
    fprintf('Saved %s\n', out);
end

% ---- quick look --------------------------------------------------------
[~, jb] = max(squeeze(max(abs(R.omega_y), [], [1 2], 'omitnan')));
ax = 'xyz';
figure('Color', 'w', 'Name', 'Particle phase average');
tl = tiledlayout(1, 3, 'TileSpacing', 'compact');
title(tl, sprintf('%s, bin %d of %d (%s mode)', PIV_case_name, R.bins(jb), R.num_bins, R.mode), ...
      'Interpreter', 'none');
for c = {'omega_x', 'omega_y'}
    nexttile
    C = R.(c{1})(:, :, jb);
    pcolor(R.A1, R.A2, double(C)); shading flat; axis equal tight; colorbar
    lim = prctile(abs(C(:)), 99.5);  if isfinite(lim) && lim > 0, caxis([-lim lim]); end
    xlabel(sprintf('%s (mm)', ax(R.inPlaneAxes(1)))); ylabel(sprintf('%s (mm)', ax(R.inPlaneAxes(2))));
    title(sprintf('\\%s (1/s)', c{1}));
end
nexttile
bar(R.bins, R.nPairs); xlabel('Phase bin'); ylabel('Image pairs'); title('Pairs per bin'); grid on

function s = tag_suffix(tag)
    if strlength(string(tag)) > 0, s = "_" + string(tag); else, s = ""; end
end

function s = version_suffix(v)
    if strlength(string(v)) > 0, s = "_" + string(v); else, s = ""; end
end
