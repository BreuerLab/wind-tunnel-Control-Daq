function method = particle_integrals_case(PIV_case_name, save_filepath_local, version, p)
% PARTICLE_INTEGRALS_CASE  Flow fields and integral quantities (wake
% lift/drag terms incl. x*omega_y, Q, planar averages, ...) of a case's
% particle-based phase average, computed by the SAME
% calc_secondary_vals_phase as the binned data and saved in the new layout
% (stb_file_paths):
%   <save>\phase_avg\<case>[_<version>]_<method>_fields.mat   flow fields
%   <save>\phase_avg\<case>[_<version>]_<method>_integral.mat    integrals
% next to the case's shared file. With p.legacy_files the old combined
% files (version <version>_<method>) are written too.
%
%   method = particle_integrals_case(PIV_case_name, save_filepath_local, version, p)
%
% Needs the case's shared file and a binned flow-field file (for the
% uncertainty mask; p.binned_method, or the first of bin, bin_hr found),
% and the particle fit from particle_phase_avg_case (same p). With
% p.hr_harmonics > 0 the fit is first smoothed across phase bins by
% harmonic regression (particleHarmonicSmooth). With p.hr_band the
% integrals are also computed from the unsmoothed fit, and the standard
% error of each harmonic-regression series (hr_curve_uncertainty) is added
% to the integral file as <name>_hr_se (e.g. lift_hr_se.vortX for
% lift.vortX; 1 sigma). A second estimate with the noise from the binned
% per-frame scatter (hr_curve_uncertainty_frames) is added as
% <name>_hr_se_frames for the forces that have per-frame (BA) values, and
% for lift.vortY from the per-frame omega_y rate (lift_hr_se_frames.vortY;
% needs binned files processed since get_wake_lift saves vortY_rate).

    PIV_case_name = string(PIV_case_name);
    method = particle_method_name(p);
    P = stb_file_paths(save_filepath_local, PIV_case_name, version, method);
    p_fit = p;  p_fit.hr_harmonics = 0;
    Pfit = stb_file_paths(save_filepath_local, PIV_case_name, version, particle_method_name(p_fit));

    if ~isfile(P.shared)
        error("No shared file %s. Run main_processing for the case (or convert_legacy_STB_files).", P.shared);
    end
    if ~isfile(Pfit.fit)
        error("No particle fit %s. Run the particle phase average first (particle_phase_avg_case).", Pfit.fit);
    end
    [binned_fields, Pbin] = find_binned_fields(save_filepath_local, PIV_case_name, version, p);

    % ---- particle fit, optionally smoothed across bins -------------------
    fprintf('Loading %s\n', Pfit.fit);
    R = load(Pfit.fit);
    if p.hr_harmonics > 0
        Bp = load(P.shared, 'bin_placement');      % where the frames of each bin sit
        fprintf('Harmonic regression across phase bins: %d harmonics\n', p.hr_harmonics);
        R = particleHarmonicSmooth(R, p.hr_harmonics, Bp.bin_placement);
    end
    S = particle_to_phase_avg_struct(R, P.shared, binned_fields);
    clear R

    % ---- flow-field file --------------------------------------------------
    [~, Sf] = split_phase_avg_struct(S);
    clear S
    Sf.method = method;  Sf.version = string(version);
    save_opts = struct('compress_save', isfield(p, 'compress_save') && p.compress_save);
    fprintf('Saving %s flow fields to %s\n', method, P.fields);
    save_STB_struct(P.fields, Sf, save_opts);

    % ---- integral quantities, exactly as for the binned data -------------
    Sh = load(P.shared);
    Sm = merge_stb_structs(Sh, Sf);
    clear Sf
    [shared_names, ~] = stb_shared_names();
    daq = shared_names(find(strcmp(shared_names, 'freq_avg')):end);
    Fdaq = struct();
    for k = 1:numel(daq)
        if isfield(Sh, daq{k}), Fdaq.(daq{k}) = Sh.(daq{k}); end
    end
    clear Sh
    legacy_version = particle_version_name(version, p);
    bools = struct('version', legacy_version, 'RPCA', false, 'turbine', false, ...
                   'compress_save', save_opts.compress_save, 'stb_paths', P, 'legacy_files', p.legacy_files);
    if p.legacy_files
        legacy_file = fullfile(P.dir, string(PIV_case_name) + "_" + legacy_version + "_phase_avg.mat");
        fprintf('Saving legacy combined file %s\n', legacy_file);
        save_STB_struct(legacy_file, Sm, bools);
    end
    S_hr = calc_secondary_vals_phase(Sm, Fdaq, bools, P.dir, default_trim_bounds());
    clear Sm

    % ---- uncertainty of the harmonic-regression series --------------------
    if p.hr_harmonics > 0 && (~isfield(p, 'hr_band') || p.hr_band)
        t_band = tic;
        fprintf('Uncertainty bands: integrals of the unsmoothed fit\n');
        R = load(Pfit.fit);
        nPairs = double(R.nPairs(:));
        S = particle_to_phase_avg_struct(R, P.shared, binned_fields);
        clear R
        [~, Sf] = split_phase_avg_struct(S);
        clear S
        Sm = merge_stb_structs(load(P.shared), Sf);
        clear Sf
        bools_raw = bools;  bools_raw.no_save = true;
        S_raw = calc_secondary_vals_phase(Sm, Fdaq, bools_raw, P.dir, default_trim_bounds());
        clear Sm
        Hs = 3;
        if isfield(p, 'hr_band_harmonics'), Hs = p.hr_band_harmonics; end
        Bp = load(P.shared, 'bin_placement');
        phi = bin_times(numel(nPairs), 1, Bp.bin_placement);
        B = hr_series_se(S_hr, S_raw, phi, nPairs, p.hr_harmonics, Hs);
        B.hr_band = struct('type', "curve_se", 'harmonics', p.hr_harmonics, ...
            'noise_harmonics', Hs, 'note', "1-sigma standard error of the HR curve (random error only)");
        save(P.integral, '-struct', 'B', '-append');
        fprintf('Saved %d uncertainty series to %s (%.0f s)\n', ...
            numel(fieldnames(B)) - 1, P.integral, toc(t_band));

        % ---- same, with the noise from the binned per-frame scatter ------
        [~, ~, freq] = parse_name(PIV_case_name);
        period = 1 / str2double(string(freq));
        Bf = hr_series_se_frames(S_hr, Pbin, phi, nPairs, p.hr_harmonics, period);
        if ~isempty(fieldnames(Bf))
            Bf.hr_band_frames = struct('type', "curve_se_frames", 'harmonics', p.hr_harmonics, ...
                'binned', Pbin.fields, 'note', "1-sigma standard error of the HR curve, " + ...
                "noise from the binned frame-to-frame SD / sqrt(frames per bin) (random error only)");
            save(P.integral, '-struct', 'Bf', '-append');
            fprintf('Saved %d frame-scatter uncertainty series to %s\n', ...
                numel(fieldnames(Bf)) - 1, P.integral);
        end
    end
    fprintf('Done: method "%s" for %s.\n', method, PIV_case_name);
