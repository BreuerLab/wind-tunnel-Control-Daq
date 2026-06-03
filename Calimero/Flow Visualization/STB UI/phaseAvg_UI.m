% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef phaseAvg_UI < handle

    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];

        cur_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
    end

properties
    mon_num; % 1 or 2, monitor to display plot on

    root_path; % file path to data
    PIV_path;
    force_path;

    inds;

    active_types;
    active_names;
    active_labels;

    force_var_types = ["y*\omega_x", "x*\omega_y", "u*w",...
        "Drag - Vorticity", "z*\omega_y", "y*\omega_z", "(u-U)*u"];
    kin_var_types = ["Speed", "Speed Error", "Acceleration",...
                "Wing Position", "Wing Speed", "Wing Acceleration",...
                "Voltage", "Current", "Power"];

    force_var_names = ["lift.vortX", "lift.vortY", "lift_vel",...
                    "drag.tot", "drag.vortY", "drag.vortZ", "drag_vel"];
    kin_var_names = ["phase_avg_speed", "phase_avg_speed_error",...
                         "phase_avg_acc", "phase_avg_wing_pos",...
                         "phase_avg_wing_speed", "phase_avg_wing_acc",...
                         "phase_avg_volt", "phase_avg_cur", "phase_avg_volt"];

    force_y_labels = ["Lift (N)","Lift (N)","Lift (N)",...
        "Drag (N)", "Drag (N)", "Drag (N)", "Drag (N)"];
    kin_y_labels = ["Speed (Hz)", "Speed Error (Hz)", "Acceleration (Hz^2)", ...
        "Position (rad)", "Speed (rad/s)", "Acceleration (rad/s^2)",...
        "Voltage (V)", "Current (mA)", "Power (mW)"];

    % boolean, normalization/non-dimensionalization on or off
    norm;
    % boolean, normalization for x-axis (divided by period)
    norm_period;
    % boolean, move pitch moment from center of transducer to LE
    pitch_shift;
    % boolean, subtraction on or off
    PIV_sub;
    force_sub;
    % boolean, spectrum plot overrides phase averaged plot
    spectrum;
    % boolean, scale frequencies of spectrum by wingbeat freq
    freq_scale;
    % boolean, log scale frequencies of spectrum when plotting
    log_scale;
    % 1, 2, or 3.
    % 1 - Raw, no filter
    % 2 - Filtered - 50 Hz cutoff frequency
    % 3 - Filtered - 10*wingbeat frequency cutoff frequency
    filt_num;
    saveFig;
    y_cen;

    calc_bool;
    align_bool;
    force_bool;
    separate_y_axis_bool;
    % used to calculate forces from vector field data

    % ------- Available parameters user can select from -------
    available_selections;

    selection; % list of selected cases
    sel_type;
    sel_freq;
    sel_amp;

    % Curves currently displayed on plot
    plot_curves;

    distance_labels;
    distance_type_dict;
    type_distance_dict
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = phaseAvg_UI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.root_path = data_path;
        obj.PIV_path = obj.root_path + "Processed Results\";
        obj.force_path = obj.root_path + "Force Measurements\";

        obj.inds = [];
        [obj.active_types, obj.active_names, obj.active_labels] = obj.get_all_variable_options();
        % bj.force_var_types = ["Lift - Vorticity", "y*\omega_x", "x*\omega_y", "u*w", "BA: y*\omega_x",...
        %     "Drag - Vorticity", "z*\omega_y", "y*\omega_z", "(u-U)*u", "BA: (u-U)*u"];
        % obj.force_var_names = ["lift.tot", "lift.vortX", "lift.vortY", "lift_vel", "lift_phase_avg.vortX",...
        %             "drag.tot", "drag.vortY", "drag.vortZ", "drag_vel", "drag_phase_avg"];

        obj.norm = false;
        obj.norm_period = true;
        obj.PIV_sub = false;
        obj.force_sub = false;
        obj.freq_scale = false;
        obj.log_scale = false;
        obj.filt_num = 3;
        obj.saveFig = false;
        obj.y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L;

        obj.force_bool = false;
        obj.calc_bool = false;
        obj.align_bool = false;
        obj.separate_y_axis_bool = false;

        % Search through files in path to get types and speeds

        contents = dir(obj.PIV_path);
        files = contents(~[contents.isdir]);

        % Get amps, freqs, types from file names
        obj.available_selections = get_sel_from_file(files);

        obj.sel_type = obj.available_selections{1,1};
        obj.sel_amp = obj.available_selections{1,2};
        obj.sel_freq = obj.available_selections{1,3};

        obj.plot_curves = [];
        % attachFileListsToBird(path, cur_bird);

        obj.sel_type = obj.cur_types(1);
        if ~isequal(sort(obj.cur_types), sort(unique(string(obj.available_selections(:, 1)))))
            error("Downstream type mismatch. Check types...")
        end

        obj.distance_labels = ["x = 0.9m","x = 1.3m","x = 1.7m"];
        obj.distance_type_dict = containers.Map(obj.distance_labels, obj.cur_types);
        obj.type_distance_dict = containers.Map(obj.cur_types, obj.distance_labels);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);

        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        % Dropdown box for flapper type selection
        drop_y1 = screen_height*0.875 - unit_spacing;
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.ValueChangedFcn = @(src, event) type_change(src, event);
        d1.Items = [obj.distance_labels, "all"];

        % Dropdown box for wingbeat frequency selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 unit_height];
        cur_freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),3);
        freqs_string = string(cur_freqs) + " Hz";
        d2.Items = [freqs_string; "all"];

        % Dropdown box for wingbeat amplitude selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        cur_amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == obj.sel_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),2);
        d3.Items = [string(cur_amps) + " deg"; "all"];

        d2.ValueChangedFcn = @(src, event) freq_change(src, event, d3);
        d3.ValueChangedFcn = @(src, event) amp_change(src, event, d2);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = drop_y3 - (unit_height + unit_spacing);
        b2 = uibutton(option_panel);
        b2.Position = [15 button2_y 80 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.Text = "Add entry";

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b3 = uibutton(option_panel);
        b3.Position = [105 button2_y 80 unit_height];
        b3.BackgroundColor = [1 1 1];
        b3.Text = "Delete entry";

        % List of cases currently displayed on the plots
        list_y = button2_y - (3*(unit_height + unit_spacing) + unit_spacing);
        lbox = uilistbox(option_panel);
        lbox.Items = strings(0);
        lbox.Position = [10 list_y 180 3*(unit_height + unit_spacing)];

        b2.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
        b3.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

        button33_y = list_y - (unit_height + unit_spacing);
        b33 = uibutton(option_panel);
        b33.Text = "Clear Entries";
        b33.FontSize = 18;
        b33.Position = [20 button33_y 160 unit_height];
        b33.BackgroundColor = [1 1 1];
        b33.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

        param_panel_height = 180;
        param_panel_width = 180;
        param_panel_y = button33_y - unit_spacing - param_panel_height;
        param_panel = uipanel(option_panel);
        param_panel.Title = "Plot Parameters";
        param_panel.TitlePosition = 'centertop';
        param_panel.Position = [10 param_panel_y param_panel_width param_panel_height];

        var_type_label = uilabel(param_panel);
        var_type_label.Text = "Variable Type";
        var_type_label.Position = [15 132 150 22];

        var_type_dropdown = uidropdown(param_panel);
        var_type_dropdown.Items = ["kinematics", "force", "BA: force"];
        var_type_dropdown.Value = "kinematics";
        var_type_dropdown.Position = [15 107 150 25];

        [init_types, ~, ~] = obj.get_variable_options(var_type_dropdown.Value);
        init_options = ["none", init_types];

        var_label1 = uilabel(param_panel);
        var_label1.Text = "Variable 1";
        var_label1.Position = [15 82 150 22];

        var_dropdown1 = uidropdown(param_panel);
        var_dropdown1.Items = init_options;
        var_dropdown1.Value = "none";
        var_dropdown1.Position = [15 57 150 25];

        var_label2 = uilabel(param_panel);
        var_label2.Text = "Variable 2";
        var_label2.Position = [15 32 150 22];

        var_dropdown2 = uidropdown(param_panel);
        var_dropdown2.Items = init_options;
        var_dropdown2.Value = "none";
        var_dropdown2.Position = [15 7 150 25];

        var_dropdown1.ValueChangedFcn = @(src, event) updateVariableSelection(src, event, plot_panel, var_dropdown1, var_dropdown2);
        var_dropdown2.ValueChangedFcn = @(src, event) updateVariableSelection(src, event, plot_panel, var_dropdown1, var_dropdown2);
        var_type_dropdown.ValueChangedFcn = @(src, event) updateVariableType(src, event, plot_panel, var_dropdown1, var_dropdown2);

        button4_y = param_panel_y - (unit_height + unit_spacing);
        b4 = uibutton(option_panel, "state");
        b4.Text = "Show Force";
        b4.FontSize = 18;
        b4.Position = [20 button4_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) force_change(src, event, plot_panel);

        button6_y = button4_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel, "state");
        b6.Text = "PIV Body Sub";
        b6.FontSize = 18;
        b6.Position = [20 button6_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

        button7_y = button6_y - (unit_height + unit_spacing);
        b7 = uibutton(option_panel, "state");
        b7.Text = "Force Body Sub";
        b7.FontSize = 18;
        b7.Position = [20 button7_y 160 unit_height];
        b7.BackgroundColor = [1 1 1];
        b7.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

        button77_y = button7_y - (unit_height + unit_spacing);
        b77 = uibutton(option_panel, "state");
        b77.Text = "Live Calculate";
        b77.FontSize = 18;
        b77.Position = [20 button77_y 160 unit_height];
        b77.BackgroundColor = [1 1 1];
        b77.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel);

        button88_y = button77_y - (unit_height + unit_spacing);
        b88 = uibutton(option_panel, "state");
        b88.Text = "Align";
        b88.FontSize = 18;
        b88.Position = [20 button88_y 160 unit_height];
        b88.BackgroundColor = [1 1 1];
        b88.ValueChangedFcn = @(src, event) align_change(src, event, plot_panel);

        button99_y = button88_y - (unit_height + unit_spacing);
        b99 = uibutton(option_panel, "state");
        b99.Text = "Separate Y-Axis";
        b99.FontSize = 18;
        b99.Position = [20 button99_y 160 unit_height];
        b99.BackgroundColor = [1 1 1];
        b99.ValueChangedFcn = @(src, event) separate_y_axis_change(src, event, plot_panel);


        % ------------------------------------------------------
        % -------Buttons built up from bottom of screen---------
        % ------------------------------------------------------

        button8_y = unit_spacing;
        field_y = button8_y + (unit_height + unit_spacing);
        label_y = field_y + unit_height - unit_spacing;

        fnl = uilabel(option_panel);
        fnl.Position = [65 label_y 80 unit_height];
        fnl.Text = "File Name";

        ef = uieditfield(option_panel);
        ef.Position = [15 field_y 160 unit_height];
        ef.Placeholder = "test";

        % Button to export data on plot to .mat file
        b10 = uibutton(option_panel);
        b10.Position = [15 button8_y 160 unit_height];
        b10.Text = "Export Data";
        b10.ButtonPushedFcn = @(src, event) exportData(src, event, ef);

        button9_y = label_y + (unit_height + unit_spacing);
        b4 = uibutton(option_panel);
        b4.Text = "Save Fig";
        b4.FontSize = 18;
        b4.Position = [20 button9_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

        % Set up plot titles and axes
        obj.update_plot(plot_panel);

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        % Callback functions to respond to user inputs. These
        % functions must be nested inside this function otherwise
        % they will reference the object snapshot at the time the
        % callback function was defined rather than updating with
        % the object
        %-----------------------------------------------------%
        %-----------------------------------------------------%

        % update type variable with new value selected by user
        function type_change(src, ~)
            if src.Value == "all"
            obj.sel_type = src.Value;
            else
            obj.sel_type = obj.distance_type_dict(src.Value);
            end
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~, d)
            if strcmp(src.Value, "all")
            obj.sel_freq = -1;
            else
            obj.sel_freq = str2double(regexp(src.Value, '\d+', 'match'));
            end
            
            % Change amplitude list to only show those available at this
            % wingbeat frequency
            if obj.sel_freq == -1
                amps = obj.available_selections(strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),2);
            else
            amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == obj.sel_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),2);
            end
            amps = unique(cell2mat(amps));
            d.Items = [string(amps) + " deg"; "all"];
        end

        % update speed variable with new value selected by user
        function amp_change(src, ~, d)
            if strcmp(src.Value, "all")
                obj.sel_amp = -1;
            else
                obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));
            end

            % Change frequency list to only show those available at this
            % wingbeat amplitude
            if obj.sel_amp == -1
                freqs = obj.available_selections(strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),3);
            else
                freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
                & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),3);
            end
            freqs = unique(cell2mat(freqs));
            d.Items = [string(freqs) + " Hz"; "all"];
        end

        function PIV_sub_change(src, ~, plot_panel)
            obj.PIV_sub = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.PIV_sub);
            obj.update_plot(plot_panel);
        end

        function force_sub_change(src, ~, plot_panel)
            obj.force_sub = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.force_sub);
            obj.update_plot(plot_panel);
        end

        function calc_change(src, ~, plot_panel)
            obj.calc_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.calc_bool);
            obj.update_plot(plot_panel);
        end

        function align_change(src, ~, plot_panel)
            obj.align_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.align_bool);
            obj.update_plot(plot_panel);
        end

        function separate_y_axis_change(src, ~, plot_panel)
            obj.separate_y_axis_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.separate_y_axis_bool);
            obj.update_plot(plot_panel);
        end

        function addToList(~, ~, plot_panel, lbox)
            selection_types = string(obj.available_selections(:,1));
            selection_amps = cell2mat(obj.available_selections(:,2));
            selection_freqs = cell2mat(obj.available_selections(:,3));

            type_mask = true(size(selection_types));
            if obj.sel_type ~= "all"
                type_mask = selection_types == obj.sel_type;
            end

            amp_mask = true(size(selection_amps));
            if obj.sel_amp ~= -1
                amp_mask = selection_amps == obj.sel_amp;
            end

            freq_mask = true(size(selection_freqs));
            if obj.sel_freq ~= -1
                freq_mask = selection_freqs == obj.sel_freq;
            end

            matching_indices = find(type_mask & amp_mask & freq_mask);
            [~, type_order] = ismember(selection_types(matching_indices), obj.cur_types);
            type_order(type_order == 0) = length(obj.cur_types) + 1;
            [~, sort_order] = sortrows([type_order(:),...
                                        selection_amps(matching_indices),...
                                        selection_freqs(matching_indices)]);
            matching_indices = matching_indices(sort_order);

            for n = 1:length(matching_indices)
                cur_idx = matching_indices(n);
                case_name = selection_types(cur_idx) + "_" + string(selection_amps(cur_idx)) +...
                    "deg_" + string(selection_freqs(cur_idx)) + "Hz";

                if sum(strcmp(string(lbox.Items), case_name)) == 0
                    lbox.Items = [lbox.Items, case_name];
                    obj.selection = [obj.selection, case_name];
                end
            end

            obj.update_plot(plot_panel);
        end

        function removeFromList(~, ~, plot_panel, lbox)
            case_name = lbox.Value;
            % removing value from list that's displayed
            new_list_indices = string(lbox.Items) ~= case_name;
            lbox.Items = lbox.Items(new_list_indices);

            % removing value from list used for plotting
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function clearList(~, ~, plot_panel, lbox)
            % removing value from list that's displayed
            new_list_indices = [];
            lbox.Items = lbox.Items(new_list_indices);

            % removing value from list used for plotting
            obj.selection = [];
            obj.update_plot(plot_panel);
        end

        function updateVariableSelection(~, ~, plot_panel, dropdown1, dropdown2)
            selected_values = [string(dropdown1.Value), string(dropdown2.Value)];
            obj.inds = [];

            for n = 1:length(selected_values)
                if selected_values(n) == "none"
                    continue
                end

                cur_ind = find(obj.active_types == selected_values(n), 1);
                if ~isempty(cur_ind) && ~ismember(cur_ind, obj.inds)
                    obj.inds = [obj.inds cur_ind];
                end
            end

            obj.update_plot(plot_panel);
        end

        function updateVariableType(src, ~, plot_panel, dropdown1, dropdown2)
            updateDropdownItems(src.Value, dropdown1);
            updateDropdownItems(src.Value, dropdown2);
            updateVariableSelection([], [], plot_panel, dropdown1, dropdown2);
        end

        function updateDropdownItems(var_type, dropdown)
            current_value = string(dropdown.Value);
            dropdown.Items = obj.get_dropdown_items(var_type, current_value);
            dropdown.Value = current_value;
        end

        function force_change(src, ~, plot_panel)
            if (src.Value)
                obj.force_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                src.Text = "Hide Force";
            else
                obj.force_bool = false;
                src.BackgroundColor = [1 1 1];
                src.Text = "Show Force";
            end

            obj.update_plot(plot_panel);
        end

        function exportData(~, ~, ef)
            filename = [ef.Value '.mat'];
            curves = obj.plot_curves;
            save(filename, "curves")
        end

        function save_figure(~, ~, plot_panel)
            obj.saveFig = true;
            obj.update_plot(plot_panel);
            obj.saveFig = false;
        end

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)
    % Helper function to get button text based on state
    function text = get_button_text(is_active, label)
        if is_active
            text = "Hide " + label;
        else
            text = "Show " + label;
        end
    end

