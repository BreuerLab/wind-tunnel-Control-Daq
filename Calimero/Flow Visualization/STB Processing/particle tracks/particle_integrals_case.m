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
% lift.vortX; 1 sigma).

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
    binned_fields = find_binned_fields(save_filepath_local, PIV_case_name, version, p);

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
function f = find_binned_fields(save_root, case_name, version, p)
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
    error("No binned flow-field file (%s) for %s. Run main_processing for the case first.", ...
          strjoin(cands, ", "), case_name);
end
