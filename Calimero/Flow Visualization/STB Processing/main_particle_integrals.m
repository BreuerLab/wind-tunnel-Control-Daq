% main_particle_integrals.m
% Integral quantities of ONE case's particle-based phase average
% (particle_integrals_case), for running it on its own: optional harmonic
% regression across bins, repackaging like phase_avg_STB, then
% calc_secondary_vals_phase. Saved in Processed Results\phase_avg\ as its
% own version (e.g. particle_pool_hr20) for phaseAvg_UI / flowField_UI.
% Use the same settings as main_particle_processing (mode, run_tag).

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name       = 'x2_wings_20deg_8Hz';   % as in main_processing
version             = "";                     % binning variant (bools.version in main_processing)
save_filepath_local = "F:\Processed Results\";

p = particle_default_opts();                  % all settings: particle_default_opts.m
% p.run_tag = "o3";                           % same tag as main_particle_processing
% p.hr_harmonics = 20;                        % 0 = no harmonic regression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

particle_integrals_case(PIV_case_name, save_filepath_local, version, p);
