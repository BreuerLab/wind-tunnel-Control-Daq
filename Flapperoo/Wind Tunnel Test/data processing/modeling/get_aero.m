function [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, wind_speed_sel, wing_length, thinAirfoil, single_AR)
    if (thinAirfoil)
        AR = 2*single_AR;
        lift_slope = ((2*pi) / (1 + 2/AR));
        alpha_zero = 0;
        if (wind_speed_sel ~= 0)
            C_L_r = lift_slope*deg2rad(eff_AoA - alpha_zero) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        else
            C_L_r = zeros(size(eff_AoA));
        end
        C_D_r = C_L_r.^2 / (pi*AR);
        C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
        C_M_r = -C_L_r / 4;
    else
        C_L_r = (-0.44*exp(-0.47*eff_AoA) + 1.19*sind(1.74*eff_AoA + 20)) .* (u_rel / wind_speed_sel).^2;
        C_D_r = (1.04 + sind(1.72*eff_AoA - 70)) .* (u_rel / wind_speed_sel).^2;
        C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
        x_cp = 0.247 + 0.016*eff_AoA.^0.6 + 0.026*eff_AoA.*exp(-0.11*eff_AoA);
        C_M_r = -C_N_r .* x_cp;
        % old formulation using fits from my data
        % C_L_r = (lift_slope*eff_AoA + lift_intercept) .* (u_rel / wind_speed_sel).^2;
        % C_D_r = (B*cosd(w*eff_AoA) + C) .* (u_rel / wind_speed_sel).^2;
        % C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
        % C_M_r = (pitch_slope*eff_AoA + pitch_intercept) .* (u_rel / wind_speed_sel).^2;

        % C_M_r = (B_pitch*sind(w_pitch*eff_AoA + off_pitch) + C_pitch) .* (u_rel / wind_speed_sel).^2;
    end
    
    % Integrating across wing
    C_L = (sum(C_L_r,2)*0.001) / wing_length;
    C_D = (sum(C_D_r,2)*0.001) / wing_length;
    C_N = (sum(C_N_r,2)*0.001) / wing_length;
    C_M = (sum(C_M_r,2)*0.001) / wing_length;
end