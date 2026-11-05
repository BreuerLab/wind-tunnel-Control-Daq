% main_particle_processing.m
% Phase-averaged velocity and vorticity computed directly from the STB
% particle tracks (particleGradientFit / particlePhaseAverage), using the
% SAME phase binning as the binned-vector phase averages: bin_ind_arr and
% num_bins are read from the phase-avg .mat that main_processing ->
% phase_avg_STB saved. Image pair k = vc7 file k = particle block k.
%
% Run main_processing for the case first (it saves the binning).

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ----------------------- Parameter Selection ------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name = 'x2_wings_20deg_8Hz_BIN2';      % as in main_processing
version       = "";                             % bools.version used there (RPCA files not handled)
setPath       = "F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\ShakeTheBox 2-pulse.set";

save_filepath_local = "F:\Processed Results\";
save_results  = true;

% particleGradientFit options
fitOpts = struct();
fitOpts.depthAxis    = 1;      % slab normal (analysis frame)
fitOpts.depthOrder   = 3;      % cubic through the slab
fitOpts.inPlaneSigma = 1.5;    % mm
fitOpts.gridSpacing  = 1.5;    % mm (~sigma; 1 mm oversamples)
fitOpts.minParticles = 20;
fitOpts.maxResid     = 0.5;    % m/s
fitOpts.mask         = "auto"; % per pair (average) or per bin (pool)

% particlePhaseAverage options
opts = struct();
opts.mode          = "average";   % "average" (fit pairs, then average) or "pool"
opts.bins          = [];          % [] = all bins; e.g. 1:10 for a quick test
opts.numWorkers    = 16;          % i9-13900K: 24 cores; lower if memory runs out
opts.binsPerChunk  = 32;          % bins held in memory at once
opts.saveGradients = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ---- phase binning from the phase-avg file ---------------------------
phase_file = fullfile(save_filepath_local, string(PIV_case_name) + ...
                      version_suffix(version) + "_phase_avg.mat");
if ~isfile(phase_file)
    error("No phase-avg file %s. Run main_processing for this case first.", phase_file);
end
vars = who('-file', char(phase_file));
if ~all(ismember({'bin_ind_arr', 'num_bins'}, vars))
    error("%s has no bin_ind_arr/num_bins; rerun main_processing.", phase_file);
end
Sb = load(phase_file, 'bin_ind_arr', 'num_bins');
fprintf('%d image pairs in %d phase bins (median %d pairs per bin)\n', ...
        numel(Sb.bin_ind_arr), Sb.num_bins, ...
        median(accumarray(Sb.bin_ind_arr(:), 1, [double(Sb.num_bins) 1])));

% ---- particle phase average ------------------------------------------
tic
R = particlePhaseAverage(setPath, Sb.bin_ind_arr, fitOpts, opts);
R.num_bins = double(Sb.num_bins);
R.PIV_case_name = string(PIV_case_name);
fprintf('Particle phase average (%s mode) done in %.1f min\n', R.mode, toc/60);

if save_results
    out = fullfile(save_filepath_local, string(PIV_case_name) + version_suffix(version) + ...
                   "_particle_" + R.mode + "_phase_avg.mat");
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

function s = version_suffix(v)
    if strlength(string(v)) > 0, s = "_" + string(v); else, s = ""; end
end