end

%% --------------------------------------------------------------
%---------------------------------------------------------------%
%---------------------------------------------------------------%
% The only function contained in this section is update_plot
methods (Access = private)
    % Helper function to get button color based on state
    function color = get_button_color(obj, is_active)
        if is_active
            color = obj.COLOR_ACTIVE;
        else
            color = obj.COLOR_INACTIVE;
        end
    end

    function [types, names, labels] = get_all_variable_options(obj)
        ba_force_types = "BA: " + obj.force_var_types;
        ba_force_names = regexprep(obj.force_var_names, '\.', "_phase_avg" + ".");

        types = [obj.force_var_types, ba_force_types, obj.kin_var_types];
        names = [obj.force_var_names, ba_force_names, obj.kin_var_names];
        labels = [obj.force_y_labels, obj.force_y_labels, obj.kin_y_labels];
    end

    function [types, names, labels] = get_variable_options(obj, var_type)
        if strcmp(var_type, "kinematics")
            types = obj.kin_var_types;
            names = obj.kin_var_names;
            labels = obj.kin_y_labels;
        elseif strcmp(var_type, "force")
            types = obj.force_var_types;
            names = obj.force_var_names;
            labels = obj.force_y_labels;
        elseif strcmp(var_type, "BA: force")
            types = "BA: " + obj.force_var_types;
            names = regexprep(obj.force_var_names, '\.', "_phase_avg" + ".");
            labels = obj.force_y_labels;
        else
            error("invalid var type")
        end
    end

    function items = get_dropdown_items(obj, var_type, current_value)
        [types, ~, ~] = obj.get_variable_options(var_type);
        items = ["none", types];

        if current_value ~= "none" && ~ismember(current_value, items)
            items = [items, current_value];
        end
    end

    function legend_entry = get_aligned_legend_entry(obj, cur_sel, index, is_force)
        [amp, type, freq] = parse_name(cur_sel);
        distance_label = obj.type_distance_dict(char(type));
        name = distance_label + ", " + amp + " deg, " + freq + " Hz";
        case_label = strrep(string(name), "_", " ");
        index_label = obj.active_types(index);

        if is_force
            force_label = obj.get_force_legend_label(index);
            if length(obj.selection) > 1 && length(obj.inds) > 1
                legend_entry = case_label + " - " + index_label + " - " + force_label;
            elseif length(obj.selection) > 1
                legend_entry = case_label + " - " + force_label;
            elseif length(obj.inds) > 1
                legend_entry = index_label + " - " + force_label;
            else
                legend_entry = case_label + " F";
            end
            return
        end

        if length(obj.selection) > 1 && length(obj.inds) > 1
            legend_entry = case_label + " - " + index_label;
        elseif length(obj.inds) > 1
            legend_entry = index_label;
        else
            legend_entry = case_label;
        end
    end

    function force_label = get_force_legend_label(obj, index)
        relative_idx = obj.get_force_relative_index(index);

        if isempty(relative_idx)
            force_label = "Force";
        elseif relative_idx <= 3
            force_label = "Lift force";
        else
            force_label = "Drag force";
        end
    end

    function line_style = get_index_line_style(obj, index)
        linestyles = ["-", "--", ":", "-."];
        if isempty(obj.inds)
            line_style = "-";
            return
        end

        line_style_idx = find(obj.inds == index, 1);
        if isempty(line_style_idx)
            line_style = "-";
            return
        end

        line_style_idx = mod(line_style_idx - 1, length(linestyles)) + 1;
        line_style = linestyles(line_style_idx);
    end

    function marker = get_force_marker(obj, index)
        markers = ["o", "s", "^", "d", "v", ">", "<", "p", "h", "x", "+", "*"];
        if isempty(obj.inds)
            marker = "o";
            return
        end

        marker_idx = find(obj.inds == index, 1);
        if isempty(marker_idx)
            marker = "o";
            return
        end

        marker_idx = mod(marker_idx - 1, length(markers)) + 1;
        marker = markers(marker_idx);
    end

    function marker = get_piv_force_marker(obj, index)
        if obj.is_force_index(index)
            marker = obj.get_force_marker(index);
        else
            marker = "";
        end
    end

    function tf = is_force_index(obj, index)
        tf = index <= 2 * length(obj.force_var_types);
    end

    function relative_idx = get_force_relative_index(obj, index)
        if ~obj.is_force_index(index)
            relative_idx = [];
            return
        end

        relative_idx = mod(index - 1, length(obj.force_var_types)) + 1;
    end

    function force_idx = get_force_measurement_index(obj, index)
        relative_idx = obj.get_force_relative_index(index);

        if isempty(relative_idx)
            force_idx = [];
        elseif relative_idx <= 3
            force_idx = 3;
        else
            force_idx = 1;
        end
    end

    function dual_plot = should_use_separate_y_axes(obj)
        dual_plot = false;
        if length(obj.inds) < 2
            return
        end

        force_indices = arrayfun(@(index) obj.is_force_index(index), obj.inds);
        dual_plot = obj.separate_y_axis_bool || ~all(force_indices);
    end

    function y_label = get_single_axis_label(obj)
        if ~isempty(obj.inds) && all(arrayfun(@(index) obj.is_force_index(index), obj.inds))
            y_label = "Force (N)";
        else
            y_label = obj.active_labels(obj.inds(1));
        end
    end

    function colors = get_default_selection_colors(~, num_selections)
        palette = ["#0072B2"; "#D55E00"; "#009E73"; "#CC79A7";...
                   "#56B4E9"; "#E69F00"; "#F0E442"; "#000000";...
                   "#332288"; "#88CCEE"; "#44AA99"; "#117733";...
                   "#999933"; "#DDCC77"; "#CC6677"; "#882255";...
                   "#AA4499"; "#DDDDDD"];

        if num_selections == 0
            colors = strings(0, 1);
            return
        end

        repeat_count = ceil(num_selections / length(palette));
        colors = repmat(palette, repeat_count, 1);
        colors = colors(1:num_selections);
    end

    function color = get_curve_color(obj, cur_sel, color_params)
        color = [0 0 0];

        if color_params.use_selection_colors && isfield(color_params, 'selection_names') && isfield(color_params, 'selection_colors')
            selection_idx = find(color_params.selection_names == string(cur_sel), 1);
            if ~isempty(selection_idx)
                color = obj.hex_to_rgb(color_params.selection_colors(selection_idx));
                return
            end
        end

        [amp, ~, freq] = parse_name(cur_sel);
        freq_idx = find(color_params.uniq_freqs == freq, 1);
        amp_idx = find(color_params.uniq_amps == amp, 1);

        if ~isempty(freq_idx) && ~isempty(amp_idx) &&...
           freq_idx <= size(color_params.colors, 1) &&...
           amp_idx <= size(color_params.colors, 2)
            color = obj.hex_to_rgb(color_params.colors(freq_idx, amp_idx));
        end
    end

    function rgb = hex_to_rgb(~, hex_color)
        hex_color = char(hex_color);
        if startsWith(hex_color, '#')
            hex_color = hex_color(2:end);
        end

        rgb = [hex2dec(hex_color(1:2)),...
               hex2dec(hex_color(3:4)),...
               hex2dec(hex_color(5:6))] / 255;
    end

    % update plot after user changes selected variables
    function update_plot(obj, plot_panel)
        fignew = figure('Visible', 'off');
        ax_target = axes('Parent', fignew);
        delete(plot_panel.Children)
        disp("-------------")

        % ----------------------------------------
        % ------------- Color Setup --------------
        % ----------------------------------------
        cur_selections = cell(length(obj.selection),3);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);
            [amp, type, freq] = parse_name(cur_sel);
    
            % Add to list of amplitudes and frequencies
            cur_selections{i,1} = type;
            cur_selections{i,2} = amp;
            cur_selections{i,3} = freq;
        end

        if isempty(obj.selection)
            uniq_types = strings(0);
            uniq_amps = [];
            uniq_freqs = [];
            colors = strings(0);
        else
            uniq_types = unique(string(cur_selections(:,1)));
            uniq_amps = unique(cell2mat(cur_selections(:,2)));
            uniq_freqs = unique(cell2mat(cur_selections(:,3)));
            if length(uniq_types) > 1
                colors = strings(0);
            else
                colors = getColors(1,...
                                   length(uniq_amps),...
                                   length(uniq_freqs),...
                                   length(obj.selection));
            end
        end

        use_selection_colors = length(uniq_types) > 1;
        selection_colors = obj.get_default_selection_colors(length(obj.selection));

        align_plot_bool = obj.align_bool &&...
                          ~isempty(obj.inds) &&...
                          ~isempty(obj.selection);
        aligned_curves = struct('val', {}, 'time', {}, 'index', {},...
                                'plot_idx', {}, 'cur_sel', {},...
                                'legend_entry', {}, 'line_style', {},...
                                'marker', {});

        % ----------------------------------------

        dual_plot = obj.should_use_separate_y_axes();
        ylabs = strings(1,2);
        if dual_plot
            ylabs(1) = obj.active_labels(obj.inds(1));
            ylabs(2) = obj.active_labels(obj.inds(2));
        end

        ax = axes(plot_panel);
        hold(ax, 'on');
        hold(ax_target, 'on');
        for j = 1:length(obj.inds)
            index = obj.inds(j);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);

            [amp, type, freq] = parse_name(cur_sel);

            filename = cur_sel + "_phase_avg";
            file_path = obj.PIV_path + filename + ".mat";
            secondary_file_path = obj.PIV_path + filename + "_integral.mat";

            var_name = obj.active_names(index);

            if obj.is_force_index(index) && obj.calc_bool
                avg_type = 1;
                norm_bool = false;
                % Compute forces from flow field live
                [var, err] = get_PIV_force(file_path, cur_sel, var_name, avg_type, norm_bool, obj.y_cen);
            else
                vars = {"L","U"};
                d2 = load(file_path, vars{:});
                if contains(var_name, ["lift_phase_avg", "drag_phase_avg"])
                    if contains(var_name, ".")
                        abbrv_name = extractBefore(var_name, ".");
                        d2 = load(file_path, abbrv_name);
                    else
                        d2 = load(file_path, var_name);
                    end
                    var = eval("d2." + var_name);
                else
                if contains(var_name, ".")
                    abbrv_name = extractBefore(var_name, ".");
                    d1 = load(secondary_file_path, abbrv_name);
                else
                    d1 = load(secondary_file_path, var_name);
                end

                var = eval("d1." + var_name);
        
                % Combine by converting to cell arrays of names/values and back to struct
                d = cell2struct([struct2cell(d1); struct2cell(d2)], [fieldnames(d1); fieldnames(d2)], 1);

                end
                % TEMP CODE TO NORMALIZE SPEEDS
                % var = var / mean(var);
            end
            
            % vars_kin = {"phase_avg_pos", "phase_avg_speed", "phase_avg_acc"};
            vars_kin = {"phase_avg_speed", "phase_avg_wing_pos",...
                "phase_avg_wing_speed", "phase_avg_wing_acc", "u_avg"};
            load(secondary_file_path, vars_kin{:})
            freq_cor = mean(phase_avg_speed);
            % added_mass = get_added_mass(phase_avg_pos, phase_avg_speed, phase_avg_acc);
            added_mass = get_added_mass(phase_avg_wing_pos, phase_avg_wing_speed, phase_avg_wing_acc);

            if obj.is_force_index(index) && obj.PIV_sub
                % filename = "body_phase_avg.mat";
                filename = "ring_time_avg";
                file_path_t = obj.PIV_path + "time_avg/" + filename + ".mat";
                secondary_file_path_t = obj.PIV_path + "time_avg/" + filename + "_integral.mat";

                if ~strcmp(var_name, "lift.vortY")
                if obj.calc_bool
                    % Compute aerodynamic forces
                    norm_bool = false;
                    [bod_var, bod_err] = get_PIV_force(file_path_t, "", var_name, 0, norm_bool, obj.y_cen);
                    var = var - bod_var;
                else
                    if contains(var_name, ".")
                        abbrv_name = extractBefore(var_name, ".");
                        d2 = load(secondary_file_path_t, abbrv_name);
                    else
                        d2 = load(secondary_file_path_t, var_name);
                    end

                    body_var = eval("d2." + var_name);
                    var = var - body_var;
                end
                end
            end

            % Shift data given convection time downstream to target
            % for curves using imaging plane data only
            if obj.is_force_index(index)
            dist = 0.9;
            sep_dist = 0.37;
            if contains(type, "UP_two")
                dist = dist + sep_dist*2;
            elseif contains(type, "UP_one")
                dist = dist + sep_dist;
            end
            speed = 4;
            % speed = mean(-squeeze(u_avg)) * d.U;
            conv_time = dist / speed; % 0.9 m downstream, 4 m/s
            % shift = conv_time * freq;
            shift = conv_time * freq_cor; % get shift as a portion of a cycle
            var = circshift(var, round(shift*length(var)));
            disp("Shifted by: " + round(shift*length(var)) + " / " + length(var))
            % disp("Shifted by: " + mod(round(shift*length(var)), length(var)) + " / " + length(var))

            end

            % If first value less than mean value, shift array since we
            % must have started on the other midstroke position
            % if var(1) < min(var) + range(var)/3
            %     var = circshift(var, 0.4*length(var));
            %     disp("Shifted STB curve for " + cur_sel)
            % end

            % 10 amp flexible case accidentally started at mid-downstroke
            % rather than mid-upstroke used for the rest
            if amp == 10 && ~contains(type, "UP")
                % var = circshift(var, round(0.44*length(var)));
                var = circshift(var, round(0.5*length(var)));
                disp("Shifted STB curve for " + cur_sel)
            end

            norm_bool = false;
            if norm_bool
                var = var / max(var);
            end

            time = 1:length(var);
            time = time / length(var);

            if align_plot_bool
                aligned_curves(end+1) = struct(...
                    'val', var,...
                    'time', time,...
                    'index', index,...
                    'plot_idx', j,...
                    'cur_sel', cur_sel,...
                    'legend_entry', obj.get_aligned_legend_entry(cur_sel, index, false),...
                    'line_style', "",...
                    'marker', obj.get_piv_force_marker(index));
            end

            time_F = [];
            force = [];
            if obj.force_bool && ~contains(type, "UP")
            
            idx = obj.get_force_measurement_index(index);

            if ~isempty(idx)
            % var_name_F = "wingbeat_avg_forces_raw";
            % var_name_F = "wingbeat_avg_forces";
            var_name_F = "wingbeat_avg_forces_smoothest";
            force = get_force(obj.force_path, type, amp, freq, idx, var_name_F);

            if obj.force_sub
                body_amp = amp;
                if body_amp == 30
                    body_amp = 20;
                end
                body_force = get_force(obj.force_path, "body", body_amp, freq, idx, var_name_F);
                force = force - body_force;
            end

            time_F = 1:length(force);
            time_F = time_F / length(force);

            % THIS NEEDS SOME FIXING HERE, NOT ALWAYS SHIFTING AT THE
            % CORRECT TIME
            % if force(1) < mean(force)
            %     force = circshift(force, round(0.4*length(force)));
            %     disp("Shifted force curve for " + cur_sel)
            % end
            end
            end

            if align_plot_bool && ~isempty(force)
                aligned_curves(end+1) = struct(...
                    'val', force,...
                    'time', time_F,...
                    'index', index,...
                    'plot_idx', j,...
                    'cur_sel', cur_sel,...
                    'legend_entry', obj.get_aligned_legend_entry(cur_sel, index, true),...
                    'line_style', "-",...
                    'marker', "none");
            end

            color_params.uniq_freqs = uniq_freqs;
            color_params.uniq_amps = uniq_amps;
            color_params.colors = colors;
            color_params.use_selection_colors = use_selection_colors;
            color_params.selection_names = string(obj.selection);
            color_params.selection_colors = selection_colors;
            if ~align_plot_bool
            obj.plot_data(ax, ax_target, time, var, time_F, force, index, dual_plot, j, cur_sel, color_params, ylabs); % ylabel_one, ylabel_two
            end
        end
        end

        if align_plot_bool && ~isempty(aligned_curves)
        lengths = arrayfun(@(s) length(s.val), aligned_curves, 'UniformOutput', true);
        aligned_curves = aligned_curves(lengths > 0);
        lengths = lengths(lengths > 0);
        if isempty(aligned_curves)
            hold(ax, 'off');
            hold(ax_target, 'off');
            return
        end
        maxLength = min(lengths);
        time_interp = 1:maxLength;
        time_interp = time_interp / length(time_interp);

        % resample data points to have the same number of bins
        for i = 1:length(aligned_curves)
            var = aligned_curves(i).val;
            time = aligned_curves(i).time;
            aligned_curves(i).val = interp1(time, var, time_interp, 'pchip');
            aligned_curves(i).time = time_interp;
        end

        lags = zeros(1,length(aligned_curves)-1);
        for i = 2:length(aligned_curves)
        [aligned_curves(i).val, lags(i-1)] = align_signals(aligned_curves(1).val, aligned_curves(i).val);
        end

        disp(lags)
        % if lags(1) < lags(2) && lags(1) < 0
        %     lags(2) = lags(2) - length(time_interp);
        % end
        % disp(lags)
        % disp(lags / length(time_interp))
        % disp(lags(2) / lags(1))


        for i = 1:length(aligned_curves)
            plot_options.legend_entry = aligned_curves(i).legend_entry;
            plot_options.line_style = aligned_curves(i).line_style;
            plot_options.marker = aligned_curves(i).marker;
            obj.plot_data(ax, ax_target, aligned_curves(i).time, aligned_curves(i).val, [], [],...
                          aligned_curves(i).index, dual_plot, aligned_curves(i).plot_idx,...
                          aligned_curves(i).cur_sel, color_params, ylabs, plot_options); % ylabel_one, ylabel_two
        end
        end

        hold(ax, 'off');
        hold(ax_target, 'off');
        if (obj.saveFig)
            filename = "saved_figure.fig";
            % fignew = figure('Visible','off'); % Invisible figure
            % fignew.Position = [500,491,800,600];
            % if (exist("l", "var"))
            %     copyobj([l ax], fignew); % Copy the appropriate axes
            % elseif (exist("cb", "var"))
            %     copyobj([ax cb], fignew); % Copy the appropriate axes
            % else
            %     copyobj(ax, fignew); % Copy the appropriate axes
            % end

            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

      
    end

    function plot_data(obj, ax, ax_target, time, var, time_F, force, index, dual_plot, plot_idx, cur_sel, color_params, ylabs, plot_options)
        if nargin < 14 || isempty(plot_options)
            plot_options = struct();
        end

        has_legend_override = isfield(plot_options, 'legend_entry') && strlength(string(plot_options.legend_entry)) > 0;
        has_line_style = isfield(plot_options, 'line_style') && strlength(string(plot_options.line_style)) > 0;
        has_marker = isfield(plot_options, 'marker') && strlength(string(plot_options.marker)) > 0;

        [amp, type, freq] = parse_name(cur_sel);
        % Get color for this case name
        original_color = obj.get_curve_color(cur_sel, color_params);

        if dual_plot
            if plot_idx == 1
                yyaxis(ax, 'left')
                line = plot(ax, time, var);
                % for hidden figure for saving
                yyaxis(ax_target, 'left')
                line_h = plot(ax_target, time, var);
            else
                yyaxis(ax, 'right')
                line = plot(ax, time, var);
                % for hidden figure for saving
                yyaxis(ax_target, 'right')
                line_h = plot(ax_target, time, var);
            end
            % Code below is for when force axes have different
            % units/legends
            % if strcmp(ylabel_one, obj.y_labels(index))
            %     yyaxis(ax, 'left')
            %     line = plot(ax, time, var);
            % elseif strcmp(ylabel_two, obj.y_labels(index))
            %     yyaxis(ax, 'right')
            %     line = plot(ax, time, var);
            % end
        else
            line = plot(ax, time, var);
            % for hidden figure for saving
            line_h = plot(ax_target, time, var);
        end
            
            if has_legend_override
                legend_entry = string(plot_options.legend_entry);
            else
                legend_entry = obj.get_aligned_legend_entry(cur_sel, index, false);
            end

            if has_line_style
                line.LineStyle = char(plot_options.line_style);
                line_h.LineStyle = char(plot_options.line_style);
            elseif ~isscalar(obj.inds)
                line_style = obj.get_index_line_style(index);
                line.LineStyle = char(line_style);
                line_h.LineStyle = char(line_style);
            end

            if has_marker
                line.Marker = char(plot_options.marker);
                line_h.Marker = char(plot_options.marker);
            else
                piv_force_marker = obj.get_piv_force_marker(index);
                if strlength(piv_force_marker) > 0
                    line.Marker = char(piv_force_marker);
                    line_h.Marker = char(piv_force_marker);
                end
            end

            disp(legend_entry + ", mean: " + mean(var))
            disp(legend_entry + ", range: " + range(var))
            line.DisplayName = legend_entry;
            line.Color = original_color;
            line.LineWidth = 2;

            line_h.DisplayName = legend_entry;
            line_h.Color = original_color;
            line_h.LineWidth = 2;
            % if contains(type, "UP")
            %     line.LineStyle = "--";
            % end

            if obj.force_bool && ~contains(type, "UP") && ~isempty(force)
                line = plot(ax, time_F, force);
                F_legend = obj.get_aligned_legend_entry(cur_sel, index, true);
                line.DisplayName = F_legend;
                disp(F_legend + ": " + mean(force))
                line.Color = original_color;
                line.LineWidth = 2;
                line.LineStyle = "-";

                % for hidden figure for saving
                line_h = plot(ax_target, time_F, force);
                line_h.DisplayName = F_legend;
                line_h.Color = original_color;
                line_h.LineWidth = 2;
                line_h.LineStyle = "-";
            end

            grid(ax, 'on');
            legend(ax, Location="best");
            % for hidden figure for saving
            grid(ax_target, 'on');
            legend(ax_target, Location="best");
            % if ~isempty(obj.inds)
            %     if length(obj.inds) > 1
            %         for n = 2:length(obj.inds)
            %             if ~strcmp(obj.y_labels(obj.inds(n-1)), obj.y_labels(obj.inds(n)))
            %                 dual_plot = true;
            %                 ylabel_one = obj.y_labels(obj.inds(n-1));
            %                 ylabel_two = obj.y_labels(obj.inds(n));
            %             end
            %         end
            %     end
            % end

            if dual_plot
                yyaxis(ax, 'left')
                ylabel(ax, ylabs(1))
                ax.YAxis(1).Color = 'k';
                yyaxis(ax, 'right')
                ylabel(ax, ylabs(2))
                ax.YAxis(2).Color = 'k';

                % for hidden figure for saving
                yyaxis(ax_target, 'left')
                ylabel(ax_target, ylabs(1))
                ax_target.YAxis(1).Color = 'k';
                yyaxis(ax_target, 'right')
                ylabel(ax_target, ylabs(2))
                ax_target.YAxis(2).Color = 'k';
            elseif ~isempty(obj.inds)
                ylabel(ax, obj.get_single_axis_label())
                % for hidden figure for saving
                ylabel(ax_target, obj.get_single_axis_label())
            end
            
        ax.FontSize = 18;
        ax_target.FontSize = 18;
    end
end
end