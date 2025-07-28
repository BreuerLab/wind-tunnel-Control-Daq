function pos = checkPos(flapper_obj, cal_matrix, case_name)
    session_duration = 0.1;
    % Collect experiment data during flapping
    disp("Checking wing position");
    results = flapper_obj.measure_force(case_name, session_duration);
    beep2;
    
    offsets = zeros(1,9);
    % Translate data from raw values into meaningful values
    [~, ~, ~, ~, theta, ~] = process_data(results, offsets, cal_matrix);
    pos = theta(end);
end