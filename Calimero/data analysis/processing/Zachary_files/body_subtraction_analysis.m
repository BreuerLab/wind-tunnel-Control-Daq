% To get plot panel of non-normalized data to show efficacy of subtraction

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
wing_plot_data = dir(files_data_path);

% now filter it to get rid of systems files (the rest should be .mat)
data_names = string({wing_plot_data.name});
wing_valid_dir = ~startsWith(data_names, ".") & ~contains(data_names, "body");
wing_plot_data = wing_plot_data(wing_valid_dir);

% Collect sub_shift and just shift data that has been processed (drift is broken)
sub_shift_wing_data = strings(0);
shift_wing_data = strings(0);
for i=1:length(wing_plot_data)
    file_name = wing_plot_data(i).name;
    if contains(file_name, "sub") && contains(file_name, "shift")...
            && ~contains(file_name, "drift") && ~contains(file_name, "norm")
        sub_shift_wing_data = [sub_shift_wing_data file_name];
    elseif ~contains(file_name, "sub") && contains(file_name, "shift")...
            && ~contains(file_name, "drift") && ~contains(file_name, "norm")
        shift_wing_data = [shift_wing_data file_name];
    end
end

% now we want body data
files_data_path = fullfile(data_path, "Calimero"); % must step into Calimero
body_plot_data = dir(files_data_path);

data_names = string({body_plot_data.name});
body_valid_dir = ~startsWith(data_names, ".") & contains(data_names, "body");
body_plot_data = body_plot_data(body_valid_dir);

sub_shift_body_data = strings(0);
% we only care about sub_shift data that has been avgalized (drift is broken)
for i=1:length(body_plot_data)
    file_name = body_plot_data(i).name;
    if ~contains(file_name, "sub") && contains(file_name, "shift")...
            && ~contains(file_name, "drift") && ~contains(file_name, "norm")
        sub_shift_body_data = [sub_shift_body_data file_name];
    end
end

% Initialize an empty struct to hold all my results
wing_sub_results = struct('type', {}, 'freq', {}, 'wind_speed', {}, "reynolds", {}, 'AoA', {}, ...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, ...
    'drag', {}, "trans", {}, 'lift', {}, "roll", {}, 'pitch', {}, "yaw", {}, ...
    'err_drag', {}, "err_trans", {}, 'err_lift', {}, "err_roll", {}, 'err_pitch', {}, "err_yaw", {});
wing_results = struct('type', {}, 'freq', {}, 'wind_speed', {}, "reynolds", {}, 'AoA', {}, ...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, ...
    'drag', {}, "trans", {}, 'lift', {}, "roll", {}, 'pitch', {}, "yaw", {}, ...
    'err_drag', {}, "err_trans", {}, 'err_lift', {}, "err_roll", {}, 'err_pitch', {}, "err_yaw", {});
body_results = struct('type', {}, 'freq', {}, 'wind_speed', {}, "reynolds", {}, 'AoA', {}, ...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, ...
    'drag', {}, "trans", {}, 'lift', {}, "roll", {}, 'pitch', {}, "yaw", {}, ...
    'err_drag', {}, "err_trans", {}, 'err_lift', {}, "err_roll", {}, 'err_pitch', {}, "err_yaw", {});

% Now we will extract the forces and moments from each of these files
AoA_options = -16:2:24;

