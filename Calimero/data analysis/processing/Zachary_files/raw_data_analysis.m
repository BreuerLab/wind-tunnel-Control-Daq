% Show time charts and 6 diagrams of the forces for the raw, non subracted
% data -- COMMENTED

% This current version instead just focuses on lift (thesis will say that
% this is repeated for all cases). Because I want the unclipped data, I
% will literally be finding these plots for one case (and not attaching the
% other plots in the Appendix as this seems like a waste of space anyways).
% This code can be easily modified to cycle through all the cases by making
% the k loop touch on multiple frequencies

clc
clear
close all

cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../../'))

DELIM = string(filesep);

h = helpdlg("Please select the folder containing processed data separated by type");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Please select the folder containing processed data separated by type") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing/Zachary_files/wing_plot_LE_fullShift", "Please select the folder containing processed data separated by type") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

% WE WILL HAVE TO LOOP THROUGH ALL FOLDERS TO GET FILES. I am only going to
% will be using 0 degrees at 0 Hz and 4 Hz

% now let's get the specific file paths
files_data_path = fullfile(data_path);

% remove non-case files
d1 = dir(files_data_path);
d1 = d1([d1.isdir]);                         % keep only directories
d1 = d1(~ismember({d1.name},{'.','..','StRe_data'}));    % drop . and .. and processed St/Re

% initialize dir_paths
wing_paths = strings(0);
for i=1:length(d1)

    wing_path1 = fullfile(data_path, d1(i).name);

    % next folder in wing_batch(i) is wind speed
    d2 = dir(wing_path1);
    d2 = d2([d2.isdir]);                         % keep only directories
    d2 = d2(~ismember({d2.name},{'.','..'}));    % drop . and ..
    wing_path2 = fullfile(wing_path1, d2(1).name); % go into first folder (should be 3 or 6 m.s)

    % next folder is a name
    d3 = dir(wing_path2);
    d3 = d3([d3.isdir]);
    d3 = d3(~ismember({d3.name},{'.','..'}));
    wing_path3 = fullfile(wing_path2, d3(1).name); % again into first folder

    % now get to files folder. We want 3 Hz, 0 degrees for this one
    wing_path4 = fullfile(wing_path3, "processed data");
    d4 = dir(wing_path4);
    files = strings(0);
    for j=1:numel(d4) % numel is length of directory
        if (contains(d4(j).name, "0Hz") || contains(d4(j).name, "4Hz")) && contains(d4(j).name, " 0deg")
            files = [files d4(j).name];
        end
    end
    
    for j = 1:length(files)
        final_wing_path = fullfile(wing_path4, files(j));
        wing_paths = [wing_paths final_wing_path];
    end
end

raw_results = struct('type', {}, 'freq', {}, 'wind_speed', {}, "reynolds", {}, "strouhal", {}, 'AoA', {}, ...
    'wing_span', {}, 'wing_chord', {}, 'wing_length', {},'amp', {}, 'time_data', {},'num_beats', {},...
    'drag_raw', {}, 'trans_raw', {}, 'lift_raw', {}, 'roll_raw', {}, 'pitch_raw', {}, 'yaw_raw', {},...
    'drag_filt', {}, 'trans_filt', {}, 'lift_filt', {}, 'roll_filt', {}, 'pitch_filt', {}, 'yaw_filt', {});

