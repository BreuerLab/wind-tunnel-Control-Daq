% used to extract forces and moment from data that has already undergone
% processing, subtracting, and shifting --> after compare_trials_AoA

clc
clear
close all
close all hidden % for ANCOVA Stats tables

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
    "max_clcd", {}, "max_clcd_AoA", {}, "err_efficiency", {}, "effic_array", {}, "stall_angle", {}, "stall_fit_RMSE", {}, "C_L_stall_fit", {}, "C_L_stall_slope", {},...
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

%% Instantiate Results (structured array)

% Now we will extract the values as a vertical concatenation
% (unfortunately, we must extract from structured array to do operations)
% Transpose so it sees four columns/series -> corresponds with 4 Strouhal in legend
plot_AoA = vertcat(results.AoA)';
plot_St = vertcat(results.strouhal)';
plot_C_D = vertcat(results.drag_coeff)';
plot_C_L = vertcat(results.lift_coeff)';
plot_C_M = vertcat(results.pitch_coeff)';

% do the same thing with the errors
plot_err_lift = vertcat(results.err_lift)';
plot_err_drag = vertcat(results.err_drag)';
plot_err_pitch = vertcat(results.err_pitch)';

% We only want to perform linear regression on -4<AoA<10 (linear region)
lower_lim = -4;
upper_lim = 10;

% filter based on limits
AoA_idx = plot_AoA(:,1) >= lower_lim & plot_AoA(:,1) <= upper_lim;
linear_AoA = plot_AoA(AoA_idx, :); % mask rows, not columns (cases)
linear_C_L = plot_C_L(AoA_idx, :);
linear_C_M = plot_C_M(AoA_idx, :);
linear_C_D = plot_C_D(AoA_idx, :); % obviously C_D is parabolic, but we are evaluating in same region

% instantiate arrays
num_trials = length(results); % for instantiating third dimension

r_sqr_error_count = 0;
for i=1:num_trials

    % LINEAR REGRESSION

    % call getStats helper function which performs an an ordinary least
    % squares regression on lift and pitch slope as well as C_D vs (C_L)^2:
    % [intercept, slope, Rsq, slope_error, intercept_error, residuals] = getStats(x_var, y_var)

    % define linear AoA, C_L, etc for this specific trial
    trial_lin_AoA = linear_AoA(:,i);
    trial_lin_cl = linear_C_L(:,i);
    trial_lin_cm = linear_C_M(:,i);
    trial_lin_cd = linear_C_D(:,i);

    % lift_slope (C_L vs AoA)

    [results(i).lift_intercept, results(i).lift_slope, results(i).lift_Rsq,...
        results(i).lift_slope_error, results(i).lift_intercept_error, results(i).lift_residuals] = getStats(trial_lin_AoA, trial_lin_cl);

    % pitch_slope (C_M vs AoA)
    [results(i).pitch_intercept, results(i).pitch_slope, results(i).pitch_Rsq,...
        results(i).pitch_slope_error, results(i).pitch_intercept_error, results(i).pitch_residuals] = getStats(trial_lin_AoA, trial_lin_cm);

    % drag_slope (C_D vs C_L^2, where CD = C_D0 + k*C_L^2)
    [results(i).C_D0, results(i).induced_drag, results(i).k_Rsq,...
        results(i).k_slope_error, results(i).C_D0_intercept_error, results(i).drag_residuals] = getStats(trial_lin_cl.^2, trial_lin_cd);

    % now warn if R_sq values suck
    if results(i).lift_Rsq < 0.98
        warning("Lift Slope: R^2 = %s (%s)", num2str(results(i).lift_Rsq), (results(i).type + ", St = " + num2str(results(i).strouhal)))
        r_sqr_error_count = r_sqr_error_count + 1;
    end
    if results(i).pitch_Rsq < 0.98
        warning("Pitch Slope: R^2 = %s (%s)", num2str(results(i).pitch_Rsq), (results(i).type + ", St = " + num2str(results(i).strouhal)))
        r_sqr_error_count = r_sqr_error_count + 1;
    end
    if results(i).k_Rsq < 0.98
        warning("Induced Drag Slope: R^2 = %s (%s)", num2str(results(i).k_Rsq), (results(i).type + ", St = " + num2str(results(i).strouhal)))
        r_sqr_error_count = r_sqr_error_count + 1;
    end
    

    % Efficiency and stall angle are in the non-linear portions too, so we'll define the relevant vars
    trial_plot_AoA = plot_AoA(:,i);
    trial_plot_cl = plot_C_L(:,i);
    trial_plot_cd = plot_C_D(:,i);
    trial_err_lift = plot_err_lift(:,i);
    trial_err_drag = plot_err_drag(:,i);

    % AERO EFFICIENCY

    % [max_efficiency, max_clcd_AoA, err_efficiency, effic_array] = find_aeroEfficiency(plot_C_L, plot_C_D, plot_AoA, err_lift, err_drag)
    [results(i).max_clcd, results(i).max_clcd_AoA, results(i).err_efficiency, results(i).effic_array] ...
        = find_aeroEfficiency(trial_plot_cl, trial_plot_cd, trial_plot_AoA, trial_err_lift, trial_err_drag);

    % STALL ANGLE

    % [stall_angle, stall_error_deg, C_L_smoothed, C_L_slope] = find_stallAngle(plot_C_L, plot_AoA)
    [results(i).stall_angle, results(i).stall_fit_RMSE,results(i).C_L_stall_fit,...
        results(i).C_L_stall_slope] = find_stallAngle(trial_plot_cl, trial_plot_AoA);

end
r_sqr_error_count

%% Plotting loops of analyses

figure(1)
% title("Lift Coefficient Slope vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Lift Coefficient Slope, $dC_L /d\alpha$", 'Interpreter','latex')
hold on

figure(2)
% title("Pitch Coefficient Slope (LE) vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Pitch Coefficient Slope, $dC_M /d\alpha$", 'Interpreter','latex')
hold on

figure(3)
% title("Parasite Drag Coefficient at Zero Lift vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Parasite Drag Coefficient at Zero Lift, $C_{D0}$", 'Interpreter','latex')
hold on

figure(4)
% title("Induced Drag Factor vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Induced Drag Factor, $k$", 'Interpreter','latex')
hold on

figure(5)
% title("Maximum Aerodynamic Efficiency vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Maximum Aerodynamic Efficiency, $(C_L / C_D)_{max}$", 'Interpreter','latex')
hold on

figure(6)
% title("Stall Angle vs Strouhal")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Stall Angle, $\alpha_{stall}$ [deg]", 'Interpreter','latex')
hold on

