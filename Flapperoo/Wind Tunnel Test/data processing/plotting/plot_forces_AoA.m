function plot_forces_AoA(path, cases, AoA, names, sub_title, regression)
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];

    avg_forces = zeros(length(AoA), 6);
    std_forces = zeros(length(AoA), 6);
    
    for i = 1:length(AoA)
        for j = 1:length(names)
            load(path + cases(i*j) + '.mat');
            for k = 1:6
                avg_forces(j,i,k) = mean(filtered_data(:, k));
                std_forces(j,i,k) = std(filtered_data(:, k));
            end
        end
    end
    
    x_label = "Angle of Attack (deg)";
    y_label_F = "Trial Average Force (N)";
    y_label_M = "Trial Average Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    if (regression)
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 1), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 1)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 2), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 2)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 3), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 3)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 4), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 4)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 5), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 5)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 6), 25, colors(i,:), HandleVisibility="off");
        x = [ones(size(AoA')), AoA'];
        y = avg_forces(i, :, 6)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA, model, DisplayName=label, Color=colors(i,:))
    end
    hold off
    legend()
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    else
        
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 1), 25, colors(i,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 2), 25, colors(i,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 3), 25, colors(i,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 4), 25, colors(i,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 5), 25, colors(i,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, avg_forces(i, :, 6), 25, colors(i,:), "filled");
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

    %%
    clearvars -except AoA std_forces names axes_labels colors sub_title

    x_label = "Angle of Attack (deg)";
    y_label_F = "Trial Standard Deviation Force (N)";
    y_label_M = "Trial Standard Deviation Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 1), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 2), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 3), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 4), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 5), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for i = 1:length(names)
        scatter(AoA, std_forces(i, :, 6), 25, colors(i,:), DisplayName=names(i));
    end
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    hL = legend();
    hL.Layout.Tile = 'East';

    % Label the whole figure.
    sgtitle(["Force and Moment Standard Deviations vs. Angle of Attack" sub_title]);
end