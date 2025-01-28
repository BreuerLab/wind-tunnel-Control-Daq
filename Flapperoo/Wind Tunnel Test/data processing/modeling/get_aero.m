function [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, wind_speed_sel, wing_length, lift_slope, pitch_slope, AR, AoA)
    alpha_zero = 0;
    
    % used to see what happens if eff AoA is removed from model
    % eff_AoA = AoA*ones(size(eff_AoA));

    if (wind_speed_sel ~= 0)
        % h = (r .* abs(sind(ang_disp)) .* abs(sind(AoA)) + chord .* cosd(AoA)) / chord;

        C_L_r = 2*lift_slope*deg2rad(eff_AoA - alpha_zero) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        C_M_r = 2*pitch_slope*deg2rad(eff_AoA - alpha_zero) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % (cosd(ang_disp).*abs(sind(eff_AoA)))
    else
        C_L_r = zeros(size(eff_AoA));
        C_M_r = zeros(size(eff_AoA));
    end
    C_D_r = C_L_r.^2 / (pi*AR);
    C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
    
    % Integrating across wing
    C_L = (sum(C_L_r,2)*0.001) / wing_length;
    C_D = (sum(C_D_r,2)*0.001) / wing_length;
    C_N = (sum(C_N_r,2)*0.001) / wing_length;
    C_M = (sum(C_M_r,2)*0.001) / wing_length;
end