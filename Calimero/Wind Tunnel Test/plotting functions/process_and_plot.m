function process_and_plot(force, cur_ind, AoA_vals, AoA_ind, tiles, wing_freq_sel, ind)
    wing_freq = wing_freq_sel(cur_ind);
    AoA = AoA_vals(AoA_ind);
    wing_freq_sorted = sort(wing_freq_sel);
    color_ind = find(wing_freq_sorted == wing_freq);
    
    % Rotate the data from the force sensor reference frame to the wind
    % tunnel reference frame (body frame to global frame)
    results_lab = coordinate_transformation(force, AoA);

    avg_force = mean(results_lab,2);

    %% Plotting
    % colors = ["#67001f"; "#b2182b"; "#d6604d";...
    %           "#4393c3"; "#2166ac"; "#053061";]; % red to blue ish colormap
    colors = ["#4393c3"; "#fdd49e"; "#fc8d59";...
            "#d7301f"; "#7f0000"; "#000000"]; % blue to shades of red to black
    % if (length(wing_freq_sel) <= 8)
    % colors = ["#fee8c8"; "#fdd49e"; "#fdbb84"; "#fc8d59"; "#ef6548";...
    %         "#d7301f"; "#b30000"; "#7f0000"];
    % else
    % colors = ["#67001f"; "#b2182b"; "#d6604d"; "#f4a582"; "#fddbc7";...
    %         "#d1e5f0"; "#92c5de"; "#4393c3"; "#2166ac"; "#053061";];
    % end
    % colors = ["#0D9C27"; "#4DDB1A"; "#BEE65C"; "#ECE0A1"; "#6E0D9C"; ...
    %     "#471ADB"; "#5C7AE6"; "#A1D3EC"; "#9C0D3A"; "#DB1AAE"; "#C85CE6"; "#BAA1EC"];

    % Create a subplot for each force/moment axis
    for k = 1:6
    axes(tiles{k})

    hold on    
    s = scatter(AoA, avg_force(k), 25, "filled");
    s.MarkerFaceColor = colors(color_ind);
    s.MarkerEdgeColor = colors(color_ind);

    if (AoA_ind == 1)
        s.DisplayName = wing_freq + " Hz";
    else
        s.HandleVisibility = "off";
    end
    
    hold off
    end
end