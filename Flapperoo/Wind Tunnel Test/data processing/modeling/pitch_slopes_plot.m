function pitch_slopes_plot(wing_freq_sel, AoA_sel, wind_speed_sel, type_sel, C_M_vals, data_bool, avg_pitch_moment)
    St_bool = true;
    colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

    pitch_slopes = zeros(1,length(wing_freq_sel));
    pitch_slopes_percent_increase = zeros(1,length(wing_freq_sel) - 1);
    for j = 1:length(wing_freq_sel)
    for m = 1:length(wind_speed_sel)
        pitch_slopes(j) = (C_M_vals(1, j, m) - C_M_vals(end, j, m)) / (AoA_sel(1) - AoA_sel(end));
        if (j > 1)
            pitch_slopes_percent_increase(j-1) = ((pitch_slopes(j) - pitch_slopes(j-1)) / pitch_slopes(j-1))*100;
        end
    end
    end

    if (St_bool)
        St = getSt(wind_speed_sel, wing_freq_sel);
        x_var = St;
        x_label = "Strouhal Number";
    else
        x_var = wing_freq_sel;
        x_label = "Flapping Frequency (Hz)";
    end

    x = [ones(size(x_var))', log(x_var)'];
    % y = log(pitch_slopes / pitch_slopes(1))';
    % norm_pitch_slopes = abs(pitch_slopes - pitch_slopes(1));
    
    % normalization routine equivalent to percent increase (well
    % not entirely percent since not multiplied by 100) since
    % first pitch slope value
    norm_pitch_slopes = (pitch_slopes / pitch_slopes(1)) - 1;
    y = log(norm_pitch_slopes)';
    test_fit = fit(x_var(2:end)', norm_pitch_slopes(2:end)', 'power1')
    x = x(2:end,:);
    y = y(2:end);
    b_pitch_log = x\y;
    model_log = x*b_pitch_log;
    pitch_slope_log = b_pitch_log(2);
    pitch_intercept_log = b_pitch_log(1);
    pitch_power = pitch_slope_log;
    pitch_constant = exp(pitch_intercept_log);
    
    x_var_fine = linspace(min(x_var), max(x_var), 100);
    model_power = pitch_constant * x_var_fine.^pitch_power;
    Rsq_power = 1 - sum((norm_pitch_slopes - interp1(x_var_fine, model_power, x_var)).^2)...
        /sum((norm_pitch_slopes - mean(norm_pitch_slopes)).^2);
    
    if data_bool
        pitch_slopes_data = zeros(1,length(wing_freq_sel));
        for j = 1:length(wing_freq_sel)
        for m = 1:length(wind_speed_sel)
        for n = 1:length(type_sel)
            x_lin = [ones(size(AoA_sel')), AoA_sel'];
            y_lin = avg_pitch_moment(:, j, m, n);
            b_lin = x_lin\y_lin;
            pitch_slopes_data(j) = b_lin(2);
        end
        end
        end
    
        x_data = [ones(size(x_var))', log(x_var)'];
        % y = log(pitch_slopes / pitch_slopes(1))';
        % norm_pitch_slopes_data = abs(pitch_slopes_data - pitch_slopes_data(1));
        norm_pitch_slopes_data = (pitch_slopes_data / pitch_slopes_data(1)) - 1;
        y_data = log(norm_pitch_slopes_data)';
        test_fit_data = fit(x_var(2:end)', norm_pitch_slopes_data(2:end)', 'power1')
        x_data = x_data(2:end,:);
        y_data = y_data(2:end);
        b_pitch_log_data = x_data\y_data;
        model_log_data = x_data*b_pitch_log_data;
        pitch_slope_log_data = b_pitch_log_data(2);
        pitch_intercept_log_data = b_pitch_log_data(1);
        pitch_power_data = pitch_slope_log_data;
        pitch_constant_data = exp(pitch_intercept_log_data);
        
        model_power_data = exp(pitch_intercept_log_data)*x_var_fine.^pitch_slope_log_data;
        Rsq_power_data = 1 - sum((norm_pitch_slopes_data - interp1(x_var_fine, model_power_data, x_var)).^2)...
            /sum((norm_pitch_slopes_data - mean(norm_pitch_slopes_data)).^2);
    end

    figure
    hold on
    plot(x_var, pitch_slopes, Color=colors(1,:))
    s = scatter(x_var, pitch_slopes, 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel(x_label)
    ylabel("Pitch Slope")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

    figure
    hold on
    plot(x_var, pitch_slopes / pitch_slopes(1), Color=colors(1,:))
    s = scatter(x_var, pitch_slopes / pitch_slopes(1), 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel(x_label)
    ylabel("Dimensionless Pitch Slope")
    title(["Dimensionless Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    figure
    hold on
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    plot(x(:,2), model_log,"DisplayName","y = " + pitch_slope_log + "*x + " + pitch_intercept_log)
    s = scatter(x(:,2), y, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Log(" + x_label + ")")
    ylabel("Log(Pitch Slope)")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    legend();

    figure
    hold on
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    p = plot(x_var_fine, model_power);
    p.DisplayName = "\textbf{Model}: $y = " + round(pitch_constant,3,'significant') + "*x^{" +...
        round(pitch_power,3,'significant') + "}$, $R^2 = " + Rsq_power + "$";
    p.Color = colors(1,:);
    % plot(wing_freq_sel, model_power,"DisplayName","y = " + exp(pitch_intercept_log) + "*x^{" + pitch_slope_log + "}, R^2 = " + Rsq_power)
    s = scatter(x_var, norm_pitch_slopes, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel(x_label, FontSize=18, Interpreter='latex')
    ylabel("$$\left(\frac{\partial{M}}{\partial\alpha}\right)^*$$",FontSize=18,Rotation=0,Interpreter='latex')
    title(["\textbf{Pitch Slope Scaling with Flapping Frequency}" "\textbf{Wind Speed: " + wind_speed_sel + " m/s}"], FontSize=20, Interpreter='latex')
    legend(Location='best', FontSize=16, Interpreter='latex');

    if data_bool
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    p = plot(x_var_fine, model_power_data);
    p.DisplayName = "\textbf{Data}: $y = " + round(pitch_constant_data,3,'significant') + "*x^{" +...
        round(pitch_power_data,3,'significant') + "}$, $R^2 = " + Rsq_power_data + "$";
    p.Color = colors(2,:);
    % plot(wing_freq_sel, model_power,"DisplayName","y = " + exp(pitch_intercept_log) + "*x^{" + pitch_slope_log + "}, R^2 = " + Rsq_power)
    s = scatter(x_var, norm_pitch_slopes_data, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(2,:);
    s.MarkerEdgeColor = colors(2,:);

    figure
    hold on
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    plot(x_data(:,2), model_log_data,"DisplayName","y = " + pitch_slope_log_data + "*x + " + pitch_intercept_log_data, Color=colors(2,:))
    s = scatter(x_data(:,2), y_data, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(2,:);
    s.MarkerEdgeColor = colors(2,:);
    xlabel("Log(" + x_label + ")")
    ylabel("Log(Pitch Slope)")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    legend();
    end
    
    % figure
    % hold on
    % plot(wing_freq_sel(2:end), pitch_slopes_percent_increase, Color=colors(1,:))
    % s = scatter(wing_freq_sel(2:end), pitch_slopes_percent_increase, 40, 'filled');
    % s.MarkerFaceColor = colors(1,:);
    % s.MarkerEdgeColor = colors(1,:);
    % xlabel("Flapping Frequency (Hz)")
    % ylabel("Pitch Slope Percent Increase")
    % title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

    figure
    hold on
    plot(x_var.^2, pitch_slopes, Color=colors(1,:))
    s = scatter(x_var.^2, pitch_slopes, 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel(x_label + " Squared")
    ylabel("Pitch Slope")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
end