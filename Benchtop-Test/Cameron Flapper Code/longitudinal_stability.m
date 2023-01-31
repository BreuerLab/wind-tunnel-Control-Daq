% This script is designed to gather data regarding the longitudinal
% stability of the 1 DOF flapper.

% Wind Tunnel: AFAM with MPS
% Load Cell: ATI-F/T Delta IP65
% DAq: NI
% DMC: Galil DMC-4020
% Motor: VEXTA PH266-E1.2 stepper motor

% longitudinal_stability.m
% Cameron Urban
% 07/21/2022

%% Initalize the experiment
clc;
clear variables;
close all;

% Set benchtop to false if you are connected to the wind tunnel and the
% MPS.
benchtop = false;

% Set debug to false if you are connected to all the equipment or running a
% real experiment.
debug = false;

% Load the load cell's calibration matrix.
load wallance_cal;

% Set the number of full steps per rotation of the stepper motor, and the
% number of microsteps per step.
steps_per_rot = 200;
microsteps = 16;

% Calculate the number of microsteps per rotation.
microsteps_per_rot = steps_per_rot * microsteps;

% If not debugging or not a benchtop test, home the MPS to 0 degrees.
if ~debug
    if ~benchtop
        pitch_home(0);
    end
end

%% Collect user input on the experimental setup

% Ask the user to input the name of this experiment, the desired speed of
% the wind tunnel, the desired angles of attack, the desired flapping
% frequency, and the number of flaps to execute.
experiment_number_raw = inputdlg("Give this experiment a number.",...
    "User Input", [1, 50], "6");
trial_number_raw = inputdlg("Give this trial a number.",...
    "User Input", [1, 50], "1");
freestream_speed_raw = inputdlg("Input the freestream speed (m/s).",...
    "User Input", [1, 50], "5.0");
alpha_min_raw = inputdlg(...
    "Input the desired minimum angle of attack (deg).", "User Input",...
    [1, 50], "-5.0");
alpha_max_raw = inputdlg(...
    "Input the desired maximum angle of attack (deg).", "User Input",...
    [1, 50], "5.0");
flapping_frequency_raw = inputdlg(...
    "Input the desired flapping frequency (Hz).", "User Input", [1, 50],...
    "1.0");

% Ask the user to select the .dmc file.
dmc_file_name = uigetfile("*.dmc", "Select the DMC file.",...
    "longitudinal_stability.dmc");

% Sanitize and process the user inputs.
experiment_name = experiment_number_raw + "_" + trial_number_raw;
freestream_speed = str2double(freestream_speed_raw);
min_alpha = str2double(alpha_min_raw);
max_alpha = str2double(alpha_max_raw);
flapping_frequency = str2double(flapping_frequency_raw);

if flapping_frequency == 0
    glide_duration_raw = inputdlg( ...
    "Enter the duration to collect glide data (s).", "User Input", ...
    [1, 50], "30.0");
    glide_duration = str2double(glide_duration_raw);
else
    num_cycles_raw = inputdlg(...
    "Input the desired number of flaps to execute.", "User Input",...
    [1, 50], "120");
    num_cycles = round(str2double(num_cycles_raw));
end

% Create a list of the angles and find the number of angles.
angles = min_alpha:max_alpha;
[~, num_angles] = size(angles);

%% Setup the Galil DMC
if flapping_frequency ~= 0
    
    % Calculate the appropriate acceleration value for the motor such that
    % it will reach top speed within one flap. The minimum acceptable
    % acceleration is 1024 microsteps per second per second.
    num_rot_to_accel = 5;
    accel = round(2 * microsteps_per_rot * flapping_frequency ^ 2 / num_rot_to_accel);
    accel = max(accel, 1024);

    % Create the carraige return and linefeed variable from the .dmc file.
    dmc = fileread(dmc_file_name);
    dmc = string(dmc);

    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    dmc = strrep(dmc, "microsteps_placeholder",...
        num2str(microsteps));
    dmc = strrep(dmc, "accel_placeholder",...
        num2str(accel));
    dmc = strrep(dmc, "speed_placeholder",...
        num2str(flapping_frequency * microsteps_per_rot));
    dmc = strrep(dmc, "distance_placeholder",...
        num2str(num_cycles * microsteps_per_rot));

    if ~debug

        % Connect to the Galil device.
        galil = actxserver("galil");

        % Set the Galil's address.
        galil.address = "192.168.1.15";

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
offset_duration_raw = inputdlg( ...
    "Enter the duration to collect offset data (s).", "User Input", ...
    [1, 50], "10.0");
offset_duration = str2double(offset_duration_raw);
offsets = cell(num_angles, 1);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Iterate through the angles and get the offset data for each.
for angle=angles

    % Call the offset function and parse the results.
    if ~debug

        % Move the MPS to this angle and print it to the console. Don't
        % actually move it if this is a benchtop test.
        if ~benchtop
            pitch_home(angle);
        end
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
    this_daq.addinput("Dev1", 6, "Voltage");
end

% Calculate the duration of each session (s) Some amount of padding is
% added to this so that we will record the trigger pulses from the DMC
% indicating the beginning and end of flapping.
session_padding = 5;
if flapping_frequency == 0
    session_duration = glide_duration + session_padding;
else
    session_duration = ceil(num_cycles / flapping_frequency) + session_padding;
end