figure(99)
% title("Lift Coefficient at \alpha = 0")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Lift Coefficient, $C_L$, at $\alpha=0^\circ$", 'Interpreter','latex')
hold on

figure(100)
% title("Lift Coefficient at \alpha = 0")
xlabel("Strouhal Number", 'Interpreter','latex')
ylabel("Pitch Coefficient, $C_M$, at $\alpha=0^\circ$", 'Interpreter','latex')
hold on

% types = chord_half, span_half, default
unique_types = unique(string({results.type}));
num_types = length(unique_types);

% Wind speeds OR Reynolds numbers depending on flow_char (ABOVE)
flow_types = double(unique(string({results.(flow_char)})));
flow_types = sort(flow_types, 'ascend'); % sort so that it plots sorted
num_flows = length(flow_types);

% RESET SYMBOLOGY
colors = lines(num_types); % for consistent colors
marker_size = 12; % for consistent sizes
markers = ['p', 'o', '^']; % pentagram, circle, triangle
count = 1; % for overlay figure numbers

% loop for different types
for i=1:num_types % should be 3 types

    current_color = colors(i,:); % for plotting

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

            % now figure out plotting for Re vs wind speed
            if flow_char == "reynolds"
                sig_fig_Re = round(flow_types(j), 2, 'significant'); % first do 2 sig fics
                flow_val = sprintf('%.0f', sig_fig_Re); % convert to string and show no decimals
            else
                flow_val = string(flow_types(j));
            end

            % extract AOA values
            this_AoA = vertcat(this_flow.AoA);

             % LIFT SLOPE
            this_lift_slope = vertcat(this_flow.lift_slope);
            this_lift_slope_error = vertcat(this_flow.lift_slope_error);

            % now sort them because Strouhal not in proper order
            lift_slope_sorted = this_lift_slope(sort_idx);
            lift_slope_error_sorted = this_lift_slope_error(sort_idx);


            % plot lift 
            figure(1)
            errorbar(str_sorted, lift_slope_sorted, lift_slope_error_sorted, ...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % PITCH SLOPE

            this_pitch_slope = vertcat(this_flow.pitch_slope);
            pitch_slope_sorted = this_pitch_slope(sort_idx);

            this_pitch_slope_error = vertcat(this_flow.pitch_slope_error);
            pitch_slope_error_sorted = this_pitch_slope_error(sort_idx);

            figure(2)
            errorbar(str_sorted, pitch_slope_sorted, pitch_slope_error_sorted,...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % % Now Rónán's function! (DOESN'T WORK BECAUSE OF GLIDING)
            % 
            % this_wing_span = vertcat(this_flow.wing_span);
            % wing_span_sorted = this_wing_span(sort_idx);
            % this_wing_length = vertcat(this_flow.wing_length);
            % wing_length_sorted = this_wing_length(sort_idx);
            % this_amp = vertcat(this_flow.amp); % will all be 20
            % amp_sorted = deg2rad(this_amp(sort_idx));
            % % ao = mean(pitch_slope_sorted(2:end)); % I want the average of the slopes, not including 0 St
            % ao = pitch_slope_sorted(1); % gliding case
            % 
            % l = wing_span_sorted./wing_length_sorted;
            % bes0 = besselj(0, amp_sorted);
            % bes1 = besselj(1, amp_sorted);
            % pitch_slope_equation = ao .* (bes0 + ((2*(pi)^2)/3)*(l.^2-3.*l+3).*(bes1./amp_sorted).*str_sorted);
            % 
            % plot(str_sorted,pitch_slope_equation,...
            %     'Marker', 'none', ...
            %     'LineStyle', '-', ...
            %     'Color', current_color, ... % error bar colors
            %     'LineWidth', 1, ...         
            %     'DisplayName', 'QSBE Model: ' + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % DRAG

            % parasitic drag
            this_C_D0 = vertcat(this_flow.C_D0);
            C_D0_sorted = this_C_D0(sort_idx);

            % CALC C_D0 ERROR
            this_C_D0_intercept_error = vertcat(this_flow.C_D0_intercept_error);
            C_D0_error_sorted = this_C_D0_intercept_error(sort_idx);

            figure(3)
            errorbar(str_sorted, C_D0_sorted,C_D0_error_sorted, ...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % induced drag factor
            this_induced_drag = vertcat(this_flow.induced_drag);
            induced_drag_sorted = this_induced_drag(sort_idx);

            % error
            this_induced_drag_error = vertcat(this_flow.k_slope_error);
            induced_drag_error_sorted = this_induced_drag_error(sort_idx);


            figure(4)
            errorbar(str_sorted, induced_drag_sorted, induced_drag_error_sorted, ...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % AERO EFFICIENCY

            this_aero_effic = vertcat(this_flow.max_clcd);
            aero_effic_sorted = this_aero_effic(sort_idx);

            % error
            this_aero_effic_error = vertcat(this_flow.err_efficiency);
            aero_effic_error_sorted = this_aero_effic_error(sort_idx);

            figure(5)
            errorbar(str_sorted, aero_effic_sorted, aero_effic_error_sorted,...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % STALL ANGLE

            this_stall_angle = vertcat(this_flow.stall_angle);
            stall_angle_sorted = this_stall_angle(sort_idx);

            % RMSE here represents the lift fit, so it doesn't make sense to plot on these figures!
            % instead, we will say error is 1 degree because we tested AoA at every 2 degrees

            this_stall_angle_error = vertcat(this_flow.stall_fit_RMSE);
            stall_angle_error_sorted = this_stall_angle_error(sort_idx);
            % stall_angle_error_sorted = ones(size(C_D0_error_sorted));

            figure(6)
            errorbar(str_sorted, stall_angle_sorted, stall_angle_error_sorted, ...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % now lift and pitch at zero angle of attack
            
            this_lift_coeff = vertcat(this_flow.lift_coeff);
            zero_ang_lift = this_lift_coeff(:,9);

            figure(99)
            plot(str_sorted, zero_ang_lift,...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            this_pitch_coeff = vertcat(this_flow.pitch_coeff);
            zero_ang_pitch = this_pitch_coeff(:,9);

            figure(100)
            plot(str_sorted, zero_ang_pitch,...
                'Marker', current_marker, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', current_color, ...
                'MarkerSize', marker_size, ...
                'LineStyle', 'none', ...
                'Color', current_color, ... % error bar colors
                'LineWidth', 1, ...         % for error bars
                'DisplayName', typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit)

            % REGRESSION FITS

            num_str = length(str_sorted);

            % for custom ylimits
            ymin_lift = 0;
            ymax_lift = 0;
            ymin_pitch = 0;
            ymax_pitch = 0;
            ymin_drag = 0;
            ymax_drag = 0;
            ymin_effic = 0;
            ymax_effic = 0;
            ymin_stall = 0;
            ymax_stall = 0;
            ymin_stall_slope = 0;
            ymax_stall_slope = 0;

            % define plot panel
            fig_h = figure(6 + count);
            % Make the window wide so the 3 panels aren't squished

            % Create layout and store the handle 'tlo'
            tlo = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'tight');

            % Pre-create the axes so they persist through both iterations of k
            ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
            ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
            ax3 = nexttile; hold(ax3, 'on'); grid(ax3, 'on');

            % Set the OVERALL title for the whole figure
            % title(tlo, "Fit Curves: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, ...
            %     'Interpreter', 'latex', 'FontSize', 16);

            % CL/CD vs AoA
            figure(7+count)
            % title("Efficiency: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, ...
                % 'Interpreter', 'latex', 'FontSize', 16)
            ylabel("Aerodynamic Efficiency, $C_L/C_D$",'Interpreter', 'latex', 'FontSize', 20)
            xlabel("Angle of Attack, $\alpha$ [deg]",'Interpreter', 'latex', 'FontSize', 20)
            hold on
            grid on

            % Stall angle vs AoA

            % define plot panel
            stall_fig = figure(8+count);

            % Create layout and store the handle 'tlo'
            tlo_stall = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'tight');

            % Pre-create the axes so they persist through both iterations of k
            ax1_stall = nexttile; hold(ax1_stall, 'on'); grid(ax1_stall, 'on');
                ylabel(ax1_stall, "Lift Coefficient, $C_L$",'Interpreter', 'latex', 'FontSize', 20);
                % xlabel(ax1_stall, "Angle of Attack, $\alpha$ [deg]",'Interpreter', 'latex', 'FontSize', 20);
            ax2_stall = nexttile; hold(ax2_stall, 'on'); grid(ax2_stall, 'on');
                ylabel(ax2_stall, "Lift Coefficient Slope, $dC_L /d\alpha$",'Interpreter', 'latex', 'FontSize', 20);
                xlabel(ax2_stall, "Angle of Attack, $\alpha$ [deg]",'Interpreter', 'latex', 'FontSize', 20);
            

            % OVERALYED PLOTS for min and max strouhal
            for k = [1, num_str]

                curr_strouhal = round(str_sorted(k), 2, 'significant');

                % New colors to differentiate the strouhal values
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

                % extract values of interest
                this_lift = vertcat(this_flow.lift_coeff);
                this_pitch = vertcat(this_flow.pitch_coeff);
                this_drag = vertcat(this_flow.drag_coeff);

                % we already have slopes
                this_ref_lift_intercept = vertcat(this_flow.lift_intercept);
                this_ref_pitch_intercept = vertcat(this_flow.pitch_intercept);

                % overlay points
                overlay_plot_AoA = this_AoA(k,:);
                overlay_plot_cl = this_lift(k,:);
                overlay_plot_cm = this_pitch(k,:);
                overlay_plot_cd = this_drag(k,:);

                % regression line data
                ref_lift_slope = this_lift_slope(k,:);
                ref_lift_intercept = this_ref_lift_intercept(k,:);

                ref_pitch_slope = this_pitch_slope(k,:);
                ref_pitch_intercept = this_ref_pitch_intercept(k,:);

                ref_drag_slope = this_induced_drag(k,:);
                ref_drag_intercept = this_C_D0(k,:);

                % plot regression (so that I can have a good legend)
                AoA_continuous = linspace(min(overlay_plot_AoA), max(overlay_plot_AoA), 100);
                C_L_continuous = linspace(min(overlay_plot_cl), max(overlay_plot_cl), 100);
                lift_fit = ref_lift_intercept + AoA_continuous .* ref_lift_slope; % lift vs AoA
                pitch_fit = ref_pitch_intercept + AoA_continuous .* ref_pitch_slope; % pitch vs AoA
                drag_fit = ref_drag_intercept + (C_L_continuous.^2) .* ref_drag_slope; % because this is versus CL^2

                % LIFT

                plot(ax1, overlay_plot_AoA, overlay_plot_cl,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1,...% for error bars
                    'DisplayName', sprintf('Data: $St = %.3f$', curr_strouhal))  
                %    'DisplayName', "$St = $" + num2str(round(curr_strouhal, 2, 'significant')))
                hold on
                plot(ax1, AoA_continuous, lift_fit,...
                    'Marker', 'none', ...
                    'LineStyle', '-', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 2, ... % for error bars
                    'DisplayName', sprintf('Fit Curve')) 
                %   'DisplayName', sprintf('Fit Curve: $St = %.3f$', curr_strouhal)) 
                %    'DisplayName',"Linear Fit: $C_{L\alpha} = $" + num2str(round(ref_lift_slope, 2, 'significant')) + "/deg")
                ylabel(ax1, 'Lift Coefficient, $C_L$', 'Interpreter', 'latex', 'FontSize', 20);
                xlabel(ax1, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 20);
                %title(ax1, "Lift: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, 'Interpreter', 'latex','FontSize', 16)

                % for ylim to dynamically change if new one is a lowerlimit
                curr_ymin = min(overlay_plot_cl);
                curr_ymax = max(overlay_plot_cl);
                if curr_ymin < ymin_lift
                    ymin_lift = curr_ymin;
                end
                if curr_ymax > ymax_lift
                    ymax_lift = curr_ymax;
                end
                ylim(ax1, [1.5*ymin_lift 1.25*ymax_lift])

                % lift text

                 text(ax1, 0.05, 0.98 - (k*0.03),... % controls spacing of two boxes
                    sprintf('$dC_L/d\\alpha = %.3f \\hspace{1mm} \\mathrm{deg}^{-1}$', round(ref_lift_slope, 2, 'significant')), ...
                    'Units', 'normalized', ...
                    'FontSize', 14, ...
                    'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', ...
                    'Color', 'k', ... % black font
                    'Interpreter', 'latex', ...
                    'BackgroundColor', [1 1 1 0.8], ... % white and slightly opaque
                    'EdgeColor', plot_color, ... % edge color shows which line
                    'LineWidth', 2, ... % border width
                    'Margin', 2);

                % PITCH

                plot(ax2, overlay_plot_AoA, overlay_plot_cm,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1) % for error bars
                %    'DisplayName',"$St = $" + num2str(round(curr_strouhal, 2, 'significant')))
                hold on
                plot(ax2, AoA_continuous, pitch_fit,...
                    'Marker', 'none', ...
                    'LineStyle', '-', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 2) % for error bars
                %    'DisplayName', "Linear Fit: $C_{M\alpha} = $" + num2str(round(ref_pitch_slope, 2, 'significant')) + "/deg")
                ylabel(ax2, 'Pitch Coefficient, $C_M$', 'Interpreter', 'latex', 'FontSize', 20);
                xlabel(ax2, 'Angle of Attack, $\alpha$ [deg]', 'Interpreter', 'latex', 'FontSize', 20);
                %title(ax2, "Pitch: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, 'Interpreter', 'latex','FontSize', 16)
                % for ylim to dynamically change if new one is a lowerlimit
                curr_ymin = min(overlay_plot_cm);
                curr_ymax = max(overlay_plot_cm);
                if curr_ymin < ymin_pitch
                    ymin_pitch = curr_ymin;
                end
                if curr_ymax > ymax_pitch
                    ymax_pitch = curr_ymax;
                end
                ylim(ax2, [1.25*ymin_pitch 1.25*ymax_pitch])

                % pitch text
                text(ax2, 0.43, 0.98 - (k*0.03),... % controls spacing of two boxes
                    sprintf('$dC_M/d\\alpha = %.3f \\hspace{1mm} \\mathrm{deg}^{-1}$', round(ref_pitch_slope, 2, 'significant')), ...
                    'Units', 'normalized', ...
                    'FontSize', 14, ...
                    'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', ...
                    'Color', 'k', ... % black font
                    'Interpreter', 'latex', ...
                    'BackgroundColor', [1 1 1 0.8], ... % white and slightly opaque
                    'EdgeColor', plot_color, ... % edge color shows which line
                    'LineWidth', 2, ... % border width
                    'Margin', 2);

                % DRAG

                plot(ax3, overlay_plot_cl, overlay_plot_cd,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1)  % for error bars
                %    'DisplayName', "$St = $" + num2str(round(curr_strouhal, 2, 'significant')))
                hold on
                plot(ax3, C_L_continuous, drag_fit,...
                    'Marker', 'none', ...
                    'LineStyle', '-', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 2)       % for error bars
                %    'DisplayName',"Linear Fit: $k = $" + num2str(round(ref_drag_slope, 2, 'significant')) + ", $C_{D0} = " + num2str(round(ref_drag_intercept, 2, 'significant')))
                ylabel(ax3, 'Drag Coefficient, $C_D$', 'Interpreter', 'latex', 'FontSize', 20);
                xlabel(ax3, 'Lift Coefficient, $C_L$', 'Interpreter', 'latex', 'FontSize', 20);
                %title(ax3, "Drag vs Lift: " + typeToTitle(unique_types(i)) + ", " + flow_descrip + flow_val + flow_unit, 'Interpreter', 'latex','FontSize', 16)

                % for ylim to dynamically change if new one is a lowerlimit
                curr_ymin = min(overlay_plot_cd);
                curr_ymax = max(overlay_plot_cd);
                if curr_ymin < ymin_drag
                    ymin_drag = curr_ymin;
                end
                if curr_ymax > ymax_drag
                    ymax_drag = curr_ymax;
                end
                ylim(ax3, [1.25*ymin_drag 1.25*ymax_drag])

                % drag text
                text(ax3, 0.05, 0.98 - (k*0.03),... % controls spacing of two boxes
                    sprintf('$k = %.3f \\hspace{1mm} \\mathrm{deg}^{-1}$, $C_{D0} = %.3f$', round(ref_drag_slope, 2, 'significant'), round(ref_drag_intercept, 2, 'significant')), ...
                    'Units', 'normalized', ...
                    'FontSize', 14, ...
                    'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', ...
                    'Color', 'k', ... % black font
                    'Interpreter', 'latex', ...
                    'BackgroundColor', [1 1 1 0.8], ... % white and slightly opaque
                    'EdgeColor', plot_color, ... % edge color shows which line
                    'LineWidth', 2, ... % border width
                    'Margin', 2);

                % AEOR EFFICIENCY PLOTS
                this_effic_array = horzcat(this_flow.effic_array)'; 
                ref_effic_array = this_effic_array(k,:);
                max_effic = this_flow(k).max_clcd;

                pos_idx = (overlay_plot_AoA >= 0);
                pos_AoA = overlay_plot_AoA(pos_idx);
                pos_cl = overlay_plot_cl(pos_idx);

                figure(7+count)

                % plot efficiencies
                plot(pos_AoA, ref_effic_array,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1,...
                     'DisplayName', sprintf('$St = %.3f$', curr_strouhal))

                % Now plot interpolation
                % Create a fine grid for a smooth slope line
                AoA_fine = linspace(min(pos_AoA), max(pos_AoA), 500);
                effic_fine = interp1(pos_AoA, ref_effic_array, AoA_fine, 'pchip');

                % Plot THIS as your yellow line instead of the discrete points
                plot(AoA_fine, effic_fine, ':', 'Color', plot_color, 'LineWidth', 2,...
                    'DisplayName', 'S-G Interpolation');

                % plot max efficiency line
                yline(max_effic,...
                    'LineStyle', '-', ...
                    'Color', [plot_color, 0.2], ... $ for transparency
                    'LineWidth', 3, ...
                    'DisplayName', sprintf('$(C_L/C_D)_{max} = %.2f', max_effic))
                %    'DisplayName', sprintf('$(C_L/C_D)_{max} = %.2f \\hspace{1mm} (St = %.3f)$', max_effic, curr_strouhal))
                legend("show",'Location','bestoutside','Interpreter','latex',FontSize=20)
                curr_ymin = min(ref_effic_array);
                curr_ymax = max(ref_effic_array);
                if curr_ymin < ymin_effic
                    ymin_effic = curr_ymin;
                end
                if curr_ymax > ymax_effic
                    ymax_effic = curr_ymax;
                end
                ylim([1.25*ymin_effic 1.25*ymax_effic])

                 % STALL ANGLE PLOTS
                this_stall_fit = horzcat(this_flow.C_L_stall_fit)'; 
                ref_stall_fit = this_stall_fit(k,:);
                stall_angle = this_flow(k).stall_angle;

                % for the calculations here, I defined angle of attack as
                % greater than -4. Not changing names here because whatever
                pos_idx = (overlay_plot_AoA >= -4);
                pos_AoA = overlay_plot_AoA(pos_idx);
                pos_cl = overlay_plot_cl(pos_idx);

                % C_L fit
                figure(8+count)
                % pos points
                plot(ax1_stall, pos_AoA, pos_cl,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1,...
                     'DisplayName', sprintf('$St = %.3f$', curr_strouhal))
                % fit line from Savitzky-Golay
                plot(ax1_stall, pos_AoA, ref_stall_fit,...
                    'Marker', 'none', ...
                    'LineStyle', ':', ...
                    'Color', plot_color, ... 
                    'LineWidth', 2,...
                    'DisplayName', sprintf('S-G Interpolation'))
                %    'DisplayName', sprintf('S-G Fit \\hspace{1mm} (St = %.3f)$', curr_strouhal))
                % stall angle
                xline(ax1_stall, stall_angle,...
                    'LineStyle', '-', ...
                    'Color', [plot_color, 0.2], ... $ for transparency
                    'LineWidth', 3, ...
                    'DisplayName', sprintf('$\\alpha_{stall} = %.1f^{\\circ}$', stall_angle))
                %    'DisplayName', sprintf('$\\alpha_{cr} = %.1f^{\\circ} \\hspace{0.5mm} (St = %.3f)$', stall_angle, curr_strouhal))
                legend(ax1_stall, "show",'Location','bestoutside','Interpreter','latex',FontSize=20)
                curr_ymin = min(overlay_plot_cl);
                curr_ymax = max(overlay_plot_cl);
                if curr_ymin < ymin_stall
                    ymin_stall = curr_ymin;
                end
                if curr_ymax > ymax_stall
                    ymax_stall = curr_ymax;
                end
                ylim(ax1_stall, [1.25*ymin_stall 1.25*ymax_stall])

                % derivative fit
                this_stall_slope = horzcat(this_flow.C_L_stall_slope)'; 
                ref_stall_slope = this_stall_slope(k,:);
                stall_angle = this_flow(k).stall_angle;

                % pos points of slope
                plot(ax2_stall, pos_AoA, ref_stall_slope,...
                    'Marker', current_marker, ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', plot_color, ...
                    'MarkerSize', marker_size, ...
                    'LineStyle', 'none', ...
                    'Color', plot_color, ... % error bar colors
                    'LineWidth', 1,...
                     'DisplayName', sprintf('$St = %.3f$', curr_strouhal))
                % Now plot interpolation
                % Create a fine grid for a smooth slope line
                AoA_fine = linspace(min(pos_AoA), max(pos_AoA), 500);
                Slope_fine = interp1(pos_AoA, ref_stall_slope, AoA_fine, 'pchip');

                % Plot THIS as your yellow line instead of the discrete points
                plot(ax2_stall, AoA_fine, Slope_fine, ':', 'Color', plot_color, 'LineWidth', 2,...
                    'DisplayName', 'Gradient Interpolation');

                % 70% condition (horiz line)
                yline(ax2_stall, ref_stall_slope(3)*0.7,...
                    'LineStyle', '-', ...
                    'Color', plot_color, ... 
                    'LineWidth', 3,...
                    'DisplayName', sprintf('Slope Cutoff (70\\%%)'))
                %    'DisplayName', sprintf('Slope Cutoff \\hspace{1mm} (St = %.3f)$', curr_strouhal))
                % stall angle (vert line)
                % xline(ax2_stall, stall_angle,...
                %     'LineStyle', '-', ...
                %     'Color', [plot_color, 0.2], ... $ for transparency
                %     'LineWidth', 3, ...
                %     'DisplayName', sprintf('$\\alpha_{cr} = %.1f^{\\circ}$', stall_angle))
                % %    'DisplayName', sprintf('$\\alpha_{cr} = %.1f^{\\circ} \\hspace{0.5mm} (St = %.3f)$', stall_angle, curr_strouhal))
                legend(ax2_stall, "show",'Location','bestoutside','Interpreter','latex',FontSize=20)
                curr_ymin = min(ref_stall_slope);
                curr_ymax = max(ref_stall_slope);
                if curr_ymin < ymin_stall_slope
                    ymin_stall_slope = curr_ymin;
                end
                if curr_ymax > ymax_stall_slope
                    ymax_stall_slope = curr_ymax;
                end
                ylim(ax2_stall, [1.25*ymin_stall_slope 1.25*ymax_stall_slope])

            end
            % shared legend
            % only calling ax1 because only one with display name and will be repeated for ax2 and ax3
            lgd = legend(ax1, 'Orientation', 'horizontal', 'Interpreter', 'latex'); 
            lgd.Layout.Tile = 'south'; % Moves it to the bottom of all 3 panels
            lgd.ItemTokenSize = [20, 18]; % Increases the length of the line/marker icon
            lgd.FontSize = 20;            % Slightly smaller font can help spacing
            % This adds a small margin between the columns
            set(lgd, 'Box', 'on', 'EdgeColor', [0.8 0.8 0.8]);
            lgd.NumColumns = 2; % to split up legend into rows
            count = count + 3; % so that I plot 2 strouhal on same figure, and there are 3 plots above
        end
    end
