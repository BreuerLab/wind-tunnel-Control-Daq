% main_particle_processing.m
% Particle-based phase average of ONE case (particle_phase_avg_case), for
% running it on its own. The same step runs inside main_processing /
% main_processing_batch with bools.particle.run = true.
%
% Needs the binned phase average of the case (main_processing), which
% supplies the phase binning and grid. Then run main_particle_integrals
% (same settings) for the integral quantities, or use particle_process_case
% to do both.

close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path (as main_processing)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PIV_case_name       = 'x2_wings_20deg_8Hz';   % as in main_processing
version             = "";                     % binning variant (bools.version in main_processing)
save_filepath_local = "F:\Processed Results\";

p = particle_default_opts();                  % all settings: particle_default_opts.m
p.plot = true;
% p.run_tag = "o3";  p.fit.depthOrder = 3;      % tag non-default settings
% p.set_pattern = "F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\*.set";   % default: the case folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

particle_phase_avg_case(PIV_case_name, save_filepath_local, version, p);
