function [force, distFromZero] = run_trial(flapper_obj, cal_matrix, case_name, offset_duration,...
    offsets, freq, measure_revs, padding_revs, hold_time,...
    galil, dmc_motion_filename, dmc_stop_filename,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, distFromZero)

    if (freq ~= 0)
        % Find what OF value is required to achieve the wingbeat frequency
        OF_init = 0.25; % min for mechanism appears to be 0.18 at 0.01 resolution
        [OF_cur, distFromZero] = speedLoop(freq, OF_init, galil, dmc_motion_filename,...
            dmc_stop_filename, flapper_obj, case_name, distFromZero);
    else
        OF_cur = 0.25;
    end

    % distFromZero = zeroWings(galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, case_name, distFromZero, freq, OF_cur);

    % Get offset data before flapping at this angle and windspeed
    offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
    offsets_before = offsets_before(1,:); % just taking means, no SDs
    disp("Initial offset data has been gathered");
    beep2;

    if (freq ~= 0)
        dmc = fileread(dmc_motion_filename);
        dmc = string(dmc);

        % Replace the place holders in the .dmc file with the values specified
        % here. Other parameters can be changed directly in .dmc file.
        dmc = strrep(dmc, "of_placeholder", num2str(OF_cur));
    
        % Load the program described by the .dmc file to the Galil device.
        galil.programDownload(dmc);
    
        % Command the galil to execute the program
        galil.command("XQ");
    end
    
    % estimate recording length based on parameters
    % ----- NEED TO UPDATE THIS WITH VALUES --------
    session_duration = estimate_duration(freq, measure_revs, padding_revs, hold_time);
    
    pause(1);

    % Collect experiment data during flapping
    disp("Experiment data collection has begun");
    pause(0.2);

    results = flapper_obj.measure_force(case_name, session_duration);

    disp("Experiment data has been gathered");
    beep2;

    pause(1);
    
    % --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
    dmc = fileread(dmc_stop_filename);
    dmc = string(dmc);
    galil.programDownload(dmc);
    galil.command("XQ");

    % Are we approaching limits of load cell?
    checkLimits(results);
    
    theta = results(:,10);
    [distFromZero] = countRev(theta, distFromZero);

    % Translate data from raw values into meaningful values
    [time, force, voltAdj, curAdj, theta, ~] = process_data(results, offsets, cal_matrix);

    if (freq ~= 0)
        measuredFreq = getFreq(theta, flapper_obj.daq.Rate, session_duration);
        disp("Finished flapping at " + measuredFreq + " Hz")
        dictate("Finished flapping at " + measuredFreq + " Hz")
    end
    
    pause(0.5);

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