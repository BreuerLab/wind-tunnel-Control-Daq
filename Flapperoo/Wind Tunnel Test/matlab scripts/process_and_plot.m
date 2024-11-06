function process_and_plot(data, cur_ind, AoA, tiles, wing_freq_sel)
    wing_freq = wing_freq_sel(cur_ind);

    raw_data = data(:,1:7);
    raw_trigger = data(:,8);
    
    % Trim off portion of data where wings are motionless or accelerating
    trimmed_results = trim_data(raw_data, raw_trigger, wing_freq);
    time_data = trimmed_results(:,1)';
    time_data = time_data - time_data(1);
    force_data = trimmed_results(:,2:7)';
    
    % Rotate the data from the force transducer reference frame to the wind
    % tunnel reference frame (body frame to global frame)
    results_lab = coordinate_transformation(force_data, AoA);

    avg_force = mean(results_lab,2);

    %% Plotting
    colors = ["#0D9C27"; "#4DDB1A"; "#BEE65C"; "#ECE0A1"; "#6E0D9C"; ...
        "#471ADB"; "#5C7AE6"; "#A1D3EC"; "#9C0D3A"; "#DB1AAE"; "#C85CE6"; "#BAA1EC"];
    
    % Create a subplot for each force/moment axis
    for k = 1:6
    axes(tiles{k})

    hold on
    
    s = scatter(AoA, avg_force(k), 25, "filled");
    s.MarkerFaceColor = colors(cur_ind);
    s.MarkerEdgeColor = colors(cur_ind);

    if (AoA == -16)
        s.DisplayName = wing_freq + " Hz";
    else
        s.HandleVisibility = "off";
    end
    
    hold off
    end
end