end

% Adds legends

for i=[1:6, 99:100]
    figure(i)

    % LEGEND
    legend("show", 'Location','bestoutside')

    % LIMITS
    xlim_values = xlim; % returns [xmin xmax]
    xmin = xlim_values(1);
    xmax = xlim_values(2);
    xlim([-0.005 0.2]) % multiply xmax by 1.1

    grid on

    % ylim_values = ylim; % returns [ymin ymax]
    % ymin = ylim_values(1);
    % ymax = ylim_values(2);
    %
    % % now separate if y is positive or negative to get 10% on each side
    % if ymin < 0
    %     ylim([ymin*1.1 ymax*0.9])
    % else
    %     ylim([ymin*0.9 ymax*1.1])
    % end
end

% change all font sizes
for i = [1:6, 99:100]
    figure(i)
    % FONTS
    fontsize(gcf, 20, 'points');
end

%% STATISTICAL ANALYSIS - ANOVA (OLD)

% % save stats table
% statFolder = fullfile(data_path, 'statistics_tables');
% if ~exist(statFolder, 'dir')
%     mkdir(statFolder);
% end
% 
% Only flapping cases
% flapping_idx = [results.strouhal] > 0;
% results_flapping = results(flapping_idx);
% 
% stat_options = {'lift_slope', 'pitch_slope', 'induced_drag', 'C_D0', 'max_clcd', 'stall_angle'};
% statistics_tables = struct();
% for i = 1:length(stat_options)
% 
%     stat = string(stat_options(i));
% 
%     [p, anova_table, stats] = aoctool([results_flapping.strouhal], [results_flapping.(stat)],...
%         [results_flapping.type] + ',' + [results_flapping.reynolds]);
% 
%     % Extracting values from the 'table' output of aoctool
%     sources = {'Experimental Configuration'; 'Strouhal Number'; 'Interaction'};
%     df = [anova_table{2,2} anova_table{3, 2} anova_table{4, 2}];     % degrees of freedom
%     F_stats = [anova_table{2,5} anova_table{3,5} anova_table{4,5}];  % F-statistics
%     p_values = [anova_table{2,6} anova_table{3,6} anova_table{4,6}]; % p-values
% 
%     % rewrite p values if super small
%     too_small_idx = p_values < 0.0001; % see which ones are small
%     p_strings = string(round(p_values, 4)); % Round values and make string
%     p_strings(too_small_idx) = "< 0.0001"; % change small ones
%     p_values = p_strings;
% 
%     stat_table = table(sources, df', round(F_stats', 4, 'significant'), p_values',...
%         'VariableNames', {'Source', 'Degrees of Freedom', 'F-statistic', 'p-values'});
% 
%     % save to table
%     statistics_tables.(stat) = stat_table;
% 
%     csv_filename = stat + '_stats_table.csv';
%     stats_save_path = fullfile(statFolder, csv_filename);
%     writetable(stat_table, stats_save_path);
% end

