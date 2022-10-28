% This script is designed to gather data on surfing wing
% 

% Wind Tunnel: AFAM with MPS
% Load Cell: ATI-F/T NANO17
% DAq: NI USB6341
% DMC: Galil DMC-4143
% Motor: Hudson Servo
% developed from scripts by Cameron and Xiaozhou
% Siyang Hao, Brown PVD
% 07/06/2022

%% Initalize the experiment
clc;
clear variables;
close all;

% Set debug to false if you are connected to all the equipment or running a
% real experiment.
debug = false;

% Load the load cell's calibration matrix.
load FT09042_cal;

    
% Set the number of steps per rotation of the stepper motor.
%steps_per_rot = 3200;

% If not debugging, home the MPS to 0 degrees.
if ~debug
    pitch_home(0);
end

%% Collect user input on the experimental setup

% Ask the user to input the name of this experiment, the desired speed of
% the wind tunnel, the desired angles of attack, the desired flapping
% frequency, and the number of flaps to execute.
experiment_number_raw = inputdlg("Give this experiment a number.",...
    "User Input", [1, 50], "4");
trial_number_raw = inputdlg("Give this trial a number.",...
    "User Input", [1, 50], "1");
freestream_speed_raw = inputdlg("Input the freestream speed (m/s).",...
    "User Input", [1, 50], "5.0");
alpha_min_raw = inputdlg(...
    "Input the desired minimum AOA (deg).", "User Input",...
    [1, 50], "0");
alpha_max_raw = inputdlg(...
    "Input the desired maximum AOA (deg).", "User Input",...
    [1, 50], "0");
alpha_step_raw = inputdlg(...
    "Input the desired step AOA (deg).", "User Input",...
    [1, 50], "1.0");
flapping_frequency_raw = inputdlg(...
    "Input the desired flapping frequency (Hz).", "User Input", [1, 50],...
    "5");

% Ask the user to select the .dmc file.
dmc_file_name = uigetfile("*.dmc", "Select the DMC file.",...
    "Flap.dmc");

% Sanitize and process the user inputs.
experiment_name = experiment_number_raw + "_" + trial_number_raw;
freestream_speed = str2double(freestream_speed_raw);
min_alpha = str2double(alpha_min_raw);
max_alpha = str2double(alpha_max_raw);
step_alpha = str2double(alpha_step_raw);
flapping_frequency = str2double(flapping_frequency_raw);

if flapping_frequency == 0
    glide_duration_raw = inputdlg( ...
    "Enter the duration to collect glide data (s).", "User Input", ...
    [1, 50], "30.0");
    glide_duration = str2double(glide_duration_raw);
else
    num_cycles_raw = inputdlg(...
    "Input the desired number of flaps to execute.", "User Input",...
    [1, 50], "60");
    num_cycles = round(str2double(num_cycles_raw));
end

% Create a list of the angles and find the number of angles.
angles = min_alpha:step_alpha:max_alpha;
[~, num_angles] = size(angles);

%% Setup the Galil DMC
if flapping_frequency ~= 0
    % Create the carraige return and linefeed variable from the .dmc file.
    dmc = fileread(dmc_file_name);
    dmc = string(dmc);

    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
%     dmc = strrep(dmc, "speed_placeholder",...
%         num2str(flapping_frequency * steps_per_rot));
    dmc = strrep(dmc, "num_cycles_holder",...
        num2str(num_cycles));

    if ~debug

        % Connect to the Galil device.
        galil = actxserver("galil");

        % Set the Galil's address.
        galil.address = "192.168.1.3";%Open connections dialog box

        % Load the program described by the .dmc file to the Galil device.
        galil.programDownload(dmc);
    end
end

%% Get offset data for this experiment

% Set the DAq samping rate (Hz).
rate = 1000;

uiwait(warndlg("Turn off the wind tunnel. Click OK once the speed" + ...
        " has stabilized.", "User Input"));

