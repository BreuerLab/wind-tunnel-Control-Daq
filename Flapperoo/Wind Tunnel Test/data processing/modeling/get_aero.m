function [C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, wind_speed_sel, wing_length, thinAirfoil)
    if (thinAirfoil)
        single_AR = 2.5;
        AR = 2*single_AR;
        lift_slope = ((2*pi) / (1 + 2/AR));
        alpha_zero = 0;
        C_L_r = lift_slope*deg2rad(eff_AoA - alpha_zero) .* (u_rel / wind_speed_sel).^2;
        C_D_r = C_L_r.^2 / (pi*AR);
        C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
        C_M_r = -C_L_r / 4;
    else
        C_L_r = (lift_slope*eff_AoA + lift_intercept) .* (u_rel / wind_speed_sel).^2;
        C_D_r = (B*cosd(w*eff_AoA) + C) .* (u_rel / wind_speed_sel).^2;
        C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
        C_M_r = (pitch_slope*eff_AoA + pitch_intercept) .* (u_rel / wind_speed_sel).^2;
        % C_M_r = (B_pitch*sind(w_pitch*eff_AoA + off_pitch) + C_pitch) .* (u_rel / wind_speed_sel).^2;
    end
    
    % Integrating across wing
    C_L = (sum(C_L_r,2)*0.001) / wing_length;
    C_D = (sum(C_D_r,2)*0.001) / wing_length;
    C_N = (sum(C_N_r,2)*0.001) / wing_length;
    C_M = (sum(C_M_r,2)*0.001) / wing_length;
end