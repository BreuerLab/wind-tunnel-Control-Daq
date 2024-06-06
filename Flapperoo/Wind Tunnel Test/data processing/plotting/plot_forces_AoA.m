function plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, nondimensional, forceIndex, regression, shift_bool)
    AoA_sel = selected_vars.AoA;
    wing_freq_sel = selected_vars.freq;
    wind_speed_sel = selected_vars.wind;
    type_sel = selected_vars.type;
    
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
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(1, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 1)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(1, :, j, m, n), err_forces(1, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
    end
    end
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(2, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 2)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(2, :, j, m, n), err_forces(2, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
    end
    end
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(3, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 3)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(3, :, j, m, n), err_forces(3, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
    end
    end
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(4, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 4)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(4, :, j, m, n), err_forces(4, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
    end
    end
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(5, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 5)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(5, :, j, m, n), err_forces(5, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
    end
    end
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    
    nexttile(tcl)
    hold on
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
    for n = 1:length(type_sel)
        
    if (regression)
        s = scatter(AoA_sel, avg_forces(6, :, j, m, n), 25, HandleVisibility="off");
        s.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = avg_forces(:, j, 6)';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        label = "R^2 = " + Rsq;
        plot(AoA_sel, model, DisplayName=label, Color=colors(j,:))
    else
        e = errorbar(AoA_sel, avg_forces(6, :, j, m, n), err_forces(6, :, j, m, n),'.');
        e.Color = colors(n + (m-1)*length(type_sel) + (j-1)*length(wind_speed_sel)*length(type_sel),:);
        e.MarkerSize = 20;
    end
    
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
            y_label_F = "Cycle Average Force Coefficient";
            y_label_M = "Cycle Average Moment Coefficient";
        else
            y_label_F = "Cycle Average Force (N)";
            y_label_M = "Cycle Average Moment (N*m)";
        end
        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];

        if (shift_bool)
        titles = ["Drag", "Transverse Lift", "Lift", "Roll Moment", "Pitch Moment about LE", "Yaw Moment"];
        else
        titles = ["Drag", "Transverse Lift", "Lift", "Roll Moment", "Pitch Moment", "Yaw Moment"];
        end
        
        if (length(wing_freq_sel) == 5 || length(wind_speed_sel) == 5)
            colors(:,:,1) = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
            colors(:,:,2) = ["#fdd49e"; "#fdbb84"; "#fc8d59"; "#e34a33"; "#b30000"];
        elseif (length(wing_freq_sel) == 4 || length(wind_speed_sel) == 4)
            colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#43a2ca"; "#0868ac"];
            colors(:,:,2) = ["#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
        elseif (length(wing_freq_sel) == 3 || length(wind_speed_sel) == 3)
            colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#2b8cbe"];
            colors(:,:,2) = ["#fdcc8a"; "#fc8d59"; "#d7301f"];
        elseif (length(wing_freq_sel) == 2 || length(wind_speed_sel) == 2)
            colors(:,:,1) = ["#a8ddb5"; "#43a2ca"];
            colors(:,:,2) = ["#fdbb84"; "#e34a33"];
        elseif (length(wing_freq_sel) == 1 || length(wind_speed_sel) == 1)
            colors(:,:,1) = ["#43a2ca"];
            colors(:,:,2) = ["#e34a33"];
        end
        markers = ["o", "pentagram", "x"];

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        
        hold on
        for n = 1:length(type_sel)
        for j = 1:length(wing_freq_sel)
        for m = 1:length(wind_speed_sel)

        if (regression)
            s = scatter(AoA_sel, avg_forces(forceIndex, :, j, m, n), 25);
            s.HandleVisibility = "off";
            if (length(wing_freq_sel) > length(wind_speed_sel))
                s.MarkerEdgeColor = colors(j,:,n);
                s.MarkerFaceColor = colors(j,:,n);
                s.Marker = markers(m);
            else
                s.MarkerEdgeColor = colors(m,:,n);
                s.MarkerFaceColor = colors(m,:,n);
                s.Marker = markers(j);
            end
    
            reg_AoA_sel = -8:1:8;
            x = [ones(size(reg_AoA_sel')), reg_AoA_sel'];
            y = avg_forces(forceIndex, AoA_sel <= max(reg_AoA_sel) & AoA_sel >= min(reg_AoA_sel), j, m, n)';
            b = x\y;
            model = x*b;
            Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
            % label = names(j,m,n) + ", M_y = " + b(2) + "\alpha + " + b(1) + "   R^2 = " + Rsq;
            label = names(j,m,n) + ", $$\frac{\partial{M}}{\partial\alpha}$$ = " + round(b(2),3);
            p = plot(reg_AoA_sel, model);
            p.DisplayName = label;
            if (length(wing_freq_sel) > length(wind_speed_sel))
                p.Color = colors(j,:,n);
            else
                p.Color = colors(m,:,n);
            end
            p.LineWidth = 2;
        else
            e = errorbar(AoA_sel, avg_forces(forceIndex, :, j, m, n), err_forces(forceIndex, :, j, m, n),'.');
            e.MarkerSize = 10;
            if (length(wing_freq_sel) > length(wind_speed_sel))
                e.Color = colors(j,:,n);
                e.MarkerFaceColor = colors(j,:,n);
                e.Marker = markers(m);
            else
                e.Color = colors(m,:,n);
                e.MarkerFaceColor = colors(m,:,n);
                e.Marker = markers(j);
            end
            e.DisplayName = names(j,m,n);
        end

        end
        end
        end
        hold off
        % colors can't be changed in latex interpreter
        % title(["\bf{" + titles(forceIndex) + "}" "\bf{" + sub_title + "}"], FontSize=20,Interpreter='latex');
        title(["\bf{" + titles(forceIndex) + "}" "\bf{" + sub_title + "}"], FontSize=20,FontName='Times New Roman');
        xlabel(x_label, FontSize=18,Interpreter='latex');
        ylabel(y_labels(forceIndex), FontSize=18,Interpreter='latex');
        [~,hobj] = legend(Location="best", FontSize=18, Interpreter='latex');
        if (regression)
            hl = findobj(hobj,'type','line');
            set(hl,'LineWidth',4);

            hobj = findobj(gcf, 'Type', 'Legend');
            HeightScaleFactor = 1.3;
            NewHeight = hobj.Position(4) * HeightScaleFactor;
            hobj.Position(4) = NewHeight;
        end
    end
end