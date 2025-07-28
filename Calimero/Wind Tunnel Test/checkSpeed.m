function freq = checkSpeed(OF, galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, cal_matrix, case_name)
    if (vel ~= 0)
        dmc = fileread(dmc_motion_filename);
        dmc = string(dmc);
    
        % Replace the place holders in the .dmc file with the values specified
        % here. Other parameters can be changed directly in .dmc file.
        dmc = strrep(dmc, "of_placeholder", num2str(OF));
    end
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    
    % Command the galil to execute the program
    galil.command("XQ");
    
    pause(0.5);
    
    session_duration = 2;
    % Collect experiment data during flapping
    disp("Experiment data collection has begun");
    results = flapper_obj.measure_force(case_name, session_duration);
    disp("Experiment data has been gathered");
    beep2;
    
    pause(0.5);
    
    % --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
    dmc = fileread(dmc_stop_filename);
    dmc = string(dmc);
    galil.programDownload(dmc);
    galil.command("XQ");
    
    % Are we approaching limits of load cell?
    checkLimits(results);
    
    offsets = zeros(1,6);
    % Translate data from raw values into meaningful values
    [time, ~, ~, ~, theta, ~] = process_data(results, offsets, cal_matrix);
    
    pause(1);
    
    freq = compute_gearbox_speed_fft(time, theta);
end