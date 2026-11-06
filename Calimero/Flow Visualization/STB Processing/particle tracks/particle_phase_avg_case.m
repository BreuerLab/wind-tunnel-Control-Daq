function R_file = particle_phase_avg_case(PIV_case_name, save_filepath_local, binned_version, p)
% PARTICLE_PHASE_AVG_CASE  Particle-based phase average of one case
% (particlePhaseAverage), with the SAME phase binning as its binned phase
% average: bin_ind_arr / num_bins come from the binned *_phase_avg.mat that
% phase_avg_STB saved. Saves <save>\<case>[_<version>]_particle_<mode>
% [_<run_tag>]_phase_avg.mat and returns its path.
%
%   R_file = particle_phase_avg_case(PIV_case_name, save_filepath_local, binned_version, p)
%
%   binned_version : suffix of the binned files ("" for none; with
%                    harmonic regression / RPCA as phase_avg_STB names them)
%   p              : particle_default_opts()

    PIV_case_name = string(PIV_case_name);
    stem = PIV_case_name + suffix(binned_version);

    % ---- phase binning (and grid) from the binned phase-avg file -------
    phase_file = find_file(save_filepath_local, stem + "_phase_avg.mat");
    vars = who('-file', char(phase_file));
    if ~all(ismember({'bin_ind_arr', 'num_bins'}, vars))
        error("%s has no bin_ind_arr/num_bins; rerun main_processing.", phase_file);
    end
    Sb = load(phase_file, 'bin_ind_arr', 'num_bins');

    fitOpts = p.fit;
    if p.match_binned_grid
        G = load(phase_file, 'y', 'z', 'L');
        ic = (size(G.y, 1) + 1) / 2;
        yv = squeeze(G.y(ic, :, 1)) * G.L * 1000;    % mm
        zv = squeeze(G.z(ic, 1, :)) * G.L * 1000;
        dy = median(abs(diff(yv)));  dz = median(abs(diff(zv)));
        if abs(dy - dz) > 0.01 * dy
            warning('Binned grid spacing differs in y (%.3f mm) and z (%.3f mm); using the smaller.', dy, dz);
        end
        fitOpts.gridSpacing  = min(dy, dz);
        fitOpts.gridLimits   = [min(yv) max(yv) min(zv) max(zv)] + [0 1 0 1] * 1e-6 * min(dy, dz);
        fitOpts.inPlaneSigma = p.sigma_per_spacing * fitOpts.gridSpacing;
        fprintf('Fitting on the binned grid: %d x %d nodes, spacing %.2f mm, sigma %.2f mm\n', ...
                numel(yv), numel(zv), fitOpts.gridSpacing, fitOpts.inPlaneSigma);
    end
    nAll = numel(Sb.bin_ind_arr);
    fprintf('%d image pairs in %d phase bins (median %d pairs per bin)\n', nAll, Sb.num_bins, ...
            median(accumarray(Sb.bin_ind_arr(:), 1, [double(Sb.num_bins) 1])));

    % ---- particle sets and their vc7 files -------------------------------
    vc7Folder = get_PIV_paths(PIV_case_name);
    pattern = string(p.set_pattern);
    if strlength(pattern) == 0
        pattern = fullfile(fileparts(char(vc7Folder)), '*.set');   % the case folder
    end
    sets = resolveParticleSets(pattern);
    fprintf('%d particle set(s):\n', numel(sets));
    P1 = loadSTBParticles(sets(1));                % metadata only
    if isscalar(sets) && P1.info.n_blocks == nAll
        frameIndex = {(1:nAll)'};
        fprintf('  %s: blocks = vc7 files 1-%d\n', sets(1), nAll);
    else
        frameIndex = cell(numel(sets), 1);
        for s = 1:numel(sets)
            fprintf('  %s: ', sets(s));
            frameIndex{s} = matchParticleBlocksToVc7(sets(s), vc7Folder);
        end
    end
    cov = false(nAll, 1);
    for s = 1:numel(frameIndex)
        f = frameIndex{s};  cov(f(f <= nAll)) = true;
    end
    gaps = find(diff([0; ~cov; 0]) == 1);  gapEnd = find(diff([0; ~cov; 0]) == -1) - 1;
    fprintf('vc7 files with particle data: %d of %d', nnz(cov), nAll);
    if ~isempty(gaps)
        fprintf('; missing: %s', strjoin(arrayfun(@(a, b) sprintf('%d-%d', a, b), gaps, gapEnd, ...
                'UniformOutput', false), ', '));
    end
    fprintf('\n');

    % ---- particle phase average ------------------------------------------
    opts = struct('mode', p.mode, 'bins', [], 'numWorkers', p.numWorkers, ...
                  'binsPerChunk', p.binsPerChunk, 'saveGradients', true, ...
                  'frameIndex', {frameIndex}, 'cacheDir', "");
    if p.cache
        root = string(p.cache_root);
        if strlength(root) == 0, root = fullfile(save_filepath_local, "particle_cache"); end
        opts.cacheDir = fullfile(root, PIV_case_name);
    end
    t0 = tic;
    R = particlePhaseAverage(sets, Sb.bin_ind_arr, fitOpts, opts);
    R.num_bins = double(Sb.num_bins);
    R.PIV_case_name = PIV_case_name;
    fprintf('Particle phase average (%s mode) done in %.1f min\n', R.mode, toc(t0)/60);

    R_file = fullfile(save_filepath_local, stem + "_particle_" + p.mode + ...
                      suffix(p.run_tag) + "_phase_avg.mat");
    save(R_file, '-struct', 'R', '-v7.3');
    fprintf('Saved %s\n', R_file);

    if p.plot, quick_look(R); end
end

% -------------------------------------------------------------------------
function quick_look(R)
    [~, jb] = max(squeeze(max(abs(R.omega_y), [], [1 2], 'omitnan')));
    ax = 'xyz';
    figure('Color', 'w', 'Name', 'Particle phase average');
    tl = tiledlayout(1, 3, 'TileSpacing', 'compact');
    title(tl, sprintf('%s, bin %d of %d (%s mode)', R.PIV_case_name, R.bins(jb), R.num_bins, R.mode), ...
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
end

function s = suffix(v)
    if strlength(string(v)) > 0, s = "_" + string(v); else, s = ""; end
end

function f = find_file(root, name)
% the UIs read Processed Results\phase_avg\; phase_avg_STB saves in the
% root. If both exist, the newer one (e.g. just reprocessed) is used.
    cands = [fullfile(root, "phase_avg", name), fullfile(root, name)];
    ok = arrayfun(@isfile, cands);
    if ~any(ok)
        error("Could not find %s in %s or its phase_avg folder. Run the binned processing first.", name, root);
    end
    cands = cands(ok);
    t = zeros(size(cands));
    for i = 1:numel(cands), d = dir(cands(i)); t(i) = d.datenum; end
    [~, k] = max(t);
    f = cands(k);
end
