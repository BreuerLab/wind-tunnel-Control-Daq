function plot_forces_AoA_tare(AoA_sel, avg_forces, err_forces, names, sub_title)
    error = true;
    
    x_label = "Angle of Attack (deg)";
    y_label_F = "Trial Average Force (N)";
    y_label_M = "Trial Average Moment (N*m)";
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
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(1, :), err_forces(1, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    s = scatter(AoA_sel, avg_forces(1, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(2, :), err_forces(2, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    s = scatter(AoA_sel, avg_forces(2, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(3, :), err_forces(3, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    s = scatter(AoA_sel, avg_forces(3, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(4, :), err_forces(4, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    s = scatter(AoA_sel, avg_forces(4, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(5, :), err_forces(5, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    s = scatter(AoA_sel, avg_forces(5, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
        
    if (error)
    e = errorbar(AoA_sel, avg_forces(6, :), err_forces(6, :),'.');
    e.Color = colors(1,:);
    e.MarkerSize = 20;
    else
    scatter(AoA_sel, avg_forces(6, :), 25, 'filled',"HandleVisibility","off");
    s.Color = colors(1,:);
    end
    
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));

    % Label the whole figure.
    sgtitle(["Force and Moment Means vs. Angle of Attack" sub_title]);
end