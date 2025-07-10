function run_trials(AoA_vals, freq_vals, speed, wing_type, measure_revs, measure_revs_slow, automatic, load_cell, debug)

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
diary("data\output logs\" + speed + "ms_" + string(time_now) + ".txt")

% DAQ Parameters
rate = 9000; % measurement rate of NI DAQ, in Hz
offset_duration = 5; % in seconds
session_duration = -1; % in seconds
calibration_filepath = "../DAQ/Calibration Files/FT52907.cal"; 
voltage = 5; % 5 or 10 volts

case_name = "force_transducer_test";

% Remind user of setup procedure
procedure_UI();

diary off % IS THIS INITIAL DIARY NECESSARY, WHAT IS GETTING OUTPUT?

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% Ensure motor is commanded to stop when the run_trial function completes
% (either on its own or termination by user)
% NEED TO UPDATE THIS FUNCTION TO COMMAND ESP32 APPROPRIATELY
cleanup = onCleanup(@()myCleanupFun(f));

% ----------------------------------------
% ---- Loop through pitch angles ---------
% ----------------------------------------
j = 1;
while (j <= length(AoA_vals))
diary("data\output logs\" + speed + "ms_" + AoA_vals(j) + "deg.txt")

% -----------------------------------------------
% Tare measurement at desired angle with wind off
% -----------------------------------------------
offsets = initial_tare(flapper_obj, offset_duration, wing_type, speed, AoA_vals(j));

% ------------------------------------------------
% ---- Loop through wingbeat frequencies ---------
% ------------------------------------------------
i = 1;
while (i <= length(freq_vals))
disp("Now running trial with " + freq_vals(i) + " Hz, at " + AoA_vals(j) + " deg AoA");
dictate("Now running trial with " + freq_vals(i) + " Hz, at " + AoA_vals(j) + " deg AoA");

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + speed + "m.s_" + AoA(j) + "deg_" + freq_vals(i) + "Hz";
vel = freq_vals(i)*rev_ticks; % ticks / sec

estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time hold_time};

% ----------------------------------------------------------
% Collect data for single trial, turning flapper on and off
% ----------------------------------------------------------
run_trial(flapper_obj, case_name, offset_duration, session_duration, estimate_params);

% -------------------------------------------------
% -------- Move to next wingbeat frequency --------
% -------------------------------------------------
if (i < length(freq) && ~automatic)
    i = handle_next_trial(i, length(freq));
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
if (j < length(AoA) && ~automatic)
    j = handle_next_AoA(j, length(AoA));
end

% Get final offset data
offset_name = wing_type + "_" + speed + "m.s_" + AoA(j) + "deg_final";
offsets_final = FT_obj.get_force_offsets(offset_name, offset_duration);
disp("Final offset data at this AoA has been gathered");
beep2;

j = j + 1;
diary off
end

% -------------------------------------
% -------- Experiment Complete --------
% -------------------------------------
% NEEDS UPDATING, SAVING PLOT THAT GETS UPDATED THROUGHOUT
time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
saveas(f,'data\plots\compareAoA_' + speed + "ms_" + string(time_now) + ".fig")

if (~debug)
    % Clean up
    delete(cleanup);
    delete(FT_obj);
end
end