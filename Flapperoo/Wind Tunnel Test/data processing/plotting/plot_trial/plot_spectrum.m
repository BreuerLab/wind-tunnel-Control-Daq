function plot_spectrum(wind_speed, data, frame_rate, case_title, subtitle, plot_St)

    [freq, freq_power, num_windows, f_min] = freq_spectrum(data, frame_rate);

    x_label = "Frequency (Hz)";
    y_label = "PSD (dB/Hz)";

    for i = 1:6
        [pks,locs] = findpeaks(freq_power(:,i), freq,'SortStr','descend');

        dominant_freqs(i, :) = locs(1:3);
    end

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    semilogx(freq, freq_power(:, 1));
    title(["F_x (streamwise)", "Dominant Frequencies: ", dominant_freqs(1,1) + " Hz, "...
        + dominant_freqs(1,2) + " Hz, " + dominant_freqs(1,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 2));
    title(["F_y (transverse)", "Dominant Frequencies: ", dominant_freqs(2,1) + " Hz, "...
        + dominant_freqs(2,2) + " Hz, " + dominant_freqs(2,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 3));
    title(["F_z (vertical)", "Dominant Frequencies: ", dominant_freqs(3,1) + " Hz, "...
        + dominant_freqs(3,2) + " Hz, " + dominant_freqs(3,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    semilogx(freq, freq_power(:, 4));
    title(["M_x (roll)", "Dominant Frequencies: ", dominant_freqs(4,1) + " Hz, "...
        + dominant_freqs(4,2) + " Hz, " + dominant_freqs(4,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 5));
    title(["M_y (pitch)", "Dominant Frequencies: ", dominant_freqs(5,1) + " Hz, "...
        + dominant_freqs(5,2) + " Hz, " + dominant_freqs(5,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    nexttile(tcl)
    semilogx(freq, freq_power(:, 6));
    title(["M_z (yaw)", "Dominant Frequencies: ", dominant_freqs(6,1) + " Hz, "...
        + dominant_freqs(6,2) + " Hz, " + dominant_freqs(6,3) + " Hz, "]);
    xlabel(x_label);
    ylabel(y_label);
    
    % Label the whole figure.
    sgtitle(["Power Spectrum" case_title "{\fontsize{10}" + subtitle + "}"]);

    if (plot_St)
        St = getSt(wind_speed, freq);

        dominant_Sts = getSt(wind_speed, dominant_freqs);
    
        x_label = "Strouhal Number";
    
        % Open a new figure.
        fig = figure;
        fig.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        semilogx(St, freq_power(:, 1));
        title(["F_x (streamwise)", "Dominant Strouhal Numbers: ", dominant_Sts(1,1) + ", "...
        + dominant_Sts(1,2) + ", " + dominant_Sts(1,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        nexttile(tcl)
        semilogx(St, freq_power(:, 2));
        title(["F_y (transverse)", "Dominant Strouhal Numbers: ", dominant_Sts(2,1) + ", "...
        + dominant_Sts(2,2) + ", " + dominant_Sts(2,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        nexttile(tcl)
        semilogx(St, freq_power(:, 3));
        title(["F_z (vertical)", "Dominant Strouhal Numbers: ", dominant_Sts(3,1) + ", "...
        + dominant_Sts(3,2) + ", " + dominant_Sts(3,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        semilogx(St, freq_power(:, 4));
        title(["M_x (roll)", "Dominant Strouhal Numbers: ", dominant_Sts(4,1) + ", "...
        + dominant_Sts(4,2) + ", " + dominant_Sts(4,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        nexttile(tcl)
        semilogx(St, freq_power(:, 5));
        title(["M_y (pitch)", "Dominant Strouhal Numbers: ", dominant_Sts(5,1) + ", "...
        + dominant_Sts(5,2) + ", " + dominant_Sts(5,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        nexttile(tcl)
        semilogx(St, freq_power(:, 6));
        title(["M_z (yaw)", "Dominant Strouhal Numbers: ", dominant_Sts(6,1) + ", "...
        + dominant_Sts(6,2) + ", " + dominant_Sts(6,3) + ", "]);
        xlabel(x_label);
        ylabel(y_label);
        
        % Label the whole figure.
        sgtitle(["Power Spectrum" case_title "{\fontsize{10}" + subtitle + "}"]);
    end
end