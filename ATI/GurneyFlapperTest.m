% This script is designed to gather data on surfing wing
% sync PIV

% Wind Tunnel: AFAM with MPS
% Load Cell: ATI-F/T Mini58
% DAq: NI USB6341
% DMC: Galil DMC-4020
% Motor: 
% developed from scripts of Cameron and Xiaozhou
% Siyang Hao, Brown PVD
% 07/06/2022

%% Initalize the experiment
clc;
clear variables;
close all;

% Set debug to false if you are connected to all the equipment or running a
% real experiment.
MPSdebug = false;
DAQdebug = false;
Motordebug = false;
% Load the load cell's calibration matrix.
load FT39745_cal;
 loadcell_range = [1400, 1400, 3400,60,60,60]';
% loadcell_range = [2800, 2800, 6800,120,120,120]';
% If not debugging, home the MPS to 0 degrees.
if ~MPSdebug
    Pitch_Home(0);
end

%% Collect user input on the experimental setup

% Ask the user to input the name of this experiment, the desired speed of
% the wind tunnel, the desired angles of attack, the desired flapping
% frequency, and the number of flaps to execute.
experiment_number_raw = inputdlg("Give this experiment a number.",...
    "User Input", [1, 50], "1");
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
% flapping_frequency_raw = inputdlg(...
%     "Input the desired flapping frequency (Hz).", "User Input", [1, 50],...
%     "5");
% flapping_amp_raw = inputdlg(...
%     "Input the desired flapping amplitude (0-pk,deg).", "User Input", [1, 50],...
%     "30");
% Ask the user to select the .dmc file.
dmc_file_name = uigetfile("*.dmc", "Select the DMC file.",...
    "GurneyFlap.dmc");

% Sanitize and process the user inputs.
experiment_name = experiment_number_raw + "_" + trial_number_raw;
freestream_speed = str2double(freestream_speed_raw);
min_alpha = str2double(alpha_min_raw);
max_alpha = str2double(alpha_max_raw);
step_alpha = str2double(alpha_step_raw);
% flapping_amp = str2double(flapping_amp_raw);
% flapping_frequency = str2double(flapping_frequency_raw);
% dt = round(1/flapping_frequency/4*1024);
% amp = round(flapping_amp/360*8000);
% angFreq = 2*pi*flapping_frequency;
% spd = abs(round(amp*angFreq*sin(angFreq*1/flapping_frequency/4)));


    num_cycles_raw = inputdlg(...
    "Input the desired number of flaps to execute.", "User Input",...
    [1, 50], "1");
    num_cycles = round(str2double(num_cycles_raw));


% Create a list of the angles and find the number of angles.
angles = min_alpha:step_alpha:max_alpha;
[~, num_angles] = size(angles);

%% Setup the Galil DMC

    % Create the carraige return and linefeed variable from the .dmc file.
    dmc = fileread(dmc_file_name);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    dmc = strrep(dmc, "cycholder",...
        num2str(num_cycles));  

    if ~Motordebug

        % Connect to the Galil device.
        galil = actxserver("galil");

        % Set the Galil's address.
        galil.address = "192.168.1.15";%Open connections dialog box

        % Load the program described by the .dmc file to the Galil device.
        galil.programDownload(dmc);
    end

%% Get offset data for this experiment

% Set the DAq samping rate (Hz).
rate = 5000;

uiwait(warndlg("Turn off the wind tunnel. Click OK once the speed" + ...
        " has stabilized.", "User Input"));

% Ask for how long they'd like to take offset data (at each angle).
% offset_duration_raw = inputdlg( ...
%     "Enter the duration to collect offset data (s).", "User Input", ...
%     [1, 50], "10.0");
offset_duration = 1;
offsets = cell(num_angles, 1);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Iterate through the angles and get the offset data for each.
for angle=angles

    % Call the offset function and parse the results.
    if ~MPSdebug

        % Move the MPS to this angle and print it to the console.
        Pitch_Home(angle);
    end    
        fprintf("Current angle for offset calculation:\t%.2f deg\n", ...
            angle);
         % Get the offsets at this angle.
        these_offsets = get_offsets( ...
         rate, offset_duration, experiment_name);
        these_offsets = these_offsets(1,:);
        % Add the offsets at this angle to the cell array.
        offsets{angle_id, 1} = these_offsets;
 

        
       
    angle_id = angle_id + 1;
