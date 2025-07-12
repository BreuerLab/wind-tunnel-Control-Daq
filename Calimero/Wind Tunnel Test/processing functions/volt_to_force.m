function force_vals = volt_to_force(raw_volt_vals, offsets, cal_matrix)
    % Apply offset and calibration to force channels
    volt_vals = raw_volt_vals(:, 1:6) - offsets(1, 1:6);
    force_vals = cal_matrix * volt_vals';
    force_vals = force_vals';
end