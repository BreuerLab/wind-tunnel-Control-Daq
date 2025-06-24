function [inertial_force_vec, theta, dot_theta, ddot_theta] = get_inertial_vibe(time, ang_disp, ang_vel, flapper, AoA, wing_freq, L_AM, L_QSBE, COP_span_AM, COP_span)
    [~, chord, COM_span, ~, ~] = getWingMeasurements(flapper);

    % a phase shift might be necessary?
    % -------From Impulse Test-----------
    z = 0.13803; % zeta - damping factor
    w_n = 112.2551; % natural frequency
    w_d = 111.1004; % damped natural frequency - observed frequency
    % -----------------------------------
    wing_mass = 0.010; % kg
    I = wing_mass * COM_span^2; % ml^2
    k = I * w_n^2;
    c = 2 * I * z * w_n;
    % cosine necessary since lift force is directed up rather than
    % perpendicular to wing length
    M_AM = L_AM .* COP_span_AM .* cosd(ang_disp);
    M_QSBE = L_QSBE .* COP_span .* cosd(ang_disp);
    M_a = M_AM + M_QSBE;
    A = wing_freq * (1/50);
    impulse_force = zeros(size(time));
    % impulse_force(1) = A;
    M_t = c * deg2rad(ang_vel) + k * deg2rad(ang_disp) + M_a + impulse_force;

    % How do I get higher resolution with power spectra? The longer the
    % signal, generally the better resolution I can get. But are all my
    % frequencies always going to be greater than the fundamental
    % frequency? What if I make the fundamental frequency that attributed
    % to the whole length of the signal, very low...
    M_t_long = [repmat(M_t(1:end-1),49,1); M_t];
    dt = time(2) - time(1);
    time_long = 0:dt:dt*(length(M_t_long) - 1);
    time_long = time_long';

    % number of modes limited by number of data points
    % base mode limited by sample period
    % w_o = 2*pi*wing_freq;
    w_o = 2*pi*(1 / max(time_long));
    A_p = zeros(1, round(length(M_t_long)/2));
    freqs = [];
    for p = 0:length(A_p)-1
        A_p(p+1) = (2 / max(time_long)) * trapz(time_long, M_t_long .* exp(-1i * p * w_o * time_long));
        freqs = [freqs (p * w_o) / (2 * pi)];
    end

    reconstruct_M_t = A_p(1) / 2;
    theta = (A_p(1) / (2*k));
    theta_long = theta;
    for p = 1:length(A_p)-1
        reconstruct_M_t = reconstruct_M_t + real( A_p(p+1) * exp(1i * p * w_o * time) );

        H_p = 1 / (1 - ((p * w_o) / w_n)^2 + 1i*2*z*((p * w_o) / w_n));
        theta = theta + real( (A_p(p+1) / k) * H_p * exp(1i * p * w_o * time) );
        theta_long = theta_long + real( (A_p(p+1) / k) * H_p * exp(1i * p * w_o * time_long) );
    end

    % dot_theta = gradient(theta, time);
    % ddot_theta = gradient(dot_theta, time);

    % corrected this calculation to not have weird effects at edge of
    % domain when differentiating by using long time series
    dot_theta = gradient(theta_long, time_long);
    ddot_theta = gradient(dot_theta, time_long);
    dot_theta = dot_theta(length(time):2*length(time)-1);
    ddot_theta = ddot_theta(length(time):2*length(time)-1);

    % LENGTH FOR M_A SHOULD NOT BE COM_SPAN, should be COP
    % Multiplied by 2 since there are two wings
    % Lift = (M_a ./ (COM_span * cosd(ang_disp))) + wing_mass * COM_span * (ddot_theta .* sin(theta) + dot_theta.^2 .* cos(theta));
    inertial_up_force = 2 * wing_mass * COM_span * (ddot_theta .* cos(theta) - dot_theta.^2 .* sin(theta));

    shift_distance = -chord/2;

    drag_force = inertial_up_force * sind(AoA);
    lift_force = inertial_up_force * cosd(AoA);
    pitch_moment = inertial_up_force * shift_distance;

    inertial_force_vec = [drag_force, lift_force, pitch_moment];

        % PLOTTING INPUT FORCING added mass and quasi-steady blade element
    % figure
    % hold on
    % plot(time, M_AM, DisplayName="Added Mass", LineWidth=2)
    % plot(time, M_QSBE, DisplayName="Quasi-Steady", LineWidth=2)
    % legend()
    % xlabel("Time (sec)")
    % ylabel("Moment (N*m)")
    % set(gca,'fontsize', 14) 

    % % PLOTTING INPUT FORCING M_T
    % figure
    % hold on
    % plot(time, M_t, DisplayName="M_t", LineWidth=2)
    % plot(time, M_a, DisplayName="M_a", LineWidth=2)
    % % plot(time, reconstruct_M_t, DisplayName="Reconstructed M_t", LineWidth=2)
    % legend()
    % xlabel("Time (sec)")
    % ylabel("Moment (N*m)")
    % set(gca,'fontsize', 14) 
    % 
    % % PLOTTING FFT
    % figure
    % plot(freqs, abs(A_p),"LineWidth",3)
    % xlim([0 30])
    % title("Spectrum for M_t")
    % xlabel("f (Hz)")
    % ylabel("|fft(X)|")
    % set(gca,'fontsize', 14) 
    % % 
    % % PLOTTING THETA
    % figure
    % hold on
    % plot(time, ang_disp, DisplayName="\theta_b", LineWidth=2)
    % plot(time, rad2deg(theta), DisplayName="\theta", LineWidth=2)
    % legend()
    % xlabel("Time (sec)")
    % ylabel("Angle (deg)")
    % set(gca,'fontsize', 14)
end