end

% Beep to signal that the offset data has been gathered.
beep;

uiwait(warndlg("Command the wind tunnel to run at the desired " + ...
    "speed. Click OK once the speed has stabilized.", "Information"));

%% Set up the DAq
if ~DAQdebug
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
    this_daq.addinput("Dev1", 7, "Voltage");

end

% Calculate the duration of each session (s).

    session_duration = ceil(num_cycles *4*1.2);


%% Begin the experiment and record data

% Save the time data began being recorded.
run_time_stamp = now();

raw_data = cell(num_angles, 4);

% Create an index variable to track which angle we are currently on.
angle_id = 1;

% Clear the console.
clc;

% Iterate through the angles.
for angle=angles
    if ~Motordebug&& ~DAQdebug

        % Move the MPS to this angle and print it to the console.
        if ~MPSdebug
        Pitch_Home(angle);
        P1 = Pitch_Read;
        MPSPos = P1.POS;
        clear P1
        end
        fprintf("Current angle for data collection:\t%.2f deg\n", angle);

        % Start the DAq session.
        start(this_daq, "Duration", session_duration);
        
        % Command the galil to execute the program if the flapping
        
        
            galil.command("XQ");
        
        
        % Read the data from this DAq session.
        these_raw_data = read(this_daq, seconds(session_duration));
        % Convert data
        these_raw_data_table = timetable2table(these_raw_data);
        
        these_raw_data_table_times = these_raw_data_table(:, 1);
        these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
        these_raw_data_table_TTL_vals = these_raw_data_table(:, 8:9);
        
        these_raw_times = seconds(table2array(these_raw_data_table_times));
        these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
        these_raw_TTL_vals = table2array(these_raw_data_table_TTL_vals);
        
        raw_data{angle_id, 1} = these_raw_times;
        raw_data{angle_id, 2} = these_raw_volt_vals;
        raw_data{angle_id, 3} = these_raw_TTL_vals;
        raw_data{angle_id, 4} = MPSPos;
        % check loadcell range
        these_raw_force_vals = matrixVals * these_raw_volt_vals';
        these_raw_force_vals_mean = mean(these_raw_force_vals,2);
        range_precent = these_raw_force_vals_mean./loadcell_range*100;
        disp('Current range used:\n');
        disp(range_precent);
        over_range = these_raw_force_vals_mean>loadcell_range;
            if any(over_range) 
                disp('WARNING, The maxium load exceed the range!!!')
                disp(over_range)
            end
    end

    angle_id = angle_id + 1;
end

%% PreProcess the data
results = cell(num_angles, 1);

for angle_id = 1:num_angles
    if ~DAQdebug
           
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

    
    % Delete all resources for the Galil DMCShell object if we aren't
    % gliding (for gliding flights we didn't create the object).

        
        galil.command("ST");

        delete(galil);


    % Clear the DAq object.
    clear this_daq;
if ~MPSdebug    

    % Home the MPS to 0 degrees.
    Pitch_Home(0);
end

% Delete unecessary variables.
clear alpha_max_raw
clear alpha_min_raw
clear angle

clear angle_id
clear code_path
clear dmc_file_name
clear experiment_number_raw
clear trial_number_raw
clear flapping_frequency_raw
clear force_vals
clear freestream_speed_raw
clear glide_dration_raw

clear num_cycles_raw

clear offset_duration_raw

clear recording_size

clear steps_per_rot
clear these_offsets
clear these_raw_data
clear these_raw_data_table
clear these_raw_data_table_times
clear these_raw_data_table_volt_vals
clear these_raw_times
clear these_raw_volt_vals
clear these_results
clear times
clear volt_vals

% Beep to signal that the data must be saved.

beep;

% Save the non-deleted variables to a MAT file.
uisave(who,...
    strjoin([experiment_name, "results", datestr(now, "mmddyy")], "_"));

% Beep to signal the experiment is finished.
FT = results{1,1};
figure 
t= FT(:,1);
plot(t,FT(:,2:7));
mean(FT(:,4),1)
xlabel('time,s')
ylabel('N/Nm')
TTL = raw_data{1,3};
figure
plot(t,TTL);
xlabel('time,s')
ylabel('V')
beep;
    

