% To get plot panel of non-normalized data that has already been subtracted

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

sub_shift_avg_data = strings(0);
% we only care about sub_shift data that has been avgalized (drift is broken)
for i=1:length(plot_data)
    file_name = plot_data(i).name;
    if contains(file_name, "sub") && contains(file_name, "shift")...
            && ~contains(file_name, "drift") && ~contains(file_name, "norm")
        sub_shift_avg_data = [sub_shift_avg_data file_name];
    end
end

% Initialize an empty struct to hold all my results
avg_results = struct('type', {}, 'freq', {}, 'wind_speed', {}, "reynolds", {}, 'AoA', {}, ...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, ...
    'drag', {}, "trans", {}, 'lift', {}, "roll", {}, 'pitch', {}, "yaw", {}, ...
    'err_drag', {}, "err_trans", {}, 'err_lift', {}, "err_roll", {}, 'err_pitch', {}, "err_yaw", {});

% Now we will extract the forces and moments from each of these files
AoA_options = -16:2:24;

% now do the same for the avg (non avgalized) data
count = 1; % this will be the position in the array
for i=1:length(sub_shift_avg_data)

    % now we will load the data from this specific file
    fname = sub_shift_avg_data(i);
    file_path = fullfile(files_data_path, fname);
    raw_data = load(file_path); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractAfter(extractBefore(fname, "m.s"), "20_"));

    for j = 1:length(raw_data.names)

        % pull out relevant info
        raw_freq = double(erase(raw_data.names(j), " Hz")); % remove Hz and make double

        % these are organized in 8 x 21 x 4 arrays
        % - 8: drag, trans, lift, roll, pitch, yaw, volt, current
        % - 21: -16:2:24 for AoA
        % - 4: 0, 2, 3, 4 Hz or Strouhal
        avg_results(count).drag = raw_data.avg_forces(1,:,j);
        avg_results(count).trans = raw_data.avg_forces(2,:,j);
        avg_results(count).lift = raw_data.avg_forces(3,:,j);
        avg_results(count).roll = raw_data.avg_forces(4,:,j);
        avg_results(count).pitch = raw_data.avg_forces(5,:,j);
        avg_results(count).yaw = raw_data.avg_forces(6,:,j);

        % now find errors
        avg_results(count).err_drag = raw_data.err_forces(1,:,j);
        avg_results(count).err_trans = raw_data.err_forces(2,:,j);
        avg_results(count).err_lift = raw_data.err_forces(3,:,j);
        avg_results(count).err_roll = raw_data.err_forces(4,:,j);
        avg_results(count).err_pitch = raw_data.err_forces(5,:,j);
        avg_results(count).err_yaw = raw_data.err_forces(6,:,j);

        % now add to results structured array
        avg_results(count).type = extractBefore(fname, "_sub");
        avg_results(count).freq = raw_freq;
        avg_results(count).AoA = AoA_options;
        avg_results(count).wind_speed = current_wind_speed;
        avg_results(count).amp = 20; % degrees

        % now calculate estimate Reynlolds

        nu = 0.00001529; % at 22.5 degrees celcius

        % to pull out chord from wingtype

        % save wing geometry
        if avg_results(count).type == "default"
            avg_results(count).wing_span = 0.177; % meters, length of single wing
            avg_results(count).wing_chord = 0.073; % meters
            avg_results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        elseif avg_results(count).type == "chord_half"
            avg_results(count).wing_span = 0.177;
            avg_results(count).wing_chord = 0.0365;
            avg_results(count).wing_length = 0.201;
        elseif avg_results(count).type == "span_half"
            avg_results(count).wing_span = 0.0885;
            avg_results(count).wing_chord = 0.073;
            avg_results(count).wing_length = 0.1125;
        else
            error("Type not found. No geometry values for Reynolds Number calculation")
        end

        % gets double value
        avg_results(count).reynolds = current_wind_speed*avg_results(count).wing_chord/nu;

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
    all_types = strtrim(string({avg_results.type})); % converts types to array of strings
    types_mask = (all_types == plot_type); % creates mask with types we care about
    avg_results = avg_results(types_mask);
end

%% Now plot avg (non avgalized) results

% types = chord_half, span_half, default
unique_types_avg = unique(string({avg_results.type}));
num_types_avg = length(unique_types_avg);

% Wind speeds OR Reynolds numbers depending on flow_char (ABOVE)
flow_types_avg = double(unique(string({avg_results.(flow_char)})));
num_flows_avg = length(flow_types_avg);

% symbology
% colors = lines(num_types); % redefining colors within loop!
marker_size = 7.5; % for consistent sizes
markers = ['o', '^', 'p']; % circle, triangle, pentagram
chart_edge = [0.15, 0.15, 0.15];
line_width = 0.7;

avg_count = 1;