%% STATISTICAL ANALYSIS - LinRegress and P-vals (NEW)

% save stats table
statFolder = fullfile(data_path, 'statistics_tables');
if ~exist(statFolder, 'dir')
    mkdir(statFolder);
end

% Only flapping cases
flapping_idx = [results.strouhal] > 0;
results_flapping = results(flapping_idx);

% Now separate out low, med, and high AR

% LOW AR
low_flapping_mask = contains([results_flapping.type], "span_half");
low_flap = results_flapping(low_flapping_mask);

low_flap14_mask = abs([low_flap.reynolds] - 14e3) < 1000;
low_flap14 = low_flap(low_flap14_mask);

low_flap29_mask = abs([low_flap.reynolds] - 29e3) < 1000;
low_flap29 = low_flap(low_flap29_mask);

% MEDIUM AR

med_flapping_mask = contains([results_flapping.type], "default");
med_flap = results_flapping(med_flapping_mask);

med_flap14_mask = abs([med_flap.reynolds] - 14e3) < 1000;
med_flap14 = med_flap(med_flap14_mask);

med_flap29_mask = abs([med_flap.reynolds] - 29e3) < 1000;
med_flap29 = med_flap(med_flap29_mask);

% HIGH AR

high_flapping_mask = contains([results_flapping.type], "chord_half");
high_flap = results_flapping(high_flapping_mask);

