% plot the normalized, already subtracted data (final data)

clc
clear
close all

cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../../'))

DELIM = string(filesep);

h = helpdlg("Please select the 'plot data' folder that contains all the processed files");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Please select the 'plot data' folder that contains all the processed files") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing/Zachary_files/plot_data_LE_fullShift/", "Please select the 'plot data' folder that contains all the processed files") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

files_data_path = fullfile(data_path, "Calimero"); % must step into Calimero
plot_data = dir(files_data_path);

% now filter it to get rid of systems files (the rest should be .mat)
% we also don't want body data
data_names = string({plot_data.name});
is_valid_dir = ~startsWith(data_names, ".") & ~contains(data_names, "body");
plot_data = plot_data(is_valid_dir);

sub_shift_norm_data = strings(0); % must use string array because character count differs
% we only care about sub_shift data that has been normalized (drift is broken)
for i=1:length(plot_data)
    file_name = plot_data(i).name;
    if  contains(file_name, "sub") && contains(file_name, "shift")...
            && ~contains(file_name, "drift") && contains(file_name, "norm")
        sub_shift_norm_data = [sub_shift_norm_data file_name];
    end
end

% Initialize an empty struct to hold all my results
results = struct('type', {}, 'strouhal', {}, 'freq', {}, 'wind_speed', {},...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, ...
    "reynolds", {}, 'AoA', {}, 'err_lift', {}, 'err_pitch', {}, 'err_drag', {},...
    'lift_coeff', {}, 'pitch_coeff', {}, 'drag_coeff', {}, ...
    "lift_slope", {}, "lift_intercept", {}, "lift_Rsq", {}, "lift_slope_error", {}, "lift_intercept_error", {}, "lift_residuals", {}, ...
    "pitch_slope", {}, "pitch_intercept", {}, "pitch_Rsq", {}, "pitch_slope_error", {}, "pitch_intercept_error", {}, "pitch_residuals", {}, ...
    "induced_drag", {}, "C_D0", {},  "k_Rsq", {}, "k_slope_error", {},  "C_D0_intercept_error", {}, "drag_residuals", {}, ...
    "max_clcd", {}, "max_clcd_AoA", {}, "err_efficiency", {}, "effic_array", {}, "stall_angle", {}, "stall_fit_RMSE", {}, "C_L_stall_fit", {},...
    "trans_coeff", {}, "err_trans", {}, "roll_coeff", {}, "err_roll", {}, "yaw_coeff", {}, "err_yaw", {});

% Now we will extract the forces and moments from each of these files
AoA_options = -16:2:24;
freq = [0,2,3,4];

