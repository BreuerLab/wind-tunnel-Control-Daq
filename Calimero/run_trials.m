function run_trials(AoA_vals, freq, speed, wing_type, measure_revs, measure_revs_slow, automatic, load_cell, debug)

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

j = 1;
while (j <= length(AoA_vals))
diary("data\output logs\" + speed + "ms_" + AoA_vals(j) + "deg.txt")

%----------------------------
% Turn off wind tunnel
%----------------------------
if (speed ~= 0)
    if (automatic)
        VFD_stop; % stop wind tunnel motor
    else
        % Confirm user has stopped wind before recording offset for this AoA
        wind_on_off_UI("off");
    end
end

move_pitch(AoA_vals(j));
wait_speed_reached(); % ADD MODIFICATION FOR NON AUTOMATIC CASE

% Get offset data before flapping at this angle with no wind
offset_name = wing_type + "_" + speed + "m.s_" + AoA_vals(j) + "deg";
offsets = flapper_obj.get_force_offsets(offset_name, offset_duration);
offsets = offsets(1,:); % just taking means, no SDs
disp("Offset data at this AoA has been gathered");
beep1;
pause(1)

% Get the offsets before experiment
offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

% Measure data during experiment
results = flapper_obj.measure_force(case_name, session_duration);

% Are we approaching limits of load cell?
checkLimits(results);

% Translate data from raw values into meaningful values
[time, force, voltAdj, theta, Z] = process_data(results, offsets_before, cal_matrix);

% Get the offset after experiment
offsets_after = flapper_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

drift = offsets_after - offsets_before; % over one trial
% Convert drift from voltages into forces and moments
drift = cal_matrix * drift';

fc = 100;  % cutoff frequency in Hz for filter

% Display preliminary data
raw_plot(time, force, voltAdj, theta, case_name, drift, rate, fc);

end