% This script is designed to gather data from the 1 DOF flapper. This
% script is adapted from twoDoFPVT_v5.m by Xiaozhou Fan.

% galil_test.m
% Cameron Urban
% 04/12/2022

% ToDo: Rename the sections to be more descriptive.

clc;
clear variables;
close all;

%% Initalize the experiment

% Set debug to false if you are connected to all the equipment or running a
% real experiment.
debug = true;

code_path = pwd;
load wallance_cal;

% Set the number of steps per rotation of the stepper motor.
steps_per_rot = 3200;

% Specify the flapping frequency (Hz) and number of cycles.
f = 1;
num_cycles = 10;

% Specify how long (s) to continue taking data after the flapping has
% stopped.
end_padding = 5;

% Set the DAq samping rate (Hz).
rate = 1000;

% Calculate the sampling interval for the Galil.
run_time_stamp = now();

%% Setup the Galil device

if ~debug
    % Connect to the Galil device.
    galil = actxserver('galil');

    % Display the Galil's library version.
    disp('Library Version: ' + galil.libraryVersion);

    % Open the connections dialog box and send ^R^V to query the
    % controller's model number. Then, display the response.
    galil.address = '';
    model_number = galil.command(strcat(char(18), char(22)));
    disp('Model Number: ' + model_number)
end

% Create the carraige return and linefeed variable from the .dmc file in
% this directory.
dmc_file_name = uigetfile('*.dmc');
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep( ...
    dmc, ...
    'speed_placeholder', ...
    num2str(f * steps_per_rot));
dmc = strrep( ...
    dmc, ...
    'distance_placeholder', ...
    num2str(num_cycles * steps_per_rot));

% Load the program described by the .dmc file to the Galil device.
if ~debug
    galil.programDownload(dmc);
end

%% Setup the DAq

% Change the current folder to the folder of this m-file. Check if this
% script is being run within MATLAB or an external application. If it's
% within MATLAB, move to the folder where this script is saved.
if ~isdeployed
    cd(fileparts(which(mfilename)));
end

% Save the location of this folder.
code_folder_path = pwd;

% Move one level up from the current folder, and make a variable to hold
% the pathname of the post processing folder.
cd("../")
post_processing_folder_path = pwd + "\post_processing";

% If there isn't already a post processing folder, make one.
if exist(post_processing_folder_path, "dir") ~= 7
    mkdir(post_processing_folder_path)
end

data_folder_path = pwd + datestr(now,'mmddyy');

% If there isn't already a data folder, make one.
if exist(data_folder_path, "dir") ~= 7
    mkdir(data_folder_path)
end

% Move into the data folder.
cd(data_folder_path)

%% Monitor the experiment

% Data is read in from the ATI-F/T Gamma IP65 load sensor in AFAM wind
% tunnel. The sensor outputs six voltages (three corresponding to forces
% and three corresponding to torques) into a CSV file.

% Ask the user to input the name of this experiment and the current speed
% of the wind tunnel.
experiment_name_raw = inputdlg( ...
    "Give this experiment a name.", ...
    "User Input", ...
    [1, 50], ...
    "test" ...
    );
freestream_speed_raw = inputdlg( ...
    "Input the freestream speed (m/s).", ...
    "User Input", ...
    [1, 50], ...
    "5.0" ...
    );

% ToDo: Check if this order of angles is correct.
angles_raw = inputdlg( ...
    [ ...
    "Input the MPS yaw angle (deg).", ...
    "Input the MPS pitch angle (deg).", ...
    "Input the MPS roll angle (deg)." ...
    ], ...
    "User Input", ...
    [1, 50], ...
    ["0.0", "0.0", "0.0"] ...
    );

freestream_speed = str2double(freestream_speed_raw);
angles = [
    str2double(angles_raw(1));
    str2double(angles_raw(2));
    str2double(angles_raw(3));
    ];
experiment_name = strjoin(lower(split(experiment_name_raw)), "_");

% load offset data
is_offset = questdlg( ...
    "Is there an offset file for this case?", ...
    "User Input", ...
    "Yes", ...
    "No", ...
    "Yes" ...
    );

switch is_offset
    case "Yes"
        offsets_file_name = uigetfile( ...
            "*.csv", ...
            "Select the offsets file." ...
            );
        offsets = readmatrix(offsets_file_name);
    otherwise
        if freestream_speed ~= 0
            uiwait(warndlg("Turn off the wind tunnel. Click OK once " + ...
                "the speed has stabilized.", "User Input"));
        end

        offset_duration_raw = dlginput( ...
            "Enter the duration to collect offset data (s).", ...
            "User Input", ...
            [1, 50],"30.0" ...
            );
        offset_duration = str2double(offset_duration_raw);
        
        fprintf( ...
            "The offset file is generating. This will take " + ...
            "%4.1f seconds./n", ...
            offset_duration ...
            );
        
        if ~debug
            offsets = get_offset(experiment_name, offset_duration, rate);
        end
        
        disp("The offset file is complete.");
end

if ~debug
    offsets = offsets(1,:);
end

if freestream_speed ~= 0
    uiwait(warndlg("Command the wind tunnel to run at the desired " + ...
        "speed. Click OK once the speed has stabilized.", "User Input"));
end

%% Process the Galil data

% Create DAq session and set its aquisition rate (Hz).
this_daq = daq('ni');
this_daq.Rate = rate;

% Add the input channels.
addInput(this_daq, 'Dev2', 0, 'Voltage');
addInput(this_daq, 'Dev2', 1, 'Voltage');
addInput(this_daq, 'Dev2', 2, 'Voltage');
addInput(this_daq, 'Dev2', 3, 'Voltage');
addInput(this_daq, 'Dev2', 4, 'Voltage');
addInput(this_daq, 'Dev2', 5, 'Voltage');

% Calculate the duration of each session (s).
session_duration = ceil(num_cycles / f + end_padding);

%% Read in sensor data.

% Command the galil to execute the program.
galil.command('XQ');

% Start the DAq session and read the data.
start this_daq;
[volt_vals, times] = read(this_daq, seconds(session_duration));

% Offset the data and multiply by the calibration matrix.
volt_vals = volt_vals(:, 1:6) - ones(session_duration * rate, 1) * offSets;
force_vals = cal_matrix * volt_vals(:, 1:6)';

% Transpose the forces and store them (with the times) as the results.
force_vals = force_vals';
results = [times force_vals];

%% Clean up

% Save the data.
results_file_name = strjoin( ...
    [experiment_name, "results", datestr(now, 'mmddyy')], ...
    "_" ...
    );
uisave(who, results_file_name);

% Delete all resources for the Galil DMCShell object.
delete(galil);

% Clear the DAq object.
clear this_daq;