count = 1; % this will be the position in the array
for i=1:length(sub_shift_norm_data)

    % now we will load the data from this specific file
    fname = sub_shift_norm_data(i);
    file_path = fullfile(files_data_path, fname);
    data = load(file_path); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractAfter(extractBefore(fname, "m.s"), "20_"));

    for j = 1:length(data.names)

        % pull out relevant info
        strouhal = double(erase(data.names(j), " St: ")); % remove St and make double

        % these are organized in 8 x 21 x 4 arrays
        % - 8: drag, trans, lift, roll, pitch, yaw, volt, current
        % - 21: -16:2:24 for AoA
        % - 4: 0, 2, 3, 4 Hz or Strouhal
        results(count).drag_coeff = data.avg_forces(1,:,j);
        results(count).trans_coeff = data.avg_forces(2,:,j);
        results(count).lift_coeff = data.avg_forces(3,:,j);
        results(count).roll_coeff = data.avg_forces(4,:,j);
        results(count).pitch_coeff = data.avg_forces(5,:,j);
        results(count).yaw_coeff = data.avg_forces(6,:,j);

        % now find errors
        results(count).err_drag = data.err_forces(1,:,j);
        results(count).err_trans = data.err_forces(2,:,j);
        results(count).err_lift = data.err_forces(3,:,j);
        results(count).err_roll = data.err_forces(4,:,j);
        results(count).err_pitch = data.err_forces(5,:,j);
        results(count).err_yaw = data.err_forces(6,:,j);

        % now add to results structured array
        results(count).type = extractBefore(fname, "_sub");
        results(count).strouhal = strouhal;
        results(count).AoA = AoA_options;
        results(count).wind_speed = current_wind_speed;
        results(count).freq = freq(j);
        results(count).amp = 20; % degrees

        % now calculate estimate Reynlolds

        nu = 0.00001529; % at 22.5 degrees celcius


        % save wing geometry
        if results(count).type == "default"
            results(count).wing_span = 0.177; % meters, length of single wing
            results(count).wing_chord = 0.073; % meters
            results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        elseif results(count).type == "chord_half"
            results(count).wing_span = 0.177;
            results(count).wing_chord = 0.0365;
            results(count).wing_length = 0.201;
        elseif results(count).type == "span_half"
            results(count).wing_span = 0.0885;
            results(count).wing_chord = 0.073;
            results(count).wing_length = 0.1125;
        else
            error("Type not found. No geometry values for Reynolds Number calculation")
        end

        % gets double value
        results(count).reynolds = current_wind_speed*results(count).wing_chord/nu;

        count = count + 1; % each Strouhal will get a different entry in results
    end
end

%% Choose plot type - CUSTOMIZE HERE

% Now choose which type to plot
plot_type = "all";

% Choose {reynolds, wind_speed} for legend
flow_char = "reynolds";
if flow_char == "reynolds"
    flow_descrip = "Re = ";
    flow_unit = "";
elseif flow_char == "wind_speed"
    flow_descrip = "U = ";
    flow_unit = " m/s";
else
    error("Unrecognized flow characteristic for legend")
end

% filter based on defined type above
if ~strcmp(plot_type, "all")
    all_types = strtrim(string({results.type})); % converts types to array of strings
    types_mask = (all_types == plot_type); % creates mask with types we care about
    results = results(types_mask);
end

%% Plot Panels for normalized forces

% types = chord_half, span_half, default
unique_types = unique(string({results.type}));
num_types = length(unique_types);

% Wind speeds OR Reynolds numbers depending on flow_char (ABOVE)
flow_types = double(unique(string({results.(flow_char)})));
num_flows = length(flow_types);

% symbology
% colors = lines(num_types); % redefining colors within loop!
marker_size = 7; % for consistent sizes
markers = ['o', '^', 'p']; % circle, triangle, pentagram
chart_edge = [0.15, 0.15, 0.15];
line_width = 0.7;

norm_count = 1;

