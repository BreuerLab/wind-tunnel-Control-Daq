function move_wings(galil, dmc_home_filename, dmc_params, ticks_to_move)
    dmc = fileread(dmc_home_filename);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    if dmc_params.galil_direction == 1
        dmc = strrep(dmc, "dir_TEMP", "2");
    else
        dmc = strrep(dmc, "dir_TEMP", "0");
    end

    dmc = strrep(dmc, "ticks_revs_TEMP", num2str(ticks_to_move));
    dmc = strrep(dmc, "ticks_TEMP", num2str(dmc_params.ticksPerRev));
    dmc = strrep(dmc, "speed_TEMP", num2str(1));
    dmc = strrep(dmc, "acc_TEMP", num2str(3));
    dmc = strrep(dmc, "waittime_TEMP", num2str(dmc_params.wait_time));
    dmc = strrep(dmc, "OC_TEMP", num2str(dmc_params.OC_pulse_step));
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    % Command the galil to execute the program
    galil.command("XQ");
end