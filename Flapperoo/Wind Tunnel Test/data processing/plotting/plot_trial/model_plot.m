function model_plot(wind_speed, wing_freq, AoA, ...
                    sub_wind_speed, sub_wing_freq, sub_AoA, ...
                    case_title, sub_case_title, ...
                    frames, wingbeat_avg_forces, wingbeat_std_forces, ...
                    norm_factors, sub_bool, nondimensional)
    CAD_bool = true;
    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq, CAD_bool);
    
    [center_to_LE, chord, COM_span, ...
        wing_length, arm_length] = getWingMeasurements();

    full_length = wing_length + arm_length;
    r = arm_length:0.001:full_length;
    lin_vel = deg2rad(ang_vel) * r;
    lin_acc = deg2rad(ang_acc) * r;
    
    [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

    [inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span, AoA);
    
    thinAirfoil = true;
    [C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, wind_speed, wing_length, thinAirfoil);

    [added_mass_force] = get_added_mass(ang_disp, ang_acc, r, wing_length, AoA);

    % lin_disp = deg2rad(ang_disp) * r;
    % lin_disp_COM = lin_disp(:, round(r,3) == round(COM_span,3));
    % wing_mass = 0.010; % kg
    % wing_to_FT_height = 0.1; % m

    % inertial_force = 2*wing_mass*lin_acc_COM.*cosd(ang_disp);
    % static_term = lin_disp_COM
    % static_mom = -2*wing_mass*wing_to_FT_height*sind(AoA);
    % static_mom = 0;

    avg_drag_force = wingbeat_avg_forces(1,:);
    avg_lift_force = wingbeat_avg_forces(3,:);
    avg_pitch_moment = wingbeat_avg_forces(5,:);
    std_drag_force = wingbeat_std_forces(1,:);
    std_lift_force = wingbeat_std_forces(3,:);
    std_pitch_moment = wingbeat_std_forces(5,:);

    pitch_moment_LE = avg_pitch_moment;

    if (nondimensional)
        avg_drag_force = avg_drag_force / norm_factors(1);
        avg_lift_force = avg_lift_force / norm_factors(1);
        pitch_moment_LE = pitch_moment_LE / norm_factors(2);

        inertial_force = [inertial_force(:,1) / norm_factors(1),...
                        inertial_force(:,2) / norm_factors(1),...
                        inertial_force(:,3) / norm_factors(2)];

        added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
                        added_mass_force(:,2) / norm_factors(1),...
                        added_mass_force(:,3) / norm_factors(2)];

        std_drag_force = std_drag_force / norm_factors(1);
        std_lift_force = std_lift_force / norm_factors(1);
    
        std_pitch_moment = std_pitch_moment / norm_factors(2);
    else
        C_D = C_D * norm_factors(1);
        C_L = C_L * norm_factors(1);
        C_M = C_M * norm_factors(2);
    end

    drag_force_up = avg_drag_force + std_drag_force;
    drag_force_low = avg_drag_force - std_drag_force;
    lift_force_up = avg_lift_force + std_lift_force;
    lift_force_low = avg_lift_force - std_lift_force;

    pitch_moment_LE_up = pitch_moment_LE + std_pitch_moment;
    pitch_moment_LE_low = pitch_moment_LE - std_pitch_moment;

    total_drag = C_D + inertial_force(:,1) + added_mass_force(:,1);
    total_lift = C_L + inertial_force(:,2) + added_mass_force(:,2);
    total_moment = C_M + inertial_force(:,3) + added_mass_force(:,3);

    if (sub_bool)
        disp("Subtracting model data (not type)")
        [sub_time, sub_ang_disp, sub_ang_vel, sub_ang_acc] = get_kinematics(sub_wing_freq, CAD_bool);
    
        sub_lin_vel = deg2rad(sub_ang_vel) * r;
        sub_lin_acc = deg2rad(sub_ang_acc) * r;
    
        [sub_eff_AoA, sub_u_rel] = get_eff_wind(sub_time, sub_lin_vel, sub_AoA, sub_wind_speed);

        [sub_inertial_force] = get_inertial(sub_ang_disp, sub_ang_acc, r, COM_span, sub_AoA);
        
        thinAirfoil = true;
        [sub_C_L, sub_C_D, sub_C_N, sub_C_M] = get_aero(sub_eff_AoA, sub_u_rel, sub_wind_speed, wing_length, thinAirfoil);
    
        [sub_added_mass_force] = get_added_mass(sub_ang_disp, sub_ang_acc, r, wing_length, sub_AoA);
    
        if (nondimensional)
            sub_inertial_force = [sub_inertial_force(:,1) / norm_factors(1),...
                            sub_inertial_force(:,2) / norm_factors(1),...
                            sub_inertial_force(:,3) / norm_factors(2)];
    
            sub_added_mass_force = [sub_added_mass_force(:,1) / norm_factors(1),...
                            sub_added_mass_force(:,2) / norm_factors(1),...
                            sub_added_mass_force(:,3) / norm_factors(2)];
        else
            sub_C_D = sub_C_D * norm_factors(1);
            sub_C_L = sub_C_L * norm_factors(1);
            sub_C_M = sub_C_M * norm_factors(2);
        end
    
        sub_total_drag = sub_C_D + sub_inertial_force(:,1) + sub_added_mass_force(:,1);
        sub_total_lift = sub_C_L + sub_inertial_force(:,2) + sub_added_mass_force(:,2);
        sub_total_moment = sub_C_M + sub_inertial_force(:,3) + sub_added_mass_force(:,3);
    
        % Subtraction
        inertial_force = inertial_force - sub_inertial_force;
        C_D = C_D - sub_C_D;
        C_L = C_L - sub_C_L;
        C_M = C_M - sub_C_M;
        added_mass_force = added_mass_force - sub_added_mass_force;
    
        total_drag = C_D + inertial_force(:,1) + added_mass_force(:,1);
        total_lift = C_L + inertial_force(:,2) + added_mass_force(:,2);
        total_moment = C_M + inertial_force(:,3) + added_mass_force(:,3);
    end

    %----------------------------------------------------------%
    % Construct a figure
    %----------------------------------------------------------%

    fig = figure;
    fig.Position = [200 50 1400 500];
    tcl = tiledlayout(1,2);
    if (sub_bool)
        sgtitle([case_title "{\color{red}{SUBTRACTION}}: " + sub_case_title]);
    else
        sgtitle(case_title);
    end
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    
    x_label = "Wingbeat Period (t/T)";
    if (nondimensional)
        y_label_F = "Force Coefficient";
        y_label_M = "Moment Coefficient";
    else
        y_label_F = "Force (N)";
        y_label_M = "Moment (N*m)";
    end

    names = ["Experiment", "Wing Inertia", "Added Mass", "Thin Airfoil", "Total"];

    % nexttile
    % hold on
    % line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
    % xconf = [frames, frames(end:-1:1)];         
    % yconf = [drag_force_up, drag_force_low(end:-1:1)];
    % p = fill(xconf, yconf, 'blue');
    % p.FaceColor = [0.8 0.8 1];      
    % p.EdgeColor = 'none';
    % p.HandleVisibility = 'off';
    % plot(frames, avg_drag_force, "DisplayName", "Experiment", LineWidth=2, Color=colors(1,:));
    % plot(time / max(time), inertial_force(:,1), DisplayName="Wing Inertia", LineStyle="--", LineWidth=2,Color=colors(2,:));
    % plot(time / max(time), added_mass_force(:,1), DisplayName="Added Mass", LineStyle="--", LineWidth=2,Color=colors(3,:));
    % plot(time / max(time), C_D, DisplayName="Quasi-Steady", LineStyle="--", LineWidth=2,Color=colors(4,:));
    % plot(time / max(time), total_drag, DisplayName="Model", LineWidth=2,Color=colors(5,:))
    % plot_wingbeat_patch();
    % legend(Location="best");
    % xlabel(x_label)
    % ylabel(y_label_F)
    % title("Drag force")  

    nexttile
    hold on
    line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
    xconf = [frames, frames(end:-1:1)];         
    yconf = [lift_force_up, lift_force_low(end:-1:1)];
    p = fill(xconf, yconf, 'blue');
    p.FaceColor = [0.8 0.8 1];      
    p.EdgeColor = 'none';
    p.HandleVisibility = 'off';
    plot(frames, avg_lift_force, LineWidth=2, Color=colors(1,:));
    plot(time / max(time), inertial_force(:,2), LineStyle="--", LineWidth=2, Color=colors(2,:));
    plot(time / max(time), added_mass_force(:,2), LineStyle="--", LineWidth=2, Color=colors(3,:));
    plot(time / max(time), C_L, LineStyle="--", LineWidth=2, Color=colors(4,:));
    plot(time / max(time), total_lift, LineWidth=2, Color=colors(5,:))
    plot_wingbeat_patch();
    xlabel(x_label)
    ylabel(y_label_F)
    title("Lift force")

    nexttile
    hold on
    line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
    xconf = [frames, frames(end:-1:1)];         
    yconf = [pitch_moment_LE_up, pitch_moment_LE_low(end:-1:1)];
    p = fill(xconf, yconf, 'blue');
    p.FaceColor = [0.8 0.8 1];      
    p.EdgeColor = 'none';
    p.HandleVisibility = 'off';
    plot(frames, pitch_moment_LE, LineWidth=2, Color=colors(1,:));
    plot(time / max(time), inertial_force(:,3), LineStyle="--", LineWidth=2, Color=colors(2,:));
    plot(time / max(time), added_mass_force(:,3), LineStyle="--", LineWidth=2, Color=colors(3,:));
    % plot(time / max(time), lin_disp_COM, "DisplayName","Static", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), C_M, LineStyle="--", LineWidth=2, Color=colors(4,:));
    plot(time / max(time), total_moment, LineWidth=2, Color=colors(5,:))
    plot_wingbeat_patch();
    xlabel(x_label)
    ylabel(y_label_M)
    title("Pitch Moment LE")

    hL = legend(names);
    hL.Layout.Tile = 'East';
end