function plot_spectrum(freq, freq_power, dominant_freq, case_name, subtitle)
    x_label = "Frequency (Hz)";
    y_label = "PSD (dB/Hz)";

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 1), 'DisplayName', 'raw');
    title(["F_x (streamwise)", "dominant freq: " + dominant_freq(1)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 2));
    title(["F_y (transverse)", "dominant freq: " + dominant_freq(2)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 3));
    title(["F_z (vertical)", "dominant freq: " + dominant_freq(3)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 4));
    title(["M_x (roll)", "dominant freq: " + dominant_freq(4)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 5));
    title(["M_y (pitch)", "dominant freq: " + dominant_freq(5)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(freq, freq_power(:, 6));
    title(["M_z (yaw)", "dominant freq: " + dominant_freq(6)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Label the whole figure.
    sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
end