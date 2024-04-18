function plot_spectrum(wind, freq, freq_power, case_name, subtitle)
    x_label = "Frequency (Hz)";
    y_label = "PSD (dB/Hz)";

    [M,I] = max(freq_power);
    dominant_freq = freq(I);

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    semilogx(freq, freq_power(:, 1), 'DisplayName', 'raw');
    title(["F_x (streamwise)", "dominant freq: " + dominant_freq(1)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 2));
    title(["F_y (transverse)", "dominant freq: " + dominant_freq(2)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 3));
    title(["F_z (vertical)", "dominant freq: " + dominant_freq(3)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    semilogx(freq, freq_power(:, 4));
    title(["M_x (roll)", "dominant freq: " + dominant_freq(4)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 5));
    title(["M_y (pitch)", "dominant freq: " + dominant_freq(5)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 6));
    title(["M_z (yaw)", "dominant freq: " + dominant_freq(6)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Label the whole figure.
    sgtitle(["Force Transducer Measurement for " + case_name subtitle]);

    St = getSt(wind, freq);
    [M,I] = max(freq_power);
    dominant_St = St(I);

    x_label = "Strouhal Number";

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 1), 'DisplayName', 'raw');
    title(["F_x (streamwise)", "dominant St: " + dominant_St(1)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 2));
    title(["F_y (transverse)", "dominant St: " + dominant_St(2)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 3));
    title(["F_z (vertical)", "dominant St: " + dominant_St(3)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 4));
    title(["M_x (roll)", "dominant St: " + dominant_St(4)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 5));
    title(["M_y (pitch)", "dominant St: " + dominant_St(5)]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    hold on
    plot(St, freq_power(:, 6));
    title(["M_z (yaw)", "dominant St: " + dominant_St(6)]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Label the whole figure.
    sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
end