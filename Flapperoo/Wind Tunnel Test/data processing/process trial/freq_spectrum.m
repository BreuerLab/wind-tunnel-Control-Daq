function dominant_freq = freq_spectrum(results, frame_rate, case_name, plots_bool)
    [pxx, f] = pwelch(results, frame_rate*2, 50, frame_rate*2, frame_rate);
    power = 10*log10(pxx);
    x_label = "Frequency (Hz)";
    y_label = "PSD (dB/Hz)";
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Power Spectrum";

    % drop higher frequency data where not much is going on anyways
    f = f(1:500);
    power = power(1:500, :);

    [M,I] = max(power);
    dominant_freq = f(I);

    if (plots_bool)

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(f, power(:, 1), 'DisplayName', 'raw');
    title(["F_x (streamwise)", "dominant freq: " + dominant_freq(1)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(f, power(:, 2));
    title(["F_y (transverse)", "dominant freq: " + dominant_freq(2)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(f, power(:, 3));
    title(["F_z (vertical)", "dominant freq: " + dominant_freq(3)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(f, power(:, 4));
    title(["M_x (roll)", "dominant freq: " + dominant_freq(4)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(f, power(:, 5));
    title(["M_y (pitch)", "dominant freq: " + dominant_freq(5)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(f, power(:, 6));
    title(["M_z (yaw)", "dominant freq: " + dominant_freq(6)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Label the whole figure.
    sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    end
end