high_flap14_mask = abs([high_flap.reynolds] - 14e3) < 1000;
high_flap14 = high_flap(high_flap14_mask);

high_flap72_mask = abs([high_flap.reynolds] - 7.2e3) < 1000;
high_flap72 = high_flap(high_flap72_mask);

flap_cases = {high_flap med_flap low_flap};
AR = ["High \ac{AR}", "Medium \ac{AR}", "Low \ac{AR}"]; 
% flap_cases = {high_flap72 high_flap14 med_flap14 med_flap29 low_flap14 low_flap29};
% AR = ["High \ac{AR} , \ac{Re} $=7200$", "High \ac{AR} , \ac{Re} $=14000$",...
%         "Medium \ac{AR}, \ac{Re} $=14000$", "Medium \ac{AR}, \ac{Re} $=29000$",...
%         "Low \ac{AR}, \ac{Re} $=14000$", "Low \ac{AR}, \ac{Re} $=29000$"]; 

stat_options = {'lift_slope', 'pitch_slope', 'induced_drag', 'C_D0', 'max_clcd', 'stall_angle'};
statistics_tables = struct();
for i = 1:length(stat_options)

    stat = string(stat_options(i));
    case_len = length(flap_cases);

    slopes = zeros(1,case_len);
    rsq_values = zeros(1,case_len);
    p_values = zeros(1,case_len);
    
    for j=1:case_len
        flap_case = flap_cases(j);
        [str_sorted, sort_idx] = sort([flap_case{1,1}.strouhal]);
        case_stat = horzcat(flap_case{1,1}.(stat));
        stat_sorted = case_stat(sort_idx);
        mdl = fitlm(str_sorted, stat_sorted);

        % to view plot
        figure(999)
        plot(mdl)
        % pause(1)

        % now find values
        slopes(j) = round(mdl.Coefficients.Estimate(2), 3, 'significant');
        rsq_values(j) = round(mdl.Rsquared.Ordinary, 3, 'significant');
        p_values(j)= round(mdl.Coefficients.pValue(2), 3, 'significant'); % The p-value for the slope (St)

        % % to compare these values to my manual getStats function
        % [intercept, slope, Rsq, slope_error, intercept_error, residuals] = getStats(str_sorted', stat_sorted');
    end    

    % rewrite p values if super small
    too_small_idx = p_values < 0.001; % see which ones are small
    p_strings = string(round(p_values, 3)); % Round values and make string
    p_strings(too_small_idx) = "$< 0.001$"; % change small ones
    p_values = p_strings;

    stat_table = table(AR', slopes', rsq_values', p_values',...
        'VariableNames', {'Aspect Ratio', 'Trend Slope', '$R^2$', 'p-values'});

    % save to table
    statistics_tables.(stat) = stat_table;

    csv_filename = stat + '_stats_table.csv';
    stats_save_path = fullfile(statFolder, csv_filename);
    writetable(stat_table, stats_save_path);