% now extract wing_sub data
count = 1; % this will be the position in the array
for i=1:length(sub_shift_wing_data)

    % now we will load the data from this specific file
    fname = sub_shift_wing_data(i);
    file_path = fullfile(files_data_path, fname);
    wing_sub_data = load(file_path); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractAfter(extractBefore(fname, "m.s"), "20_"));

    for j = 1:length(wing_sub_data.names)

        % pull out relevant info
        raw_freq = double(erase(wing_sub_data.names(j), " Hz")); % remove Hz and make double

        % these are organized in 8 x 21 x 4 arrays
        % - 8: drag, trans, lift, roll, pitch, yaw, volt, current
        % - 21: -16:2:24 for AoA
        % - 4: 0, 2, 3, 4 Hz or Strouhal
        wing_sub_results(count).drag = wing_sub_data.avg_forces(1,:,j);
        wing_sub_results(count).trans = wing_sub_data.avg_forces(2,:,j);
        wing_sub_results(count).lift = wing_sub_data.avg_forces(3,:,j);
        wing_sub_results(count).roll = wing_sub_data.avg_forces(4,:,j);
        wing_sub_results(count).pitch = wing_sub_data.avg_forces(5,:,j);
        wing_sub_results(count).yaw = wing_sub_data.avg_forces(6,:,j);

        % now find errors
        wing_sub_results(count).err_drag = wing_sub_data.err_forces(1,:,j);
        wing_sub_results(count).err_trans = wing_sub_data.err_forces(2,:,j);
        wing_sub_results(count).err_lift = wing_sub_data.err_forces(3,:,j);
        wing_sub_results(count).err_roll = wing_sub_data.err_forces(4,:,j);
        wing_sub_results(count).err_pitch = wing_sub_data.err_forces(5,:,j);
        wing_sub_results(count).err_yaw = wing_sub_data.err_forces(6,:,j);

        % now add to results structured array
        wing_sub_results(count).type = extractBefore(fname, "_sub");
        wing_sub_results(count).freq = raw_freq;
        wing_sub_results(count).AoA = AoA_options;
        wing_sub_results(count).wind_speed = current_wind_speed;
        wing_sub_results(count).amp = 20; % degrees

        % now calculate estimate Reynlolds

        nu = 0.00001529; % at 22.5 degrees celcius

        % to pull out chord from wingtype

        % save wing geometry
        if wing_sub_results(count).type == "default"
            wing_sub_results(count).wing_span = 0.177; % meters, length of single wing
            wing_sub_results(count).wing_chord = 0.073; % meters
            wing_sub_results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        elseif wing_sub_results(count).type == "chord_half"
            wing_sub_results(count).wing_span = 0.177;
            wing_sub_results(count).wing_chord = 0.0365;
            wing_sub_results(count).wing_length = 0.201;
        elseif wing_sub_results(count).type == "span_half"
            wing_sub_results(count).wing_span = 0.0885;
            wing_sub_results(count).wing_chord = 0.073;
            wing_sub_results(count).wing_length = 0.1125;
        else
            error("Type not found. No geometry values for Reynolds Number calculation")
        end

        % gets double value
        wing_sub_results(count).reynolds = current_wind_speed*wing_sub_results(count).wing_chord/nu;

        count = count + 1; % each Strouhal will get a different entry in results
    end
end

% now do non-subbed data
count = 1; % this will be the position in the array
for i=1:length(shift_wing_data)

    % now we will load the data from this specific file
    fname = shift_wing_data(i);
    file_path = fullfile(files_data_path, fname);
    wing_data = load(file_path); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractAfter(extractBefore(fname, "m.s"), "20_"));

    for j = 1:length(wing_data.names)

        % pull out relevant info
        raw_freq = double(erase(wing_data.names(j), " Hz")); % remove Hz and make double

        % these are organized in 8 x 21 x 4 arrays
        % - 8: drag, trans, lift, roll, pitch, yaw, volt, current
        % - 21: -16:2:24 for AoA
        % - 4: 0, 2, 3, 4 Hz or Strouhal
        wing_results(count).drag = wing_data.avg_forces(1,:,j);
        wing_results(count).trans = wing_data.avg_forces(2,:,j);
        wing_results(count).lift = wing_data.avg_forces(3,:,j);
        wing_results(count).roll = wing_data.avg_forces(4,:,j);
        wing_results(count).pitch = wing_data.avg_forces(5,:,j);
        wing_results(count).yaw = wing_data.avg_forces(6,:,j);

        % now find errors
        wing_results(count).err_drag = wing_data.err_forces(1,:,j);
        wing_results(count).err_trans = wing_data.err_forces(2,:,j);
        wing_results(count).err_lift = wing_data.err_forces(3,:,j);
        wing_results(count).err_roll = wing_data.err_forces(4,:,j);
        wing_results(count).err_pitch = wing_data.err_forces(5,:,j);
        wing_results(count).err_yaw = wing_data.err_forces(6,:,j);

        % now add to results structured array
        wing_results(count).type = extractBefore(fname, "_shift");
        wing_results(count).freq = raw_freq;
        wing_results(count).AoA = AoA_options;
        wing_results(count).wind_speed = current_wind_speed;
        wing_results(count).amp = 20; % degrees

        % now calculate estimate Reynlolds

        nu = 0.00001529; % at 22.5 degrees celcius

        % to pull out chord from wingtype

        % save wing geometry
        if wing_results(count).type == "default"
            wing_results(count).wing_span = 0.177; % meters, length of single wing
            wing_results(count).wing_chord = 0.073; % meters
            wing_results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        elseif wing_results(count).type == "chord_half"
            wing_results(count).wing_span = 0.177;
            wing_results(count).wing_chord = 0.0365;
            wing_results(count).wing_length = 0.201;
        elseif wing_results(count).type == "span_half"
            wing_results(count).wing_span = 0.0885;
            wing_results(count).wing_chord = 0.073;
            wing_results(count).wing_length = 0.1125;
        else
            error("Type not found. No geometry values for Reynolds Number calculation")
        end

        % gets double value
        wing_results(count).reynolds = current_wind_speed*wing_results(count).wing_chord/nu;

        count = count + 1; % each Strouhal will get a different entry in results
    end
