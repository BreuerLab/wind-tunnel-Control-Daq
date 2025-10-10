clear
close all
clc

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer.

% Author: Ronan Gissler
% Date: 09/12/2025

addpath(genpath("../"))

% case_name = wing_type + "_" + speed + "m.s_" + AoA_vals(j) + "deg_" + freq_vals(i) + "Hz";

% Galil Setup
galil_plots = true;
galil_IP_address = "192.168.1.3";
dmc_benchtop_filename = "benchtop_test.dmc";
ticksPerRev = 18432;
freq = 8; % Hz
acc = 3; % Hz
measure_revs = 50;
padding_revs = 4;
hold_time = 15; % sec
wait_time = 1000; % ms
% REMEMBER MOTOR WIRES NEED TO BE FLIPPED TOO WHEN CHANGING DIRECTION
galil_direction = 0; % 0 - forward, 1 - reverse

case_name = "benchtop_" + 0 + "m.s_" + 0 + "deg_" + freq + "Hz_";
time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
case_name = case_name + string(time_now);

daq_bool = false;
% DAQ Setup
if daq_bool
[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

% DAQ Parameters
rate = 12000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);
end

% estimate recording length based on parameters
[num_revs, session_duration] = estimate_duration(freq, acc, measure_revs, padding_revs, hold_time, true);

try
    galil = galil_setup(galil_IP_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFunB(galil));
catch
    disp("Oops couldn't connect to Galil, trying again...")
    pause(2)

    galil = galil_setup(galil_IP_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFunB(galil));
end

% ---------------------------
% % Select what to record: e.g. position (_TPA) and torque (_TTA)
% % galil.command('DR0,0');
% galil.command('DRF=_TPA,_TTA,TIME');  % Must include TIME explicitly!
% 
%  % Create a buffer to hold incoming records
% % Use a property or appdata to keep it accessible in callback
% ref = RefHolder();
% ref.Data = [];
% 
% % Define callback for onRecord event
% % Use a cell callback that passes the COM object as an input
% % galil.onRecord = {@recCallback, galil, data};
% listener = addlistener(galil, 'onRecord', @(src, event) recCallback(src, event, ref));
% 
% % Start recording at 5 ms interval
% galil.recordsStart(10);
% % ---------------------------

dmc = fileread(dmc_benchtop_filename);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
if galil_direction == 1
    dmc = strrep(dmc, "dir_TEMP", "2");
else
    dmc = strrep(dmc, "dir_TEMP", "0");
end
dmc = strrep(dmc, "ticks_TEMP", num2str(ticksPerRev));
dmc = strrep(dmc, "revs_TEMP", num2str(num_revs));
dmc = strrep(dmc, "speed_TEMP", num2str(freq));
dmc = strrep(dmc, "acc_TEMP", num2str(acc));
dmc = strrep(dmc, "waittime_TEMP", num2str(wait_time));

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

if daq_bool
% Get the offsets before experiment
offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs
disp("Initial offset data has been gathered");
beep2;
end

% fig = uifigure;
% fig.Position = [600 500 430 160];
% movegui(fig,'center')
% message = ["Offsets collected! Ready for experiment"];
% title = "Experiment Setup Reminder";
% uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
% uiwait(fig);

pause(1);

% Command the galil to execute the program
galil.command("XQ");

if daq_bool
% Collect experiment data during flapping
disp("Experiment data collection has begun");
results = flapper_obj.measure_force(case_name, session_duration);
disp("Experiment data has been gathered");
beep2;

pause(1);

% Are we approaching limits of load cell?
checkLimits(results);

% Translate data from raw values into meaningful values
[time, force, voltAdj, curAdj, enc_pulse] = process_data(results, offsets_before, cal_matrix);

pause(1);
else
    pause(session_duration)
end

% -----------------
% Stop recording
% galil.recordsStart(0);





% data = galil.record;   % Equivalent to galiltools 'record' function call
% pos   = galil.sourceValue(data, '_TPA');   % access each field by its DRF name
% torque= galil.sourceValue(data, '_TTA');
% srcs = galil.sources;

% for j = 1:length(srcs)
%     cur_src = srcs{j};
%     pos = -1*ones(1, length(ref.Data));
% for i = 1:length(ref.Data)
%     temp = ref.Data(:,i)';
%     pos(i) = galil.sourceValue(temp, cur_src);   % access each field by its DRF name
% end
%     if (mean(pos) ~= 0)
%         disp(j)
%     end
%     disp(cur_src)
%     disp(mean(pos))
% end




% pos = -1*ones(1, length(ref.Data));
% for i = 1:length(ref.Data)
%     temp = ref.Data(:,i)';
%     pos(i) = galil.sourceValue(temp, 'TIME');   % access each field by its DRF name
% end
% ------------------

if daq_bool
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
raw_plot(time, force, voltAdj, curAdj, enc_pulse, case_name, drift, flapper_obj.daq.Rate, fc,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4);
end

if (galil_plots)
galil_traj_plot(galil);
end

clear cleanup