function force = run_trial(flapper_obj, esp32, cal_matrix, case_name, offset_duration,...
    offsets, freq, measure_revs, padding_revs, hold_time,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4)
    % Get offset data before flapping at this angle and windspeed
    offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
    offsets_before = offsets_before(1,:); % just taking means, no SDs
    disp("Initial offset data has been gathered");
    beep2;
    
    % -------SET FLAPPING SPEED WITH ENCODER-------------
    % Wait until flapping speed is reached by controller
    % include tic toc to see how long this takes and record that value in diary
    % by printing it out

    PWM = freq;
    if (PWM ~= 0)
        writeline(esp32, strcat('s', num2str(PWM), '.'));
    end
    
    % estimate recording length based on parameters
    % ----- NEED TO UPDATE THIS WITH VALUES --------
    session_duration = estimate_duration(freq, measure_revs, padding_revs, hold_time);
    
    pause(2);

    % Collect experiment data during flapping
    disp("Experiment data collection has begun");
    results = flapper_obj.measure_force(case_name, session_duration);
    disp("Experiment data has been gathered");
    beep2;

    pause(2);
    
    % --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
    writeline(esp32, 's');
    pause(0.5);

    writeline(esp32, 'z');
    reachedZero = false;
    while ~reachedZero
        % Read incoming messages from ESP32
        if esp32.NumBytesAvailable > 0
            line = readline(esp32);
            disp(line) % debugging
            if contains(line, "ZERO")
                reachedZero = true;
            end
        end
    end
    % pause(5);

    % Are we approaching limits of load cell?
    checkLimits(results);
    
    % Translate data from raw values into meaningful values
    [time, force, voltAdj, curAdj, theta, Z] = process_data(results, offsets, cal_matrix);
    
    pause(1);

    disp("Collecting final offset")
    % Get offset data after flapping at this angle and windspeed
    offsets_after = flapper_obj.get_force_offsets(case_name + "_after", offset_duration);
    offsets_after = offsets_after(1,:); % just taking means, no SDs
    disp("Final offset data has been gathered");
    beep2;
    
    drift = offsets_after - offsets_before; % over one trial
    total_drift = offsets_after - offsets; % since initial tare
    
    % Convert drift from voltages into forces and moments
    drift = cal_matrix * drift(1:6)';
    total_drift = cal_matrix * total_drift(1:6)';
    
    drift_string = string(total_drift);
    % separate numbers by space
    drift_string = [sprintf('%s   ',drift_string{1:end-1}), drift_string{end}];
    disp("Drift since tare with tunnel off: ")
    disp(drift_string)
    
    try
        % clf([f1 f2 f3], 'reset')
        for k = 1:6
            cla([tiles_1{k} tiles_2{k}])
        end
        for k = 1:3
            cla([tiles_3{k} tiles_4{k}])
        end
    catch
        % disp("No figures to clear")
        disp("No axes to clear")
    end

    fc = 100;  % cutoff frequency in Hz for filter
    % Display preliminary data
    raw_plot(time, force, voltAdj, curAdj, theta, case_name, drift, flapper_obj.daq.Rate, fc,...
        f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4);
end