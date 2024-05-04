function plot_forces_mult_subset(path, cases, main_title, sub_title, subtraction_string)
    single = false;
    nondimensional = true;

    if (subtraction_string == "none")
        body_subtraction = false;
    else
        body_subtraction = true;
    end

    titles = ["Drag", "Transverse", "Lift", "Roll", "Pitch", "Yaw"];

    if ~single
    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 1400 500];
    tcl = tiledlayout(1,3);
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    alpha = 0.4;
    a=nexttile;b=nexttile;c=nexttile;
    
    x_label = "Wingbeat Period (t/T)";
    % y_label_F = "Force Coefficient";
    % y_label_M = "Moment Coefficient";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    for i = 1:length(cases)
        load(path + cases(i) + '.mat');

        if (nondimensional)
            avg_forces = dimensionless(wingbeat_avg_forces, norm_factors);
            std_forces = dimensionless(wingbeat_std_forces, norm_factors);
        else
            avg_forces = wingbeat_avg_forces;
            std_forces = wingbeat_std_forces;
        end

        disp("Loading data from " + cases(i) + " trial")

        if (body_subtraction)
            [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(cases(i));
            type = convertCharsToStrings(type);
    
            % Parse relevant information from subtraction string
            case_parts = strtrim(split(subtraction_string));
            sub_type = "";
            sub_wing_freq = wing_freq;
            sub_wind_speed = wind_speed;
            sub_AoA = AoA;
            index = length(case_parts) + 1;
            for j=1:length(case_parts)
                if (contains(case_parts(j), "Hz"))
                    sub_wing_freq = str2double(erase(case_parts(j), "Hz"));
                    if index ~= -1
                        index = j;
                    end
                elseif (contains(case_parts(j), "m.s"))
                    sub_wind_speed = str2double(erase(case_parts(j), "m.s"));
                    if index ~= -1
                        index = j;
                    end
                elseif (contains(case_parts(j), "deg"))
                    sub_AoA = str2double(erase(case_parts(j), "deg"));
                    if index ~= -1
                        index = j;
                    end
                end
            end
            sub_type = strjoin(case_parts(1:index-1)); % speed is first thing after type
            
            sub_case_name = sub_type + " " + sub_wind_speed + "m.s " + sub_AoA + "deg " + sub_wing_freq + "Hz";
        
            load(path + sub_case_name + '.mat');
    
            if (nondimensional)
                norm_wingbeat_avg_forces = dimensionless(wingbeat_avg_forces, norm_factors);
                avg_forces = avg_forces - norm_wingbeat_avg_forces;
            else
                avg_forces = avg_forces - wingbeat_avg_forces;
            end

            disp("Subtracting data from " + sub_case_name + " trial")
        end

        % Create three subplots to show the force time histories. 
        axes(a)
        hold on
        xconf = [frames, frames(end:-1:1)];         
        yconf = [avg_forces(1, :) + std_forces(1, :), avg_forces(1, end:-1:1) - std_forces(1, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, avg_forces(1, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(b)
        hold on
        xconf = [frames, frames(end:-1:1)];            
        yconf = [avg_forces(3, :) + std_forces(3, :), avg_forces(3, end:-1:1) - std_forces(3, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, avg_forces(3, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(c)
        hold on
        xconf = [frames, frames(end:-1:1)];            
        yconf = [avg_forces(5, :) + std_forces(5, :), avg_forces(5, end:-1:1) - std_forces(5, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, avg_forces(5, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_y (pitch)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
    end
        hL = legend();
        hL.Layout.Tile = 'East';
    
        % Label the whole figure.
        sgtitle([main_title sub_title]);
    else

        index = 5;
        % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    alpha = 0.4;
    
    x_label = "Wingbeat Period (t/T)";
    % y_label_F = "Force Coefficient";
    % y_label_M = "Moment Coefficient";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    for i = 1:length(cases)
        load(path + cases(i) + '.mat');
        
        hold on
        xconf = [frames, frames(end:-1:1)];         
        yconf = [wingbeat_avg_forces(index, :) + wingbeat_std_forces(index, :), wingbeat_avg_forces(index, end:-1:1) - wingbeat_std_forces(index, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, wingbeat_avg_forces(index, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
    end
        hL = legend();
    
        % Label the whole figure.
        sgtitle(titles(index));
    end

    %% --------------------RMSE plot-------------------
    RMSE_plot = false;
    if (RMSE_plot)
    clearvars -except path cases main_title sub_title

     % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    alpha = 0.4;
    a=nexttile;b=nexttile;c=nexttile;d=nexttile;e=nexttile;f=nexttile;
    
    x_label = "Wingbeat Period (t/T)";
    y_label_F = "RMSE";
    y_label_M = "RMSE";
    axes_labels = [x_label, y_label_F, y_label_M];

    for i = 1:length(cases)
        load(path + cases(i) + '.mat');
        
        % Create three subplots to show the force time histories. 
        axes(a)
        hold on
        plot(frames, wingbeat_rmse_forces(1, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(b)
        hold on
        plot(frames, wingbeat_rmse_forces(2, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_y (transverse)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(c)
        hold on
        plot(frames, wingbeat_rmse_forces(3, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        % Create three subplots to show the moment time histories.
        axes(d)
        hold on
        plot(frames, wingbeat_rmse_forces(4, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_x (roll)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        axes(e)
        hold on
        plot(frames, wingbeat_rmse_forces(5, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_y (pitch)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        axes(f)
        hold on
        plot(frames, wingbeat_rmse_forces(6, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_z (yaw)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        hL = legend();
        hL.Layout.Tile = 'East';
    
        % Label the whole figure.
        sgtitle([main_title sub_title]);
    end
    end

    %% --------------------COP plot-------------------
    COP_plot = false;
    if (COP_plot)
    clearvars -except path cases main_title sub_title

     % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    
    title("Movement of Center of Pressure")
    xlabel("Wingbeat Period (t/T)");
    ylabel("COP Location (m)");

    for i = 1:length(cases)
        load(path + cases(i) + '.mat');
        [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(cases(i));

        % Calculate normal force from lift and drag forces for each
        % angle of attack
        lift_force = wingbeat_avg_forces(3,:);
        drag_force = wingbeat_avg_forces(1,:);
        pitch_moment = wingbeat_avg_forces(5,:);

        normal_force = lift_force*cosd(AoA) + drag_force*sind(AoA);

        % COP position (in meters) relative to load cell center
        COP = - pitch_moment ./ normal_force;
        [COP_LE, COP_chord] = posToChord(COP);

        hold on
        plot(frames, COP_chord, DisplayName=cases(i), Color=colors(i,:))
        ylim([-100, 100])
        hold off
    end
    legend();
    end
end