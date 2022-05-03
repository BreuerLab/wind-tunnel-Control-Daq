% This script is designed to gather data regarding the longitudinal
% stability of the the 1 DOF flapper.

% TODO: Add the motor type below.
% Wind Tunnel: AFAM with MPS
% Load Cell: ATI-F/T Gamma IP65
% DAq: NI
% DMC: Galil DMC-4020
% Motor: VEXTA PH266-E1.2 stepper motor

% longitudinal_stability.m
% Cameron Urban
% 05/03/2022

%% Initalize the experiment
clc;
clear variables;
close all;

% Set debug to false if you are connected to all the equipment or running a
% real experiment.
debug = true;

% Load the load cell's calibration matrix.
load wallance_cal;

% Set the number of steps per rotation of the stepper motor.
steps_per_rot = 3200;

% Set the DAq samping rate (Hz).
rate = 1000;

% If not debugging, home the MPS to 0 degrees.
if ~debug
    pitch_home(0)
end

%% Collect user input on the experimental setup

% Ask the user to input the name of this experiment, the desired speed of
% the wind tunnel, the desired angles of attack, the desired flapping
% frequency, and the number of flaps to execute.
experiment_name_raw = inputdlg( ...
    "Give this experiment a name.", ...
    "User Input", ...
    [1, 50], ...
    "longitudinal_stability" ...
    );
freestream_speed_raw = inputdlg( ...
    "Input the freestream speed (m/s).", ...
    "User Input", ...
    [1, 50], ...
    "5.0" ...
    );
alpha_min_raw = inputdlg( ...
    "Input the desired minimum angle of attack (deg).", ...
    "User Input", ...
    [1, 50], ...
    "-10.0");
alpha_max_raw = inputdlg( ...
    "Input the desired maximum angle of attack (deg).", ...
    "User Input", ...
    [1, 50], ...
    "10.0");
flapping_frequency_raw = inputdlg( ...
    "Input the desired flapping frequency (Hz).", ...
    "User Input", ...
    [1, 50], ...
    "1.0" ...
    );
num_cycles_raw = inputdlg( ...
    "Input the desired number of flaps to execute.", ...
    "User Input", ...
    [1, 50], ...
    "10");

% Ask the user to select the .dmc file.
dmc_file_name = uigetfile("*.dmc", "Select the DMC file.",...
    "longitudinal_stability.dmc");

% Ask if there is already an offset file for this experiment
pre_existing_offsets = questdlg( ...
    "Is there an offset file for this experiment?", ...
    "User Input", ...
    "Yes", ...
    "No", ...
    "No" ...
    );

% Sanitize and process the user inputs.
experiment_name = string(strjoin(lower(split(experiment_name_raw)), "_"));
freestream_speed = str2double(freestream_speed_raw);
min_alpha = str2double(alpha_min_raw);
max_alpha = str2double(alpha_max_raw);
flapping_frequency = str2double(flapping_frequency_raw);
num_cycles = round(str2double(num_cycles_raw));

%% Setup the Galil DMC

if ~debug
    % Connect to the Galil device.
    galil = actxserver("galil");

    % Open the connections dialog box and send ^R^V to query the
    % controller's model number. Then, display the response.
    galil.address = "";
    model_number = galil.command(strcat(char(18), char(22)));
end

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep( ...
    dmc, ...
    "speed_placeholder", ...
    num2str(flapping_frequency * steps_per_rot));
dmc = strrep( ...
    dmc, ...
    "distance_placeholder", ...
    num2str(num_cycles * steps_per_rot));

% Load the program described by the .dmc file to the Galil device.
if ~debug
    galil.programDownload(dmc);
end

%% Get offset data for this experiment
switch pre_existing_offsets
    case "Yes"
        offsets_file_name = uigetfile( ...
            "*.csv", ...
            "Select the offsets file.", ...
            "longitudinal_stability_offsets_05032022.csv"...
            );
        offsets = readmatrix(offsets_file_name);
    otherwise
        if freestream_speed ~= 0
            uiwait(warndlg("Turn off the wind tunnel. Click OK once " + ...
                "the speed has stabilized.", "User Input"));
        end

        offset_duration_raw = inputdlg( ...
            "Enter the duration to collect offset data (s).", ...
            "User Input", ...
            [1, 50], ...
            "30.0" ...
            );
        offset_duration = str2double(offset_duration_raw);

        if ~debug
            offsets = get_offsets(experiment_name, rate, offset_duration);
        end
end

if ~debug
    offsets = offsets(1,:);
end

if freestream_speed ~= 0
    uiwait(warndlg("Command the wind tunnel to run at the desired " + ...
        "speed. Click OK once the speed has stabilized.", "Information"));
end

%% Set up the DAq

if ~debug
    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;

    % Add the input channels.
    this_daq.addinput("Dev1", 0, "Voltage");
    this_daq.addinput("Dev1", 1, "Voltage");
    this_daq.addinput("Dev1", 2, "Voltage");
    this_daq.addinput("Dev1", 3, "Voltage");
    this_daq.addinput("Dev1", 4, "Voltage");
    this_daq.addinput("Dev1", 5, "Voltage");
end

% Calculate the duration of each session (s).
session_duration = ceil(num_cycles / flapping_frequency);

%% Begin the experiment and record data

% Save the time data began being recorded.
run_time_stamp = now();

angles = min_alpha:max_alpha;
[~, num_angles] = size(angles);

raw_data = cell(num_angles, 1);

angle_id = 1;

for angle=angles
    if ~debug

        % Move the MPS to this angle
        pitch_home(angle);
    
        % Start the DAq session and read the data.
        this_daq.start;
        these_raw_data = read(this_daq, seconds(session_duration));

        % Command the galil to execute the program.
        galil.command("XQ");

        raw_data{angle_id, 1} = these_raw_data;
    end

    angle_id = angle_id + 1;
end

%% Process the data
results = cell(num_angles, 1);

for angle_id = 1:num_angles
    if ~debug
        
        [volt_vals, times] = raw_data{angle_id, 1};

        recording_size = size(volt_vals);
        num_recordings = recording_size(1);
    
        offsets_matrix = ones(num_recordings, 1) * offsets;
    
        % Offset the data and multiply by the calibration matrix.
        volt_vals = volt_vals(:, 1:6) - offsets_matrix;
        force_vals = cal_matrix * volt_vals';
    
        % Transpose the forces and store them (with the times) as the
        % results.
        force_vals = force_vals';
        these_results = [times force_vals];
        
        results{angle_id, 1} = these_results;
    end
end

%% Clean up

if ~debug
    % Delete all resources for the Galil DMCShell object.
    delete(galil);

    % Clear the DAq object.
    clear this_daq;

    % Home the MPS to 0 degrees.
    pitch_home(0);
end

% Delete unecessary variables.
clear alpha_max_raw
clear alpha_min_raw
clear angles
clear angle_id
clear code_path
clear dmc_file_name
clear experiment_name_raw
clear flapping_frequency_raw
clear force_vals
clear freestream_speed_raw
clear num_cycles_raw
clear num_recordings
clear offset_duration_raw
clear offsets_matrix
clear recording_size
clear session_duration
clear steps_per_rot
clear volt_vals

% Save the data.
uisave(who,...
    strjoin([experiment_name, "results", datestr(now, "mmddyy")], "_")...
    );