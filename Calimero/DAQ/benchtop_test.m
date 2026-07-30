clear
close all
clc

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer.

% Author: Ronan Gissler
% Date: 09/12/2025

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));

addpath(genpath("../"))

% case_name = wing_type + "_" + speed + "m.s_" + AoA_vals(j) + "deg_" + freq_vals(i) + "Hz";

% Galil Setup
galil_bool = true;
galil_IP_address = "192.168.1.3";
DR_bool = false; % false - store data in arrays (RA), true - data record packets (DR)
dmc_params.ticksPerRev = 18432;
freq = 4; % Hz
acc = 3; % Hz
measure_revs = 180; % 270
padding_revs = 4;
hold_time = 10; % sec
dmc_params.wait_time = 1000; % ms
dmc_params.OC_pulse_step = 4; % in ticks
% REMEMBER MOTOR WIRES NEED TO BE FLIPPED TOO WHEN CHANGING DIRECTION
dmc_params.galil_direction = 0; % 0 - forward, 1 - reverse
if DR_bool
    dmc_benchtop_filename = "benchtop_test_DR.dmc";
else
    dmc_benchtop_filename = "benchtop_test_RA.dmc";
end
dmc_hold_filename = "hold.dmc";
dmc_home_filename = "home_move.dmc";
dmc_get_FF_filename = "obtain_cycle_torque.dmc";
dmc_play_FF_filename = "benchtop_test_FF.dmc";

amp = 20;
speed = 0;
AoA = 10;
wing_type = "benchtop";
case_name = wing_type + "_" + amp + "_" + speed + "m.s_" + AoA + "deg_" + freq + "Hz_";
% case_name = "UP_two_PIV_flexible_20_" + 4 + "m.s_" + 10 + "deg_" + freq + "Hz_";
% case_name = "ringdown_" + 0 + "m.s_" + 10 + "deg_" + 0 + "Hz_";
time_now = datetime;
time_now.Format = 'yyyy_MM_dd_HH_mm_ss';
case_name = case_name + string(time_now);

daq_bool = true;
async = true; % run daq in asynchronous or synchronous mode
force_bool = true; % plot force data or not
laser_bool = false; 
% DAQ Setup
if daq_bool
[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

% DAQ Parameters
rate = 15000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell
results_path = "data\experiment data\";
home_path = "data\home data\";

if async
    flapper_obj = Calimero_parallel();
    flapper_obj.setup_DAQ(voltage, rate);
else
    flapper_obj = Calimero_serial(rate, voltage);
end

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);
end

% estimate recording length based on parameters
[num_revs, session_duration, time_to_speed, at_speed_pos] = ...
    estimate_duration(freq, acc, measure_revs, padding_revs, hold_time, dmc_params.wait_time, true);

% save data recording parameters
currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
currentDateTimeStr = char(currentDateTime);
file_name = strjoin(["experiment_params", currentDateTimeStr], "_");
full_file_name = "data\experiment parameters\" + file_name + ".mat";

vars = whos;
saveVars = {};
excludeNames = ["flapper_obj", "tiles_1", "tiles_2", "tiles_3", "tiles_4"];

for k = 1:numel(vars)
    val = evalin('base', vars(k).name);
    if ~isa(val, 'matlab.ui.Figure') && ...
       ~any(strcmp(vars(k).name, excludeNames))
        saveVars{end+1} = vars(k).name;
    end
end

save(full_file_name, saveVars{:});

if galil_bool
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

auto_home = true;
if auto_home
    disp("Homing wings automatically...")
    % Set wings to midstroke automatically
    home_wings(flapper_obj, galil, home_path, case_name + "_home", dmc_home_filename, dmc_params)
    pause(2)
else
    % Set wings to midstroke manually by giving user time to adjust wings
    time = 8; % countdown time for setting wing position
    set_hold_position(galil, dmc_hold_filename, dmc_params.galil_direction, time)
    pause(5) % wait for wind tunnel door to be closed
end

% ---------------------------
if DR_bool
% Create a buffer to hold incoming records
% Use a property or appdata to keep it accessible in callback
ref = RefHolder();
ref.Data = [];

% Define callback for onRecord event
% Use a cell callback that passes the COM object as an input
% galil.onRecord = {@recCallback, galil, data};
listener = addlistener(galil, 'onRecord', @(src, event) recCallback(src, event, ref));

% Start recording at 4 ms interval
dt = 10;
galil.recordsStart(dt);
end
% ---------------------------
if freq == 0
    default_motor_control(galil, dmc_hold_filename, dmc_parms,...
    num_revs, freq, acc, at_speed_pos, padding_revs);
