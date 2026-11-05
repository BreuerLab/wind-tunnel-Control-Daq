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
run_tag       = "o3";

% particleGradientFit options
fitOpts = struct();
fitOpts.depthAxis    = 1;      % slab normal (analysis frame)
fitOpts.depthOrder   = 3;      % 3 = cubic; 5 for vortices more compact than ~10 mm along x
fitOpts.inPlaneSigma = 1.5;    % mm (overridden by match_binned_grid)
fitOpts.gridSpacing  = 1.5;    % mm (overridden by match_binned_grid)
% Fit directly at the nodes of the binned case's grid. main_particle_integrals
% resamples onto that grid anyway, so a finer fit grid is mostly discarded
% work. sigma is then set to sigma_per_spacing * grid spacing: the force
% integrals barely depend on sigma, but sigma below ~half the spacing would
% leave gaps between nodes in the integrals. Set false for fine maps.
match_binned_grid = true;
sigma_per_spacing = 0.75;      % 0.5 left visible node-to-node noise in the forces
fitOpts.minParticles = 20;
fitOpts.maxResid     = 0.5;    % m/s
fitOpts.mask         = "auto"; % per pair (average) or per bin (pool)

% particlePhaseAverage options
opts = struct();
opts.mode          = "pool";   % "average" (fit pairs, then average) or "pool"
opts.bins          = [];          % [] = all bins; e.g. 1:10 for a quick test
opts.numWorkers    = 8;          % i9-13900K: 24 cores; lower if memory runs out
opts.binsPerChunk  = 16;          % bins held in memory at once
opts.saveGradients = true;        % needed by main_particle_integrals
% vc7 file of each particle block (cell array, one vector per set).
% [] = found automatically for every set (matchParticleBlocksToVc7), or
% block k = vc7 file k for a single set covering the whole recording.
opts.frameIndex    = [];
% one-time MAT-file copy of the particles (~3.6 MB per image pair, ~11 GB
% for 3000): built on the first run (about as long as reading through
% lvpyio once), then reruns read from it in parallel. Delete the folder
% after reprocessing the particles in DaVis. "" = always read via lvpyio.
opts.cacheDir      = fullfile(save_filepath_local, "particle_cache", PIV_case_name);

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

if match_binned_grid
    G = load(phase_file, 'y', 'z', 'L');
    ic = (size(G.y, 1) + 1) / 2;
    yv = squeeze(G.y(ic, :, 1)) * G.L * 1000;    % mm
    zv = squeeze(G.z(ic, 1, :)) * G.L * 1000;
    dy = median(abs(diff(yv)));  dz = median(abs(diff(zv)));
    if abs(dy - dz) > 0.01 * dy
        warning('Binned grid spacing differs in y (%.3f mm) and z (%.3f mm); using the smaller.', dy, dz);
    end
    fitOpts.gridSpacing  = min(dy, dz);
    fitOpts.gridLimits   = [min(yv) max(yv) min(zv) max(zv)] + [0 1 0 1] * 1e-6 * min(dy, dz);  % keep last node despite round-off
    fitOpts.inPlaneSigma = sigma_per_spacing * fitOpts.gridSpacing;
    fprintf('Fitting on the binned grid: %d x %d nodes, spacing %.2f mm, sigma %.2f mm\n', ...
            numel(yv), numel(zv), fitOpts.gridSpacing, fitOpts.inPlaneSigma);
end
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
