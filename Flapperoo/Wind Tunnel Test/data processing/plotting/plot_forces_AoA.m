function cases_final = plot_forces_AoA(path, cases, AoA, names, sub_title, nondimensional, regression, error)
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
        
    avg_forces = zeros(length(AoA), length(names), 6);
    err_forces = zeros(length(AoA), length(names), 6);
    cases_final = strings(length(AoA), length(names));
    
    for i = 1:length(AoA)
        for j = 1:length(names)
            file_name = strrep(cases((i-1)*length(names) + j),' ','_');
            [case_name, type, wing_freq, curAoA, wind_speed] = parse_filename(file_name);
            load(path + case_name + '.mat');
            if (nondimensional)
                for k = 1:6
                    avg_forces(find(AoA == curAoA), j, k) = mean(filtered_norm_data(:, k));
                    if (wing_freq == 0)
                        err_forces(find(AoA == curAoA), j, k) = std(filtered_norm_data(:, k));
                    else
                        err_forces(find(AoA == curAoA), j, k) = mean(wingbeat_rmse_forces(:, k));
                    end
                end
            else
                for k = 1:6
                    avg_forces(find(AoA == curAoA), j, k) = mean(filtered_data(:, k));
                    if (wing_freq == 0)
                        err_forces(find(AoA == curAoA), j, k) = std(filtered_data(:, k));
                    else
                        err_forces(find(AoA == curAoA), j, k) = mean(wingbeat_rmse_forces(:, k));
                    end
                end
            end
            cases_final(find(AoA == curAoA),j) = file_name;
        end
    end
    
%      for j = 1:length(names)
%         for i = 1:length(AoA)
%             file_name = strrep(cases((j-1)*length(AoA) + i),' ','_');
%             [case_name, type, wing_freq, curAoA, wind_speed] = parse_filename(file_name);
%             load(path + case_name + '.mat');
%             if (nondimensional)
%                 for k = 1:6
%                     avg_forces(find(AoA == curAoA), j, k) = mean(filtered_norm_data(:, k));
%                     if (wing_freq == 0)
%                         err_forces(find(AoA == curAoA), j, k) = std(filtered_norm_data(:, k));
%                     else
%                         err_forces(find(AoA == curAoA), j, k) = mean(wingbeat_rmse_forces(:, k));
%                     end
%                 end
%             else
%                 for k = 1:6
%                     avg_forces(find(AoA == curAoA), j, k) = mean(filtered_data(:, k));
%                     if (wing_freq == 0)
%                         err_forces(find(AoA == curAoA), j, k) = std(filtered_data(:, k));
%                     else
%                         err_forces(find(AoA == curAoA), j, k) = mean(wingbeat_rmse_forces(:, k));
%                     end
%                 end
%             end
%             cases_final(find(AoA == curAoA),j) = file_name;
%         end
%     end
    
    x_label = "Angle of Attack (deg)";
    if (nondimensional)
        y_label_F = "Trial Average Force Coefficient";
        y_label_M = "Trial Average Moment Coefficient";
    else
        y_label_F = "Trial Average Force (N)";
        y_label_M = "Trial Average Moment (N*m)";
    end
    axes_labels = [x_label, y_label_F, y_label_M];
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    if (regression)
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 1), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 1)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 2), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 2)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 3), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 3)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 4), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 4)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 5), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 5)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 6), 25, colors(j,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(:, j, 6)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(j,:))
    end
    hold off
    legend()
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    elseif (error)
        
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 1), err_forces(:, j, 1),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 2), err_forces(:, j, 2),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 3), err_forces(:, j, 3),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 4), err_forces(:, j, 4),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 5), err_forces(:, j, 5),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["M_y (pitch)"]);
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        e = errorbar(AoA, avg_forces(:, j, 6), err_forces(:, j, 6),'.');
        e.Color = colors(j,:);
        e.MarkerSize = 20;
    end
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    
    else
        
        % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 1), 25, colors(j,:), 'filled',"HandleVisibility","off");
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 2), 25, colors(j,:), 'filled',"HandleVisibility","off");
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 3), 25, colors(j,:), 'filled',"HandleVisibility","off");
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 4), 25, colors(j,:), 'filled',"HandleVisibility","off");
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
       scatter(AoA, avg_forces(:, j, 5), 25, colors(j,:), 'filled',"HandleVisibility","off");
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
       scatter(AoA, avg_forces(:, j, 6), 25, colors(j,:), 'filled');
    end
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
        
    end
    
    hL = legend(names);
    hL.Layout.Tile = 'East';

    % Label the whole figure.
    sgtitle(["Force and Moment Means vs. Angle of Attack" sub_title]);
end