else
    improved_control = true;
    if improved_control
        improved_motor_control(galil, dmc_get_FF_filename, dmc_play_FF_filename,...
    dmc_params, measure_revs, num_revs, at_speed_pos, freq, acc, padding_revs);
    else
        default_motor_control(galil, dmc_benchtop_filename, dmc_params,...
    num_revs, freq, acc, at_speed_pos, padding_revs, DR_bool);
    end
end

end

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

if galil_bool
% Command the galil to execute the program
galil.command("XQ");
end

if daq_bool
% Collect experiment data during flapping
disp("Experiment data collection has begun");
results = flapper_obj.measure_force(case_name, session_duration, results_path);
disp("Experiment data has been gathered");
beep2;

pause(1);

% Are we approaching limits of load cell?
checkLimits(results);

ticksPerRev = 18432;
% Translate data from raw values into meaningful values
[time, force, voltAdj, curAdj, pos, speed, acc, wing_pos, wing_speed, wing_acc] = ...
    process_data(results, offsets_before, cal_matrix, dmc_params.ticksPerRev, dmc_params.OC_pulse_step, amp, async);

fc = 20;
fs = rate;
[b,a] = butter(6,fc/(fs/2));
filtered_speed = filtfilt(b,a,speed);

mean(speed(6*rate:end-6*rate))
std(speed(6*rate:end-6*rate))

OC_f = figure;
plot(time, speed)
xlabel("Time (seconds)")
ylabel("Filtered Speed (Hz)")
title("Speed measured from OC pulses")
saveas(OC_f,'data\plots\' + case_name + "_OC.png")

% 1, 2, 3, 4, 6, 8, 9, 12, 16, 18, 24, 32, 36, 48, 64, 72, 96, 128,
% 144, 192, 256, 288, 384, 512, 576, 768, 1024, 1152, 1536, 2048,
% 2304, 3072, 4608, 6144, 9216, 18432


% pulsesPerStep = 18432 / OC_pulse_step;
% % trim beginning and end
% pulse_count = results(8*rate:end-8*rate,11);
% pulse_count = pulse_count(pulse_count ~= 0 & pulse_count ~= pulse_count(end));
% whole_idx = find(mod(pulse_count, pulsesPerStep) <3);
% diff_idx = diff(whole_idx);
% diff_idx = diff_idx(diff_idx ~= 1);
% eff_freq = rate ./ diff_idx;
% % wingbeat frequency error over a single wingbeat
% err = abs(eff_freq - freq);
% laser_freq = 192;
% cycle_frames = 96;
% err_frames = err*(1/freq)*laser_freq;

if laser_bool
las_count = results(:,12);
las_count_diff = diff(las_count);
last_time = time(las_count_diff ~= 0);
last_time = last_time(end);
disp("-------------------------------------------------------------")
disp("Final pulse fired at: " + last_time + " s")

las_count = las_count(las_count ~= 0 & las_count ~= las_count(end));
las_count_diff = diff(las_count);
whole_idx = find(las_count_diff ~= 0);
las_rep_rate = rate ./ diff(whole_idx);
disp("Length of las_rep_rate: " + length(las_rep_rate) + ", with mean: " + mean(las_rep_rate))
disp("-------------------------------------------------------------")

cam_count = results(:,13);
end

% What's most important for phase averaging PIV is that a full cycle
% has some repeatable time


pause(3);
else
    pause(session_duration + 9)
end

if galil_bool && freq ~= 0
% -----------------
if DR_bool
% Stop recording
galil.recordsStart(0);
% -----------------

galil_data = cell2mat(ref.Data);

galil_traj_plot_DR(galil_data, dt);
else
% [TimeArr, Current, DesPos, ActPos, ActVel] = galil_traj_plot(galil);
% 
% currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
% currentDateTimeStr = char(currentDateTime);
% file_name = strjoin([case_name, currentDateTimeStr], "_");
% full_file_name = "data\galil\" + file_name + ".mat";
% 
% saveVars = {"TimeArr", "Current", "DesPos", "ActPos", "ActVel"};
% save(full_file_name, saveVars{:});
% 
% plot_current_comp(time, curAdj, TimeArr, Current, freq, padding_revs, time_to_speed, case_name)
end
% ------------------
end

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
raw_plot(time, force, voltAdj, curAdj, speed, case_name, drift, flapper_obj.DAQ.Rate, fc,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, force_bool);
end

clear cleanup