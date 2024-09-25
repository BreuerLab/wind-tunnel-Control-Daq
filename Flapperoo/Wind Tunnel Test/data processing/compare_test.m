% Author: Ronan Gissler
% Last updated: October 2023

addpath 'general'
addpath 'process_trial'
addpath 'process_trial/functions'
addpath 'plotting'
addpath 'robot_parameters'

clear
slopes_plot = true;
static_margin_bool = true; % only matters if slopes_plot = true
NP_plot = false;
COP_plot = false;

% comment out for slopes plot
% for index = 1:3
%     if index == 1
%         if (NP_plot)
%             close all
%             posF = figure;
%             hold on
%             momF = figure;
%             hold on
%         end
%         wing_freq_sel = [0,2,3];
%         wind_speed_sel = [2];
%     elseif index == 2
%         wing_freq_sel = [2,3,4,5];
%         wind_speed_sel = [4];
%     elseif index == 3
%         wing_freq_sel = [0,3,4];
%         wind_speed_sel = [6];
%     end

wing_freq_sel = [2,3,4,5];
wind_speed_sel = [4];

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
% wing_freq_sel = [2,3,4,5];
% wind_speed_sel = [4];
type_sel = ["blue wings with tail"];
AoA_sel = -10:1:10;
% AoA_sel = -2:2:2;

wind_speeds = [2,4,6];
% wind_speeds = [0,2,4,6];

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% select_type_UI(processed_data_path)

sub_strings = ["no wings with tail"];
% sub_strings = ["no wings with tail", "- no wings with tail 0Hz", "blue wings with tail 0Hz"];

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;

NP_pos_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));
NP_mom_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));
St_vals = zeros(length(wing_freq_sel),length(wind_speed_sel));

% map = [[189, 215, 231]; [107, 174, 214]; [49, 130, 189]; [8, 81, 156]];
% map = map / 255;
map = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
% map = ["#bae4bc"; "#7bccc4"; "#2b8cbe"];
map = hex2rgb(map);
xquery = linspace(0,1,128);
numColors = size(map);
numColors = numColors(1);
map = interp1(linspace(0,1,numColors), map, xquery,'pchip');

if (slopes_plot || COP_plot)
    close all
    f = figure;
    f.Position = [562 329 800 500];
    cmap = colormap(map);
    zmap = linspace(0.15, 0.5, length(cmap));
    min_slope = 0;
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

    shift_bool = false; % get pitch moment data shifted
    norm_bool = false;
    [avg_forces, err_forces, names, sub_title, norm_factors] = ...
        get_data_AoA(selected_vars, processed_data_path, norm_bool, sub_strings, shift_bool);

    % For NP_plot
    [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, false, sub_title);
    [NP_pos_LE, NP_pos_chord] = posToChord(NP_pos);
    NP_pos_vals(wing_freq_sel == selected_vars.freq, wind_speed_sel == selected_vars.wind)...
        = NP_pos_chord;
    norm_M_factor = mean(norm_factors(2,:,1,1));
    NP_mom_vals(wing_freq_sel == selected_vars.freq, wind_speed_sel == selected_vars.wind)...
        = NP_mom / norm_M_factor;

    if (slopes_plot)
        [distance_vals_chord, slopes] = findCOMrange(avg_forces, AoA_sel, false);
        static_margin = NP_pos_chord - distance_vals_chord;
        % norm_M_factor = mean(norm_factors(2,:,1,1));
        slopes = slopes / norm_M_factor;
        if (min(slopes) < min_slope)
            min_slope = min(slopes);
        end
        if (static_margin_bool)
            line = plot(static_margin, slopes);
        else
            line = plot(distance_vals_chord, slopes);
        end
        if (selected_vars.freq == 0)
            line.Color = 'black';
            line.DisplayName = 'Gliding';
            line.LineWidth = 3;
        else
            line.Color = interp1(zmap, cmap, St);
            line.HandleVisibility = 'off';
            line.LineWidth = 2;
        end
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
    caxis([0.15, 0.5])
    xlim([0 100])
    % ylim([min_slope 0])
    cb = colorbar();
    ylabel(cb,'Strouhal Number','FontSize',16,'Rotation',270)
    if (static_margin_bool)
        xlabel("Static Margin (\% chord)",FontSize=16,Interpreter='latex')
    else
        xlabel("COM Position (\% chord)",FontSize=16,Interpreter='latex')
    end
    ylabel("$$\frac{\partial{M}}{\partial\alpha}$$",FontSize=16,Rotation=0,Interpreter='latex')
    % title("Designing a Stable Flier",FontSize=18,Interpreter='latex')
    if (ismember(0,wing_freq_sel))
        legend(Location="best",FontSize=16);
    end
