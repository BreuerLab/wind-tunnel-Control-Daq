function [time, force, voltAdj, theta, Z] = process_data(results, offsets, cal_matrix)
    time = results(:,1);
    force = volt_to_force(results(:,2:7), offsets, cal_matrix);
    theta = volt_to_angle(results(:,8), offsets(1,7));
    voltAdj = voltM_to_voltA(results(:,9), offsets(1,8));

    Z = get_wingtip_motion(theta);
end