function fitAeroData(AoA_sel, wind_speed_sel, avg_forces)
    figure
    hold on
    s = scatter(AoA_sel, avg_forces(1, :), 25, HandleVisibility="off");
    s.MarkerEdgeColor = [0 0.4470 0.7410];
    s.MarkerFaceColor = [0 0.4470 0.7410];
    [w,B,C] = cos_curve_fit(AoA_sel, avg_forces(1,:));
    model = B*cosd(w*AoA_sel) + C;
    y = avg_forces(1, :);
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "y = " + B + "*cos(" + w + "*\alpha) + " + C + "   R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
    legend()
    xlabel("Angle of Attack \alpha")
    ylabel("Drag Coefficient")
    title(["Drag" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    figure
    hold on
    s = scatter(AoA_sel, avg_forces(3, :), 25, HandleVisibility="off");
    s.MarkerEdgeColor = [0 0.4470 0.7410];
    s.MarkerFaceColor = [0 0.4470 0.7410];
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(3, :)';
    b_lift = x\y;
    model = x*b_lift;
    lift_slope = b_lift(2);
    lift_intercept = b_lift(1);
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "y = " + lift_slope + "x + " + lift_intercept + "   R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
    legend()
    xlabel("Angle of Attack \alpha")
    ylabel("Lift Coefficient")
    title(["Lift" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    % sub_title = "Wind Speed: " + wind_speed_sel + " m/s";
    % [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, true, sub_title);
    
    figure
    hold on
    s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
    s.MarkerEdgeColor = [0 0.4470 0.7410];
    s.MarkerFaceColor = [0 0.4470 0.7410];
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = avg_forces(5, :)';
    b_pitch = x\y;
    model = x*b_pitch;
    pitch_slope = b_pitch(2);
    pitch_intercept = b_pitch(1);
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    label = "y = " + pitch_slope + "x + " + pitch_intercept + "   R^2 = " + Rsq;
    plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
    legend()
    xlabel("Angle of Attack \alpha")
    ylabel("Pitch Moment Coefficient")
    title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    figure
    hold on
    plot(AoA_sel, abs(y - model), Color=[0 0.4470 0.7410])
    s = scatter(AoA_sel, abs(y - model), 25);
    s.MarkerEdgeColor = [0 0.4470 0.7410];
    s.MarkerFaceColor = [0 0.4470 0.7410];
    xlabel("Angle of Attack \alpha")
    ylabel("Residual")
    title(["Pitch Moment Residual from Linear Fit" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    % figure
    % hold on
    % s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
    % s.MarkerEdgeColor = [0 0.4470 0.7410];
    % s.MarkerFaceColor = [0 0.4470 0.7410];
    % [off_pitch, w_pitch, B_pitch, C_pitch] = sin_curve_fit(AoA_sel, avg_forces(5, :), 5);
    % model = B_pitch*sind(w_pitch*AoA_sel + off_pitch) + C_pitch;
    % % [w_pitch, B_pitch, C_pitch] = sin_curve_fit(AoA_sel, avg_forces(5, :));
    % % model = B_pitch*sind(w_pitch*AoA_sel) + C_pitch;
    % y = avg_forces(5, :);
    % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    % label = "y = " + B_pitch + "sin(" + w_pitch +"*x + " + off_pitch + ") + " + C_pitch + "   R^2 = " + Rsq;
    % % label = "y = " + B_pitch + "sin(" + w_pitch +"*x) + " + C_pitch + "   R^2 = " + Rsq;
    % plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
    % legend()
    % xlabel("Angle of Attack \alpha")
    % ylabel("Pitch Moment Coefficient")
    % title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])
    % 
    % figure
    % hold on
    % s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
    % s.MarkerEdgeColor = [0 0.4470 0.7410];
    % s.MarkerFaceColor = [0 0.4470 0.7410];
    % p = polyfit(AoA_sel, avg_forces(5, :), 4);
    % y = avg_forces(5, :);
    % model = p(1)*AoA_sel.^4 + p(2)*AoA_sel.^3 + p(3)*AoA_sel.^2 + p(4)*AoA_sel + p(5);
    % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    % label = "   R^2 = " + Rsq;
    % plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
    % legend()
    % xlabel("Angle of Attack \alpha")
    % ylabel("Pitch Moment Coefficient")
    % title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    % SineParams = sineFit(AoA_sel, avg_forces(5, :),true);
    % [offs, amp, freq, phi, MSE]
end