end


% now do body data
count = 1; % this will be the position in the array
for i=1:length(sub_shift_body_data)

    % now we will load the data from this specific file
    fname = sub_shift_body_data(i);
    file_path = fullfile(files_data_path, fname);
    body_data = load(file_path); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractAfter(extractBefore(fname, "m.s"), "20_"));

    for j = 1:length(body_data.names)

        % pull out relevant info
        raw_freq = double(erase(body_data.names(j), " Hz")); % remove Hz and make double

        % these are organized in 8 x 21 x 4 arrays
        % - 8: drag, trans, lift, roll, pitch, yaw, volt, current
        % - 21: -16:2:24 for AoA
        % - 4: 0, 2, 3, 4 Hz or Strouhal
        body_results(count).drag = body_data.avg_forces(1,:,j);
        body_results(count).trans = body_data.avg_forces(2,:,j);
        body_results(count).lift = body_data.avg_forces(3,:,j);
        body_results(count).roll = body_data.avg_forces(4,:,j);
        body_results(count).pitch = body_data.avg_forces(5,:,j);
        body_results(count).yaw = body_data.avg_forces(6,:,j);

        % now find errors
        body_results(count).err_drag = body_data.err_forces(1,:,j);
        body_results(count).err_trans = body_data.err_forces(2,:,j);
        body_results(count).err_lift = body_data.err_forces(3,:,j);
        body_results(count).err_roll = body_data.err_forces(4,:,j);
        body_results(count).err_pitch = body_data.err_forces(5,:,j);
        body_results(count).err_yaw = body_data.err_forces(6,:,j);

        % now add to results structured array
        body_results(count).type = extractBefore(fname, "_shift");
        body_results(count).freq = raw_freq;
        body_results(count).AoA = AoA_options;
        body_results(count).wind_speed = current_wind_speed;
        body_results(count).amp = 20; % degrees

        % now calculate estimate Reynlolds

        nu = 0.00001529; % at 22.5 degrees celcius

        % to pull out chord from wingtype

        % save wing geometry
        if body_results(count).type == "bodyDefault"
            body_results(count).wing_span = 0.177; % meters, length of single wing
            body_results(count).wing_chord = 0.073; % meters
            body_results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        elseif body_results(count).type == "bodyChordhalf"
            body_results(count).wing_span = 0.177;
            body_results(count).wing_chord = 0.0365;
            body_results(count).wing_length = 0.201;
        elseif body_results(count).type == "bodySpanhalf"
            body_results(count).wing_span = 0.0885;
            body_results(count).wing_chord = 0.073;
            body_results(count).wing_length = 0.1125;
        else
            error("Type not found. No geometry values for Reynolds Number calculation")
        end

        % gets double value
        body_results(count).reynolds = current_wind_speed*body_results(count).wing_chord/nu;

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
    all_types = strtrim(string({body_results.type})); % converts types to array of strings
    types_mask = (all_types == plot_type); % creates mask with types we care about

    % filter all three arrays
    body_results = body_results(types_mask);
    wing_results = wing_results(types_mask);
    wing_sub_results = wing_sub_results(types_mask);
end

%% Now plot avg results

% types = chord_half, span_half, default
unique_types_avg = unique(string({wing_sub_results.type}));
num_types_avg = length(unique_types_avg);

% Wind speeds OR Reynolds numbers depending on flow_char (ABOVE)
flow_types_avg = double(unique(string({wing_sub_results.(flow_char)})));
num_flows_avg = length(flow_types_avg);

