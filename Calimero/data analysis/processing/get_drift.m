% returns drift since beginning of experiment
% offsets now - offsets from before first freq with wind on
function [drift] = get_drift(experiment_filename, offsets_files)
    wing_freqs = [10, 4, 8, 0, 2, 6]; 
    offsets_string = "_after_offsets_";
    calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal";
    cal_mat = obtain_cal(calibration_filepath);

    [case_name_exp, time_stamp_exp, type_exp, wing_freq_exp, AoA_exp, wind_speed_exp] = parse_filename(experiment_filename);

    [offsets_cur, offsets_cur_filename] = findMatchingOffset(offsets_files, offsets_string, wing_freq_exp, AoA_exp, wind_speed_exp, type_exp);
    disp("Current offsets: " + offsets_cur_filename)

    [offsets_first, offsets_first_filename] = findMatchingOffset(offsets_files, offsets_string, wing_freqs(1), AoA_exp, wind_speed_exp, type_exp);
    disp("Original offsets: " + offsets_first_filename)
    % changed code for offsets_first which used to have nested for loop on
    % 10/08/2025

    drift_volt = offsets_cur - offsets_first;
    drift_volt = drift_volt(1:6); % dropping voltage, current, encoder data
    drift_force = cal_mat * drift_volt';
    drift = coordinate_transformation(drift_force, AoA_exp);
end