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
PIV_case_name = 'x3_wings_20deg_6Hz';
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

% Range of phase-bin counts to search. findBestNumBins2 picks the count
% in this range (and the bin offset) with the smallest phase spread per
% bin; it was choosing ~193 in 180-210. Fewer bins = more frames per bin
% (less noise) but coarser phase resolution. [n n] forces n bins.
bools.bin_range = [80 120]; % [180 210]

% Version name added to the saved file names, e.g. "coarse" saves
% x3_wings_20deg_6Hz_coarse_phase_avg.mat (and _integral.mat); phaseAvg_UI
% lists it under that name in its version dropdown. "" = default (no
% suffix). Phase averages only; avoid "deg" and "Hz" in the name.
bools.version = "coarse";

% Harmonic regression instead of bin averaging. Each point's time series
% is fitted over ALL frames at their actual phases with a Fourier series
% of num_harmonics wingbeat harmonics, then evaluated at the bin centres,
% so the saved fields have the same shape as the bin averages and the UIs
% and secondary values work unchanged. Removes the phase spread within
% bins and filters noise above num_harmonics x wingbeat frequency. std,
% Reynolds stresses and Q_inst are still computed per bin. Saved with
% "_hr" added to the version name (e.g. coarse_hr), so it doesn't
% overwrite the bin-averaged files. See harmonic_regression_STB.m.
bools.harmonic_reg = false;
bools.num_harmonics = 10; % 2*10+1 = 21 coefficients per point and field
bools.hr_save_coef = false; % save coefficients (to evaluate fit / exact d/dt at any phase); large files

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = true;

process_case(PIV_case_name, save_filepath_local, num_images, bools);
return