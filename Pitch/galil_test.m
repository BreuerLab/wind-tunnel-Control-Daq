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

% ToDo: Identify these variables and their units.
f = 4;
c = 1000/1024;
sigma = 50;
num_cycles = 50;
data_site = 3500;

% Set the DAq samping rate (Hz).
rate = 1000;

% Calculate the sampling interval for the Galil.
% ToDo: Check if this equation is correct. Is 1000 supposed to be fs? Where
% does 2 come from? What are the units?
sampling_int = ceil(log(1000 * num_cycles/(c * f * data_site)) / log(2));
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

    % ToDo: Determine what this command does.
    galil.command('SHAB');
end

% Create the carraige return and linefeed variable from the .dmc file in
% this directory.
dmc_file_name = uigetfile('*.dmc');
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Be very careful about the order of the placeHolders! Other
% parameters can be changed directly in .dmc file.
dmc = strrep(dmc,'placeHolder1',num2str(f));
dmc = strrep(dmc,'placeHolder2',num2str(sampling_int));
dmc = strrep(dmc,'placeHolder3',num2str(data_site));
dmc = strrep(dmc,'placeHolder4',num2str(sigma));
dmc = strrep(dmc,'placeHolder5',num2str(num_cycles));

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

% ToDo: Determine what this commented out line means.
% disp('Change fps in PCC!')

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

% ToDo: Determine why, previously, there were 7 channels. 
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
% ToDo: Determine if we should really be rounding by number of cycles here.
% Can the DAq not handle non-integer durations? Also, where does 5 come
% from?
session_duration = round(num_cycles / f + 5);

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

%% Extract the torque and velocity data from the Galil device.
tqA = extract_matrix(galil, data_site, 'tqA');
tqB = extract_matrix(galil, data_site, 'tqB');
vA = extract_matrix(galil, data_site, 'vA');
vB = extract_matrix(galil, data_site, 'vB');
pA = extract_matrix(galil, data_site, 'pA');
pB = extract_matrix(galil, data_site, 'pB');

%% Save the data
results_file_name = strjoin( ...
    [experiment_name, "results", datestr(now, 'mmddyy')], ...
    "_" ...
    );
uisave(who, results_file_name);

%% Monitor the force data, trigger timing, and phase average

% ToDo: Determine what the option object is.
option.verbose = 1;

cd(post_processing_folder_path);
results_folder_path = data_folder_path + "\" + results_file_name;

% ToDo: Ask Xiaozhou to send me the procFile_v8 function.
if ~debug
    procFile_v8(results_folder_path, fc, rate, option);
end

cd(code_folder_path);

%% Clean up

% Delete all resources for the Galil DMCShell object.
delete(galil);

% Clear the DAq object.
clear this_daq;