AoA_options = -16:2:24;
count = 1; % this will be the position in the array
for i=1:length(wing_paths)

    % now we will load the data from this specific file
    fname = wing_paths(i);
    raw_data = load(fname); % this will give us workspace with avg_forces and names

    current_wind_speed = double(extractBetween(fname, " 20 ", "m.s"));

    % pull out relevant info
    raw_freq = double(extractBetween(fname, "deg ", "Hz 2026")); % remove Hz and make double

    % now extract raw forces from force_data
    raw_results(count).drag_raw = raw_data.force_data(1,:);
    raw_results(count).trans_raw = raw_data.force_data(2,:);
    raw_results(count).lift_raw = raw_data.force_data(3,:);
    raw_results(count).roll_raw = raw_data.force_data(4,:);
    raw_results(count).pitch_raw = raw_data.force_data(5,:);
    raw_results(count).yaw_raw = raw_data.force_data(6,:);

    % now extract filtered forces from filtered_data (this is used in
    % compare_trials_AoA)
    raw_results(count).drag_filt = raw_data.filtered_data(1,:);
    raw_results(count).trans_filt = raw_data.filtered_data(2,:);
    raw_results(count).lift_filt = raw_data.filtered_data(3,:);
    raw_results(count).roll_filt = raw_data.filtered_data(4,:);
    raw_results(count).pitch_filt = raw_data.filtered_data(5,:);
    raw_results(count).yaw_filt = raw_data.filtered_data(6,:);

    % now add to results structured array
    raw_results(count).type = extractBetween(fname, " m.s/", "_2026");
    raw_results(count).freq = raw_freq;
    raw_results(count).AoA = double(extractBetween(fname, "m.s ", "deg "));
    raw_results(count).wind_speed = current_wind_speed;
    raw_results(count).amp = 20; % degrees
    raw_results(count).time_data = raw_data.time_data';
    raw_results(count).num_beats = 180;

    % now calculate estimate Reynlolds

    nu = 0.00001529; % at 22.5 degrees celcius

    % to pull out chord from wingtype

    % save wing geometry
    if raw_results(count).type == "default"
        raw_results(count).wing_span = 0.177; % meters, length of single wing
        raw_results(count).wing_chord = 0.073; % meters
        raw_results(count).wing_length = 0.201; % meters, distance from wingtip to axis of rotation
    elseif raw_results(count).type == "chord_half"
        raw_results(count).wing_span = 0.177;
        raw_results(count).wing_chord = 0.0365;
        raw_results(count).wing_length = 0.201;
    elseif raw_results(count).type == "span_half"
        raw_results(count).wing_span = 0.0885;
        raw_results(count).wing_chord = 0.073;
        raw_results(count).wing_length = 0.1125;
    else
        error("Type not found. No geometry values for Reynolds Number calculation")
    end

    % gets double value
    reynolds_estimate = current_wind_speed * raw_results(count).wing_chord / nu;
    raw_results(count).reynolds = round(reynolds_estimate,2,'significant'); % not using exact because of plot sorting
    raw_results(count).strouhal = round(raw_data.St,2,'significant');
    count = count + 1; % each Strouhal will get a different entry in results
end

%% Choose plot type - CUSTOMIZE HERE

% next steps is cutting the data for one wingbeat (time data/180) and then
% plotting!

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
    all_types = strtrim(string({raw_results.type})); % converts types to array of strings
    types_mask = (all_types == plot_type); % creates mask with types we care about
    raw_results = raw_results(types_mask);
end

%% Med AR, 3m/s, 0 deg, 4 Hz case

tol = 1e-3;
for i = 1:length(raw_results)
    if raw_results(i).type == "default"
        if (abs(raw_results(i).freq - 4) < tol) && (abs(raw_results(i).wind_speed - 3) < tol)
            this_flow = raw_results(i);
            break
        end
    end
end
    

% NOW I NEED TO PROCESS MY UNTRIMMED DATA SO THAT IT ISN'T A VOLTAGE

% now load my one specific case for the untrimmed data
load("default_20_3m.s_0deg_4Hz_experiment_2026_02_03_10_02_16.mat") % loads results
% we have to semi-process this data to convert voltages to forces, but we
% won't trim the data

% define offsets
load('default_20_3m.s_0deg_offsets_2026_02_03_09_55_56.mat'); % load in offsets var
offsets = offsets(1,:);

% define cal matrx
calibration_filepath = '/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/DAQ/Calibration Files/Mini40/FT52906.cal'; 
cal_matrix = obtain_cal(calibration_filepath);

% other vars
ticksPerRev = 18432;
OC_pulse_step = 4;
async = 1;

[time_data, force_data, voltAdj, curAdj, speed, OC_pulse_count] = process_data(results, offsets, cal_matrix, ticksPerRev, OC_pulse_step, async);

lift_untrim = force_data(3,:);
time_untrim = time_data(:,1);

% extract values
this_AoA = vertcat(this_flow.AoA);
this_lift_raw = vertcat(this_flow.lift_raw);
this_lift_filt = vertcat(this_flow.lift_filt);
this_time = vertcat(this_flow.time_data);
this_wing_beat = vertcat(this_flow.num_beats);


% Calculate how many samples are in one actual flapping period
dt = mean(diff(this_time)); % time between measurements
fs = 1/dt; % frequency of measurement

samples_per_cycle = round(fs / 4); % points/cycle = points/s * s/cycle

% Ensure we don't exceed the array size
% I'm adding samples_per_cycle because I want to start after one wingbeat
time_period = samples_per_cycle + min(samples_per_cycle, length(this_time)); % to compare static and flapping case

% define num cycles we want to view
n = 5;

% define start and end
start_idx = samples_per_cycle + 1;           % Start after 1st cycle
end_idx   = start_idx + (n * samples_per_cycle) - 1; % Go for n cycles

