function [time, force, voltAdj, curAdj, enc_pulse, OC_pulse_count] = process_data(results, offsets, cal_matrix, ticksPerRev, OC_pulse_step)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    voltAdj = voltM_to_voltA(results(:,8), offsets(1,7));
    curAdj = volt_to_cur(results(:,9), offsets(1,8));
    enc_pulse = results(:,10);

    OC_pulse_count = results(:,11);
end