end

% -------------------------------------------------------------------------
function B = hr_series_se(S_hr, S_raw, phi, w, H, Hs)
% <name>_hr_se for every per-bin series in the integrals: top-level
% vectors with one value per bin, and those inside top-level structs
% (lift.vortX -> lift_hr_se.vortX)
    nb = numel(w);
    B = struct();
    is_series = @(a) isnumeric(a) && isreal(a) && isvector(a) && numel(a) == nb;
    for f = fieldnames(S_hr)'
        name = f{1};
        if ~isfield(S_raw, name), continue; end
        a = S_hr.(name);  b = S_raw.(name);
        if isstruct(a) && isscalar(a) && isstruct(b) && isscalar(b)
            T = struct();
            for g = fieldnames(a)'
                sub = g{1};
                if isfield(b, sub) && is_series(a.(sub)) && is_series(b.(sub))
                    T.(sub) = reshape(hr_curve_uncertainty(b.(sub), a.(sub), phi, w, H, Hs), size(a.(sub)));
                end
            end
            if ~isempty(fieldnames(T)), B.([name '_hr_se']) = T; end
        elseif is_series(a) && is_series(b)
            B.([name '_hr_se']) = reshape(hr_curve_uncertainty(b, a, phi, w, H, Hs), size(a));
        end
    end
end

