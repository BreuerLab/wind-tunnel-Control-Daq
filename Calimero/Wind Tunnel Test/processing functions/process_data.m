function [time, force, voltAdj, curAdj, enc_pulse, filtered_speed] = process_data(results, offsets, cal_matrix)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    voltAdj = voltM_to_voltA(results(:,8), offsets(1,7));
    curAdj = volt_to_cur(results(:,9), offsets(1,8));
    enc_pulse = results(:,10);

    dt = time(2) - time(1);
    speed = gradient(results(:,11), dt);
    ticksPerRev = 18432;
    ticksPerPulse = 4;
    speed = speed / (ticksPerRev / ticksPerPulse);
    fc = 200;
    fs = round(1 / dt);
    [b,a] = butter(6,fc/(fs/2));
    filtered_speed = filtfilt(b,a,speed);
end