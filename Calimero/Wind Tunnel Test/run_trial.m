function [force, distFromZero] = run_trial(flapper_obj, cal_matrix, case_name, offset_duration,...
    offsets, ticksPerRev, freq, acc, measure_revs, padding_revs, hold_time, wait_time,...
    galil, dmc_motion_filename, dmc_stop_filename,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, distFromZero)

    [num_revs, session_duration] = estimate_duration(freq, acc, measure_revs, padding_revs, hold_time);

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
        dmc = strrep(dmc, "ticks_TEMP", num2str(ticksPerRev));
        dmc = strrep(dmc, "revs_TEMP", num2str(num_revs));
        dmc = strrep(dmc, "speed_TEMP", num2str(speed));
        dmc = strrep(dmc, "acc_TEMP", num2str(acc));
        dmc = strrep(dmc, "waittime_TEMP", num2str(wait_time));
    
        % Load the program described by the .dmc file to the Galil device.
        galil.programDownload(dmc);
    
        % Command the galil to execute the program
        galil.command("XQ");
    end
    
    pause(1);

    % Collect experiment data during flapping
    disp("Experiment data collection has begun");
    pause(0.2);

    results = flapper_obj.measure_force(case_name, session_duration);

    disp("Experiment data has been gathered");
    beep2;

    pause(1);

    % Are we approaching limits of load cell?
    checkLimits(results);

    % Translate data from raw values into meaningful values
    [time, force, voltAdj, curAdj, theta, ~] = process_data(results, offsets, cal_matrix);
    
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