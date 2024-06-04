function pitch_slopes_plot(wing_freq_vals, AoA_sel, wind_speed_sel, C_M_vals)
    colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250]];

    pitch_slopes = zeros(1,length(wing_freq_vals));
    pitch_slopes_percent_increase = zeros(1,length(wing_freq_vals) - 1);
    for m = 1:length(wing_freq_vals)
        pitch_slopes(m) = (C_M_vals(m,1) - C_M_vals(m,end)) / (AoA_sel(1) - AoA_sel(end));
        if (m > 1)
            pitch_slopes_percent_increase(m-1) = ((pitch_slopes(m) - pitch_slopes(m-1)) / pitch_slopes(m-1))*100;
        end
    end
    
    x = [ones(size(wing_freq_vals))', log(wing_freq_vals)'];
    y = log(abs(pitch_slopes - pitch_slopes(1)))';
    x = x(2:end,:);
    y = y(2:end);
    b_pitch_log = x\y;
    model_log = x*b_pitch_log;
    pitch_slope_log = b_pitch_log(2);
    pitch_intercept_log = b_pitch_log(1);
    
    model_power = exp(pitch_intercept_log)*wing_freq_vals.^pitch_slope_log;
    y_power = abs(pitch_slopes - pitch_slopes(1));
    Rsq_power = 1 - sum((y_power - model_power).^2)/sum((y_power - mean(y_power)).^2);
    
    figure
    hold on
    plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    s = scatter(wing_freq_vals, pitch_slopes, 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Flapping Frequency (Hz)")
    ylabel("Pitch Slope")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    
    figure
    hold on
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    plot(x(:,2), model_log,"DisplayName","y = " + pitch_slope_log + "*x + " + pitch_intercept_log)
    s = scatter(x(:,2), y, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Log(Flapping Frequency)")
    ylabel("Log(Pitch Slope)")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    legend();
    
    figure
    hold on
    % plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
    plot(wing_freq_vals, model_power,"DisplayName","y = " + exp(pitch_intercept_log) + "*x^{" + pitch_slope_log + "}, R^2 = " + Rsq_power)
    s = scatter(wing_freq_vals, y_power, 40, 'filled');
    s.HandleVisibility = "off";
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Flapping Frequency (Hz)")
    ylabel("Pitch Slope")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
    legend();
    
    figure
    hold on
    plot(wing_freq_vals(2:end), pitch_slopes_percent_increase, Color=colors(1,:))
    s = scatter(wing_freq_vals(2:end), pitch_slopes_percent_increase, 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Flapping Frequency (Hz)")
    ylabel("Pitch Slope Percent Increase")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

    figure
    hold on
    plot(wing_freq_vals.^2, pitch_slopes, Color=colors(1,:))
    s = scatter(wing_freq_vals.^2, pitch_slopes, 40, 'filled');
    s.MarkerFaceColor = colors(1,:);
    s.MarkerEdgeColor = colors(1,:);
    xlabel("Flapping Frequency Squared (Hz)")
    ylabel("Pitch Slope")
    title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
end