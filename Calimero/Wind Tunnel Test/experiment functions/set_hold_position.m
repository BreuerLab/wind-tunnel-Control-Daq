function set_hold_position(galil, dmc_hold_filename, galil_direction)
    % Allow user to set wings at midstroke and then galil will hold that
    % position afterwards
    % Define the total countdown time in seconds
    totalTime = 10; 
    
    % Define the update interval in seconds (how frequently the display updates)
    interval = 2; 
    
    fprintf('Countdown starting...\n');
    
    for i = totalTime:-interval:interval
        fprintf('Time remaining: %d seconds\n', i);
        pause(interval); 
    end
    
    dmc = fileread(dmc_hold_filename);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    if galil_direction == 1
        dmc = strrep(dmc, "dir_TEMP", "2");
    else
        dmc = strrep(dmc, "dir_TEMP", "0");
    end
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    % Command the galil to execute the program
    galil.command("XQ");
end