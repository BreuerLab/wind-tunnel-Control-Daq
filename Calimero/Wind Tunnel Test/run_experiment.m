function run_experiment(AoA_vals, freq_vals, speed, wing_type, measure_revs, hold_time, automatic, debug)

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
diary("data\output logs\" + speed + "ms_" + string(time_now) + ".txt")

% DAQ Parameters
rate = 12000; % measurement rate of NI DAQ, in Hz
offset_duration = 6; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% Galil Parameters
galil_address = "192.168.1.3";
dmc_motion_filename = "motion.dmc";
dmc_hold_filename = "hold.dmc";
ticksPerRev = 18432;
acc = 3; % Hz^2
padding_revs = 4;
wait_time = 2000; % ms

% Remind user of setup procedure
procedure_UI();

% Make figure to keep track of average values vs. AoA
AFAM_bool = true;
[f, tiles] = compare_AoA_fig(AFAM_bool);
[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

% Connect to galil
try
    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f));
catch
    disp("Oops couldn't connect to Galil, trying again...")
    pause(2)

    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f));
end

% Allow user to set wings at midstroke and then galil will hold that
% position afterwards
% Define the total countdown time in seconds
totalTime = 10; 

% Define the update interval in seconds (how frequently the display updates)
interval = 2; 

fprintf('Countdown starting...\n');

for i = totalTime:-interval:interval
    fprintf('Time remaining: %d seconds\n', i);
    pause(interval); 
end

dmc = fileread(dmc_hold_filename);
dmc = string(dmc);

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);
% Command the galil to execute the program
galil.command("XQ");

diary off % IS THIS INITIAL DIARY NECESSARY, WHAT IS GETTING OUTPUT?

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% ----------------------------------------
% ---- Loop through pitch angles ---------
% ----------------------------------------
j = 1;
while (j <= length(AoA_vals))
diary("data\output logs\" + speed + "ms_" + AoA_vals(j) + "deg.txt")

% -----------------------------------------------
% Tare measurement at desired angle with wind off
% -----------------------------------------------
offsets = initial_tare(flapper_obj, offset_duration, wing_type, speed, AoA_vals(j), automatic);

% ------------------------------------------------
% ---- Loop through wingbeat frequencies ---------
% ------------------------------------------------
i = 1;
while (i <= length(freq_vals))
msg = "Now running trial with " + freq_vals(i) + " Hz, at " + AoA_vals(j) + " deg AoA";
disp(msg);
dictate(msg);

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + speed + "m.s_" + AoA_vals(j) + "deg_" + freq_vals(i) + "Hz";

% ----------------------------------------------------------
% Collect data for single trial, turning flapper on and off
% ----------------------------------------------------------
[force] = run_trial(flapper_obj, cal_matrix, case_name, offset_duration,...
    offsets, ticksPerRev, freq_vals(i), acc, measure_revs, padding_revs, hold_time, wait_time,...
    galil, dmc_motion_filename,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4);

process_and_plot(force, i, AoA_vals(j), tiles, freq_vals);

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
offset_name = wing_type + "_" + speed + "m.s_" + AoA_vals(j) + "deg_final";
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
saveas(f,"data\plots\compareAoA_" + speed + "ms_" + string(time_now) + ".fig")

if (~debug)
    % Clean up
    delete(cleanup);
    delete(flapper_obj);
end
end