% -------------------------------------------------------------------------
function B = hr_series_se_frames(S_hr, Pbin, phi, w, H, period)
% <name>_hr_se_frames: standard error of each HR force curve with each
% bin's noise = (binned frame-to-frame SD)^2 / frames
% (hr_curve_uncertainty_frames), for the forces with per-frame (BA) values
% in the binned file:  lift.* / drag.* <- lift_before_std.* /
% drag_before_std.*, lift_vel / drag_vel <- *_before_std. lift.vortY is
% the time integral of a rate (get_wake_lift), so its noise is that of the
% per-frame rate (lift_before_std.vortY_rate) carried through the same
% integral (lift_vortY_operator).
    B = struct();
    nb = numel(w);
    have = string(stb_who(Pbin));
    names = ["lift_before_std", "drag_before_std", "lift_vel_before_std", "drag_vel_before_std"];
    names = names(ismember(names, have));
    if isempty(names)
        fprintf('No binned per-frame SDs in %s: no frame-scatter uncertainty\n', Pbin.fields);
        return
    end
    D = stb_load(Pbin, names{:});
    fit_se = @(sd, M) reshape(hr_curve_uncertainty_frames(sd, w, phi, w, H, M), 1, []);
    ok_sd = @(sd) isnumeric(sd) && numel(sd) == nb;
    for top = ["lift", "drag"]
        sd_name = top + "_before_std";
        if ~isfield(D, sd_name) || ~isfield(S_hr, top) || ~isstruct(S_hr.(top)), continue; end
        T = struct();
        for g = string(fieldnames(S_hr.(top)))'
            if g == "vortY" && top == "lift"
                if isfield(D.(sd_name), 'vortY_rate') && ok_sd(D.(sd_name).vortY_rate)
                    t = phi(:) * period;
                    T.vortY = fit_se(D.(sd_name).vortY_rate, lift_vortY_operator(t, period));
                else
                    fprintf('No per-frame omega_y rate in %s (binned processing before it was saved): no lift.vortY frame-scatter uncertainty\n', Pbin.fields);
                end
            elseif isfield(D.(sd_name), g) && ok_sd(D.(sd_name).(g)) && numel(S_hr.(top).(g)) == nb
                T.(g) = fit_se(D.(sd_name).(g), []);
            end
        end
        if ~isempty(fieldnames(T)), B.(top + "_hr_se_frames") = T; end
    end
    for top = ["lift_vel", "drag_vel"]
        sd_name = top + "_before_std";
        if isfield(D, sd_name) && ok_sd(D.(sd_name)) && isfield(S_hr, top) && numel(S_hr.(top)) == nb
            B.(top + "_hr_se_frames") = fit_se(D.(sd_name), []);
        end
    end
end

% -------------------------------------------------------------------------
function M = lift_vortY_operator(t, period)
% Linear map from the per-bin omega_y rate to lift.vortY as it is plotted:
% remove the periodic mean (trapezoidal weights wrapping the period,
% periodic_mean), cumtrapz over the bin times, then remove the mean of the
% result as well (phaseAvg_UI plots every curve with its mean removed).
% Without that last step the integral is pinned to zero at the first bin,
% so the band pinched to zero there; with it the integration constant is
% the curve's mean, as plotted. The constant 2*rho*U*U is already in the
% rate (lift.vortY_rate).
    t = t(:);  nb = numel(t);
    tp = [t(end) - period; t; t(1) + period];
    wt = (tp(3:end) - tp(1:end-2)) / 2;           % sums to the period
    P = eye(nb) - ones(nb, 1) * (wt' / period);   % mean removal
    C = zeros(nb);                                % cumtrapz(t, .)
    for i = 2:nb
        C(i, :) = C(i - 1, :);
        dt = t(i) - t(i - 1);
        C(i, i - 1) = C(i, i - 1) + dt / 2;
        C(i, i) = C(i, i) + dt / 2;
    end
    M = P * C * P;
end

% -------------------------------------------------------------------------
function [f, Pb] = find_binned_fields(save_root, case_name, version, p)
% binned flow-field file supplying the uncertainty for the force mask
    if isfield(p, 'binned_method') && strlength(string(p.binned_method)) > 0
        cands = string(p.binned_method);
    else
        cands = ["bin", "bin_hr"];
    end
    for m = cands
        Pb = stb_file_paths(save_root, case_name, version, m);
        if isfile(Pb.fields), f = Pb.fields; return; end
    end
    Pb = [];
    error("No binned flow-field file (%s) for %s. Run main_processing for the case first.", ...
          strjoin(cands, ", "), case_name);
end
