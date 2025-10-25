% returns drift since beginning of experiment
% offsets now - offsets from before first freq with wind on
function [drift, offsets_before, offsets_after] = get_total_drift(experiment_filename, offsets_files)
    calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal";
    cal_mat = obtain_cal(calibration_filepath);

    [case_name_exp, time_stamp_exp, type_exp, wing_freq_exp, AoA_exp, wind_speed_exp] = parse_filename(experiment_filename);

    offsets_string = "offsets";
    [offsets_init, offsets_init_filename] = findMatchingOffset...
        (offsets_files, offsets_string, wing_freq_exp, AoA_exp, wind_speed_exp, type_exp, time_stamp_exp);
    disp("Initial offsets: " + offsets_init_filename)

    offsets_string = "final_offsets";
    [offsets_final, offsets_final_filename] = findMatchingOffset...
        (offsets_files, offsets_string, wing_freq_exp, AoA_exp, wind_speed_exp, type_exp, time_stamp_exp);
    disp("Final offsets: " + offsets_final_filename)

    drift_volt = offsets_final - offsets_init;
    drift_volt_force = drift_volt(1:6); % dropping voltage, current, encoder data
    drift_force = cal_mat * drift_volt_force';
    drift = coordinate_transformation(drift_force, AoA_exp);
    drift = [drift; drift_volt(7:8)']; % encoder data still excluded

    % Get offsets to return
    offsets_before = coordinate_transformation(cal_mat * offsets_init(1:6)', AoA_exp);
    offsets_before = [offsets_before; offsets_init(7:8)']; % encoder data still excluded

    offsets_after = coordinate_transformation(cal_mat * offsets_final(1:6)', AoA_exp);
    offsets_after = [offsets_after; offsets_final(7:8)']; % encoder data still excluded
end