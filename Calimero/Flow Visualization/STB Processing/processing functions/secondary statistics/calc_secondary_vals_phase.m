function S = calc_secondary_vals_phase(D, F, bools, save_filepath_local, bounds)
% Returns the integral quantities S as well as saving them. With
% bools.no_save nothing is saved (S only; used for the unsmoothed particle
% fit's forces in particle_integrals_case).
tic

config.uField = 'u_phase_avg';
config.vField = 'v_phase_avg';
config.wField = 'w_phase_avg';
config.UtotField = 'Utot_phase_avg';
config.UtotDiffField = 'Utot_diff_phase_avg';

config.vortXField = 'vortX_phase_avg';
config.vortYField = 'vortY_phase_avg';
config.vortZField = 'vortZ_phase_avg';
% vorticity of the phase-averaged velocity
config.vortXUavgField = 'vortX_uavg';
config.vortYUavgField = 'vortY_uavg';
config.vortZUavgField = 'vortZ_uavg';
config.vortTotField = 'vortTot_phase_avg';

config.uncField = 'uncTot_phase_avg';
config.numPField = 'numP_phase_avg';
config.helField = 'hel_phase_avg';

config.dudxField = 'dudx_phase_avg';
config.dudyField = 'dudy_phase_avg';
config.dudzField = 'dudz_phase_avg';
config.dvdxField = 'dvdx_phase_avg';
config.dwdxField = 'dwdx_phase_avg';
config.dvdyField = 'dvdy_phase_avg';
config.dwdzField = 'dwdz_phase_avg';
config.dvdzField = 'dvdz_phase_avg';
config.dwdyField = 'dwdy_phase_avg';

config.uuField = 'uu_stress';
config.vvField = 'vv_stress';
config.wwField = 'ww_stress';
config.uvField = 'uv_stress';
config.uwField = 'uw_stress';
config.vwField = 'vw_stress';
config.uwxField = 'u_wx_stress';
config.uwyField = 'u_wy_stress';

if ~bools.turbine
    num_bins = D.num_bins;
    speed = D.U_act * D.U;
    [~, ~, freq] = parse_name(D.PIV_case_name);
    dt = 1 / (freq * num_bins);
    x_conv = zeros(1, num_bins);
    for k = 1:num_bins
        x_conv(k) =  speed * dt * (k - 1);
    end
    
    config.xConv = x_conv;   % nominal, uniform (used by helm_decomp)
    % actual bin times (mean phase of each bin's frames) for the lift
    % integrals in get_wake_lift; nominal if bin_placement not saved
    placement = [];
    if isfield(D, 'bin_placement'), placement = D.bin_placement; end
    config.xConvBins = speed * bin_times(num_bins, 1/freq, placement)';
    config.period = 1 / freq;
    config.includeHelmDecomp = true;
    
    config.speed = speed;
    config.density = D.rho_act;
else
    config.speed = D.U;
    config.density = D.rho;
end

config.length = D.L;

% Standard error of the phase-averaged u, v, w at each point: the
% frame-to-frame SD within the bin / sqrt(frames in the bin)
if isfield(D, 'u_phase_std') && isfield(D, 'bin_count')
    n_frames = reshape(sqrt(double(D.bin_count)), 1, 1, 1, []);
    D.u_phase_se = D.u_phase_std ./ n_frames;
    D.v_phase_se = D.v_phase_std ./ n_frames;
    D.w_phase_se = D.w_phase_std ./ n_frames;
    config.uSeField = 'u_phase_se';
    config.vSeField = 'v_phase_se';
    config.wSeField = 'w_phase_se';
end

S = calc_secondary_vals_common(D, config, bounds);
if isfield(bools, 'no_save') && bools.no_save
    return
end

% New file layout (bools.stb_paths from phase_avg_STB or the particle
% steps): the integral file holds the integral quantities and, for the
% binned method, the per-frame-averaged forces; the DAQ data are in the
% shared file. With bools.legacy_files (default false) the old combined
% integral file (with the DAQ data copied in) is written too.
legacy = isfield(bools, 'legacy_files') && bools.legacy_files;
if isfield(bools, 'stb_paths')
    P = bools.stb_paths;
    Si = S;
    [~, before_avg] = stb_shared_names();
    for k = 1:numel(before_avg)
        if isfield(D, before_avg{k}), Si.(before_avg{k}) = D.(before_avg{k}); end
    end
    Si.method = P.method;
    Si.PIV_case_name = string(D.PIV_case_name);
    disp("Saving integral quantities to: " + P.integral)
    save_STB_struct(P.integral, Si, bools);
    clear Si
    if ~legacy
        fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
        return
    end
end

% legacy combined integral file: copy over data from phase averaged
% kinematics and power
fnames = fieldnames(F);
for i = 1:numel(fnames)
    S.(fnames{i}) = F.(fnames{i});
end

% same version name as the main file (bools.version, e.g. _coarse)
save_stem = string(D.PIV_case_name);
if isfield(bools, 'version') && strlength(string(bools.version)) > 0
    save_stem = save_stem + "_" + string(bools.version);
end
if bools.RPCA
    save_filename = save_stem + "_RPCA_phase_avg_integral.mat";
else
    save_filename = save_stem + "_phase_avg_integral.mat";
end

% Save the entire structure
save_path = fullfile(save_filepath_local, save_filename);
disp("Saving data to: " + save_path)
save_STB_struct(save_path, S, bools);

fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
end