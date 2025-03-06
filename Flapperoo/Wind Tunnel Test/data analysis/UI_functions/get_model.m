function aero_force = get_model(flapper, path, AoA_list, freq, speed, lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, amp)
    C_L_vals = zeros(1, length(AoA_list));
    C_D_vals = zeros(1, length(AoA_list));
    C_N_vals = zeros(1, length(AoA_list));
    C_M_vals = zeros(1, length(AoA_list));
    % COP_span_vals = zeros(1, length(AoA_list));
    aero_force = zeros(6, length(AoA_list));

    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, freq, amp);
        
    [center_to_LE, chord, COM_span, ...
        wing_length, arm_length] = getWingMeasurements(flapper);
    
    full_length = wing_length + arm_length;
    r = arm_length:0.001:full_length;
    % lin_vel = deg2rad(ang_vel) * r;
    lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;

    for i = 1:length(AoA_list)
        AoA = AoA_list(i);
        
        [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, speed);
        
        [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, speed, wing_length,...
            lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR);

        % if ~(AoA == 0) 
        %     C_L = C_L / abs(sind(AoA));
        %     C_D = C_D / abs(sind(AoA));
        %     C_N = C_N / abs(sind(AoA));
        %     C_M = C_M / abs(sind(AoA));
        % end
        
        C_L_vals(i) = mean(C_L);
        C_D_vals(i) = mean(C_D);
        C_N_vals(i) = mean(C_N);
        C_M_vals(i) = mean(C_M);
        % COP_span_vals(i) = mean(COP_span);
    end

    aero_force(1,:) = C_D_vals;
    aero_force(3,:) = C_L_vals;
    aero_force(5,:) = C_M_vals;
end