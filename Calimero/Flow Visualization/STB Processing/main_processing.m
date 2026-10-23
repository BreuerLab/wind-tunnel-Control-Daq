clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ----------------------- Parameter Selection ------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Want to know what case names are available?
% Call "  case_names = get_case_names();  "
% PIV_case_name = 'UP_two_flexible_20deg_6Hz';
% PIV_case_name = 'x5_wings_20deg_0Hz';
% PIV_case_name = 'MPS_wings_20deg_6Hz';
PIV_case_name = 'x2_wings_20deg_4Hz';
% PIV_case_name = 'x3_ring';
% PIV_case_name = 'turbine';

% num_images = 1200; 
num_images = 3000;

% save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "F:\Processed Results\";

bools.nondim = true; % non-dimensionalize data
bools.RPCA = false; % RPCA filtering of vector fields
bools.Q_inst = false; % per-frame Q averaged over each bin, plus its std (Q*_inst_avg, Q*_inst_std), slow
bools.vort_uavg = false; % vorticity of the averaged velocity (vort*_uavg)
bools.num_workers = 8; % parallel workers for phase bins (0 = serial); lower if out of memory
bools.compress_save = false; % true = MATLAB's compressed .mat (smaller, much slower to save)
bools.proc_vel = true; % false if just calculating secondary values

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = true;

process_case(PIV_case_name, save_filepath_local, num_images, bools);
return