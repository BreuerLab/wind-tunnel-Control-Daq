function run_experiment(AoA_vals, freq_vals, speed, wing_type, amp, measure_revs, hold_time, automatic, debug)

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
diary("data\output logs\" + speed + "ms_" + string(time_now) + ".txt")

% DAQ Parameters
rate = 15000; % measurement rate of NI DAQ, in Hz
offset_duration = 6; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell
async = true;
home_path = "data\home data\";

% Galil Parameters
galil_address = "192.168.1.3";
dmc_motion_filename = "motion.dmc";
dmc_hold_filename = "hold.dmc";
dmc_home_filename = "home_move.dmc";
dmc_get_FF_filename = "obtain_cycle_torque.dmc";
dmc_play_FF_filename = "benchtop_test_FF.dmc";
dmc_params.ticksPerRev = 18432;
acc = 3; % Hz^2
padding_revs = 4;
dmc_params.wait_time = 4000; % ms
dmc_params.OC_pulse_step = 4; % in ticks
dmc_params.galil_direction = 0; % 0 - forward, 1 - reverse

% save data recording parameters
currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
currentDateTimeStr = char(currentDateTime);
file_name = strjoin(["experiment_params", currentDateTimeStr], "_");
full_file_name = "data\experiment parameters\" + file_name + ".mat";
save(full_file_name);

% Remind user of setup procedure
procedure_UI();

% Make figure to keep track of average values vs. AoA
AFAM_bool = true;
[f, tiles] = compare_AoA_fig(AFAM_bool);
[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

% Make Calimero data collection object
if async
    flapper_obj = Calimero_parallel();
    flapper_obj.setup_DAQ(voltage, rate);
else
    flapper_obj = Calimero_serial(rate, voltage);
end

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% Connect to galil
try
    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f, wing_type, speed));
catch
    disp("Oops couldn't connect to Galil, trying again...")
    pause(2)

    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f, wing_type, speed));
end

auto_home = true;
if auto_home
    disp("Homing wings automatically...")
    % Set wings to midstroke automatically
    home_wings(flapper_obj, galil, home_path, speed + "ms_" + AoA_vals(j) + "deg_home", dmc_home_filename, dmc_params)
    pause(2)
else
    % Set wings to midstroke manually by giving user time to adjust wings
    time = 8; % countdown time for setting wing position
    set_hold_position(galil, dmc_hold_filename, dmc_params.galil_direction, time)
    pause(5) % wait for wind tunnel door to be closed
end

diary off % IS THIS INITIAL DIARY NECESSARY, WHAT IS GETTING OUTPUT?

% ----------------------------------------
% ---- Loop through pitch angles ---------
% ----------------------------------------
j = 1;
while (j <= length(AoA_vals))
diary("data\output logs\" + speed + "ms_" + AoA_vals(j) + "deg.txt")

% -----------------------------------------------
% Tare measurement at desired angle with wind off
% -----------------------------------------------
offsets = initial_tare(flapper_obj, offset_duration*2, wing_type, speed, AoA_vals(j), automatic, amp);

% ------------------------------------------------
% ---- Loop through wingbeat frequencies ---------
% ------------------------------------------------
i = 1;
while (i <= length(freq_vals))
msg = "Now running trial with " + freq_vals(i) + " Hz, at " + AoA_vals(j) + " deg AoA";
disp(msg);
dictate(msg);

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + amp + "_" + speed + "m.s_" + AoA_vals(j) + "deg_" + freq_vals(i) + "Hz";

% ----------------------------------------------------------
% Collect data for single trial, turning flapper on and off
% ----------------------------------------------------------
[force] = run_trial(flapper_obj, cal_matrix, case_name, offset_duration,...
    offsets, dmc_params, amp, freq_vals(i), acc, measure_revs, padding_revs, hold_time,...
    galil, dmc_motion_filename, dmc_get_FF_filename, dmc_play_FF_filename,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, async);

process_and_plot(force, i, AoA_vals, j, tiles, freq_vals);

% -------------------------------------------------
% -------- Move to next wingbeat frequency --------
% -------------------------------------------------
if (i < length(freq_vals) && ~automatic)
    i = handle_next_trial(i, length(freq_vals));
end

if (~debug)
    % save wind tunnel data for non-dimensionalization later
    wind_tunnel_save(case_name)
end

i = i + 1;
end

% ------------------------------------------
% -------- Move to next pitch angle --------
% ------------------------------------------
if (j < length(AoA_vals) && ~automatic)
    j = handle_next_AoA(j, length(AoA_vals));
end

% Get final offset data
offset_name = wing_type + "_" + amp + "_" + speed + "m.s_" + AoA_vals(j) + "deg_final";
flapper_obj.get_force_offsets(offset_name, offset_duration);
disp("Final offset data at this AoA has been gathered");
beep2;

j = j + 1;
diary off
end

% -------------------------------------
% -------- Experiment Complete --------
% -------------------------------------
time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
saveas(f, "data\plots\compareAoA_" + wing_type + "_" + speed + "ms_" + string(time_now) + ".fig")

if (~debug)
    % Clean up
    delete(cleanup);
    delete(flapper_obj);
    VFD_stop;
    msg = "Experiments complete!";
    disp(msg);
    dictate(msg);
end
end