% symbology
% colors = lines(num_types); % redefining colors within loop!
marker_size = 8.5; % for consistent sizes
markers = ['o', '^', 'p']; % circle, triangle, pentagram
chart_edge = [0.15, 0.15, 0.15];
line_width = 0.5;

% custom colors for this section only
sub_color = [0 0.9 0];
body_color  =[0.9 0 0];
no_sub_color = 'k';

avg_count = 1;

% we want 6 plots for the 6 flow types
for i=1:num_types_avg % should be 3 types

    % filter results to only have type we want
    type_idx = (string({wing_sub_results.type}) == unique_types_avg(i));
    this_type_wing_sub = wing_sub_results(type_idx);
    this_type_wing = wing_results(type_idx);
    this_type_body = body_results(type_idx);

    % loop for different flows within type (because legend entry depends on which flow)
    for j=1:num_flows_avg % 3 Reynolds options, but each wing type only has 2

        current_marker = markers(j); % for plotting

        % filter results to only have speed we want (must use tolerance)
        % Define a small tolerance
        tol = 1e-3;
        flow_vals = [this_type_wing_sub.(flow_char)];
        flow_idx = abs(flow_vals - flow_types_avg(j)) < tol;
        this_flow_wing_sub = this_type_wing_sub(flow_idx);
        this_flow_wing = this_type_wing(flow_idx);
        this_flow_body = this_type_body(flow_idx);

        if ~isempty(this_flow_wing_sub) % because not every flow type has all the reynolds options
           
            % extract and sort Strouhal
            this_freq = vertcat(this_flow_wing_sub.freq);
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
            sub_fig = figure(avg_count);
            % Make the window wide so the 3 panels aren't squished

            % Create layout and store the handle 'tlo'
            tlo = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'tight');

            % Pre-create the axes so they persist through both iterations of k
            ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
                ylabel(ax1, 'Drag Force, $D$ [N]', 'Interpreter', 'latex', 'FontSize', 18);
                xlabel(ax1, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
                ylabel(ax2, 'Transverse Force [N]', 'Interpreter', 'latex', 'FontSize', 18);
                xlabel(ax2, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax3 = nexttile; hold(ax3, 'on'); grid(ax3, 'on');
            ylabel(ax3, 'Lift Force, $L$ [N]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax3, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax4 = nexttile; hold(ax4, 'on'); grid(ax4, 'on');
            ylabel(ax4, 'Roll Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax4, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax5 = nexttile; hold(ax5, 'on'); grid(ax5, 'on');
            ylabel(ax5, 'Pitch Moment, $M$ [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax5, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);
            ax6 = nexttile; hold(ax6, 'on'); grid(ax6, 'on');
            ylabel(ax6, 'Yaw Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 18);
            xlabel(ax6, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 18);

            % Set the OVERALL title for the whole figure
            % title(tlo, "Subtraction Efficacy Data: " + typeToTitle(unique_types_avg(i)) + ", " + flow_descrip + flow_val + flow_unit + ', 4 Hz', ...
            %     'Interpreter', 'latex', 'FontSize', 16);

            % for k = 1:num_freq
            for k = 4 % just plotting the last frequency

                curr_freq = round(freq_sorted(k), 2, 'significant');

                % [plot_color] = getPlotColorPanels(k, num_freq, unique_types_avg(i));

                this_AoA = vertcat(this_flow_wing_sub(k).AoA);

                % WING NO SUB

                % extract values
                this_drag_wing = vertcat(this_flow_wing(k).drag);
                this_trans_wing = vertcat(this_flow_wing(k).trans);
                this_lift_wing = vertcat(this_flow_wing(k).lift);
                this_roll_wing = vertcat(this_flow_wing(k).roll);
                this_pitch_wing = vertcat(this_flow_wing(k).pitch);
                this_yaw_wing = vertcat(this_flow_wing(k).yaw);

                % extract errors
                this_drag_wing_error = vertcat(this_flow_wing(k).err_drag);
                this_trans_wing_error = vertcat(this_flow_wing(k).err_trans);
                this_lift_wing_error = vertcat(this_flow_wing(k).err_lift);
                this_roll_wing_error = vertcat(this_flow_wing(k).err_roll);
                this_pitch_wing_error = vertcat(this_flow_wing(k).err_pitch);
                this_yaw_wing_error = vertcat(this_flow_wing(k).err_yaw);

                % now plot!

                errorbar(ax1, this_AoA, this_drag_wing,this_drag_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width,...% for error bars
                    'DisplayName', "Wing + Body")
                
                errorbar(ax2, this_AoA, this_trans_wing,this_trans_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax3, this_AoA, this_lift_wing,this_lift_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax4, this_AoA, this_roll_wing,this_roll_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax5, this_AoA, this_pitch_wing,this_pitch_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax6, this_AoA, this_yaw_wing,this_yaw_wing_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', no_sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                % BODY DATA

                % extract values
                this_drag_body = vertcat(this_flow_body(k).drag);
                this_trans_body = vertcat(this_flow_body(k).trans);
                this_lift_body = vertcat(this_flow_body(k).lift);
                this_roll_body = vertcat(this_flow_body(k).roll);
                this_pitch_body = vertcat(this_flow_body(k).pitch);
                this_yaw_body = vertcat(this_flow_body(k).yaw);

                % extract errors
                this_drag_body_error = vertcat(this_flow_body(k).err_drag);
                this_trans_body_error = vertcat(this_flow_body(k).err_trans);
                this_lift_body_error = vertcat(this_flow_body(k).err_lift);
                this_roll_body_error = vertcat(this_flow_body(k).err_roll);
                this_pitch_body_error = vertcat(this_flow_body(k).err_pitch);
                this_yaw_body_error = vertcat(this_flow_body(k).err_yaw);

                % now plot!

                errorbar(ax1, this_AoA, this_drag_body,this_drag_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width,...% for error bars
                    'DisplayName', "Body")
                
                errorbar(ax2, this_AoA, this_trans_body,this_trans_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax3, this_AoA, this_lift_body,this_lift_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax4, this_AoA, this_roll_body,this_roll_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax5, this_AoA, this_pitch_body,this_pitch_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax6, this_AoA, this_yaw_body,this_yaw_body_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', body_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                % WING SUB

                % extract values
                this_drag_wing_sub = vertcat(this_flow_wing_sub(k).drag);
                this_trans_wing_sub = vertcat(this_flow_wing_sub(k).trans);
                this_lift_wing_sub = vertcat(this_flow_wing_sub(k).lift);
                this_roll_wing_sub = vertcat(this_flow_wing_sub(k).roll);
                this_pitch_wing_sub = vertcat(this_flow_wing_sub(k).pitch);
                this_yaw_wing_sub = vertcat(this_flow_wing_sub(k).yaw);

                % extract errors
                this_drag_wing_sub_error = vertcat(this_flow_wing_sub(k).err_drag);
                this_trans_wing_sub_error = vertcat(this_flow_wing_sub(k).err_trans);
                this_lift_wing_sub_error = vertcat(this_flow_wing_sub(k).err_lift);
                this_roll_wing_sub_error = vertcat(this_flow_wing_sub(k).err_roll);
                this_pitch_wing_sub_error = vertcat(this_flow_wing_sub(k).err_pitch);
                this_yaw_wing_sub_error = vertcat(this_flow_wing_sub(k).err_yaw);

                % now plot!

                errorbar(ax1, this_AoA, this_drag_wing_sub,this_drag_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width,...% for error bars
                    'DisplayName', "Wing")
                
                errorbar(ax2, this_AoA, this_trans_wing_sub,this_trans_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax3, this_AoA, this_lift_wing_sub,this_lift_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax4, this_AoA, this_roll_wing_sub,this_roll_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax5, this_AoA, this_pitch_wing_sub,this_pitch_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars

                errorbar(ax6, this_AoA, this_yaw_wing_sub,this_yaw_wing_sub_error,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', chart_edge, ...
                    'MarkerFaceColor', sub_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', chart_edge, ... % error bar colors
                    'LineWidth', line_width) % for error bars
            end

            lgd_avg = legend(ax1, 'Orientation', 'horizontal', 'Interpreter', 'latex');
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
% plotFolder = fullfile(data_path, 'body_sub_plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1:6];
% figNames = ["body_sub_plots_highAR14", "body_sub_plots_highAR72", "body_sub_plots_mediumAR14", "body_sub_plots_mediumAR29",...
%     "body_sub_plots_lowAR14", "body_sub_plots_lowAR29"];
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