% Ask for how long they'd like to take offset data (at each angle).
% offset_duration_raw = inputdlg( ...
%     "Enter the duration to collect offset data (s).", "User Input", ...
%     [1, 50], "10.0");
offset_duration = 20;
offsets = cell(num_angles, 1);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Iterate through the angles and get the offset data for each.
for angle=angles

    % Call the offset function and parse the results.
    if ~debug

        % Move the MPS to this angle and print it to the console.
        pitch_home(angle);
        fprintf("Current angle for offset calculation:\t%.2f deg\n", ...
            angle);
         % Get the offsets at this angle.
        these_offsets = get_offsets( ...
        experiment_name, rate, offset_duration);
        these_offsets = these_offsets(1,:);
        % Add the offsets at this angle to the cell array.
        offsets{angle_id, 1} = these_offsets;
    end

        
       
    angle_id = angle_id + 1;
end

% Beep to signal that the offset data has been gathered.
beep;

uiwait(warndlg("Command the wind tunnel to run at the desired " + ...
    "speed. Click OK once the speed has stabilized.", "Information"));

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
if flapping_frequency == 0
    session_duration = glide_duration;
else
    session_duration = ceil(num_cycles / flapping_frequency*10);
end

%% Begin the experiment and record data

% Save the time data began being recorded.
run_time_stamp = now();

raw_data = cell(num_angles, 2);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Clear the console.
clc;

% Iterate through the angles.
for angle=angles
    if ~debug

        % Move the MPS to this angle and print it to the console.
        pitch_home(angle);
        fprintf("Current angle for data collection:\t%.2f deg\n", angle);

        % Start the DAq session.
        start(this_daq, "Duration", session_duration);
        
        % Command the galil to execute the program if the flapping
        % frequency isn't zero.
        if flapping_frequency ~= 0
            galil.command("XQ");
        end
        
        % Read the data from this DAq session.
        these_raw_data = read(this_daq, seconds(session_duration));
        
        these_raw_data_table = timetable2table(these_raw_data);
        
        these_raw_data_table_times = these_raw_data_table(:, 1);
        these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
        
        these_raw_times = seconds(table2array(these_raw_data_table_times));
        these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
        
        raw_data{angle_id, 1} = these_raw_times;
        raw_data{angle_id, 2} = these_raw_volt_vals;
    end

    angle_id = angle_id + 1;
end

%% Process the data
results = cell(num_angles, 1);

for angle_id = 1:num_angles
    if ~debug
           
        times = raw_data{angle_id, 1};
        volt_vals = raw_data{angle_id, 2};

        recording_size = size(volt_vals);
        num_recordings = recording_size(1);
        
        % Get the offsets associated with this angle and transform them
        % into a matrix.
        these_offsets = offsets{angle_id, 1};
        offsets_matrix = ones(num_recordings, 1) * these_offsets;

        % Offset the data and multiply by the calibration matrix.
        volt_vals = volt_vals(:, 1:6) - offsets_matrix;
        force_vals = matrixVals * volt_vals';

        % Transpose the forces and store them (with the times) as the
        % results.
        force_vals = force_vals';
        these_results = [times force_vals];

        results{angle_id, 1} = these_results;
    end
end

%% Clean up
if ~debug
    
    % Delete all resources for the Galil DMCShell object if we aren't
    % gliding (for gliding flights we didn't create the object).
    if flapping_frequency ~= 0
        
        galil.command("ST");

        delete(galil);
    end

    % Clear the DAq object.
    clear this_daq;

    % Home the MPS to 0 degrees.
    pitch_home(0);
end

% Delete unecessary variables.
% clear alpha_max_raw
% clear alpha_min_raw
% clear angle
% clear angles
% clear angle_id
% clear code_path
% clear dmc_file_name
% clear experiment_number_raw
% clear trial_number_raw
% clear flapping_frequency_raw
% clear force_vals
% clear freestream_speed_raw
% clear glide_dration_raw
% clear num_angles
% clear num_cycles
% clear num_cycles_raw
% clear num_recordings
% clear offset_duration_raw
% clear offsets_matrix
% clear recording_size
% clear session_duration
% clear steps_per_rot
% clear these_offsets
% clear these_raw_data
% clear these_raw_data_table
% clear these_raw_data_table_times
% clear these_raw_data_table_volt_vals
% clear these_raw_times
% clear these_raw_volt_vals
% clear these_results
% clear times
% clear volt_vals

% Beep to signal that the data must be saved.

beep;

% Save the non-deleted variables to a MAT file.
uisave(who,...
    strjoin([experiment_name, "results", datestr(now, "mmddyy")], "_"));

% Beep to signal the experiment is finished.
beep;
    