% start after one beat, end after n cycles
time_beat = this_time(start_idx:end_idx);
lift_beat_filt = this_lift_filt(start_idx:end_idx);
lift_beat_raw = this_lift_raw(start_idx:end_idx);

% get normalzied time beat
% - subtract the minimum so that is starts at zero
% - divide by the length of the time beat (T)
time_beat_normalized = (time_beat - min(time_beat)) / (max(time_beat) - min(time_beat)) * n;

% get colors like before

% New colors to differentiate the strouhal values
colors = lines(3); % for consistent colors
current_color = colors(2,:);
k = 4;
base_hsv = rgb2hsv(current_color); % Convert RGB to HSV
if k == 1
    % Case 1: Bright, High-Energy Pastel
    adjusted_hsv = base_hsv;
    adjusted_hsv(2) = 0.4; % Set a fixed, moderate saturation (not too grey)
    adjusted_hsv(3) = 1.0; % Maximize brightness
else
    % Case 2: Deep, Saturated Bolder version
    adjusted_hsv = base_hsv;
    adjusted_hsv(2) = 1.0; % Maximize saturation (most vivid)
    adjusted_hsv(3) = 0.8; % Drop brightness slightly to make it "richer"
end
plot_color = hsv2rgb(adjusted_hsv); % Convert back to RGB for plotting
chart_edge = [0.15, 0.15, 0.15];
marker_size = 7; % for consistent sizes
line_width = 2;

% now plot!

% figure showing raw data and what is clipped off
figure(1)
grid('on');
ylabel('Lift Force, $L$ [N]', 'Interpreter', 'latex', 'FontSize', 20);
xlabel('Time, $t$ [s]', 'Interpreter', 'latex', 'FontSize', 20);
% title('Lift Force Raw/Clipped')
hold on
plot(time_untrim,lift_untrim,...
    'Marker', 'none', ...
    'MarkerEdgeColor', chart_edge, ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', marker_size, ...
    'LineStyle', '-', ...
    'Color', 'k', ... % for lines
    'LineWidth', line_width,...
    'DisplayName', 'Untrimmed Data')
hold on
plot(this_time,this_lift_raw,...
    'Marker', 'none', ...
    'MarkerEdgeColor', chart_edge, ...
    'MarkerFaceColor', plot_color, ...
    'MarkerSize', marker_size, ...
    'LineStyle', '-', ...
    'Color', plot_color, ... % for lines
    'LineWidth', line_width,...
    'DisplayName', 'Trimmed Data')
legend('show', 'Location','bestoutside')
hold off

