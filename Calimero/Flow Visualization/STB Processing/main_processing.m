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
% PIV_case_name = 'flexible_20deg_2Hz';
PIV_case_name = 'x5_wings_20deg_0Hz'; % UP_two_body
% PIV_case_name = 'turbine';

% save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "Y:\Processed Results\";

bools.nondim = true; % non-dimensionalize data
bools.RPCA = false; % RPCA filtering of vector fields
bools.proc_vel = false; % false if just calculating secondary values

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = true;

process_case(PIV_case_name, save_filepath_local, bools);
return