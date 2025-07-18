function [C_L, C_D, C_N, C_M, COP_span] ...
    = get_aero(ang_disp, eff_AoA, u_rel, wind_speed_sel, wing_length, dr, ...
    lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, r)
    
    % used to see what happens if eff AoA is removed from model
    % eff_AoA = AoA*ones(size(eff_AoA));

    if (wind_speed_sel ~= 0)
        % h = (r .* abs(sind(ang_disp)) .* abs(sind(AoA)) + chord .* cosd(AoA)) / chord;

        % removed 2* in front for 2 wings, this factor of 2 is in numerator
        % and denominator of area term so it drops out
        % % *********************************
        C_L_r = lift_slope*deg2rad(eff_AoA - zero_lift_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        C_M_r = pitch_slope*deg2rad(eff_AoA - zero_pitch_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % *********************************
        % Without effective area term
        % C_L_r = lift_slope*deg2rad(eff_AoA - zero_lift_alpha) .* (u_rel / wind_speed_sel).^2;
        % C_M_r = pitch_slope*deg2rad(eff_AoA - zero_pitch_alpha) .* (u_rel / wind_speed_sel).^2;
        % Using geometric AoA
        % C_L_r = lift_slope*deg2rad(eff_AoA(1,1) - zero_lift_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = pitch_slope*deg2rad(eff_AoA(1,1) - zero_pitch_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % Without effective wind term
        % C_L_r = lift_slope*deg2rad(eff_AoA - zero_lift_alpha) .* cosd(ang_disp);
        % C_M_r = pitch_slope*deg2rad(eff_AoA - zero_pitch_alpha) .* cosd(ang_disp);

        % C_L_r = 3*sin(2*deg2rad(eff_AoA - zero_lift_alpha)) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = -0.7081*sin(2*deg2rad(eff_AoA - zero_pitch_alpha)) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_L_r = 3*sin(1.591*deg2rad(eff_AoA - zero_lift_alpha) + 3.083) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = 0.4*sin(-4.1*deg2rad(eff_AoA - zero_pitch_alpha) + 3.083) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_L_r = lift_slope*sin(deg2rad(eff_AoA - zero_lift_alpha)) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = pitch_slope*sin(deg2rad(eff_AoA - zero_pitch_alpha)) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_L_r = 3.9913*deg2rad(eff_AoA - zero_lift_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = -2*deg2rad(eff_AoA - zero_pitch_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_L_r = 3.9913*deg2rad(eff_AoA - zero_lift_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % C_M_r = -2.5*deg2rad(eff_AoA - zero_pitch_alpha) .* (u_rel / wind_speed_sel).^2 .* cosd(ang_disp);
        % (cosd(ang_disp).*abs(sind(eff_AoA)))

        % -------------------------------------
        % TRY THIS
        % pitch_slope * sin(2 * eff_AoA)
        % -------------------------------------
    else
        C_L_r = zeros(size(eff_AoA));
        C_M_r = zeros(size(eff_AoA));
    end
    C_D_r = C_L_r.^2 / (pi*AR);
    C_N_r = C_L_r .* cosd(eff_AoA) + C_D_r .* sind(eff_AoA);
    
    % Integrating across wing
    % C_L = sum(C_L_r,2) * (dr / wing_length);
    % C_D = sum(C_D_r,2) * (dr / wing_length);
    % C_N = sum(C_N_r,2) * (dr / wing_length);
    % C_M = sum(C_M_r,2) * (dr / wing_length);

    % Integrating across wing
    C_L = trapz(dr, C_L_r, 2) / wing_length;
    C_D = trapz(dr, C_D_r, 2) / wing_length;
    C_N = trapz(dr, C_N_r, 2) / wing_length;
    C_M = trapz(dr, C_M_r, 2) / wing_length;

    % Spanwise location of COM
    COP_span = sum(C_L_r .* r, 2) ./ sum(C_L_r, 2);
end