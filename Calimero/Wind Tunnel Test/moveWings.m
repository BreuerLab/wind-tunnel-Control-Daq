function moveWings(OF, wait_time, galil, dmc_motion_filename, dmc_stop_filename)
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
    
    pause(wait_time);

    % --------COMMAND MOTOR TO STOP SPINNING AND RETURN TO GLIDING POSITION---
    dmc = fileread(dmc_stop_filename);
    dmc = string(dmc);
    galil.programDownload(dmc);
    galil.command("XQ");
end