end

%% Linear Mixed Effects Model (NEW but not as useful)
% 
% % Only flapping cases
% flapping_idx = [results.strouhal] > 0;
% results_flapping = results(flapping_idx);
% 
% stat_options = {'lift_slope', 'pitch_slope', 'induced_drag', 'C_D0', 'max_clcd', 'stall_angle'};
% statistics_tables = struct();
% for i = 1:length(stat_options)
% 
%     stat = string(stat_options(i));
% 
%     AR = [results_flapping.type]';
%     St = [results_flapping.strouhal]';
%     Re = [results_flapping.reynolds]';
%     stat_vals = [results_flapping.(stat)]';
% 
%     stat_table = table(AR, Re, St, stat_vals, ...
%     'VariableNames', {'Aspect_Ratio', 'Reynolds_Number', 'Strouhal', 'stat_vals'});
% 
%     % now run linear mixed effects model
%     formula = 'stat_vals ~ Strouhal + (Strouhal | Aspect_Ratio)';
%     % formula = 'stat ~ Strouhal + (1 | Aspect_Ratio)';
%     lme = fitlme(stat_table,formula);
% end

%% Now save

% % R^2 table
% 
% type_array = [results.type];
% title_array = strings(length([results.type]),1);
% for i = 1:length([results.type])
%     title_array(i) = typeToTitle(type_array(i));
% end
% 
% r_square_table = table(title_array, round([results.reynolds]',2,'significant'),...
%     round([results.strouhal]',2,'significant'), round([results.lift_Rsq]', 4),...
%     round([results.pitch_Rsq]', 4), round([results.k_Rsq]',4),...
%     'VariableNames', {'Wing Types', 'Reynolds Number', 'Strouhal Number',...
%     'Lift $R^2$', 'Pitch $R^2$', 'Drag $R^2$'});
% writetable(r_square_table, 'r_squared.csv');

% % Make folder
% plotFolder = fullfile(data_path, 'dimensionless_analysis_plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1:24, 99:100];
% figNames = ["lift_slope", "pitch_slope", "parasite_drag", "induced_drag",...
%      "aero_efficiency", "stall_angle", "fit_high14", "efficiency_high14", "stall_high14", "fit_high72", "efficiency_high72",...
%      "stall_high72", "fit_med14", "efficiency_med14", "stall_med14", "fit_med29", "efficiency_med29", "stall_med29",...
%      "fit_low14", "efficiency_low14", "stall_low14", "fit_low29", "efficiency_low29", "stall_low29",...
%      "lift_at_zero", "pitch_at_zero"];
% 
% for k = 1:length(figHandles)
%     currentFig = figure(figHandles(k));
%     baseName = fullfile(plotFolder, figNames(k));
% 
%     % 1. Save as MATLAB .fig (for future editing)
%     % saveas(currentFig, baseName + '.fig');
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

function [intercept, slope, Rsq, slope_error, intercept_error, residuals] = getStats(x_var, y_var)
% ordinary least squares regression on function in form y = mx + b

% not instantiating vars because this is complicated, I don't need them to
% save for each trial outside of results, and MATLAB will do it for me

% The backslash operator handles the regression for one trial
% X = [intercept_column, x_coord_column]
X = [ones(size(x_var,1), 1), x_var];

b = X\y_var; % solves y=Xb, where b contains slope and intercepts
intercept = b(1);
slope = b(2);

% now make line of best fit
fit_line = X*b; % gets predicted fitline from regress

% STANDARD ERROR OF SLOPE (look at notes)

% % define residuals
residuals = y_var - fit_line; % standard error of est from real
n = length(y_var);
p = 2; % 2 parameters = slope and intercepts

% Mean Sqare Error from residuals in slope
MSE = sum(residuals.^2) / (n - p); % Mean Squared Error

% % denominator is spread of x
% spread_indep = sum((x_var - mean(x_var)).^2);
%
% % now calculate standard error and 95% confidence interval
% stand_error_slope = sqrt(MSE/spread_indep);
% slope_error = 2.3 * stand_error_slope;
% % 95% confidence interval estimate because critical value from t* is
% % ~2.3 if sample size is small

% Next, we will do LinAlg to get denominators/errors

% Covariance Matrix Calculation: Var(b) = MSE*(X'*X)^-1
% This matrix is 2x2.
% Position (1,1) is the variance of the intercept
% Position (2,2) is the variance of the slope
C = inv(X' * X) * MSE;

% Extract Standard Errors and apply t-distribution multiplier (2.447)
% this is for 95% confidence interval with 6 dof (8 data points - 2
% measured quanitites [slope, intercept] = 6)
% Variances of the individual coefficient estimates are along main diagonal
intercept_error = 2.447 * sqrt(C(1,1));
slope_error = 2.447 * sqrt(C(2,2));

% finally calc R^2
Rsq = 1 - sum((residuals).^2)...
    /sum((y_var - mean(y_var)).^2); % R^2 value

end

function [max_efficiency, max_clcd_AoA, err_efficiency, effic_array] = find_aeroEfficiency(plot_C_L, plot_C_D, plot_AoA, err_lift, err_drag)

% transitioning to S-Golay as well, which will be applied on drag and lift
% to "filter" before calculating aero efficiency. S-G is good here because
% it preserves shape, has a moving filter so doesn't blunt max or min by
% much

% filter results to only have AoA > 0 (because slope = 0 occurs when neg
% too)
pos_idx = plot_AoA >= 0;
AoA_pos = plot_AoA(pos_idx);
C_L_pos = plot_C_L(pos_idx);
C_D_pos = plot_C_D(pos_idx);
err_lift_pos = err_lift(pos_idx);
err_drag_pos = err_drag(pos_idx);

% 1. S-G  filter
order = 2; % means we want a parabola
framelen = 5; % fit three points (middle and two neighbors)
[~, g] = sgolay(order, framelen);

% 2. Calculate the S-G for lift and drag
% g(:,2) contains the 1st derivative filter coefficients
dx = mean(diff(AoA_pos)); % we need to calculate the spacing of the derivative
dy_lift = zeros(length(AoA_pos),2); % predefine array that will solve for derivative
for p=0:1 % p=0 is the filtered function, p=1 is the derivative

    % 'conv' applies the 3-point local slope across the whole array (this is
    % just in MATLAB documentation)
    dy_lift(:,p+1) = conv(C_L_pos, factorial(p)/(-dx)^p * g(:,p+1), 'same');
end

% now exctracting other values for plotting
lift_smoothed = dy_lift(:,1);

dx = mean(diff(AoA_pos)); % we need to calculate the spacing of the derivative
dy_drag = zeros(length(AoA_pos),2); % predefine array that will solve for derivative
for p=0:1 % p=0 is the filtered function, p=1 is the derivative

    % 'conv' applies the 3-point local slope across the whole array (this is
    % just in MATLAB documentation)
    dy_drag(:,p+1) = conv(C_D_pos, factorial(p)/(-dx)^p * g(:,p+1), 'same');
end

% now exctracting other values for plotting
drag_smoothed = dy_drag(:,1);

% Aerodynamic efficiency = C_L/C_D
effic_array = lift_smoothed./drag_smoothed;

% must define slope along entire region in high resolution, as S-G finds
% discrete points
AoA_fine = linspace(min(AoA_pos), max(AoA_pos), 500);
effic_smoothed_fine = interp1(AoA_pos, effic_array, AoA_fine, 'pchip');

% now here is my max logic
[max_efficiency, max_effic_idx] = max(effic_smoothed_fine);
max_clcd_AoA = AoA_fine(max_effic_idx);

% NOW ERROR IS FROM MEASUREMENT, NOT S-G

% we need interpolated array to calculate the error at the max value, as
% this doesn't occur at one of our discrete values

err_lift_fine = interp1(AoA_pos, err_lift_pos, AoA_fine, 'pchip');
C_L_fine = interp1(AoA_pos, C_L_pos, AoA_fine, 'pchip');
err_drag_fine = interp1(AoA_pos, err_drag_pos, AoA_fine, 'pchip');
C_D_fine = interp1(AoA_pos, C_D_pos, AoA_fine, 'pchip');

% standard error for a division is defined  below:
err_efficiency_array = abs(effic_smoothed_fine) .* sqrt((err_lift_fine./C_L_fine).^2+(err_drag_fine./C_D_fine).^2);

% we only want the error of the maximum efficiency value
err_efficiency = err_efficiency_array(max_effic_idx);

% now, for a 95% confidence interval, multiply it by t = 2.179 because DoF = 12 (n=13, p=1) [Dof = n-p]
err_efficiency = 2.179*err_efficiency;

% % Old calc just found the max of our discrete points
% [max_efficiency, max_idx] = max(effic_array);  % calculate the max
% max_clcd_AoA = plot_AoA(max_idx);
end

function [stall_angle, stall_error_deg, C_L_smoothed, C_L_slope] = find_stallAngle(plot_C_L, plot_AoA)

% WE WILL USE SAVITSKY-GOLAY TO CALCULATE A PARABOLA AT EVERY THREE POINTS.
% WE CAN COMPARE THIS NEW DERIVATIVE TO THE 0 DEGREE CASE AND FIND WHEN IT
% REACHES 70% OF THE INITIAL. THIS WILL LEAD TO GREATER ACCURACY, AS THE
% POINTS WON'T BE SKEWED

% filter results to only have AoA > 0
range_idx = plot_AoA >= -4;
AoA_range = plot_AoA(range_idx);
C_L_range = plot_C_L(range_idx);

% 1. S-G  filter
order = 2; % means we want a parabola
framelen = 5; % fit five points (middle and two neighbors on each side)

% Smoothed signal
C_L_smoothed = sgolayfilt(C_L_range, order, framelen);

% First derivative
% C_L_slope = sgolayfilt(C_L_pos, order, framelen) / dx;
C_L_slope = gradient(C_L_smoothed, AoA_range);

% 3. Apply your stall logic

% must define slope along entire region in high resolution, as S-G finds
% discrete points

% Stall must occur after 0 degrees
pos_idx = AoA_range >= 0;
AoA_pos = AoA_range(pos_idx);
C_L_slope_pos = C_L_slope(pos_idx);

AoA_fine = linspace(min(AoA_pos), max(AoA_pos), 500);
slope_fine = interp1(AoA_pos, C_L_slope_pos, AoA_fine, 'pchip');

% now here is my stall logic
initial_slope = C_L_slope_pos(1); % Slope at AoA = 0 is first entry
stall_threshold = 0.7 * initial_slope;
stall_idx = find(slope_fine < stall_threshold, 1, "first");

if isempty(stall_idx)
    stall_angle = NaN; % Keeps the array size consistent
else
    % Use interp1 for a non-quantized angle (continuous)
    % interp1(x - indept var is slope, AoA is output, stall_thresh is the
    % query point of slope)
    stall_angle = AoA_fine(stall_idx);
end

% 5. Calculate ERROR (Fitting Error)
% This represents the noise the S-G filter removed
residuals = C_L_smoothed - C_L_range;
stall_fit_RMSE = sqrt(mean(residuals.^2));

% error propagation: delta_alpha = delta_C_L / dC_L/d\alpha because _alpha
% is only a function of C_L here.
local_slope_at_stall = abs(interp1(AoA_fine, slope_fine, stall_angle));

% Simple error propagation: delta_Alpha = delta_CL / (dCL/dAlpha)
stall_error_deg = stall_fit_RMSE / local_slope_at_stall;

% now get 95% confidence interval: t = 2.145 (n=15, p=1)
stall_error_deg = 2.145*stall_error_deg;

% figure;
% plot(AoA_pos, C_L_slope, 'o-', 'LineWidth', 1.5); hold on;
% yline(stall_threshold, '--r', '70% Threshold');
% xline(stall_angle, '-b', 'Calculated Stall');
% grid on;
% xlabel('Angle of Attack [deg]');
% ylabel('Lift Slope dC_L/d\alpha');
% title('Stall Detection via Derivative Threshold');

% OLD VERSION DID ONE POLYLINE. I AM NOW USING SAVITSKY-GOLAY

% We want to return an estimate of the stall angle, which we can only
% by fitting a polyline. Otherwise, our stall angle estimate will be
% quantized to the specific trials we conducted
%
% % now calculate 2nd order polyfit: p(x) = p1*x^2 + p2*x + p3
% lift_fit = polyfit(AoA_pos, C_L_pos, 2);
% C_L_stall_fit = polyval(lift_fit, AoA_pos); % this gets the y values at each AoA corresponding with fit
% 
% % We will define stall  as when slope of polyfit is 70% of the initial
% % slope (at AoA = 0). This is arbitrary but will provide a cutoff based off declining efficiency
% 
% p1 = lift_fit(1);
% p2 = lift_fit(2);
% 
% % Derivative of p(x), which is slope: 2*p1*x + p2
% AoA_continuous = linspace(min(AoA_pos), max(AoA_pos), 100);
% p_slope = 2*p1.*AoA_continuous + p2;
% 
% % % Uncomment to visualize plots
% % figure(100)
% % plot(AoA_pos, C_L_pos, 'LineStyle','none', 'Marker','o')
% % hold on
% % plot(AoA_continuous, p_slope, 'LineStyle','--','Marker','none')
% % hold on
% % plot(AoA_pos, C_L_stall_fit)
% % pause(0.1)
% % hold off

% % idx of where slope < 0.7 * initial slope -> initial slope = dp/dx(x=0) = p2
% stall_idx = find(p_slope < (0.7*p2),1,"first");

% % now we will find error of polyfit using ROOT MEAN SQUARE ERROR = sqrt[sum(residuals^2)/n]
% 
% residuals = C_L_pos - C_L_stall_fit;
% n = length(C_L_pos);
% 
% stall_fit_RMSE = sqrt(sum(residuals.^2)/n);

% OLD VERSION WITH JUST SLOPE AND QUANTIZED VALUES:

% % filter results to only have AoA > 0
% pos_idx = plot_AoA > 0;
% AoA_pos = plot_AoA(pos_idx);
% C_L_pos = plot_C_L(pos_idx);
%
% % Now going going to smooth the data before I calculate slope max. 3
% % means it is comparing to nearest neighbors to calculate smoothed
% C_L_smoothed = smoothdata(C_L_pos, 'gaussian', 3);
%
% % First derivative using central difference, where end_points use 2
% % points and middle use 3
% three_point_slopes = gradient(C_L_smoothed, AoA_pos);

end

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