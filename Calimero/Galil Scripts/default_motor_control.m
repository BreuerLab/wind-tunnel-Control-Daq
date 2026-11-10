function default_motor_control(galil, dmc_filename, dmc_params,...
    num_revs, freq, acc, at_speed_pos, padding_revs, DR_bool)

    dmc = fileread(dmc_filename);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    if dmc_params.galil_direction == 1
        dmc = strrep(dmc, "dir_TEMP", "10"); % 2 only reverses main enc, 10 reverse both
    else
        dmc = strrep(dmc, "dir_TEMP", "0");
    end
    
    if (freq ~= 0)
    dmc = strrep(dmc, "ticks_TEMP", num2str(dmc_params.ticksPerRev));
    dmc = strrep(dmc, "revs_TEMP", num2str(num_revs));
    dmc = strrep(dmc, "speed_TEMP", num2str(freq));
    dmc = strrep(dmc, "acc_TEMP", num2str(acc));
    dmc = strrep(dmc, "waittime_TEMP", num2str(dmc_params.wait_time));
    dmc = strrep(dmc, "OC_TEMP", num2str(dmc_params.OC_pulse_step));
    if ~DR_bool
        dmc = strrep(dmc, "revsRec_TEMP", num2str(round(at_speed_pos) + padding_revs));
    end
    end
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
end