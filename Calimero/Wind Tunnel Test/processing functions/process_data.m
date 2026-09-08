function [time, force, voltAdj, curAdj, home_signal, pos, speed, acc, wing_pos, wing_speed, wing_acc] = ...
    process_data(results, offsets, cal_matrix, ticksPerRev, OC_pulse_step, amp, async)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    voltAdj = voltM_to_voltA(results(:,8), offsets(1,7));
    curAdj = volt_to_cur(results(:,9), offsets(1,8));
    home_signal = results(:,10);

    dt = time(2) - time(1);
    order = 2; % was 3
    framelen = 1001;
    OC_pulse_count = results(:,11);

    [d, r] = get_calimero_dims(amp);

    if async
        raw_pos = OC_pulse_count / (ticksPerRev / OC_pulse_step); % revs
        wing_raw_pos = calimero_mechanism(raw_pos*2*pi, d, r);
        [pos, speed, acc] = savitskyGolayDiff(raw_pos, order, framelen, dt);
        [wing_pos,wing_speed,wing_acc] = savitskyGolayDiff(wing_raw_pos, order, framelen, dt);
    else
    digEdges = results(:,10);
    % Initialize edge count array
    edgeCountArr = zeros(size(digEdges));
    counter = 0;
    
    % Loop through the signal
    for k = 2:length(digEdges)
        if digEdges(k) ~= digEdges(k-1)  % detect any edge (rising or falling)
            counter = counter + 1;
        end
        edgeCountArr(k) = counter;
    end

    speed = savitskyGolayDiff(edgeCountArr, order, framelen, dt);
    speed = speed / 48;
    end
end