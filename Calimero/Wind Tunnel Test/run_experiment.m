function run_experiment(AoA_vals, freq_vals, speed, wing_type, measure_revs, automatic, debug)

time_now = datetime;
time_now.Format = 'yyyy-MM-dd HH-mm-ss';
diary("data\output logs\" + speed + "ms_" + string(time_now) + ".txt")

% DAQ Parameters
rate = 10000; % measurement rate of NI DAQ, in Hz
offset_duration = 5; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% ESP Serial Communication
% --- CONFIGURATION ---
portName = "COM32";      % Change to your ESP32 port
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

% Remind user of setup procedure
procedure_UI();

% Make figure to keep track of average values vs. AoA
[f, tiles] = compare_AoA_fig();
[f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures();

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

% wingbeat frequency is used to calculate session duration
padding_revs = 4;
hold_time = 10; % sec

% ----------------------------------------------------------
% Collect data for single trial, turning flapper on and off
% ----------------------------------------------------------
force = run_trial(flapper_obj, esp32, cal_matrix, case_name, offset_duration,...
    offsets, freq_vals(i), measure_revs, padding_revs, hold_time,...
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
saveas(f,'data\plots\compareAoA_' + speed + "ms_" + string(time_now) + ".fig")

if (~debug)
    % Clean up
    delete(cleanup);
    delete(flapper_obj);
end
end