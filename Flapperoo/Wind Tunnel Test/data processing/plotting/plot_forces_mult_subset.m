function plot_forces_mult_subset(path, cases, main_title, sub_title)
    single = true;


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
        
        % Create three subplots to show the force time histories. 
        axes(a)
        hold on
        xconf = [frames, frames(end:-1:1)];         
        yconf = [wingbeat_avg_forces(1, :) + wingbeat_std_forces(1, :), wingbeat_avg_forces(1, end:-1:1) - wingbeat_std_forces(1, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, wingbeat_avg_forces(1, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(b)
        hold on
        xconf = [frames, frames(end:-1:1)];            
        yconf = [wingbeat_avg_forces(3, :) + wingbeat_std_forces(3, :), wingbeat_avg_forces(3, end:-1:1) - wingbeat_std_forces(3, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, wingbeat_avg_forces(3, :), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(c)
        hold on
        xconf = [frames, frames(end:-1:1)];            
        yconf = [wingbeat_avg_forces(5, :) + wingbeat_std_forces(5, :), wingbeat_avg_forces(5, end:-1:1) - wingbeat_std_forces(5, end:-1:1)];
        p = fill(xconf, yconf, colors(i,:), 'FaceAlpha',alpha,'HandleVisibility','off');  
        p.EdgeColor = 'none';
        plot(frames, wingbeat_avg_forces(5, :), DisplayName=cases(i), Color=colors(i,:));
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
        sgtitle(["Drag for blue wings"]);
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
        plot(frames, wingbeat_rmse_forces(:, 1), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(b)
        hold on
        plot(frames, wingbeat_rmse_forces(:, 2), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_y (transverse)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        axes(c)
        hold on
        plot(frames, wingbeat_rmse_forces(:, 3), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        % Create three subplots to show the moment time histories.
        axes(d)
        hold on
        plot(frames, wingbeat_rmse_forces(:, 4), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_x (roll)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        axes(e)
        hold on
        plot(frames, wingbeat_rmse_forces(:, 5), DisplayName=cases(i), Color=colors(i,:));
        hold off
        title(["M_y (pitch)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        axes(f)
        hold on
        plot(frames, wingbeat_rmse_forces(:, 6), DisplayName=cases(i), Color=colors(i,:));
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
    COP_plot = true;
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
        
        hold on
        COP = wingbeat_avg_forces(:,5) ./ wingbeat_avg_forces(:,3); % M_y / F_z
        plot(frames, COP, DisplayName=cases(i), Color=colors(i,:))
        ylim([-1, 1])
        hold off
    end
    legend();
    end
end