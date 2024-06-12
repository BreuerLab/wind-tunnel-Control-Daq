function plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, nondimensional, forceIndex, regression, shift_bool)
    AoA_sel = selected_vars.AoA;
    wing_freq_sel = selected_vars.freq;
    wind_speed_sel = selected_vars.wind;
    type_sel = selected_vars.type;
    
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

    if (forceIndex == 0)    
        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
            
        for k = 1:6
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        for j = 1:length(wing_freq_sel)
        for m = 1:length(wind_speed_sel)
        for n = 1:length(type_sel)
            
        if (regression)
            s = scatter(AoA_sel, avg_forces(k, :, j, m, n), 20);
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
    
            x = [ones(size(AoA_sel')), AoA_sel'];
            y = avg_forces(k, :, j, m, n)';
            b = x\y;
            model = x*b;
            Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
            % label = names(j,m,n) + ", M_y = " + b(2) + "\alpha + " + b(1) + "   R^2 = " + Rsq;
            label = names(j,m,n) + ", $$\frac{\partial{M}}{\partial\alpha}$$ = " + round(b(2),3);
            p = plot(AoA_sel, model);
            p.DisplayName = label;
            if (length(wing_freq_sel) > length(wind_speed_sel))
                p.Color = colors(j,:,n);
            else
                p.Color = colors(m,:,n);
            end
            p.LineWidth = 2;
        else
            e = errorbar(AoA_sel, avg_forces(k, :, j, m, n), err_forces(k, :, j, m, n),'.');
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
        title(["\textbf{" + titles(k) + "}"], Interpreter='latex');
        xlabel(x_label, Interpreter='latex');
        ylabel(y_labels(k), Interpreter='latex');
        end
        
        hL = legend(names);
        hL.Layout.Tile = 'East';
    
        % Label the whole figure.
        sgtitle(["Force and Moment Means vs. Angle of Attack" sub_title]);
    
    else
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
        title(["\bf{" + titles(forceIndex) + "}" "\bf{" + sub_title + "}"], FontSize=20, FontName='Times New Roman');
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