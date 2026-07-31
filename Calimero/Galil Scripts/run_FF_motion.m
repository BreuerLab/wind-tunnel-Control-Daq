function run_FF_motion(galil, dmc_play_FF_filename, dmc_params, measure_revs, num_revs,...
    freq, acc, at_speed_pos, padding_revs, phase_avg_torque)
    dmc = fileread(dmc_play_FF_filename);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    if dmc_params.galil_direction == 1
        dmc = strrep(dmc, "dir_TEMP", "2");
    else
        dmc = strrep(dmc, "dir_TEMP", "0");
    end

    dmc = strrep(dmc, "revs_TEMP", num2str(num_revs));
    dmc = strrep(dmc, "ticks_TEMP", num2str(dmc_params.ticksPerRev));
    dmc = strrep(dmc, "speed_TEMP", num2str(freq));
    dmc = strrep(dmc, "acc_TEMP", num2str(acc));
    dmc = strrep(dmc, "waittime_TEMP", num2str(dmc_params.wait_time));
    dmc = strrep(dmc, "OC_TEMP", num2str(dmc_params.OC_pulse_step));
    dmc = strrep(dmc, "revsRec_TEMP", num2str(round(at_speed_pos + padding_revs)));

    % replace num_samples string with actual number of samples
    num_samples = length(phase_avg_torque);
    dmc = strrep(dmc, "NUM_SAMPLES_TEMP", num2str(num_samples));

    dmc = strrep(dmc, "MAX_REV_TEMP", num2str(measure_revs));
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
end