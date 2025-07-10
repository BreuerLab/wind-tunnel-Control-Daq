%% Input data
    data = results;
    angle_per_turn = 360; 
    % Extract useful columns
    position_vals = data(:, end-1);    % Motor angle (ticks or degrees)
    force_Z = data(:, 4);              % Force in z-direction
    Z_vals = data(:, end);             % wingtip position
    raw_times = data(:, 1);            % Time (not used here)
    force_X = data(:,2);


    % Find the first index where the position is no longer zero
    % start_idx = find(position_vals ~= 0, 1, 'first');
    
    % Find the first index where the variation from the first value exceeds
    % angle_threshold
    angle_threshold = 15;  % threshold (in deg)
    initial_angle = position_vals(1);
    delta_from_start = abs(position_vals - initial_angle);
    
    start_idx = find(delta_from_start > angle_threshold, 1, 'first');
    raw_times(start_idx)

    % Truncate all data from there
    position_vals = position_vals(start_idx:end);
    force_Z = force_Z(start_idx:end);
    force_X = force_X(start_idx:end);
    Z_vals = Z_vals(start_idx:end);
    raw_times = raw_times(start_idx:end);


    % Filtering raw data from z-force
    frame_rate = 10000;  % Hz
    fc = 100;
    fc2 = 50;            % cutoff frequency
    size(force_Z);

    fs = frame_rate;
    [b,a] = butter(6, fc/(fs/2));
    [b1,a1] = butter(6, fc2/(fs/2));
    force_Z_filtered = filtfilt(b, a, force_Z);  % direct processing on 1D vector
    force_X_filtered = filtfilt(b1, a1, force_X);

    % Convert ticks to degrees if necessary (adapt according to encoder)
    % position_deg = position_vals * (360 / 1024);  % if 1024 tick encoder
    position_deg = mod(position_vals, angle_per_turn);         % if already in degrees or ticks rescaled

    % Angular sampling parameters
    angle_bins = 0:1:floor(angle_per_turn)-1;

    Z_binned = nan(length(angle_bins), 1);
    Fz_binned = nan(length(angle_bins), 1);
    Fx_binned = nan(length(angle_bins), 1);
    Fz_binned_filtered = nan(length(angle_bins), 1);
    Fx_binned_filtered = nan(length(angle_bins), 1);

    % Storing values ​​by angle
    Z_per_angle = cell(length(angle_bins), 1);
    Fz_per_angle = cell(length(angle_bins), 1);
    Fx_per_angle = cell(length(angle_bins), 1);
    Fz_per_angle_filtered = cell(length(angle_bins), 1);
    Fx_per_angle_filtered = cell(length(angle_bins), 1);

    % Distribution of values ​​by angle bin
    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(Z_per_angle));
        Z_per_angle{idx}(end+1) = Z_vals(i);
        Fz_per_angle{idx}(end+1) = force_Z(i);
        Fz_per_angle_filtered{idx}(end+1) = force_Z_filtered(i);
        Fx_per_angle{idx}(end+1) = force_X(i);
        Fx_per_angle_filtered{idx}(end+1) = force_X_filtered(i);
    end

    % Averages per angle
    for k = 1:length(angle_bins)
        if ~isempty(Z_per_angle{k})
            Z_binned(k) = mean(Z_per_angle{k});
        end
        if ~isempty(Fz_per_angle{k})
            Fz_binned(k) = mean(Fz_per_angle{k});
        end
        if ~isempty(Fz_per_angle_filtered{k})
            Fz_binned_filtered(k) = mean(Fz_per_angle_filtered{k});
        end
        if ~isempty(Fx_per_angle{k})
            Fx_binned(k) = mean(Fx_per_angle{k});
        end
        if ~isempty(Fx_per_angle_filtered{k})
            Fx_binned_filtered(k) = mean(Fx_per_angle_filtered{k});
        end
    end

    % --- Filtering the Z position before derivation
    fc_pos = 100;  % cutoff frequency for position
    [bZ, aZ] = butter(4, fc_pos / (frame_rate / 2));
    Z_vals_filtered = filtfilt(bZ, aZ, Z_vals);

    % --- Time conversion
    times_s = raw_times / 1000;  % conversion ms -> s

    % --- Calculation of speed (dZ/dt)
    dt_v = diff(times_s);  % N-1
    Z_vals_vitesse = [0; diff(Z_vals_filtered) ./ dt_v];


    % --- Calculation of acceleration (d²Z/dt²)
    dt_a = diff(times_s(1:end));  % size N-2
    dV = diff(Z_vals_vitesse);  % size N-2
    size(dt_a);
    size(dV);
    Z_vals_accel = [0; dV ./ dt_a; 0];  % size N

    % --- Distribution of values ​​by angle bin
    VZ_per_angle = cell(length(angle_bins), 1);
    AZ_per_angle = cell(length(angle_bins), 1);
    VZ_binned = nan(length(angle_bins), 1);
    AZ_binned = nan(length(angle_bins), 1);

    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(VZ_per_angle));
        VZ_per_angle{idx}(end+1) = Z_vals_vitesse(i);
        AZ_per_angle{idx}(end+1) = Z_vals_accel(i);
    end

    for k = 1:length(angle_bins)
        if ~isempty(VZ_per_angle{k})
            VZ_binned(k) = mean(VZ_per_angle{k});
        end
        if ~isempty(AZ_per_angle{k})
            AZ_binned(k) = mean(AZ_per_angle{k});
        end
    end


    % Recover voltage and current
    voltage = data(start_idx:end, 8);        % in V
    courant_mA = data(start_idx:end, 9);     % in mA
    current = courant_mA / 1000;             % conversion to A

    power = voltage .* current;          % in W

    % Recover angle
    P_per_angle = cell(length(angle_bins), 1);
    P_binned = nan(length(angle_bins), 1);

    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(P_per_angle));
        P_per_angle{idx}(end+1) = power(i);
    end

    for k = 1:length(angle_bins)
        if ~isempty(P_per_angle{k})
            P_binned(k) = mean(P_per_angle{k});
        end
    end

    f = figure('Name', 'Force et Position Z - Repliée sur 1 période');

    tiledlayout(2,2);

    %% --- Plot 1: Z (wingtip position) with superimposed force
    nexttile;

    ax1 = gca;

    % Left Y axis: acceleration (negative)
    yyaxis(ax1, 'left');
    hold on;
    plot(angle_bins, -AZ_binned, '-', 'LineWidth', 1.5, 'Color', [0.4 0 0.8]); % negative acceleration
    ylabel('Accélération Z (mm/s²)');
    ylim([-6e11 6e11]);
    hold off;

    % Right Y axis: forces
    yyaxis(ax1, 'right');
    hold on;
    %%plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    plot(angle_bins, Fz_binned_filtered, 'k-', 'LineWidth', 1);
    plot(angle_bins, Fx_binned_filtered, 'g-', 'LineWidth', 1);
    ylabel('Force Z (N)');
    ylim([-0.5 0.5]); % scale adapted to the forces
    hold off;

    title('Z Acceleration and Z Force');
    xlabel('Motor Angle (°)');
    legend('accel', 'force Z', 'forceX');
    grid on;


    %% --- Trace 2: Z force with scatter
    nexttile;
    hold on;
    for k = 1:length(angle_bins)
        scatter(repmat(angle_bins(k), length(Fz_per_angle{k}), 1), Fz_per_angle{k}, 5, [1 0.7 0.7], 'filled');
    end
    plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    title('Force along Z (full cloud)');
    xlabel('Angle moteur (°)');
    ylabel('Force Z (N)');
    grid on;
    hold off;

    %% --- Plot 3: Position, velocity, Z acceleration
    nexttile;

    % Plot with two Y axes
    yyaxis left
    hold on;
    plot(angle_bins, Z_binned, 'b-', 'LineWidth', 1.5);     % Position
    ylabel('Z / dZ (mm et mm/s)');
    ylim padded

    yyaxis right
    plot(angle_bins, AZ_binned, 'm-', 'LineWidth', 1.2);     % Accélération
    ylabel('Accélération Z (mm/s²)');
    ylim padded
    yline(0, '--k');  % zero line to center well

    title('Position, Speed ​​and Acceleration Z (folded over 1 period)');
    xlabel('Angle moteur (°)');
    legend('Position Z', 'Accélération Z', 'Location', 'best');
    grid on;
    hold off;

    %% --- Graph 4: Electrical power (Voltage x Current)

    nexttile;
    hold on;
    for k = 1:length(angle_bins)
        scatter(repmat(angle_bins(k), length(P_per_angle{k}), 1), P_per_angle{k}, 5, [0.8 1 0.8], 'filled');
    end
    plot(angle_bins, P_binned, 'g-', 'LineWidth', 2);
    title('Puissance électrique (V × I)');
    xlabel('Angle moteur (°)');
    ylabel('Puissance (W)');
    grid on;
    hold off;

    %% === Save ===
    saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee.fig");


    %% --- Force Z plot by frequency range (multi-curve)

    % Paramètres
    step_duration = 5;            % Duration of a frequency step (s)
    freq_start = 60;               % Hz
    freq_step = 10;

    angle_per_turn = 360;         % <-- Adjustable value if you don't have exactly 360° per turn
    angle_bins = 0:1:floor(angle_per_turn)-1;
    % Préparation
    cmap = jet(20);                 % color palette
    all_Fz_binned = [];
    freqs = [];

    % Detection of passages close to 0° (synchronization by revolution)
    zero_cross_idx = find(mod(position_vals, angle_per_turn) < 2 | ...
                          mod(position_vals, angle_per_turn) > angle_per_turn - 2);
    zero_cross_idx = zero_cross_idx(diff([0; zero_cross_idx]) > 20);  % avoid duplicates that are too close

    % Loop on synchronized segments
    i = 1; % index in zero_cross_idx
    n = 1; % frequency counter
    while i < length(zero_cross_idx) - 1
        t_start = raw_times(zero_cross_idx(i));
        t_end = t_start;

        % Stack full rounds until step_duration is reached
        j = i + 1;
        while j <= length(zero_cross_idx)
            t_next = raw_times(zero_cross_idx(j));
            if t_next - t_start >= step_duration
                break;
            end
            t_end = t_next;
            j = j + 1;
        end

        % Indices of this segment
        idx_segment = find(raw_times >= t_start & raw_times < t_end);
        if isempty(idx_segment)
            i = j;
            continue;
        end

        % Extract the data
        pos_deg_part = mod(position_vals(idx_segment), angle_per_turn);
        force_Z_part = force_Z_filtered(idx_segment);
        freqs(n) = freq_start + (n-1)*freq_step;

        % Binning by angle
        Fz_bins_part = nan(length(angle_bins), 1);
        Fz_angle_part = cell(length(angle_bins), 1);
        for k = 1:length(pos_deg_part)
            idx_bin = floor(pos_deg_part(k));  % from 0 to 359
            if idx_bin >= 0 && idx_bin < angle_per_turn
                idx_cell = min(idx_bin + 1, length(Fz_angle_part));
                Fz_angle_part{idx_cell}(end+1) = force_Z_part(k);
            end
        end

        for k = 1:length(angle_bins)
            if ~isempty(Fz_angle_part{k})
                Fz_bins_part(k) = mean(Fz_angle_part{k});
            end
        end

        all_Fz_binned(n, :) = Fz_bins_part';
        n = n + 1;
        i = j;  % Advance to the next sync
    end

    figure('Name', 'Z force per angle for each frequency');
    hold on;
    for n = 1:length(freqs)
        plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
             'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 2);
    end
    xlabel('Angle moteur (°)');
    ylabel('Force Z filtrée (N)');
    title('Z force per beat frequency (synchronized revolutions)');
    legend show;
    grid on;

    % --- BODE dB (Amplitude vs fréquence)
    amplitudes = max(all_Fz_binned, [], 2) - min(all_Fz_binned, [], 2);
    amplitudes_dB = 20 * log10(amplitudes);

    % New figure with subplots
    figure('Name', 'Analyse en fréquence - Force Z');

    % Subplot 1 : angular curves
    subplot(2,1,1);
    hold on;
    for n = 1:length(freqs)
        plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
             'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 1.5);
    end
    xlabel('Angle moteur (°)');
    ylabel('Force Z (N)');
    title('Force Z filtrée par angle et fréquence');
    legend show;
    grid on;

    % Subplot 2 : Bode en amplitude (dB)
    subplot(2,1,2);
    plot(freqs, amplitudes_dB, '-o', 'LineWidth', 2, 'Color', 'k');
    xlabel('Fréquence (Hz)');
    ylabel('Amplitude (dB)');
    title('Diagramme de Bode - amplitude de Force Z');
    grid on;



    %% === Sauvegarde ===
    saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee_multi_freq_membrane.fig");