clear
close all
clc

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer.

% Author: Alex Waultre
% Date: 07/1/2025

addpath(genpath("../"))

PWM = 80;

% DAQ Parameters
rate = 10000; % measurement rate of NI DAQ, in Hz
offset_duration = 5; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% ESP Serial Communication
% --- CONFIGURATION ---
portName = "COM5";      % Change to your ESP32 port
% portName = "COM32";      % Change to your ESP32 port
baudRate = 115200;
timeoutSeconds = 10;
% --- Create serialport object ---
esp32 = serialport(portName, baudRate, "Timeout", timeoutSeconds);
configureTerminator(esp32, "LF");
flush(esp32);
disp("Connected to ESP32 on " + portName);

% --- AUTOMATIC SEQUENCE ---
keepRunning = true;
sentInitialZero = false;
while keepRunning
    % Read incoming messages from ESP32
    if esp32.NumBytesAvailable > 0 &&keepRunning
        line = readline(esp32);
        disp("ESP32: " + line);
        % Detect the message asking to press a key
        if ~sentInitialZero && contains(line, "ESP32 SETUP")
            pause(1);  % Optional delay before responding
            writeline(esp32, '0');
            disp(">> Sent automatic '0' to continue initialization.");
            sentInitialZero = true;
            keepRunning =false;
        end
    end
end
disp("ESP32 SETUP OK, ZERO POSITION SET");
pause(1);

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% Get the offsets before experiment
offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs
disp("Initial offset data has been gathered");
beep2;

fig = uifigure;
fig.Position = [600 500 430 160];
movegui(fig,'center')
message = ["Offsets collected! Ready for experiment"];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);

if (PWM ~= 0)
    writeline(esp32, strcat('s', num2str(PWM), '.'));
end

% estimate recording length based on parameters
% ----- NEED TO UPDATE THIS WITH VALUES --------
session_duration = estimate_duration(freq, measure_revs, padding_revs, hold_time);

pause(2);

% Collect experiment data during flapping
disp("Experiment data collection has begun");
results = flapper_obj.measure_force(case_name, session_duration);
disp("Experiment data has been gathered");
beep2;

pause(2);

% --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
writeline(esp32, 's');
pause(0.5);

writeline(esp32, 'z');
reachedZero = false;
while ~reachedZero
    % Read incoming messages from ESP32
    if esp32.NumBytesAvailable > 0
        line = readline(esp32);
        disp(line) % debugging
        if contains(line, "ZERO")
            reachedZero = true;
        end
    end
end
% pause(5);

% Are we approaching limits of load cell?
checkLimits(results);

% Translate data from raw values into meaningful values
[time, force, voltAdj, curAdj, theta, Z] = process_data(results, offsets, cal_matrix);

pause(1);

% Get the offset after experiment
offsets_after = FT_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

% Display preliminary data
drift = offsets_after - offsets_before;
FT_obj.plot_results(results, case_name, drift);

% Reaching torque or force limits?
if(max(abs(results(:,2:4))) > 0.7*force_limit)
    beep3;
    msgbox("Approaching Force Limit!!!","DANGER!","error");
end
if (max(abs(results(:,5:7))) > 0.7*torque_limit)
    beep3;
    msgbox("Approaching Torque Limit!!!","DANGER!","error");
end