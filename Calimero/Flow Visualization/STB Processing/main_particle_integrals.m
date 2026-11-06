% main_particle_integrals.m
% Integral quantities (wake lift/drag terms incl. the x*omega_y term, Q,
% planar averages, ...) for the particle-based phase average, computed by
% the SAME calc_secondary_vals_phase as the binned data, and saved as a
% separate version so phaseAvg_UI / flowField_UI list it next to the binned
% result:
%   Processed Results\phase_avg\<case>_<version>_phase_avg.mat
%   Processed Results\phase_avg\<case>_<version>_phase_avg_integral.mat
%
% Needs:  main_processing run for the case (binned *_phase_avg.mat and
%         *_phase_avg_integral.mat), and main_particle_processing run with
%         opts.saveGradients = true and all bins.
%
% The particle fields are resampled onto the binned grid and use the
% binned uncertainty for the force mask, so the two versions differ only
% in how velocity and its gradients were estimated.

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name  = 'x2_wings_20deg_8Hz';        % as in main_processing
binned_version = "";                          % bools.version of the binned run
particle_mode  = "pool";                   % mode used in main_particle_processing
run_tag        = "o7";                          % run_tag used in main_particle_processing
% Harmonic regression across phase bins (particleHarmonicSmooth): each
% node's bin-to-bin series is replaced by a fit of hr_harmonics wingbeat
% harmonics, as bools.harmonic_reg does for binned data. 0 = off. Saved as
% its own version (e.g. particle_pool_o5s30_hr10).
hr_harmonics   = 10;
save_filepath_local = "F:\Processed Results\";
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% version name for the particle files ("particle" or "particle_pool");
% avoid "deg" and "Hz" (phaseAvg_UI parses names)
new_version = "particle";
if particle_mode == "pool", new_version = "particle_pool"; end
if strlength(run_tag) > 0, new_version = new_version + "_" + run_tag; end
if hr_harmonics > 0, new_version = new_version + "_hr" + hr_harmonics; end
if strlength(binned_version) > 0, new_version = binned_version + "_" + new_version; end

phase_dir = fullfile(save_filepath_local, "phase_avg");
stem_b    = string(PIV_case_name) + suffix(binned_version);
binned_phase_file    = find_file(save_filepath_local, stem_b + "_phase_avg.mat");
binned_integral_file = find_file(save_filepath_local, stem_b + "_phase_avg_integral.mat");
particle_R_file = fullfile(save_filepath_local, stem_b + "_particle_" + particle_mode + ...
                           suffix(run_tag) + "_phase_avg.mat");
if ~isfile(particle_R_file)
    error("No %s. Run main_particle_processing first.", particle_R_file);
end

% ---- repackage particle result like phase_avg_STB ---------------------
fprintf('Loading %s\n', particle_R_file);
R = load(particle_R_file);
if hr_harmonics > 0
    vars_b = who('-file', char(binned_phase_file));
    if ismember('bin_placement', vars_b)
        Bp = load(binned_phase_file, 'bin_placement');  bp = Bp.bin_placement;
    else
        bp = [];
    end
    fprintf('Harmonic regression across phase bins: %d harmonics\n', hr_harmonics);
    R = particleHarmonicSmooth(R, hr_harmonics, bp);
end
S = particle_to_phase_avg_struct(R, binned_phase_file);
clear R

bools = struct('version', new_version, 'RPCA', false, 'turbine', false, ...
               'compress_save', false);
out_phase = fullfile(phase_dir, string(S.PIV_case_name) + "_" + new_version + "_phase_avg.mat");
fprintf('Saving %s\n', out_phase);
save_STB_struct(out_phase, S, bools);

% ---- DAQ kinematics / power copied from the binned integral file -------
% (phase_avg_STB passes these to calc_secondary_vals_phase, which copies
% them into the _integral file for phaseAvg_UI)
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

% ---- secondary values, exactly as for the binned data -----------------
% calc_secondary_vals_phase saves <case>_<version>_phase_avg_integral.mat
calc_secondary_vals_phase(S, Fdaq, bools, phase_dir, default_trim_bounds());
fprintf('Done. In phaseAvg_UI pick version "%s" for this case.\n', new_version);

% -------------------------------------------------------------------------
function s = suffix(v)
    if strlength(string(v)) > 0, s = "_" + string(v); else, s = ""; end
end

function p = find_file(root, name)
% the UIs read Processed Results\phase_avg\; main_processing may save in the root
    cands = [fullfile(root, "phase_avg", name), fullfile(root, name)];
    k = find(arrayfun(@isfile, cands), 1);
    if isempty(k)
        error("Could not find %s in %s or its phase_avg folder. Run main_processing first.", name, root);
    end
    p = cands(k);
end
