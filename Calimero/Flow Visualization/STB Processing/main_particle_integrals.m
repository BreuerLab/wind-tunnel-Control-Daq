% main_particle_integrals.m
% Integral quantities of ONE case's particle-based phase average
% (particle_integrals_case), for running it on its own: optional harmonic
% regression across bins, repackaging like phase_avg_STB, then
% calc_secondary_vals_phase. Saved in Processed Results\phase_avg\ as its
% own version (e.g. particle_pool_o5s30_hr20) for phaseAvg_UI / flowField_UI.
% Use the same settings as main_particle_processing (mode, run_tag).

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name       = 'x2_wings_20deg_8Hz';   % as in main_processing
binned_version      = "";                     % version part of the binned files
save_filepath_local = "F:\Processed Results\";

p = particle_default_opts();                  % all settings: particle_default_opts.m
% p.run_tag = "o5s30";
% p.hr_harmonics = 20;                        % 0 = no harmonic regression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

particle_integrals_case(PIV_case_name, save_filepath_local, binned_version, p);
