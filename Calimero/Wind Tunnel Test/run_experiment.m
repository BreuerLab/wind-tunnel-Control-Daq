function run_experiment(AoA_vals, freq_vals, speed, wing_type, measure_revs, automatic, debug)

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
diary("data\output logs\" + speed + "ms_" + string(time_now) + ".txt")

% DAQ Parameters
rate = 9000; % measurement rate of NI DAQ, in Hz
offset_duration = 5; % in seconds
calibration_filepath = "../DAQ/Calibration Files/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% Remind user of setup procedure
procedure_UI();

% Make figure to keep track of average values vs. AoA
[f, tiles] = compare_AoA_fig();

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
msg = "Now running trial with " + freq_vals(i) + " Hz, at " + AoA_vals(j) + " deg AoA";
disp(msg);
dictate(msg);

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + speed + "m.s_" + AoA(j) + "deg_" + freq_vals(i) + "Hz";

% wingbeat frequency is used to calculate session duration
padding_revs = 4;
estimate_params = {freq_vals(i), measure_revs, padding_revs, hold_time};

% ----------------------------------------------------------
% Collect data for single trial, turning flapper on and off
% ----------------------------------------------------------
force = run_trial(flapper_obj, cal_matrix, case_name, offset_duration, offsets, estimate_params{:});

process_and_plot(force, i, AoA(j), tiles, freq_vals);

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
saveas(f,'data\plots\compareAoA_' + speed + "ms_" + string(time_now) + ".fig")

if (~debug)
    % Clean up
    delete(cleanup);
    delete(flapper_obj);
end
end