function plot_forces_AoA_combo(freq_speed_combos, selected_vars, avg_forces, err_forces, names, sub_title, nondimensional, forceIndex)
    AoA_sel = selected_vars.AoA;
    type_sel = selected_vars.type;

    regression = false;
    error = true;
    
    if (forceIndex == 0)
    
    x_label = "Angle of Attack (deg)";
    if (nondimensional)
        y_label_F = "Trial Average Force Coefficient";
        y_label_M = "Trial Average Moment Coefficient";
    else
        y_label_F = "Trial Average Force (N)";
        y_label_M = "Trial Average Moment (N*m)";
    end
    axes_labels = [x_label, y_label_F, y_label_M];
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
        
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(1, :, j, n), err_forces(1, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(1, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 1)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    s = scatter(AoA_sel, avg_forces(1, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(2, :, j, n), err_forces(2, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(2, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 2)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    s = scatter(AoA_sel, avg_forces(2, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(3, :, j, n), err_forces(3, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(3, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 3)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    s = scatter(AoA_sel, avg_forces(3, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(4, :, j, n), err_forces(4, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(4, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 4)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    s = scatter(AoA_sel, avg_forces(4, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(5, :, j, n), err_forces(5, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(5, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 5)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    s = scatter(AoA_sel, avg_forces(5, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
    for j = 1:length(freq_speed_combos)
    for n = 1:length(type_sel)
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(6, :, j, n), err_forces(6, :, j, n),'.');
    e.Color = colors(n + (j-1)*length(type_sel),:);
    e.MarkerSize = 20;
    elseif (regression)
    s = scatter(AoA_sel, avg_forces(6, :, j, n), 25, HandleVisibility="off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(:, j, 6)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
    scatter(AoA_sel, avg_forces(6, :, j, n), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(n + (j-1)*length(type_sel),:);
    end
    
    end
    end
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    

    hL = legend(names);
    hL.Layout.Tile = 'East';

    % Label the whole figure.
    sgtitle(["Force and Moment Means vs. Angle of Attack" sub_title]);
    
    else
         x_label = "Angle of Attack (deg)";
        if (nondimensional)
            y_label_F = "Trial Average Force Coefficient";
            y_label_M = "Trial Average Moment Coefficient";
        else
            y_label_F = "Trial Average Force (N)";
            y_label_M = "Trial Average Moment (N*m)";
        end
        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];
        titles = ["F_x (drag)", "F_y (transverse lift)", "F_z (vertical lift)", "M_x (roll)", "M_y (pitch)", "M_z (yaw)"];
        colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
                [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
                [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
                [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];

        % Open a new figure.
%         f = figure;
%         f.Position = [200 50 900 560];
        
        hold on
        for j = 1:length(freq_speed_combos)
        for n = 1:length(type_sel)

        if (error)
        markers = ["pentagram", "o"];
        e = errorbar(AoA_sel, avg_forces(forceIndex, :, j, n), err_forces(forceIndex, :, j, n),'.');
%         e.Color = colors(j,:);
        e.Color = colors(mod(j,2) + 1,:);
        e.MarkerFaceColor = colors(mod(j,2) + 1,:);
        e.MarkerSize = 10;
        e.Marker = markers(round(j/2));
        e.DisplayName = names(j,n);
        elseif (regression)
        s = scatter(AoA_sel, avg_forces(forceIndex, :, j, n), 25, HandleVisibility="off");
        s.Color = colors(n + (j-1)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 6)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
        else
        scatter(AoA_sel, avg_forces(forceIndex, :, j, n), 25, 'filled');
        s.Color = colors(j,:);
        end

        end
        end
        hold off
        title(titles(forceIndex), FontSize=18);
        xlabel(x_label, FontSize=14);
        ylabel(y_labels(forceIndex), FontSize=14);
        format short
        legend(Location="northwest");
    end
end