% we want 6 plots for the 6 flow types
for i=1:num_types % should be 3 types

    % filter results to only have type we want
    type_idx = (string({results.type}) == unique_types(i));
    this_type = results(type_idx);

    % loop for different flows within type (because legend entry depends on which flow)
    for j=1:num_flows % 3 Reynolds options, but each wing type only has 2

        current_marker = markers(j); % for plotting

        % filter results to only have speed we want (must use tolerance)
        % Define a small tolerance
        tol = 1e-3;
        flow_vals = [this_type.(flow_char)];
        flow_idx = abs(flow_vals - flow_types(j)) < tol;
        this_flow = this_type(flow_idx);

        if ~isempty(this_flow) % because not every flow type has all the reynolds options
           
            % extract and sort Strouhal
            this_str = vertcat(this_flow.strouhal);
            [str_sorted, sort_idx] = sort(this_str);
            num_str = length(str_sorted);

            % now figure out plotting for Re vs wind speed
            if flow_char == "reynolds"
                sig_fig_Re = round(flow_types(j), 2, 'significant'); % first do 2 sig fics
                flow_val = sprintf('%.0f', sig_fig_Re); % convert to string and show no decimals
            else
                flow_val = string(flow_types(j));
            end

            % define plot panel
            norm_fig = figure(norm_count);
            % Make the window wide so the 3 panels aren't squished

            % Create layout and store the handle 'tlo'
            tlo_norm = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'tight');

            % Pre-create the axes so they persist through both iterations of k
            ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
                ylabel(ax1, 'Drag Coefficient, $C_D$', 'Interpreter', 'latex', 'FontSize', 16);
                xlabel(ax1, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);
            ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
                ylabel(ax2, 'Transverse Force Coefficient', 'Interpreter', 'latex', 'FontSize', 16);
                xlabel(ax2, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);
            ax3 = nexttile; hold(ax3, 'on'); grid(ax3, 'on');
            ylabel(ax3, 'Lift Coefficient, $C_L$', 'Interpreter', 'latex', 'FontSize', 16);
            xlabel(ax3, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);
            ax4 = nexttile; hold(ax4, 'on'); grid(ax4, 'on');
            ylabel(ax4, 'Roll Coefficient', 'Interpreter', 'latex', 'FontSize', 16);
            xlabel(ax4, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);
            ax5 = nexttile; hold(ax5, 'on'); grid(ax5, 'on');
            ylabel(ax5, 'Pitch Coefficient, $C_M$', 'Interpreter', 'latex', 'FontSize', 16);
            xlabel(ax5, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);
            ax6 = nexttile; hold(ax6, 'on'); grid(ax6, 'on');
            ylabel(ax6, 'Yaw Coefficient', 'Interpreter', 'latex', 'FontSize', 16);
            xlabel(ax6, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 16);

            % Set the OVERALL title for the whole figure
            % title(tlo_norm, "Normalized Data: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, ...
            %    'Interpreter', 'latex', 'FontSize', 16);

            for k = 1:num_str

                curr_strouhal = round(str_sorted(k), 2, 'significant');

                [plot_color] = getPlotColorPanels(k, num_str, unique_types(i));

                % extract values
                this_AoA = vertcat(this_flow(k).AoA);
                this_drag_norm = vertcat(this_flow(k).drag_coeff);
                this_trans_norm = vertcat(this_flow(k).trans_coeff);
                this_lift_norm = vertcat(this_flow(k).lift_coeff);
                this_roll_norm = vertcat(this_flow(k).roll_coeff);
                this_pitch_norm = vertcat(this_flow(k).pitch_coeff);
                this_yaw_norm = vertcat(this_flow(k).yaw_coeff);

                % extract errors
                this_drag_norm_error = vertcat(this_flow(k).err_drag);
                this_trans_norm_error = vertcat(this_flow(k).err_trans);
                this_lift_norm_error = vertcat(this_flow(k).err_lift);
                this_roll_norm_error = vertcat(this_flow(k).err_roll);
                this_pitch_norm_error = vertcat(this_flow(k).err_pitch);
                this_yaw_norm_error = vertcat(this_flow(k).err_yaw);

                % now plot!

                errorbar(ax1, this_AoA, this_drag_norm,this_drag_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width,...% for error bars
                    'DisplayName', "St $ = $" + num2str(round(curr_strouhal, 2, 'significant')))
                
                errorbar(ax2, this_AoA, this_trans_norm,this_trans_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax3, this_AoA, this_lift_norm,this_lift_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax4, this_AoA, this_roll_norm,this_roll_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax5, this_AoA, this_pitch_norm,this_pitch_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax6, this_AoA, this_yaw_norm,this_yaw_norm_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars
            end

            lgd_norm = legend(ax1, 'Orientation', 'horizontal', 'Interpreter', 'latex');
            lgd_norm.Layout.Tile = 'south'; % Moves it to the bottom of all 3 panels
            lgd_norm.FontSize = 16;
            lgd_norm.ItemTokenSize = [10, 18];
            lgd_norm.NumColumns = 2; % to split up legend into rows

            norm_count = norm_count + 1;
        end

    end
end

% % Coefficient of Drag vs AoA
% figure(1)
% errorbar(plot_AoA, plot_C_D, plot_err_drag, 'Marker', 'o', 'LineStyle', 'none')
% legend("St: " + string(plot_St))
% title(typeToTitle(plot_type) + ": Drag Coefficient vs. AoA")
% xlabel("AoA")
% ylabel("$C_D$", 'Interpreter','latex')
% 
% % Coefficient of Lift vs AoA
% figure(2)
% errorbar(plot_AoA, plot_C_L, plot_err_lift, 'Marker', 'o', 'LineStyle', 'none')
% legend("St: " + string(plot_St))
% title(typeToTitle(plot_type) + ": Lift Coefficient vs. AoA")
% xlabel("AoA")
% ylabel("$C_L$", 'Interpreter','latex')
% hold on
% 
% % Coefficient of Pitch vs AoA
% figure(3)
% errorbar(plot_AoA, plot_C_M, plot_err_pitch, 'Marker', 'o', 'LineStyle', 'none')
% legend("St: " + string(plot_St))
% title(typeToTitle(plot_type) + ": Pitch Coefficient vs. AoA")
% xlabel("AoA")
% ylabel("$C_M$", 'Interpreter','latex')

%% Now save

% Make folder
plotFolder = fullfile(data_path, 'norm_data_plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

% List of figure numbers you want to save
figHandles = [1:6];
figNames = ["norm_data_highAR14", "norm_data_highAR72", "norm_data_mediumAR14", "norm_data_mediumAR29",...
    "norm_data_lowAR14", "norm_data_lowAR29"];

for k = 1:length(figHandles)
    currentFig = figure(figHandles(k));
    baseName = fullfile(plotFolder, figNames(k));

    % 1. Save as MATLAB .fig (for future editing)
    saveas(currentFig, baseName + '.fig');

    % 2. Save as .png (for Word/PowerPoint)
    % 'Resolution', 300 makes it high-definition
    exportgraphics(currentFig, baseName + '.png', 'Resolution', 600);

    % 3. Save as .eps (Vector format for LaTeX or high-end publishing)
    exportgraphics(currentFig, baseName + '.eps', 'ContentType', 'vector');

    fprintf('Saved Figure %d to %s\n', figHandles(k), plotFolder);
end

%% HELPER FUNCTIONS

function [plot_title] = typeToTitle(plot_type)
if strcmp(plot_type, "default")
    plot_title = "Medium AR";
elseif strcmp(plot_type, "chord_half")
    plot_title = "High AR";
elseif strcmp(plot_type, "span_half")
    plot_title = "Low AR";
elseif strcmp(plot_type, "all")
    plot_title = "";
end
end

function [plot_color] = getPlotColorPanels(k, num_str, unique_type)
t = (k - 1) / max(1, (num_str - 1));

if contains(unique_type, "chord_half") % High AR (Blue)
    h_start = 0.52; h_end = 0.65;
    s_start = 0.30; s_end = 0.85; % Lighter (0.3) -> Darker (0.85)
    v_start = 0.90; v_end = 0.50; % Brighter (0.9) -> Deeper (0.5)

elseif contains(unique_type, "default") % Medium AR (Red/Pink)
    h_start = 0.08; h_end = 0.05;   % Moves from a warm yellow-tint to a red-tint
    s_start = 0.25; s_end = 0.90;   % Pale -> Very Saturated
    v_start = 1.00; v_end = 0.65;   % Bright -> Deep/Burnt

else % Low AR (Gold/Yellow)
    h_start = 0.14; h_end = 0.12;
    s_start = 0.25; s_end = 0.80; % Cream -> Mustard
    v_start = 1.00; v_end = 0.75; % White-ish -> Rich Gold
end

% Interpolate to get the specific color for this Strouhal
plot_color = hsv2rgb([mod(h_start + (h_end-h_start)*t, 1), ...
    s_start + (s_end-s_start)*t, ...
    v_start + (v_end-v_start)*t]);
end