figure(2)
grid('on');
ylabel('Lift Force, $L$ [N]', 'Interpreter', 'latex', 'FontSize', 20);
xlabel('Normalized Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
% title('Lift Force Filtered')
hold on
plot(time_beat_normalized, lift_beat_raw,...
    'Marker', 'none', ...
    'MarkerEdgeColor', chart_edge, ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', marker_size, ...
    'LineStyle', '-', ...
    'Color', 'k', ... % error bar colors
    'LineWidth', line_width,...
    'DisplayName', 'Unfiltered Data')
% Raw Mean Line (Blue)
yline(mean(this_lift_raw), 'Color', [0.75 0.75 0.75], 'LineWidth', 4, 'LineStyle', '-', 'DisplayName', 'Unfiltered Mean');
plot(time_beat_normalized, lift_beat_filt,...
    'Marker', 'none', ...
    'MarkerEdgeColor', chart_edge, ...
    'MarkerFaceColor', plot_color, ...
    'MarkerSize', marker_size, ...
    'LineStyle', '-', ...
    'Color', plot_color, ... % error bar colors
    'LineWidth', line_width, ...
    'DisplayName', 'Filtered Data')
% Filtered Mean Line (Red)
yline(mean(this_lift_filt), 'r', 'LineWidth', line_width, 'LineStyle', '--', 'DisplayName', 'Filtered Mean');


legend('show', 'Location','bestoutside')
hold off

%% Now save
% 
% % Make folder
% plotFolder = fullfile(data_path, 'raw_data_plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1:2];
% figNames = ["lift_clipped_medAR14", "lift_filtered_medAR14"];
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

%% Plot Panels forces as a function of time - GETTING RID BECAUSE ONLY DOING ONE TYPE

% % types = chord_half, span_half, default
% unique_types = unique(string({raw_results.type}));
% num_types = length(unique_types);
% 
% % Wind speeds OR Reynolds numbers depending on flow_char (ABOVE)
% flow_types = double(unique(string({raw_results.(flow_char)})));
% num_flows = length(flow_types);
% 
% % symbology
% colors = lines(num_types); % for consistent colors
% marker_size = 7; % for consistent sizes
% markers = ['o', '^', 'p']; % circle, triangle, pentagram
% chart_edge = [0.15, 0.15, 0.15];
% line_width = 2;
% 
% count = 1;
% 
% % we want 6 plots for the 6 flow types
% for i=1:num_types % should be 3 types
% 
%     current_color = colors(i,:); % for plotting
% 
%     % filter results to only have type we want
%     type_idx = (string({raw_results.type}) == unique_types(i));
%     this_type = raw_results(type_idx);
% 
%     % loop for different flows within type (because legend entry depends on which flow)
%     for j=1:num_flows % 3 Reynolds options, but each wing type only has 2
% 
%         current_marker = markers(j); % for plotting
% 
%         % filter results to only have speed we want (must use tolerance)
%         % Define a small tolerance
%         tol = 1e-3;
%         flow_vals = [this_type.(flow_char)];
%         flow_idx = abs(flow_vals - flow_types(j)) < tol;
%         this_flow = this_type(flow_idx);
% 
%         if ~isempty(this_flow) % because not every flow type has all the reynolds options
% 
%             % extract and sort Strouhal
%             this_freq = vertcat(this_flow.freq);
%             [freq_sorted, sort_idx] = sort(this_freq);
%             num_freq = length(freq_sorted);
% 
%             % now figure out plotting for Re vs wind speed
%             if flow_char == "reynolds"
%                 sig_fig_Re = round(flow_types(j), 2, 'significant'); % first do 2 sig fics
%                 flow_val = sprintf('%.0f', sig_fig_Re); % convert to string and show no decimals
%             else
%                 flow_val = string(flow_types(j));
%             end
% 
%             % These panels are commented out because we only want to focus
%             % on lift
%            
%             % % define plot panel
%             % fig = figure(count);
%             % % Make the window wide so the 3 panels aren't squished
%             % 
%             % % Create layout and store the handle 'tlo'
%             % tlo = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'tight');
%             % 
%             % % Pre-create the axes so they persist through both iterations of k
%             % ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
%             % ylabel(ax1, 'Drag Force, $D$ [N]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax1, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
%             % ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
%             % ylabel(ax2, 'Transverse Force [N]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax2, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
%             % ax3 = nexttile; hold(ax3, 'on'); grid(ax3, 'on');
%             % ylabel(ax3, 'Lift Force, $L$ [N]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax3, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
%             % ax4 = nexttile; hold(ax4, 'on'); grid(ax4, 'on');
%             % ylabel(ax4, 'Roll Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax4, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
%             % ax5 = nexttile; hold(ax5, 'on'); grid(ax5, 'on');
%             % ylabel(ax5, 'Pitch Moment, $M$ [N-m]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax5, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
%             % ax6 = nexttile; hold(ax6, 'on'); grid(ax6, 'on');
%             % ylabel(ax6, 'Yaw Moment [N-m]', 'Interpreter', 'latex', 'FontSize', 20);
%             % xlabel(ax6, 'Time, $t/T$', 'Interpreter', 'latex', 'FontSize', 20);
% 
%             % Set the OVERALL title for the whole figure
%             % title(tlo, "Raw Cycle Data: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit + ", $\alpha = 0$ deg", ...
%             %     'Interpreter', 'latex', 'FontSize', 16);
% 
%             for k = num_freq % only doing the flapping, 4Hz case
% 
%                 curr_freq = this_freq(k,1);
% 
%                 % New colors to differentiate the strouhal values
%                 base_hsv = rgb2hsv(current_color); % Convert RGB to HSV
%                 if k == 1
%                     % Case 1: Bright, High-Energy Pastel
%                     adjusted_hsv = base_hsv;
%                     adjusted_hsv(2) = 0.4; % Set a fixed, moderate saturation (not too grey)
%                     adjusted_hsv(3) = 1.0; % Maximize brightness
%                 else
%                     % Case 2: Deep, Saturated Bolder version
%                     adjusted_hsv = base_hsv;
%                     adjusted_hsv(2) = 1.0; % Maximize saturation (most vivid)
%                     adjusted_hsv(3) = 0.8; % Drop brightness slightly to make it "richer"
%                 end
%                 plot_color = hsv2rgb(adjusted_hsv); % Convert back to RGB for plotting
% 
%                 % extract values
%                 this_AoA = vertcat(this_flow(k).AoA);
%                 this_drag_raw = vertcat(this_flow(k).drag_raw);
%                 this_trans_raw = vertcat(this_flow(k).trans_raw);
%                 this_lift_raw = vertcat(this_flow(k).lift_raw);
%                 this_roll_raw = vertcat(this_flow(k).roll_raw);
%                 this_pitch_raw = vertcat(this_flow(k).pitch_raw);
%                 this_yaw_raw = vertcat(this_flow(k).yaw_raw);
%                 this_drag_filt = vertcat(this_flow(k).drag_filt);
%                 this_trans_filt = vertcat(this_flow(k).trans_filt);
%                 this_lift_filt = vertcat(this_flow(k).lift_filt);
%                 this_roll_filt = vertcat(this_flow(k).roll_filt);
%                 this_pitch_filt = vertcat(this_flow(k).pitch_filt);
%                 this_yaw_filt = vertcat(this_flow(k).yaw_filt);
%                 this_time = vertcat(this_flow(k).time_data);
%                 this_wing_beat = vertcat(this_flow(k).num_beats);
% 
%                 % now extract over one period/wing beat
%                 time_period = round(size(this_time, 2)./this_wing_beat); % finds the amount of columns per wingbeat to define array size
% 
%                 % Calculate how many samples are in one actual flapping period
%                 dt = mean(diff(this_time)); % time between measurements
%                 fs = 1/dt; % frequency of measurement
% 
%                 if raw_freq > 0
%                     samples_per_cycle = round(fs / raw_freq); % points/cycle = points/s * s/cycle
%                 else
%                     samples_per_cycle = length(this_time); % For 0Hz static cases, show the whole window
%                 end
% 
%                 % Ensure we don't exceed the array size
%                 % I'm adding samples_per_cycle because I want to start after one wingbeat
%                 time_period = samples_per_cycle + min(samples_per_cycle, length(this_time)); % to compare static and flapping case
% 
%                 % define num cycles we want to view
%                 n = 3;
% 
%                 % start after one beat, end after n cycles
%                 time_beat = this_time(samples_per_cycle:time_period*n);
%                 drag_beat = this_drag_filt(samples_per_cycle:time_period*n);
%                 trans_beat = this_trans_filt(samples_per_cycle:time_period*n);
%                 lift_beat = this_lift_filt(samples_per_cycle:time_period*n);
%                 roll_beat = this_roll_filt(samples_per_cycle:time_period*n);
%                 pitch_beat = this_pitch_filt(samples_per_cycle:time_period*n);
%                 yaw_beat = this_yaw_filt(samples_per_cycle:time_period*n);
% 
%                 % get normalzied time beat
%                 % - subtract the minimum so that is starts at zero
%                 % - divide by the length of the time beat (T)
%                 time_beat_normalized = ((time_beat - min(time_beat)) / (max(time_beat) - min(time_beat)))*n;
% 
%                 % now plot!
% 
% 
%                 % plot(ax1, time_beat_normalized,drag_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width,...% for error bars
%                 %     'DisplayName', "Frequency$ = $" + num2str(round(curr_freq, 2, 'significant')) + " Hz")
%                 % 
%                 % plot(ax2, time_beat_normalized, trans_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width) % for error bars
%                 % 
%                 % plot(ax3, time_beat_normalized, lift_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width) % for error bars
%                 % 
%                 % plot(ax4, time_beat_normalized, roll_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width) % for error bars
%                 % 
%                 % plot(ax5, time_beat_normalized, pitch_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width) % for error bars
%                 % 
%                 % plot(ax6, time_beat_normalized, yaw_beat,...
%                 %     'Marker', 'none', ...
%                 %     'MarkerEdgeColor', chart_edge, ...
%                 %     'MarkerFaceColor', plot_color, ...
%                 %     'MarkerSize', marker_size, ...
%                 %     'LineStyle', '-', ...
%                 %     'Color', plot_color, ... % error bar colors
%                 %     'LineWidth', line_width) % for error bars
%             end
% 
%             count = count + 1;
%         end
% 
%     end
% end
% 
% % change all font sizes
% for i = 1:12
%     figure(i)
%     % FONTS
%     fontsize(gcf, 18, 'points');
% 
%     % legend
%     lgd = legend('Orientation', 'horizontal', 'Interpreter', 'latex');
%     lgd.Layout.Tile = 'south'; % Moves it to the bottom of all 3 panels
%     lgd.FontSize = 16;
%     lgd.ItemTokenSize = [10, 18];
%     lgd.NumColumns = 2; % to split up legend into rows
% end

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
% 
% % Make folder
% plotFolder = fullfile(data_path, 'raw_data_plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1:6];
% figNames = ["raw_plots_highAR14", "raw_plots_highAR72", "raw_plots_mediumAR14", "raw_plots_mediumAR29",...
%     "raw_plots_lowAR14", "raw_plots_lowAR29"];
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