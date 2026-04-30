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

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
vc7_filepath = "Y:\VC7 Data\";
save_filepath_local = "Y:\Processed Results\";

avg_type = 1; % 0 - time average, 1 - phase average

nondim_bool = true; % non-dimensionalize data
RPCA_bool = false; % RPCA filtering of vector fields

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
PIV_plot_bool = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
plot_bool = false;

circ_plot_bool = false;
movie_plot_bool = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

case_names = get_case_names(vc7_filepath);
sel_case_names = [];
for i = 1:length(case_names)
    cur_name = case_names{i};
    if contains(cur_name, "UP_one") && ~contains(cur_name, "UP_two") ...
        && ~contains(cur_name, "turbine") && contains(cur_name, "flexible") ...
        && ~contains(cur_name, "0Hz")
        sel_case_names = [sel_case_names case_names(i)];
    end
end

for i = 1:length(sel_case_names)
PIV_case_name = sel_case_names(i);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------ Dependent parameters --------------------------
if contains(PIV_case_name,"turbine")
    turbine_bool = true;
else
    turbine_bool = false;
end

% characteristic windspeed (freestream) and characteristic length
if turbine_bool
    U = 6;
    L = 0.07; % temp value, replace with diameter of turbine
else
    U = 4;
    L = 0.07; % guess of mean aerodynamic chord
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_path = get_PIV_paths(PIV_case_name);
files = dir(fullfile(file_path,'*.vc7'));
num_files = length(files);

switch avg_type
    case 0
        disp("Time Average: Loading file: " + file_path)
        num_files = 1000; % TEMPORARY LINE ---- DELETE
        S = time_avg_STB(file_path, nondim_bool, U, L, num_files, save_filepath_local,...
            PIV_case_name, RPCA_bool);
        
        if PIV_plot_bool
            time_avg_plots(S);
        end
    case 1
        disp("Phase Average: Loading file: " + file_path)
        tic
        S = phase_avg_STB(file_path, nondim_bool, U, L, save_filepath_local,...
            PIV_case_name, turbine_bool, plot_bool, RPCA_bool);
        toc

        if PIV_plot_bool
            error("Plotting phase averaged results not currently supported")
            phase_avg_plots(S);
        end
end
end
return