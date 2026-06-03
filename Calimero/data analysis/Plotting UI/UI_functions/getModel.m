% Inputs:
% sel_freq - wingbeat frequency, ex: "2 Hz", "2 Hz v2"
% AoA - angle of attack (in degrees), ex: 2
% wind_speed - wind speed (in m/s), ex: 4
% Outputs:
% All are 1 x n arrays where n represents many points over a
% wingbeat period
function [time, inertial_force, added_mass_force, aero_force] = ...
    getModel(path, flapper, sel_freq, AoA, wind_speed, lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, amp, norm_factors, norm_bool)

    wing_freq = str2double(extractBefore(sel_freq, " Hz"));

    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, wing_freq, amp);

    [center_to_LE, chord, COM_span, ...
        wing_length, arm_length] = getWingMeasurements(flapper);

    % load(path + "Vibes/theta_response.mat")
    % 
    % % No this is getting the response following a 100g drop which is not
    % % what I want
    % ang_disp_vibe = interp1(t, response, time);

    full_length = wing_length + arm_length;
    dr = 0.001;
    r = arm_length:dr:full_length;
    lin_vel = deg2rad(ang_vel) * r;
    lin_acc = deg2rad(ang_acc) * r;
    
    [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

    % [inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span, chord, AoA);
    
    [C_L, C_D, C_N, C_M, COP_span] = get_aero(ang_disp, eff_AoA, u_rel, wind_speed, wing_length, dr,...
        lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, r);
    aero_force = [C_D, C_L, C_M];

    [added_mass_force, COP_span_AM] = get_added_mass(ang_disp, ang_vel, ang_acc, wing_length, chord, AoA, dr, r);

    % dimensional value needed for get_inertial_vibe
    aero_force = [aero_force(:,1) * norm_factors(1),...
            aero_force(:,2) * norm_factors(1),...
            aero_force(:,3) * norm_factors(2)];

    % Should only be used in non-normalized mode since moments are
    % calculated using real distances?
    L_AM = added_mass_force(:,2);
    L_QSBE = aero_force(:,2);
    [inertial_force, theta, dot_theta, ddot_theta] = ...
        get_inertial_vibe(time, ang_disp, ang_vel, flapper, AoA, wing_freq, L_AM, L_QSBE, COP_span_AM, COP_span);

     if (norm_bool)
        inertial_force = [inertial_force(:,1) / norm_factors(1),...
                        inertial_force(:,2) / norm_factors(1),...
                        inertial_force(:,3) / norm_factors(2)];
        added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
                        added_mass_force(:,2) / norm_factors(1),...
                        added_mass_force(:,3) / norm_factors(2)];
        aero_force = [aero_force(:,1) / norm_factors(1),...
                    aero_force(:,2) / norm_factors(1),...
                    aero_force(:,3) / norm_factors(2)];
     end


    % for i = 1:5
    %      % Recalculate aerodynamics considering bending
    %     lin_vel = dot_theta * r;
    %     [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);
    % 
    %     [C_L, C_D, C_N, C_M, COP_span] = get_aero(rad2deg(theta), eff_AoA, u_rel, wind_speed, wing_length, dr,...
    %     lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, r);
    %     aero_force = [C_D, C_L, C_M];
    % 
    %     [added_mass_force, COP_span_AM] = get_added_mass(rad2deg(theta), rad2deg(ddot_theta), wing_length, chord, AoA, dr, r);
    % 
    %     % Use dynamic pressure force to scale modeled data
    %     if (norm_bool)
    %         added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
    %                 added_mass_force(:,2) / norm_factors(1),...
    %                 added_mass_force(:,3) / norm_factors(2)];
    %     else
    %         aero_force = [aero_force(:,1) * norm_factors(1),...
    %                 aero_force(:,2) * norm_factors(1),...
    %                 aero_force(:,3) * norm_factors(2)];
    %     end
    % 
    %     L_AM = added_mass_force(:,2);
    %     L_QSBE = aero_force(:,2);
    %     [inertial_force, theta, dot_theta, ddot_theta] = ...
    %         get_inertial_vibe(time, ang_disp, ang_vel, flapper, AoA, wing_freq, L_AM, L_QSBE, COP_span_AM, COP_span);
    % end

    % 
    % % PLOTTING Angular velocity and angular acceleration from THETA
    % figure
    % hold on
    % plot(time, rad2deg(dot_theta), DisplayName="\theta vel", LineWidth=2)
    % plot(time, rad2deg(ddot_theta), DisplayName="\theta acc", LineWidth=2)
    % legend()
    % xlabel("Time (sec)")
    % % ylabel("Angle (deg)")
    % set(gca,'fontsize', 14)
    % 
    % % PLOTTING terms used to calculate lift force
    % figure
    % hold on
    % plot(time, rad2deg(ddot_theta .* sin(theta)), DisplayName="\theta vel", LineWidth=2)
    % plot(time, rad2deg(dot_theta.^2 .* cos(theta)), DisplayName="\theta acc", LineWidth=2)
    % legend()
    % xlabel("Time (sec)")
    % % ylabel("Angle (deg)")
    % set(gca,'fontsize', 14) 
    % 
    % PLOTTING LIFT
    % figure
    % hold on
    % plot(time, inertial_up_force, LineWidth=2)
    % xlabel("Time (sec)")
    % ylabel("Lift Force (N)")
    % set(gca,'fontsize', 14) 

    % L = length(M_t);
    % Fs = L * wing_freq;
    % A_p = fftshift(M_t); % real signals have two-sided spectrum
    % A_p = A_p(L/2:L-1);
    % freqs = Fs/L*(0:L/2-1);
end

    % % % added bit here to get impulse force
    % % I = 0.007; % amplitude of curve
    % % phi = pi/2; % phase shift of curve
    % % z = 0.13803;
    % % w_n = 112.2551;
    % % w_d = 111.1004;
    % % % I = I * (16/9); % should this somehow be a function of freq
    % % impulse_force = (exp(-z*w_n*time) .* sin(w_d*time + phi)) / (I*w_d);
    % 
    % % impulse should be an impulse instead of the system response to
    % % an impulse
    % A = 10;
    % impulse_force = zeros(size(time));
    % impulse_force(1) = A;
    % 
    % % A = 0.01;
    % % impulse_force = A*ones(size(time));

    % % assume inertial force acts at center of wings
    % shift_distance = -chord/2;

    % drag_force = impulse_force * sind(AoA);
    % lift_force = impulse_force * cosd(AoA);
    % pitch_moment = impulse_force * shift_distance;
    % 
    % impulse_force = [drag_force, lift_force, pitch_moment];