% we want 6 plots for the 6 flow types
for i=1:num_types_avg % should be 3 types

    % filter results to only have type we want
    type_idx = (string({avg_results.type}) == unique_types_avg(i));
    this_type = avg_results(type_idx);

    % loop for different flows within type (because legend entry depends on which flow)
    for j=1:num_flows_avg % 3 Reynolds options, but each wing type only has 2

        current_marker = markers(j); % for plotting

        % filter results to only have speed we want (must use tolerance)
        % Define a small tolerance
        tol = 1e-3;
        flow_vals = [this_type.(flow_char)];
        flow_idx = abs(flow_vals - flow_types_avg(j)) < tol;
        this_flow = this_type(flow_idx);

        if ~isempty(this_flow) % because not every flow type has all the reynolds options
           
            % extract and sort Strouhal
            this_freq = vertcat(this_flow.freq);
            [freq_sorted, sort_idx] = sort(this_freq);
            num_freq = length(freq_sorted);

            % now figure out plotting for Re vs wind speed
            if flow_char == "reynolds"
                sig_fig_Re = round(flow_types_avg(j), 2, 'significant'); % first do 2 sig fics
                flow_val = sprintf('%.0f', sig_fig_Re); % convert to string and show no decimals
            else
                flow_val = string(flow_types_avg(j));
            end

            % define plot panel
            avg_fig = figure(avg_count);
            % Make the window wide so the 3 panels aren't squished

            % Create layout and store the handle 'tlo'
            tlo_avg = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'tight');

            % Pre-create the axes so they persist through both iterations of k
            ax1_avg = nexttile; hold(ax1_avg, 'on'); grid(ax1_avg, 'on');
                ylabel(ax1_avg, 'Drag Force, $D$ [N]', 'Interpreter', 'latex', 'FontSize', 18);
                xlabel(ax1_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax2_avg = nexttile; hold(ax2_avg, 'on'); grid(ax2_avg, 'on');
                ylabel(ax2_avg, 'Transverse Force [N]', 'Interpreter', 'latex', 'FontSize', 18);
                xlabel(ax2_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax3_avg = nexttile; hold(ax3_avg, 'on'); grid(ax3_avg, 'on');
            ylabel(ax3_avg, 'Lift Force, $L$ [N]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax3_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax4_avg = nexttile; hold(ax4_avg, 'on'); grid(ax4_avg, 'on');
            ylabel(ax4_avg, 'Roll Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax4_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax5_avg = nexttile; hold(ax5_avg, 'on'); grid(ax5_avg, 'on');
            ylabel(ax5_avg, 'Pitch Moment, $M$ [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax5_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax6_avg = nexttile; hold(ax6_avg, 'on'); grid(ax6_avg, 'on');
            ylabel(ax6_avg, 'Yaw Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax6_avg, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);

            % Set the OVERALL title for the whole figure
            % title(tlo_avg, "Averaged Data: " + typeToTitle(unique_types_avg(i)) + ", " + flow_descrip + flow_val + flow_unit, ...
            %     'Interpreter', 'latex', 'FontSize', 16);

            for k = 1:num_freq

                curr_freq = round(freq_sorted(k), 2, 'significant');

                [plot_color] = getPlotColorPanels(k, num_freq, unique_types_avg(i));

                % extract values
                this_AoA_avg = vertcat(this_flow(k).AoA);
                this_drag_avg = vertcat(this_flow(k).drag);
                this_trans_avg = vertcat(this_flow(k).trans);
                this_lift_avg = vertcat(this_flow(k).lift);
                this_roll_avg = vertcat(this_flow(k).roll);
                this_pitch_avg = vertcat(this_flow(k).pitch);
                this_yaw_avg = vertcat(this_flow(k).yaw);

                % extract errors
                this_drag_avg_error = vertcat(this_flow(k).err_drag);
                this_trans_avg_error = vertcat(this_flow(k).err_trans);
                this_lift_avg_error = vertcat(this_flow(k).err_lift);
                this_roll_avg_error = vertcat(this_flow(k).err_roll);
                this_pitch_avg_error = vertcat(this_flow(k).err_pitch);
                this_yaw_avg_error = vertcat(this_flow(k).err_yaw);

                % now plot!

                errorbar(ax1_avg, this_AoA_avg, this_drag_avg,this_drag_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width,...% for error bars
                    'DisplayName', "f $ = $" + num2str(round(curr_freq, 2, 'significant')) + ' Hz')
                
                errorbar(ax2_avg, this_AoA_avg, this_trans_avg,this_trans_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax3_avg, this_AoA_avg, this_lift_avg,this_lift_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax4_avg, this_AoA_avg, this_roll_avg,this_roll_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax5_avg, this_AoA_avg, this_pitch_avg,this_pitch_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax6_avg, this_AoA_avg, this_yaw_avg,this_yaw_avg_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars
            end

            lgd_avg = legend(ax1_avg, 'Orientation', 'horizontal', 'Interpreter', 'latex');
            lgd_avg.Layout.Tile = 'south'; % Moves it to the bottom of all 3 panels
            lgd_avg.FontSize = 18;
            lgd_avg.ItemTokenSize = [10, 18];
            lgd_avg.NumColumns = 2; % to split up legend into rows

            avg_count = avg_count + 1;
        end

    end
end

%% Now save

% % Make folder
% plotFolder = fullfile(data_path, 'averaged_plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1:6];
% figNames = ["averaged_plots_highAR14", "averaged_plots_highAR72", "averaged_plots_mediumAR14", "averaged_plots_mediumAR29",...
%     "averaged_plots_lowAR14", "averaged_plots_lowAR29"];
% 
% for k = 1:length(figHandles)
%     currentFig = figure(figHandles(k));
%     baseName = fullfile(plotFolder, figNames(k));
% 
%     % 1. Save as MATLAB .fig (for future editing)
%     saveas(currentFig, baseName + '.fig');
% 
%     % 2. Save as .png (for Word/PowerPoint)
%     % 'Resolution', 300 makes it high-definition
%     exportgraphics(currentFig, baseName + '.png', 'Resolution', 600);
% 
%     % 3. Save as .eps (Vector format for LaTeX or high-end publishing)
%     exportgraphics(currentFig, baseName + '.eps', 'ContentType', 'vector');
% 
%     fprintf('Saved Figure %d to %s\n', figHandles(k), plotFolder);
% end

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