elseif (COP_plot)
    caxis([0, 0.5])
    cb = colorbar();
    ylabel(cb,'Strouhal Number',FontSize=16,Rotation=270,Interpreter='latex')
    xlabel("Angle of Attack (deg)",Interpreter='latex')
    ylabel("Center of Pressure Location (% Chord)",Interpreter='latex')
    % title(type_sel + " " + wind_speed_sel + " m/s " + wing_freq_sel + " Hz")
end

if (NP_plot)
    if (length(wind_speeds) == 5)
        % colors(:,:,1) = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
        colors = ["#fdd49e"; "#fdbb84"; "#fc8d59"; "#e34a33"; "#b30000"];
    elseif (length(wind_speeds) == 4)
        % colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#43a2ca"; "#0868ac"];
        colors = ["#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
    elseif (length(wind_speeds) == 3)
        % colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#2b8cbe"];
        colors = ["#fdcc8a"; "#fc8d59"; "#d7301f"];
    elseif (length(wind_speeds) == 2)
        % colors(:,:,1) = ["#a8ddb5"; "#43a2ca"];
        colors = ["#fdbb84"; "#e34a33"];
    elseif (length(wind_speeds) == 1)
        % colors(:,:,1) = ["#43a2ca"];
        colors = ["#e34a33"];
    end

    for j = 1:length(sub_strings)
        sub_string = sub_strings(j);
        case_parts = strtrim(split(sub_string));

        if (case_parts(1) == "-")
            sub_bool = false;
            sub_string = strjoin(case_parts(2:end));
        else
            sub_bool = true;
        end

        if (sub_bool)
            sub_string = "{\color{red}{SUBTRACTION}}: " + sub_string;
        else
            sub_string = "{\color{blue}{ADDITION}}: " + sub_string;
        end

        sub_strings(j) = sub_string;
    end

    St_bool = true;

    set(0,'CurrentFigure',posF)  
    if (St_bool)
        s = scatter(St_vals, NP_pos_vals, 100, 'filled');
    else
        s = scatter(wing_freq_sel, NP_pos_vals, 100, 'filled');
    end
    s.MarkerFaceColor = colors(wind_speeds == wind_speed_sel);
    s.MarkerEdgeColor = colors(wind_speeds == wind_speed_sel);
    s.DisplayName = int2str(wind_speed_sel) + " m/s";
    xlabel("Strouhal Number", FontSize=18, Interpreter='latex')
    ylabel("Neutral Position (\% Chord)", FontSize=18, Interpreter='latex')
    legend()
    title(["Neutral Position" sub_strings], FontSize=20, FontName='Times New Roman');

    set(0,'CurrentFigure',momF)
    if (St_bool)
        s = scatter(St_vals, NP_mom_vals, 100, 'filled');
    else
        s = scatter(wing_freq_sel, NP_mom_vals, 100, 'filled');
    end
    s.MarkerFaceColor = colors(wind_speeds == wind_speed_sel);
    s.MarkerEdgeColor = colors(wind_speeds == wind_speed_sel);
    s.DisplayName = int2str(wind_speed_sel) + " m/s";

    if (St_bool)
        xlabel("Strouhal Number", FontSize=18, Interpreter='latex')
    else
        xlabel("Wingbeat Frequency", FontSize=18, Interpreter='latex')
    end
    ylabel("Moment Coefficient", FontSize=18, Interpreter='latex')
    legend()
    title(["Pitch Moment at Neutral Position" sub_strings], FontSize=20, FontName='Times New Roman');
end

% end