function run_trial(flapper_obj, case_name, offset_duration, session_duration, estimate_params)
    % Get offset data before flapping at this angle and windspeed
    offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
    offsets_before = offsets_before(1,:); % just taking means, no SDs
    disp("Initial offset data has been gathered");
    beep2;
    
    % -------SET FLAPPING SPEED WITH ENCODER-------------
    % Wait until flapping speed is reached by controller
    % include tic toc to see how long this takes and record that value in diary
    % by printing it out
    
    % estimate recording length based on parameters
    % ----- NEED TO UPDATE THIS WITH VALUES --------
    [distance, session_duration, trigger_pos] = estimate_duration(estimate_params{:});
    
    % Collect experiment data during flapping
    disp("Experiment data collection has begun");
    results = flapper_obj.measure_force(case_name, session_duration);
    disp("Experiment data has been gathered");
    beep2; 
    
    % --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
    
    % Are we approaching limits of load cell?
    checkLimits(results);
    
    % Translate data from raw values into meaningful values
    [time, force, voltAdj, theta, Z] = process_data(results, offsets, cal_matrix);
    
    % Get offset data after flapping at this angle and windspeed
    offsets_after = flapper_obj.get_force_offsets(case_name + "_after", offset_duration);
    offsets_after = offsets_after(1,:); % just taking means, no SDs
    disp("Final offset data has been gathered");
    beep2;
    
    drift = offsets_after - offsets_before; % over one trial
    total_drift = offsets_after - offsets; % since initial tare
    
    % Convert drift from voltages into forces and moments
    drift = cal_matrix * drift';
    total_drift = cal_matrix * total_drift';
    
    drift_string = string(total_drift);
    % separate numbers by space
    drift_string = [sprintf('%s   ',drift_string{1:end-1}), drift_string{end}];
    disp("Drift since tare with tunnel off: ")
    disp(drift_string)
    
    fc = 100;  % cutoff frequency in Hz for filter
    
    % Display preliminary data
    raw_plot(time, force, voltAdj, theta, case_name, drift, rate, fc);
end