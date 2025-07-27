clear
close all
clc

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer.

% --------Revision History-------------
% Alex Waultre 07/1/2025
% Ronan Gissler 07/20/2025 - Reduced form taking advantage of functions
% Ronan Gissler 07/27/2025 - Replacing ESP32 with Galil

addpath(genpath("../"))

[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

case_name = "1k_PWM";
measure_revs = 100;
padding_revs = 4;
hold_time = 10; % sec

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
case_name = case_name + string(time_now);

% DAQ Parameters
rate = 10000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% Get the offsets before experiment
offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs
disp("Initial offset data has been gathered");
beep2;

% fig = uifigure;
% fig.Position = [600 500 430 160];
% movegui(fig,'center')
% message = ["Offsets collected! Ready for experiment"];
% title = "Experiment Setup Reminder";
% uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
% uiwait(fig);

pause(1);

% if (PWM ~= 0)
%     writeline(esp32, strcat('s', num2str(PWM), '.'));
% % end
% writeline(esp32, 'p');

% estimate recording length based on parameters
% ----- NEED TO UPDATE THIS WITH VALUES --------
session_duration = estimate_duration(PWM, measure_revs, padding_revs, hold_time);

pause(2);

% Collect experiment data during flapping
disp("Experiment data collection has begun");
results = flapper_obj.measure_force(case_name, session_duration);
disp("Experiment data has been gathered");
beep2;

pause(2);

% --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
% writeline(esp32, 's');
% pause(0.5);

% writeline(esp32, 'z');
% reachedZero = false;
% while ~reachedZero
%     % Read incoming messages from ESP32
%     if esp32.NumBytesAvailable > 0
%         line = readline(esp32);
%         disp(line) % debugging
%         if contains(line, "ZERO")
%             reachedZero = true;
%         end
%     end
% end
% pause(5);

% Are we approaching limits of load cell?
checkLimits(results);

% Translate data from raw values into meaningful values
[time, force, voltAdj, curAdj, theta, Z] = process_data(results, offsets_before, cal_matrix);

pause(1);

disp("Collecting final offset")
% Get offset data after flapping at this angle and windspeed
offsets_after = flapper_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs
disp("Final offset data has been gathered");
beep2;

drift = offsets_after - offsets_before; % over one trial

% Convert drift from voltages into forces and moments
drift = cal_matrix * drift(1:6)';

drift_string = string(drift);
% separate numbers by space
drift_string = [sprintf('%s   ',drift_string{1:end-1}), drift_string{end}];
disp("Drift since tare with tunnel off: ")
disp(drift_string)

try
    % clf([f1 f2 f3], 'reset')
    for k = 1:6
        cla([tiles_1{k} tiles_2{k}])
    end
    for k = 1:3
        cla([tiles_3{k} tiles_4{k}])
    end
catch
    % disp("No figures to clear")
    disp("No axes to clear")
end

fc = 100;  % cutoff frequency in Hz for filter
% Display preliminary data
raw_plot(time, force, voltAdj, curAdj, theta, case_name, drift, flapper_obj.daq.Rate, fc,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4);