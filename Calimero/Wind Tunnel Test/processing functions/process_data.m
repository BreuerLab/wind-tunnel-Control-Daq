function [time, force, voltAdj, curAdj, theta, Z] = process_data(results, offsets, cal_matrix)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    force = force';
    voltAdj = voltM_to_voltA(results(:,8), offsets(1,7));
    curAdj = volt_to_cur(results(:,9), offsets(1,8));
    theta = volt_to_angle(results(:,10), offsets(1,9));

    Z = get_wingtip_motion(theta);
end