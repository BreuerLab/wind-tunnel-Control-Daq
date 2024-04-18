% Author: Ronan Gissler
% Last updated: October 2023

addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

clear
% close all
% posF = figure;
% hold on
% momF = figure;
% hold on

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
wing_freq_sel = [0,2,3,4,5];
wind_speed_sel = [4];
type_sel = ["blue wings with tail"];
AoA_sel = -10:1:10;
% AoA_sel = -2:2:2;

wind_speeds = [0,2,4,6];

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% select_type_UI(processed_data_path)

subtraction_string = "no wings with tail";
% subtraction_string = "no wings with tail 0m.s. 0Hz";
slopes_plot = true;
NP_plot = false;
COP_plot = false;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;

NP_pos_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));
NP_mom_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));
St_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));

map = [[189, 215, 231]; [107, 174, 214]; [49, 130, 189]; [8, 81, 156]];
map = map / 255;
xquery = linspace(0,1,128);
numColors = size(map);
numColors = numColors(1);
map = interp1(linspace(0,1,numColors), map, xquery,'pchip');

if (slopes_plot || COP_plot)
    close all
    f = figure;
    f.Position = [562 329 800 500];
    cmap = colormap(map);
    zmap = linspace(0, 0.5, length(cmap));
    hold on
end

for n = 1:length(type_sel)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    selected_vars.freq = wing_freq_sel(j);
    selected_vars.wind = wind_speed_sel(m);
    selected_vars.type = type_sel(n);
    St = getSt(selected_vars.wind, selected_vars.freq);
    St_vals(wing_freq_sel == selected_vars.freq, wind_speed_sel == selected_vars.wind)...
        = St;

    [avg_forces, err_forces, names, sub_title, norm_factors] = ...
        get_data_AoA(selected_vars, processed_data_path, false, subtraction_string);

    % For NP_plot
    [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, false);
    [NP_pos_LE, NP_pos_chord] = posToChord(NP_pos);
    NP_pos_vals(wing_freq_sel == selected_vars.freq, wind_speed_sel == selected_vars.wind)...
        = NP_pos_chord;
    norm_M_factor = mean(norm_factors(2,:,1,1));
    NP_mom_vals(wing_freq_sel == selected_vars.freq, wind_speed_sel == selected_vars.wind)...
        = NP_mom / norm_M_factor;

    if (slopes_plot)
        [distance_vals_chord, slopes] = findCOMrange(avg_forces, AoA_sel, false);
        static_margin = NP_pos_chord - distance_vals_chord;
        norm_M_factor = mean(norm_factors(2,:,1,1));
        slopes = slopes / norm_M_factor;
        % line = plot(distance_vals_chord, slopes);
        line = plot(static_margin, slopes);
        line.Color = interp1(zmap, cmap, St);
        line.LineWidth = 2;
    elseif (COP_plot)
        shift_distance = 0;
        [shifted_avg_forces, COP] = shiftPitchMom(avg_forces, AoA_sel, shift_distance);

% markers(find(wind_speeds == wind_speed_sel))

        dot_color = interp1(zmap, cmap, St);
        markers = ["^","o","diamond","square"];
        scatter(AoA_sel(AoA_sel > 2 | AoA_sel < -2), COP(AoA_sel > 2 | AoA_sel < -2), 40, dot_color,'filled');
        % plot(AoA_sel, COP)
        % plot(AoA_sel, 25*ones(1,length(AoA_sel)), 'k--')
    end

end
end
end

if (slopes_plot)
    caxis([0, 0.5])
    cb = colorbar();
    ylabel(cb,'Strouhal Number','FontSize',16,'Rotation',270)
    % xlabel("COM Position (% chord)",'FontSize',16)
    xlabel("Static Margin (% chord)",'FontSize',16)
    ylabel("dM/d\alpha Slope",'FontSize',16)
    title("Stability Picture",'FontSize',18)
elseif (COP_plot)
    caxis([0, 0.5])
    cb = colorbar();
    ylabel(cb,'Strouhal Number','FontSize',16,'Rotation',270)
    xlabel("Angle of Attack (deg)")
    ylabel("Center of Pressure Location (% Chord)")
    % title(type_sel + " " + wind_speed_sel + " m/s " + wing_freq_sel + " Hz")
end

if (NP_plot)
    colors = [[189,215,231]; [107,174,214]; [49,130,189]; [8,81,156]];
    colors = colors / 255;

    set(0,'CurrentFigure',posF)  
    s = scatter(St_vals, NP_pos_vals, 100, 'filled');
    s.MarkerFaceColor = colors(wind_speeds == wind_speed_sel,:);
    s.MarkerEdgeColor = colors(wind_speeds == wind_speed_sel,:);
    s.DisplayName = int2str(wind_speed_sel) + " m/s";
    xlabel("Strouhal Number")
    ylabel("Neutral Position (% Chord)")
    legend()

    set(0,'CurrentFigure',momF)
    s = scatter(St_vals, NP_mom_vals, 100, 'filled');
    s.MarkerFaceColor = colors(wind_speeds == wind_speed_sel,:);
    s.MarkerEdgeColor = colors(wind_speeds == wind_speed_sel,:);
    s.DisplayName = int2str(wind_speed_sel) + " m/s";
    xlabel("Strouhal Number")
    ylabel("Pitching Moment Coefficient at Neutral Position")
    legend()
end