%% Begin the experiment and record data

% Save the time data began being recorded.
run_time_stamp = now();

raw_data = cell(num_angles, 3);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Clear the console.
clc;

% Iterate through the angles.
for angle=angles
    if ~debug

        % Move the MPS to this angle and print it to the console. Don't
        % actually move it if this is a benchtop test.
        if ~benchtop
            pitch_home(angle);
        else
            pause(3);
        end
        fprintf("Current angle for data collection:\t%.2f deg\n", angle);

        % Start the DAq session.
        start(this_daq, "Duration", session_duration);
        
        % Command the galil to execute the program if the flapping
        % frequency isn't zero.
        if flapping_frequency ~= 0
            galil.command("XQ");
        end
        
        % Wait for the extra padding. The DAq will stop reading before this
        % pause is up, but it's added anyway for safety.
        pause(session_padding)
        
        % Read the data from this DAq session.
        these_raw_data = read(this_daq, seconds(session_duration));
        
        these_raw_data_table = timetable2table(these_raw_data);
        
        these_raw_data_table_times = these_raw_data_table(:, 1);
        these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
        these_raw_data_table_trigger_vals = these_raw_data_table(:, 8);
        
        these_raw_times = seconds(table2array(these_raw_data_table_times));
        these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
        these_raw_trigger_vals = table2array(these_raw_data_table_trigger_vals);
        
        raw_data{angle_id, 1} = these_raw_times;
        raw_data{angle_id, 2} = these_raw_volt_vals;
        raw_data{angle_id, 3} = these_raw_trigger_vals;
    end

    angle_id = angle_id + 1;
end

%% Process the data
results = cell(num_angles, 1);

for angle_id = 1:num_angles
    if ~debug
           
        times = raw_data{angle_id, 1};
        volt_vals = raw_data{angle_id, 2};
        trigger_vals = raw_data{angle_id, 3};

        recording_size = size(volt_vals);
        num_recordings = recording_size(1);
        
        % Get the offsets associated with this angle and transform them
        % into a matrix.
        these_offsets = offsets{angle_id, 1};
        offsets_matrix = ones(num_recordings, 1) * these_offsets;

        % Offset the data and multiply by the calibration matrix.
        volt_vals = volt_vals(:, 1:6) - offsets_matrix;
        force_vals = cal_matrix * volt_vals';

        % Transpose the forces and store them (with the times) as the
        % results.
        force_vals = force_vals';
        these_results = [times force_vals trigger_vals];

        results{angle_id, 1} = these_results;
    end
end

%% Clean up
if ~debug
    
    % Delete all resources for the Galil DMCShell object if we aren't
    % gliding (for gliding flights we didn't create the object).
    if flapping_frequency ~= 0
        delete(galil);
    end

    % Clear the DAq object.
    clear this_daq;

    % Home the MPS to 0 degrees unless this is a benchtop test.
    if ~benchtop
        pitch_home(0);
    end
end

%% Display preliminary data
for angle_id = 1:num_angles
    
    % For each angle of attack, get the loads and times stored.
    this_angle = angles(angle_id);
    these_results = results{angle_id, 1};
    these_forces = these_results(:, 2:7);
    these_times = these_results(:, 1);
    
    % Open a new figure.
    figure;
    
    % Create three subplots to show the force time histories. 
    subplot(2, 3, 1);
    plot(these_times, these_forces(:, 1));
    title("X-Component of Force");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 2);
    plot(these_times, these_forces(:, 2));
    title("Y-Component of Force");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 3);
    plot(these_times, these_forces(:, 3));
    title("Z-Component of Force");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    % Create three subplots to show the moment time histories.
    subplot(2, 3, 4);
    plot(these_times, these_forces(:, 4));
    title("X-Component of Torque");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 5);
    plot(these_times, these_forces(:, 5));
    title("Y-Component of Torque");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 6);
    plot(these_times, these_forces(:, 6));
    title("Z-Component of Torque");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    % Label the whole figure.
    sgtitle("Time Series of Loads at " + this_angle + "°") ;
end

%% Save the data

% Delete unecessary variables so they don't clutter saved results.
clear alpha_max_raw
clear alpha_min_raw
clear angle
clear angles
clear angle_id
clear code_path
clear dmc_file_name
clear experiment_number_raw
clear trial_number_raw
clear flapping_frequency_raw
clear force_vals
clear freestream_speed_raw
clear glide_dration_raw
clear num_angles
clear num_cycles
clear num_cycles_raw
clear num_recordings
clear num_rotate_to_accel
clear offset_duration_raw
clear offsets_matrix
clear recording_size
clear session_duration
clear session_padding
clear steps_per_rot
clear microsteps_per_rot
clear these_offsets
clear this_angle
clear these_raw_data
clear these_raw_data_table
clear these_raw_data_table_times
clear these_raw_data_table_volt_vals
clear these_raw_data_table_trigger_vals
clear these_raw_times
clear these_raw_volt_vals
clear these_raw_trigger_vals
clear these_results
clear these_forces
clear these_times
clear times
clear volt_vals
clear trigger_vals

% Beep to signal that the data must be saved.
beep;

% Save the non-deleted variables to a MAT file.
uisave(who,...
    strjoin([experiment_name, "results", datestr(now, "mmddyy")], "_"));

% Beep to signal the experiment is finished.
beep;