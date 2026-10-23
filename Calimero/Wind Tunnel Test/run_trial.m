function [force, LC_idx, end_idx] = run_trial(flapper_obj, cal_matrix, case_name, offset_duration,...
    offsets, dmc_params, amp, freq, acc, measure_revs, padding_revs, hold_time,...
    results_path, galil, dmc_hold_filename, dmc_motion_filename, dmc_get_FF_filename, dmc_play_FF_filename,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, async, galil_bool)

    % handle quasi-steady case
    if freq < 1
        measure_revs = 20;
        padding_revs = 1;
    end

    [num_revs, session_duration, time_to_speed, at_speed_pos] = ...
        estimate_duration(freq, acc, measure_revs, padding_revs, hold_time, dmc_params.wait_time, true);

    disp("Acquiring initial offset");
    % Get offset data before flapping at this angle and windspeed
    offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
    offsets_before = offsets_before(1,:); % just taking means, no SDs
    disp("Initial offset data has been gathered");
    beep2;

    if freq < 1
        improved_control = false;
    else
        improved_control = true;
    end

    if galil_bool
    if freq == 0
        default_motor_control(galil, dmc_hold_filename, dmc_params,...
        num_revs, freq, acc, at_speed_pos, padding_revs, false);
    else
        if improved_control
            improved_motor_control(galil, dmc_get_FF_filename, dmc_play_FF_filename,...
        dmc_params, measure_revs, num_revs, at_speed_pos, freq, acc, padding_revs);
        else
            default_motor_control(galil, dmc_motion_filename, dmc_params,...
        num_revs, freq, acc, at_speed_pos, padding_revs, false);
        end
    end

    % Command the galil to execute the program
    galil.command("XQ");
    end

    % Collect experiment data during flapping
    disp("Acquiring experimental data");
    pause(0.2);

    results = flapper_obj.measure_force(case_name, session_duration, results_path);

    disp("Experiment data has been gathered");
    beep2;

    pause(1);

    % Are we approaching limits of load cell?
    checkLimits(results);

    % Translate data from raw values into meaningful values
    [time, force, voltAdj, curAdj, home_signal, pos, speed, acc, wing_pos, wing_speed, wing_acc] =...
        process_data(results, offsets, cal_matrix,  dmc_params.ticksPerRev, dmc_params.OC_pulse_step, amp, async);

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

    if freq ~= 0
        learning_complete_rev = round(at_speed_pos + padding_revs) + 20;
        LC_time = time(pos >= learning_complete_rev);
        LC_time = LC_time(1);
        LC_idx = find(time == LC_time);
        end_rev = measure_revs + (padding_revs + round((at_speed_pos) + 0.5));
        end_time = time(pos >= end_rev);
        end_time = end_time(1);
        end_idx = find(time == end_time);
    else
        LC_idx = 1;
        LC_time = time(LC_idx);
        end_idx = length(time);
        end_time = time(end_idx);
    end

    fc = 100;  % cutoff frequency in Hz for filter
    force_bool = true;
    % Display preliminary data
    raw_plot(time, force, voltAdj, curAdj, speed, case_name, drift, flapper_obj.DAQ.Rate, fc,...
        f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, force_bool, LC_time, end_time);
end