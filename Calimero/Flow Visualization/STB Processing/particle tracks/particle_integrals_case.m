function new_version = particle_integrals_case(PIV_case_name, save_filepath_local, binned_version, p)
% PARTICLE_INTEGRALS_CASE  Integral quantities (wake lift/drag terms incl.
% x*omega_y, Q, planar averages, ...) for a case's particle-based phase
% average, computed by the SAME calc_secondary_vals_phase as the binned
% data, and saved as its own version so phaseAvg_UI / flowField_UI list it
% next to the binned result:
%   <save>\phase_avg\<case>_<version>_phase_avg.mat
%   <save>\phase_avg\<case>_<version>_phase_avg_integral.mat
%
%   new_version = particle_integrals_case(PIV_case_name, save_filepath_local, binned_version, p)
%
% Needs the binned *_phase_avg.mat and *_phase_avg_integral.mat and the
% particle phase average from particle_phase_avg_case (same p). With
% p.hr_harmonics > 0 the particle fields are first smoothed across phase
% bins by harmonic regression (particleHarmonicSmooth).

    PIV_case_name = string(PIV_case_name);
    stem = PIV_case_name + suffix(binned_version);
    new_version = particle_version_name(binned_version, p);

    phase_dir = fullfile(save_filepath_local, "phase_avg");
    if ~isfolder(phase_dir), mkdir(phase_dir); end
    binned_phase_file    = find_file(save_filepath_local, stem + "_phase_avg.mat");
    binned_integral_file = find_file(save_filepath_local, stem + "_phase_avg_integral.mat");
    R_file = fullfile(save_filepath_local, stem + "_particle_" + p.mode + ...
                      suffix(p.run_tag) + "_phase_avg.mat");
    if ~isfile(R_file)
        error("No %s. Run the particle phase average first (particle_phase_avg_case).", R_file);
    end

    % ---- particle result, optionally smoothed across bins ----------------
    fprintf('Loading %s\n', R_file);
    R = load(R_file);
    if p.hr_harmonics > 0
        vars_b = who('-file', char(binned_phase_file));
        bp = [];
        if ismember('bin_placement', vars_b)
            Bp = load(binned_phase_file, 'bin_placement');  bp = Bp.bin_placement;
        end
        fprintf('Harmonic regression across phase bins: %d harmonics\n', p.hr_harmonics);
        R = particleHarmonicSmooth(R, p.hr_harmonics, bp);
    end
    S = particle_to_phase_avg_struct(R, binned_phase_file);
    clear R

    bools = struct('version', new_version, 'RPCA', false, 'turbine', false, ...
                   'compress_save', false);
    out_phase = fullfile(phase_dir, string(S.PIV_case_name) + "_" + new_version + "_phase_avg.mat");
    fprintf('Saving %s\n', out_phase);
    save_STB_struct(out_phase, S, bools);

    % ---- DAQ kinematics / power copied from the binned integral file -----
    daq_names = {'freq_avg', 'norm_time_speed', 'phase_avg_pos', 'phase_std_pos', ...
        'phase_avg_speed', 'phase_std_speed', 'phase_avg_acc', 'phase_std_acc', ...
        'phase_avg_wing_pos', 'phase_std_wing_pos', 'phase_avg_wing_speed', 'phase_std_wing_speed', ...
        'phase_avg_wing_acc', 'phase_std_wing_acc', 'bin_count_speed', 'bin_std_speed', ...
        'phase_avg_volt', 'phase_std_volt', 'phase_avg_cur', 'phase_std_cur', ...
        'phase_avg_speed_error', 'phase_avg_power', 'phase_avg_volt_model'};
    vars = who('-file', char(binned_integral_file));
    daq_names = daq_names(ismember(daq_names, vars));
    Fdaq = load(binned_integral_file, daq_names{:});
    fprintf('Copied %d DAQ fields from %s\n', numel(daq_names), binned_integral_file);

    % ---- secondary values, exactly as for the binned data ----------------
    calc_secondary_vals_phase(S, Fdaq, bools, phase_dir, default_trim_bounds());
    fprintf('Done. In phaseAvg_UI pick version "%s" for this case.\n', new_version);
end

% -------------------------------------------------------------------------
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
