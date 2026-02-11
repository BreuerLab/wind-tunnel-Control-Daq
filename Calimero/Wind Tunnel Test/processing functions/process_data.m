function [time, force, voltAdj, curAdj, speed, OC_pulse_count] = ...
    process_data(results, offsets, cal_matrix, ticksPerRev, OC_pulse_step, async)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    voltAdj = voltM_to_voltA(results(:,8), offsets(1,7));
    curAdj = volt_to_cur(results(:,9), offsets(1,8));

    dt = time(2) - time(1);
    order = 3;
    framelen = 21;
    OC_pulse_count = results(:,11);

    if async
    speed = savitskyGolayDiff(results(:,11), order, framelen, dt);
    speed = speed / (ticksPerRev / OC_pulse_step);
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