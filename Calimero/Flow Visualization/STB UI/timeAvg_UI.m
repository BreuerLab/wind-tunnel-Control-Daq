% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef timeAvg_UI < handle
    
    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];
        operations = ["mean", "range", "shift"];
        cur_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
        x_axis_types = ["wingbeat frequency", "wingbeat amplitude", "downstream distance"];
        x_axis_labels = ["Wingbeat Frequency", "Wingbeat Amplitude", "Downstream Distance"];
        downstream_distances = [0.9; 1.3; 1.7];
        downstream_distance_labels = ["x = 0.9m"; "x = 1.3m"; "x = 1.7m"];
    end

    properties
        mon_num; % 1 or 2, monitor to display plot on

        root_path; % file path to data
        PIV_path;
        force_path;

        % integer, 0-6, defines which force/moment axes to display
        index;
        % force and moment axes labels used in dropdown box
        axes_labels;

        box_labels;
        var_names;
        y_labels;

        % boolean, normalization/non-dimensionalization on or off
        y_norm;
        x_norm;
        x_axis_type;

        filt_num;

        force_bool;
        force_var;
        force_vars;
        PIV_bool;
        PIV_sub;
        force_sub;
        err_bool;
        calc_bool;

        y_cen; % spanwise position of center of body for mirroring

        % ------- Available parameters user can select from -------
        available_selections;

        selection; % list of selected cases
        sel_type;
        sel_freq;
        sel_amp;

        % Curves currently displayed on plot
        plot_curves;
        saveFig;

        distance_labels;
        distance_type_dict;

        operation;
    end

    methods
        % Constructor Function
        % Defines constants and default values for parameters
        function obj = timeAvg_UI(mon_num, data_path)
            obj.mon_num = mon_num;
            obj.root_path = data_path;
            obj.PIV_path = obj.root_path + "Processed Results\phase_avg\";
            obj.force_path = obj.root_path + "Force Measurements\";

            obj.index = 1;
            obj.box_labels = ["lift vortX", "lift vortY", "lift vel diff", "lift vel", "drag vort", "drag vel",...
                            "speed", "speed error", "voltage", "current", "electric power", "KE",...
                            "KE wake", "power wake", "KE Full", "enstrophy",...
                            "helicity", "avg u", "avg v", "avg w", "pitot U", "total uncertainty",...
                            "# particles", "# bins", "# clusters", "phase spread ratio"];
            obj.var_names = ["lift.vortX", "lift.vortY", "lift.vel", "lift_vel", "drag.tot", "drag_vel",...
                "phase_avg_speed", "phase_avg_speed_error", "phase_avg_volt", "phase_avg_cur", "phase_avg_power", "KE",...
                "KE_diff", "power", "KE_tot", "enst", "hel_avg",...
                "u_avg", "v_avg", "w_avg", "U_act", "unc_avg",...
                "numP_avg", "num_bins", "num_clusters", "phase_spread_ratio"];
            % obj.var_names = ["lift_phase_avg", "lift_vel", "drag_phase_avg", "drag_vel",...
            %     "phase_avg_speed", "phase_avg_volt", "phase_avg_cur", "KE", "enst", "u_avg"];
            % obj.var_names = ["lift", "lift_vel", "drag", "drag_vel",...
            %     "phase_avg_speed", "phase_avg_volt", "phase_avg_cur", "KE", "enst", "u_avg"];
            obj.y_labels = ["Lift (N): $\frac{2\rho}{N} \sum\limits_{n_f = 1}^{N} \int_S -u \omega_x y dA$",...
                "Lift (N)", "Lift (N)","Lift (N)","Drag (N)",...
                "Drag (N): $\frac{2\rho}{N} \sum\limits_{n_f = 1}^{N} \int_S -u(u + U) dA$",...
                "Speed (Hz)", "Speed (Hz)", "Voltage (V)", "Current (mA)", "Power (mW)",...
                "KE: $\frac{1}{N c^2} \sum\limits_{n_f = 1}^{N} \int_S \frac{\mathbf{u}^2}{U^2} dA$",...
                "KE: $\frac{1}{N c^2} \sum\limits_{n_f = 1}^{N} \int_S \frac{(\mathbf{u} + U)^2}{U^2} dA$",...
                "Power: $\frac{1}{N c^2} \sum\limits_{n_f = 1}^{N} \int_S \frac{-(\mathbf{u} + U)^2 \mathbf{u}}{U^3} dA$",...
                "KE", "Enstrophy", "Helicity",...
                "Speed", "Speed", "Speed",...
                "Freestream Speed", "Uncertainty", "count", "count", "count", ""];
            obj.PIV_sub = false;
            obj.force_sub = false;
            obj.filt_num = 3;
            obj.operation = "mean";

            obj.x_norm = false;
            obj.y_norm = false;
            obj.force_bool = false;
            obj.PIV_bool = true;
            obj.force_var = obj.var_names(1);
            obj.force_vars = obj.force_var;
            obj.saveFig = false;
            obj.err_bool = false;
            obj.calc_bool = false;
            obj.y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L;

            % Search through files in path to get types and speeds
            contents = dir(obj.PIV_path);
            files = contents(~[contents.isdir]);

            % Get amps, freqs, types from file names
            obj.available_selections = get_sel_from_file(files);

            if isempty(obj.available_selections)
                error("No STB files found in %s. Expected *_phase_avg.mat or *_time_avg.mat files.", obj.PIV_path)
            end

            obj.plot_curves = [];
            obj.selection = strings(0);

            [selection_types, obj.distance_labels] = obj.get_available_type_options();
            obj.sel_type = selection_types(1);
            obj.sel_amp = obj.get_first_amp(obj.sel_type);
            obj.sel_freq = obj.get_first_freq(obj.sel_type, obj.sel_amp);
            obj.distance_type_dict = containers.Map(cellstr(obj.distance_labels), cellstr(selection_types));
            obj.x_axis_type = obj.x_axis_types(1);
        end

        % Builds figure with all UI elements and defines all callback
        % functions to be used when user clicks on UI elements
        function dynamic_plotting(obj)
            % Create a GUI figure with a grid layout
            [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);

            screen_height = screen_size(4);
            unit_height = round(0.03*screen_height);
            unit_spacing = round(0.005*screen_height);

            % Dropdown box for selecting the x-axis variable
            drop_y0 = screen_height*0.85 - 30;
            x_axis_dropdown = uidropdown(option_panel);
            x_axis_dropdown.Position = [10 drop_y0 180 30];
            x_axis_dropdown.Items = obj.x_axis_labels(:);
            x_axis_dropdown.Value = obj.get_x_axis_label(obj.x_axis_type);

            % Dropdown boxes for variables held fixed while the x-axis varies
            drop_y1 = drop_y0 - (unit_height + unit_spacing);
            fixed_dropdown_1 = uidropdown(option_panel);
            fixed_dropdown_1.Position = [10 drop_y1 180 unit_height];

            drop_y3 = drop_y1 - (unit_height + unit_spacing);
            fixed_dropdown_2 = uidropdown(option_panel);
            fixed_dropdown_2.Position = [10 drop_y3 180 unit_height];
            obj.reset_fixed_variable_defaults();
            obj.update_fixed_dropdowns(fixed_dropdown_1, fixed_dropdown_2);

            % Button to add entry
            button2_y = drop_y3 - (unit_height + unit_spacing);
            add_button = uibutton(option_panel);
            add_button.Position = [15 button2_y 80 unit_height];
            add_button.Text = "Add entry";

            % Button to remove entry
            delete_button = uibutton(option_panel);
            delete_button.Position = [105 button2_y 80 unit_height];
            delete_button.Text = "Delete entry";

            % List of cases currently displayed on the plots
            list_h = 4*(unit_height + unit_spacing);
            list_y = button2_y - (list_h + unit_spacing);
            lbox = uilistbox(option_panel);
            lbox.Items = strings(0);
            lbox.Position = [10 list_y 180 list_h];

            x_axis_dropdown.ValueChangedFcn = @(src, event) x_axis_change(src, event, fixed_dropdown_1, fixed_dropdown_2, plot_panel, lbox);
            fixed_dropdown_1.ValueChangedFcn = @(src, event) fixed_1_change(src, event, fixed_dropdown_2);
            fixed_dropdown_2.ValueChangedFcn = @(src, event) fixed_2_change(src, event);
            add_button.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
            delete_button.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

            clear_button_y = list_y - (unit_height + unit_spacing);
            clear_button = uibutton(option_panel);
            clear_button.Text = "Clear Entries";
            clear_button.FontSize = 18;
            clear_button.Position = [20 clear_button_y 160 unit_height];
            clear_button.BackgroundColor = [1 1 1];
            clear_button.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

            % Dropdown boxes for variable selection
            drop_y4 = clear_button_y - 35;
            force_var_dropdown_1 = uidropdown(option_panel);
            force_var_dropdown_1.Position = [10 drop_y4 180 30];
            force_var_dropdown_1.Items = ["none", obj.box_labels];
            force_var_dropdown_1.Value = obj.get_force_var_label(obj.force_var);

            drop_y44 = drop_y4 - 35;
            force_var_dropdown_2 = uidropdown(option_panel);
            force_var_dropdown_2.Position = [10 drop_y44 180 30];
            force_var_dropdown_2.Items = ["none", obj.box_labels];
            force_var_dropdown_2.Value = "none";
            force_var_dropdown_1.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, force_var_dropdown_1, force_var_dropdown_2);
            force_var_dropdown_2.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, force_var_dropdown_1, force_var_dropdown_2);

            drop_y444 = drop_y44 - 35;
            operation_dropdown = uidropdown(option_panel);
            operation_dropdown.Position = [10 drop_y444 180 30];
            operation_dropdown.Items = obj.operations;
            operation_dropdown.ValueChangedFcn = @(src, event) operation_change(src, event, plot_panel);

            button4_y = drop_y444 - (unit_height + unit_spacing);
            piv_button = uibutton(option_panel, "state");
            piv_button.Text = "Show PIV";
            piv_button.Value = true;
            piv_button.FontSize = 18;
            piv_button.Position = [20 button4_y 160 unit_height];
            piv_button.BackgroundColor = obj.COLOR_ACTIVE;
            piv_button.ValueChangedFcn = @(src, event) PIV_bool_change(src, event, plot_panel);

            button44_y = button4_y - (unit_height + unit_spacing);
            piv_sub_button = uibutton(option_panel, "state");
            piv_sub_button.Text = "PIV Body Sub";
            piv_sub_button.FontSize = 18;
            piv_sub_button.Position = [20 button44_y 160 unit_height];
            piv_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            piv_sub_button.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

            button5_y = button44_y - (unit_height + unit_spacing);
            force_button = uibutton(option_panel, "state");
            force_button.Text = "Show Force";
            force_button.FontSize = 18;
            force_button.Position = [20 button5_y 160 unit_height];
            force_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_button.ValueChangedFcn = @(src, event) force_bool_change(src, event, plot_panel);

            button55_y = button5_y - (unit_height + unit_spacing);
            force_sub_button = uibutton(option_panel, "state");
            force_sub_button.Text = "Force Body Sub";
            force_sub_button.FontSize = 18;
            force_sub_button.Position = [20 button55_y 160 unit_height];
            force_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_sub_button.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

            button6_y = button55_y - (unit_height + unit_spacing);
            x_norm_button = uibutton(option_panel, "state");
            x_norm_button.Text = "Normalize X-axis";
            x_norm_button.FontSize = 18;
            x_norm_button.Position = [20 button6_y 160 unit_height];
            x_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            x_norm_button.ValueChangedFcn = @(src, event) x_norm_change(src, event, plot_panel);

            button66_y = button6_y - (unit_height + unit_spacing);
            y_norm_button = uibutton(option_panel, "state");
            y_norm_button.Text = "Normalize Y-axis";
            y_norm_button.FontSize = 18;
            y_norm_button.Position = [20 button66_y 160 unit_height];
            y_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            y_norm_button.ValueChangedFcn = @(src, event) y_norm_change(src, event, plot_panel);

            button7_y = button66_y - (unit_height + unit_spacing);
            err_button = uibutton(option_panel, "state");
            err_button.Text = "Error";
            err_button.FontSize = 18;
            err_button.Position = [20 button7_y 160 unit_height];
            err_button.BackgroundColor = obj.COLOR_INACTIVE;
            err_button.ValueChangedFcn = @(src, event) err_change(src, event, plot_panel);

            edit1_y = button7_y - (unit_height + unit_spacing);
            y_cen_field = uieditfield(option_panel, 'numeric');
            y_cen_field.Value = obj.y_cen;
            y_cen_field.Position = [20 edit1_y 160 unit_height];
            y_cen_field.ValueChangedFcn = @(src, event) y_cen_change(src, event, plot_panel);

            button8_y = edit1_y - (unit_height + unit_spacing);
            calc_button = uibutton(option_panel, "state");
            calc_button.Text = "Live Calculate";
            calc_button.FontSize = 18;
            calc_button.Position = [20 button7_y 160 unit_height];
            calc_button.BackgroundColor = obj.COLOR_INACTIVE;
            calc_button.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel);

            save_fig_button_y = (unit_height + unit_spacing);
            save_fig_button = uibutton(option_panel);
            save_fig_button.Text = "Save Fig";
            save_fig_button.FontSize = 18;
            save_fig_button.Position = [20 save_fig_button_y 160 unit_height];
            save_fig_button.BackgroundColor = [1 1 1];
            save_fig_button.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

            % Set up plot titles and axes
            obj.update_plot(plot_panel);

            % ===== Nested Callback Functions =====
            
            function x_axis_change(src, ~, fixed_dropdown_1, fixed_dropdown_2, plot_panel, lbox)
                obj.x_axis_type = obj.get_x_axis_type(src.Value);
                obj.reset_fixed_variable_defaults();
                obj.update_fixed_dropdowns(fixed_dropdown_1, fixed_dropdown_2);
                obj.selection = strings(0);
                lbox.Items = strings(0);
                obj.update_plot(plot_panel);
            end

            function fixed_1_change(src, ~, fixed_dropdown_2)
                fixed_vars = obj.get_fixed_variable_names();
                obj.set_selected_value_from_item(fixed_vars(1), src.Value);
                obj.set_first_available_value(fixed_vars(2));
                obj.update_fixed_dropdown(fixed_dropdown_2, fixed_vars(2));
            end

            function fixed_2_change(src, ~)
                fixed_vars = obj.get_fixed_variable_names();
                obj.set_selected_value_from_item(fixed_vars(2), src.Value);
            end

            function force_var_change(~, ~, plot_panel, dropdown_1, dropdown_2)
                selected_values = [string(dropdown_1.Value), string(dropdown_2.Value)];
                obj.force_vars = strings(0);

                for n = 1:length(selected_values)
                    if selected_values(n) == "none"
                        continue
                    end

                    cur_var = obj.var_names(obj.box_labels == selected_values(n));
                    if ~isempty(cur_var) && ~ismember(cur_var, obj.force_vars)
                        obj.force_vars(end + 1) = cur_var;
                    end
                end

                if isempty(obj.force_vars)
                    obj.force_var = "";
                else
                    obj.force_var = obj.force_vars(1);
                end

                obj.update_plot(plot_panel);
            end

            function operation_change(src, ~, plot_panel)
                obj.operation = src.Value;
                obj.update_plot(plot_panel);
            end

            function PIV_bool_change(src, ~, plot_panel)
                obj.PIV_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.PIV_bool);
                src.Text = obj.get_button_text(obj.PIV_bool, "PIV");
                obj.update_plot(plot_panel);
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

            function force_bool_change(src, ~, plot_panel)
                obj.force_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.force_bool);
                src.Text = obj.get_button_text(obj.force_bool, "Force");
                obj.update_plot(plot_panel);
            end

            function x_norm_change(src, ~, plot_panel)
                obj.x_norm = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.x_norm);
                obj.update_plot(plot_panel);
            end

            function y_norm_change(src, ~, plot_panel)
                obj.y_norm = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.y_norm);
                obj.update_plot(plot_panel);
            end

            function err_change(src, ~, plot_panel)
                obj.err_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.err_bool);
                obj.update_plot(plot_panel);
            end
            
            function calc_change(src, ~, plot_panel)
                obj.calc_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.calc_bool);
                obj.update_plot(plot_panel);
            end

            function addToList(~, ~, plot_panel, lbox)
                selection_keys = obj.get_current_selection_keys();

                for n = 1:length(selection_keys)
                    selection_key = selection_keys(n);
                    case_name = obj.get_selection_label(selection_key);

                    if (sum(strcmp(obj.selection, selection_key)) == 0)
                        lbox.Items = [lbox.Items, case_name];
                        obj.selection = [obj.selection, selection_key];
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
                obj.selection = obj.selection(new_list_indices);
                obj.update_plot(plot_panel);
            end

            function clearList(~, ~, plot_panel, lbox)
                lbox.Items = strings(0);
                obj.selection = strings(0);
                obj.update_plot(plot_panel);
            end

            function y_cen_change(src, ~, plot_panel)
                obj.y_cen = src.Value;
                obj.update_plot(plot_panel);
            end

            function save_figure(~, ~, plot_panel)
                obj.saveFig = true;
                obj.update_plot(plot_panel);
                obj.saveFig = false;
            end
        end
    end

    methods (Access = private)
        function [selection_types, selection_labels] = get_available_type_options(obj)
            available_types = unique(string(obj.available_selections(:, 1)), 'stable');
            available_types = available_types(strlength(available_types) > 0);
            selection_types = obj.get_ordered_type_options(available_types);
            selection_labels = strings(length(selection_types), 1);

            for i = 1:length(selection_types)
                selection_labels(i) = obj.get_type_label(selection_types(i));
            end
        end

        function amps = get_amp_options(obj, selected_type)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            amps = unique(selection_amps(selection_types == string(selected_type)));
        end

        function freqs = get_freq_options(obj, selected_type, selected_amp)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));
            mask = selection_types == string(selected_type) & selection_amps == selected_amp;
            freqs = unique(selection_freqs(mask));
        end

        function amp = get_first_amp(obj, selected_type)
            amps = obj.get_amp_options(selected_type);
            amp = amps(1);
        end

        function freq = get_first_freq(obj, selected_type, selected_amp)
            freqs = obj.get_freq_options(selected_type, selected_amp);
            freq = freqs(1);
        end

        function label = get_x_axis_label(obj, x_axis_type)
            label = obj.x_axis_labels(obj.x_axis_types == string(x_axis_type));
        end

        function x_axis_type = get_x_axis_type(obj, label)
            x_axis_type = obj.x_axis_types(obj.x_axis_labels == string(label));
        end

        function fixed_vars = get_fixed_variable_names(obj)
            switch obj.x_axis_type
                case "wingbeat frequency"
                    fixed_vars = ["type", "amp"];
                case "wingbeat amplitude"
                    fixed_vars = ["type", "freq"];
                case "downstream distance"
                    fixed_vars = ["amp", "freq"];
                otherwise
                    error("Unknown x-axis type: %s", obj.x_axis_type)
            end
        end

        function reset_fixed_variable_defaults(obj)
            fixed_vars = obj.get_fixed_variable_names();
            for i = 1:length(fixed_vars)
                obj.set_first_available_value(fixed_vars(i));
            end
        end

        function set_first_available_value(obj, variable_name)
            options = obj.get_fixed_variable_options(variable_name);
            if isempty(options)
                return
            end

            switch variable_name
                case "type"
                    obj.sel_type = string(options(1));
                case "amp"
                    obj.sel_amp = options(1);
                case "freq"
                    obj.sel_freq = options(1);
            end
        end

        function update_fixed_dropdowns(obj, dropdown_1, dropdown_2)
            fixed_vars = obj.get_fixed_variable_names();
            obj.update_fixed_dropdown(dropdown_1, fixed_vars(1));
            obj.update_fixed_dropdown(dropdown_2, fixed_vars(2));
        end

        function update_fixed_dropdown(obj, dropdown, variable_name)
            options = obj.get_fixed_variable_options(variable_name);

            if isempty(options)
                dropdown.Items = "all";
                dropdown.Value = "all";
                return
            end

            switch variable_name
                case "type"
                    obj.ensure_selected_value(variable_name, options);
                    labels = strings(length(options), 1);
                    for i = 1:length(options)
                        labels(i) = obj.get_type_label(options(i));
                    end
                    dropdown.Items = [labels; "all"];
                    if obj.sel_type == "all"
                        dropdown.Value = "all";
                    else
                        dropdown.Value = obj.get_type_label(obj.sel_type);
                    end
                case "amp"
                    obj.ensure_selected_value(variable_name, options);
                    dropdown.Items = [string(options(:)) + " deg"; "all"];
                    if obj.sel_amp == -1
                        dropdown.Value = "all";
                    else
                        dropdown.Value = string(obj.sel_amp) + " deg";
                    end
                case "freq"
                    obj.ensure_selected_value(variable_name, options);
                    dropdown.Items = [string(options(:)) + " Hz"; "all"];
                    if obj.sel_freq == -1
                        dropdown.Value = "all";
                    else
                        dropdown.Value = string(obj.sel_freq) + " Hz";
                    end
            end
        end

        function ensure_selected_value(obj, variable_name, options)
            selected_value = obj.get_selected_value(variable_name);
            if obj.is_all_value(variable_name, selected_value)
                return
            end

            if isempty(selected_value) || ~ismember(selected_value, options)
                obj.set_first_available_value(variable_name);
            end
        end

        function selected_value = get_selected_value(obj, variable_name)
            switch variable_name
                case "type"
                    selected_value = obj.sel_type;
                case "amp"
                    selected_value = obj.sel_amp;
                case "freq"
                    selected_value = obj.sel_freq;
            end
        end

        function set_selected_value_from_item(obj, variable_name, item)
            switch variable_name
                case "type"
                    if string(item) == "all"
                        obj.sel_type = "all";
                    else
                        obj.sel_type = string(obj.distance_type_dict(char(item)));
                    end
                case "amp"
                    if string(item) == "all"
                        obj.sel_amp = -1;
                    else
                        obj.sel_amp = str2double(erase(string(item), " deg"));
                    end
                case "freq"
                    if string(item) == "all"
                        obj.sel_freq = -1;
                    else
                        obj.sel_freq = str2double(erase(string(item), " Hz"));
                    end
            end
        end

        function options = get_fixed_variable_options(obj, variable_name)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));
            mask = true(size(selection_amps));

            fixed_vars = obj.get_fixed_variable_names();
            target_index = find(fixed_vars == string(variable_name), 1);
            for i = 1:target_index - 1
                prior_var = fixed_vars(i);
                prior_value = obj.get_selected_value(prior_var);
                mask = mask & obj.get_variable_mask(selection_types, selection_amps, selection_freqs, prior_var, prior_value);
            end

            switch variable_name
                case "type"
                    options = obj.get_ordered_type_options(selection_types(mask));
                case "amp"
                    options = unique(selection_amps(mask));
                case "freq"
                    options = unique(selection_freqs(mask));
            end
        end

        function mask = get_variable_mask(~, selection_types, selection_amps, selection_freqs, variable_name, value)
            switch variable_name
                case "type"
                    if string(value) == "all"
                        mask = true(size(selection_types));
                    else
                        mask = selection_types == string(value);
                    end
                case "amp"
                    if value == -1
                        mask = true(size(selection_amps));
                    else
                        mask = selection_amps == value;
                    end
                case "freq"
                    if value == -1
                        mask = true(size(selection_freqs));
                    else
                        mask = selection_freqs == value;
                    end
            end
        end

        function all_value = is_all_value(~, variable_name, value)
            switch variable_name
                case "type"
                    all_value = string(value) == "all";
                case {"amp", "freq"}
                    all_value = value == -1;
            end
        end

        function selection_types = get_ordered_type_options(obj, available_types)
            selection_types = strings(0, 1);

            for i = 1:length(obj.cur_types)
                type = obj.cur_types(i);
                if any(available_types == type)
                    selection_types(end + 1, 1) = type;
                end
            end

            other_types = setdiff(available_types(:), selection_types, 'stable');
            selection_types = [selection_types; other_types(:)];
        end

        function label = get_type_label(obj, type)
            type = string(type);
            type_index = find(obj.cur_types == type, 1);
            if isempty(type_index)
                label = type;
            else
                label = obj.downstream_distance_labels(type_index);
            end
        end

        function selection_keys = get_current_selection_keys(obj)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));
            fixed_vars = obj.get_fixed_variable_names();
            mask = true(size(selection_amps));

            for i = 1:length(fixed_vars)
                variable_name = fixed_vars(i);
                value = obj.get_selected_value(variable_name);
                mask = mask & obj.get_variable_mask(selection_types, selection_amps, selection_freqs, variable_name, value);
            end

            matching_indices = find(mask);
            [~, type_order] = ismember(selection_types(matching_indices), obj.cur_types);
            type_order(type_order == 0) = length(obj.cur_types) + 1;
            [~, sort_order] = sortrows([type_order(:),...
                                        selection_amps(matching_indices),...
                                        selection_freqs(matching_indices)]);
            matching_indices = matching_indices(sort_order);
            selection_keys = strings(0);

            for n = 1:length(matching_indices)
                cur_idx = matching_indices(n);
                selection_key = obj.x_axis_type;

                for i = 1:length(fixed_vars)
                    variable_name = fixed_vars(i);
                    switch variable_name
                        case "type"
                            value = selection_types(cur_idx);
                        case "amp"
                            value = selection_amps(cur_idx);
                        case "freq"
                            value = selection_freqs(cur_idx);
                    end

                    selection_key = selection_key + "|" + variable_name + "=" + string(value);
                end

                if sum(strcmp(selection_keys, selection_key)) == 0
                    selection_keys(end + 1) = selection_key;
                end
            end
        end

        function info = decode_selection(~, selection_key)
            parts = split(string(selection_key), "|");
            info = struct("x_axis_type", parts(1), "type", "", "amp", NaN, "freq", NaN);

            for i = 2:length(parts)
                variable_name = extractBefore(parts(i), "=");
                value = extractAfter(parts(i), "=");
                switch variable_name
                    case "type"
                        info.type = value;
                    case "amp"
                        info.amp = str2double(value);
                    case "freq"
                        info.freq = str2double(value);
                end
            end
        end

        function label = get_selection_label(obj, selection_key)
            info = obj.decode_selection(selection_key);

            switch info.x_axis_type
                case "wingbeat frequency"
                    label = "Freq | " + obj.get_type_label(info.type) + " | " + info.amp + " deg";
                case "wingbeat amplitude"
                    label = "Amp | " + obj.get_type_label(info.type) + " | " + info.freq + " Hz";
                case "downstream distance"
                    label = "Distance | " + info.amp + " deg | " + info.freq + " Hz";
            end
        end

        function points = get_selection_points(obj, info)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));

            switch info.x_axis_type
                case "wingbeat frequency"
                    mask = selection_types == info.type & selection_amps == info.amp;
                    freqs = unique(selection_freqs(mask));
                    points.types = repmat(info.type, 1, length(freqs));
                    points.amps = repmat(info.amp, 1, length(freqs));
                    points.freqs = freqs(:)';
                    points.x_values = points.freqs;
                case "wingbeat amplitude"
                    mask = selection_types == info.type & selection_freqs == info.freq;
                    amps = unique(selection_amps(mask));
                    points.types = repmat(info.type, 1, length(amps));
                    points.amps = amps(:)';
                    points.freqs = repmat(info.freq, 1, length(amps));
                    points.x_values = points.amps;
                case "downstream distance"
                    mask = selection_amps == info.amp & selection_freqs == info.freq;
                    types = obj.get_ordered_type_options(selection_types(mask));
                    x_values = NaN(size(types));
                    for i = 1:length(types)
                        x_values(i) = obj.get_downstream_distance(types(i));
                    end
                    valid_indices = isfinite(x_values);
                    points.types = types(valid_indices)';
                    points.amps = repmat(info.amp, 1, sum(valid_indices));
                    points.freqs = repmat(info.freq, 1, sum(valid_indices));
                    points.x_values = x_values(valid_indices)';
            end
        end

        function distance = get_downstream_distance(obj, type)
            type_index = find(obj.cur_types == string(type), 1);
            if isempty(type_index)
                distance = NaN;
            else
                distance = obj.downstream_distances(type_index);
            end
        end

        function [x_var, x_label] = get_x_axis_values(obj, x_axis_type, points, measured_freqs, wind_speed_acts)
            switch x_axis_type
                case "wingbeat frequency"
                    if obj.x_norm
                        x_var = NaN(1, length(measured_freqs));
                        for i = 1:length(measured_freqs)
                            if measured_freqs(i) == 0
                                x_var(i) = 0;
                            elseif isfinite(wind_speed_acts(i))
                                x_var(i) = freqToSt(measured_freqs(i), wind_speed_acts(i), points.amps(i));
                            end
                        end
                        x_label = "Strouhal Number";
                    else
                        x_var = measured_freqs;
                        x_label = "Wingbeat Frequency (Hz)";
                    end
                case "wingbeat amplitude"
                    x_var = points.amps;
                    x_label = "Wingbeat Amplitude (deg)";
                case "downstream distance"
                    x_var = points.x_values;
                    x_label = "Downstream Distance (m)";
            end
        end

        function label = get_curve_label(obj, info)
            switch info.x_axis_type
                case "wingbeat frequency"
                    label = strrep(info.type, "_", " ") + ", " + info.amp + " deg";
                case "wingbeat amplitude"
                    label = strrep(info.type, "_", " ") + ", " + info.freq + " Hz";
                case "downstream distance"
                    label = info.amp + " deg, " + info.freq + " Hz";
            end
        end

        % Helper function to get button color based on state
        function color = get_button_color(obj, is_active)
            if is_active
                color = obj.COLOR_ACTIVE;
            else
                color = obj.COLOR_INACTIVE;
            end
        end

        % Helper function to get button text based on state
        function text = get_button_text(obj, is_active, label)
            if is_active
                text = "Hide " + label;
            else
                text = "Show " + label;
            end
        end

        function force_vars = get_active_force_vars(obj)
            force_vars = string(obj.force_vars);
            force_vars = force_vars(strlength(force_vars) > 0);
            force_vars = force_vars(ismember(force_vars, obj.var_names));
            force_vars = unique(force_vars, 'stable');
        end

        function label = get_force_var_label(obj, force_var)
            label = obj.box_labels(obj.var_names == string(force_var));
            if isempty(label)
                label = "none";
            end
        end

        function y_label = get_force_vars_y_label(obj, force_vars)
            y_labels = strings(1, length(force_vars));
            for i = 1:length(force_vars)
                y_labels(i) = obj.y_labels(obj.var_names == force_vars(i));
            end

            if isempty(y_labels)
                y_label = "";
            elseif all(y_labels == y_labels(1))
                y_label = y_labels(1);
            else
                y_label = "Selected Variable Values";
            end
        end

        function legend_label = get_plot_legend_label(obj, curve_label, force_var, num_vars)
            var_label = obj.get_force_var_label(force_var);
            if length(obj.selection) > 1 && num_vars > 1
                legend_label = curve_label + " - " + var_label;
            elseif num_vars > 1
                legend_label = var_label;
            else
                legend_label = curve_label;
            end
        end

        function marker = get_variable_marker(~, var_idx)
            markers = ["o", "s", "^", "d", "v", ">", "<", "p", "h", "x", "+", "*"];
            marker = markers(mod(var_idx - 1, length(markers)) + 1);
        end

        function idx = get_load_cell_index(~, force_var)
            idx = [];
            if contains(force_var, "drag")
                idx = 1;
            elseif contains(force_var, "lift")
                idx = 3;
            end
        end

        % Update plot after user changes selected variables
        function update_plot(obj, plot_panel)
            delete(plot_panel.Children)

            ax = axes(plot_panel);
            hold(ax, 'on');
            l = legend(ax, Location="best");
            set(ax, FontSize=18)

            is_shift_operation = strcmp(obj.operation, "shift");
            selected_force_vars = obj.get_active_force_vars();
            num_vars = length(selected_force_vars);
            curve_colors = lines(max(1, length(obj.selection) * max(1, num_vars)));

            for var_idx = 1:num_vars % Loop through each selected variable
                force_var = selected_force_vars(var_idx);
                load_cell_idx = obj.get_load_cell_index(force_var);
                variable_marker = obj.get_variable_marker(var_idx);

            for i = 1:length(obj.selection) % Loop through each selection
                info = obj.decode_selection(obj.selection(i));
                points = obj.get_selection_points(info);
                num_points = length(points.freqs);

                if num_points == 0
                    continue
                end

                color_idx = (i - 1) * num_vars + var_idx;
                original_color = curve_colors(color_idx,:);
                curve_label = obj.get_curve_label(info);
                legend_label = obj.get_plot_legend_label(curve_label, force_var, num_vars);

                forces = zeros(2, num_points);
                if is_shift_operation
                    forces(:) = NaN;
                end
                errors = zeros(1, num_points);
                measured_freqs = points.freqs;
                wind_speed_acts = NaN(1, num_points);
                PIV_signals = cell(1, num_points);
                force_signals = cell(1, num_points);
                
                for j = 1:num_points % Loop through all matching cases
                    type = points.types(j);
                    amp = points.amps(j);
                    freq = points.freqs(j);

                    if obj.PIV_bool
                        name = type + "_" + amp + "deg_" + freq + "Hz";
                        if freq == 0
                            suffix = "_time_avg";
                        else
                            suffix = "_phase_avg";
                        end
                        filepath = obj.PIV_path + name + suffix + ".mat";
                        secondary_filepath = obj.PIV_path + name + suffix + "_integral.mat";

                        if freq == 0
                            avg_type = 0;
                            measured_freqs(j) = 0;
                            errors(j) = 0;
                        else
                            avg_type = 1;
                            d = load(filepath, "U", "L", "U_act", "rho_act", "bin_std");
                            F = load(secondary_filepath, "freq_avg");
                            measured_freqs(j) = mean(F.freq_avg);
                            % gain = 0.01;
                            % gain = 0.001;
                            errors(j) = mean(d.bin_std);
                            % errors(j) = 0;
                            wind_speed = d.U;
                            density = d.rho_act;
                            area = d.L * d.L * 3 * 2;
                            wind_speed_acts(j) = d.U_act * d.U;
                            % errors(j) = 0.2 / length(d.bin_std);
                        end

                        if is_shift_operation && freq == 0
                            disp("Skipping 0 Hz time-average case for phase shift")
                        elseif obj.calc_bool && obj.is_piv_force_variable(force_var)
                            [var, err] = get_PIV_force(filepath, name, force_var, avg_type, obj.y_norm, obj.y_cen);

                            if obj.PIV_sub
                                % filename = "body_time_avg.mat";
                                filename = "ring_time_avg.mat";
                                bod_filepath = obj.PIV_path + "time_avg/" + filename;
                                [bod_var, ~] = get_PIV_force(bod_filepath, "", force_var, 0, obj.y_norm, obj.y_cen);
                                var = var - bod_var;
                            end
                        elseif ~is_shift_operation || freq > 0
                            if contains(force_var, ".")
                                abbrv_name = extractBefore(force_var, ".");
                                d = load(secondary_filepath, abbrv_name);

                                var = eval("d." + force_var);
                            else
                                if ismember(force_var, ["U_act", "num_bins","num_clusters","phase_spread_ratio"])
                                    d = load(filepath, force_var);
                                else
                                    d = load(secondary_filepath, force_var);
                                end
                                var = d.(force_var);
                            end

                            % TEMPORARY for dimensionalization of power
                            % var = var * (1/2) * density * wind_speed^3 * area;

                            if obj.PIV_sub
                                % filename = "body_time_avg.mat";
                                filename = "ring_time_avg_integral.mat";
                                if contains(force_var, ".")
                                    abbrv_name = extractBefore(force_var, ".");
                                    bod = load(obj.PIV_path + "time_avg/" + filename, abbrv_name);
                                    bod_var = eval("bod." + force_var);
                                else
                                    bod = load(obj.PIV_path + "time_avg/" + filename, force_var);
                                    bod_var = bod.(force_var);
                                end
                                var = var - bod_var;
                            end  
                        end
                        
                        % Calculate mean force and store in array for plotting
                        if is_shift_operation && freq > 0
                            if obj.is_piv_force_variable(force_var)
                                var = obj.apply_convection_shift(var, type, measured_freqs(j));
                            end
                            PIV_signals{j} = var;
                        elseif strcmp(obj.operation, "mean")
                            forces(1,j) = mean(var);
                        elseif strcmp(obj.operation, "range")
                            forces(1,j) = range(var);
                        end
                    end

                    if obj.force_bool && ~contains(type, "UP") && ~isempty(load_cell_idx)
                        var_name_F = "results_lab";
                        % var_name_F = "filtered_data";
                        % var_name_F = "wingbeat_avg_forces_smoothest";
                        if freq == 0
                            var_name_F = "results_lab";
                            % var_name_F = "filtered_data";
                        end

                        idx = load_cell_idx;

                        if is_shift_operation && freq == 0
                            disp("Skipping 0 Hz force case for phase shift")
                        else
                            force_signal = get_force(obj.force_path, type, amp, freq, idx, var_name_F);

                            if is_shift_operation
                                force_signals{j} = force_signal;
                            elseif strcmp(obj.operation, "mean")
                                forces(2,j) = mean(force_signal);
                            elseif strcmp(obj.operation, "range")
                                forces(2,j) = range(force_signal);
                            end

                            if obj.force_sub
                                body_amp = amp;
                                if body_amp == 30
                                    body_amp = 20;
                                end
                                body_force = get_force(obj.force_path, "body", body_amp, freq, idx, var_name_F);
                                if is_shift_operation
                                    force_signals{j} = obj.subtract_alignment_body_signal(force_signal, body_force);
                                else
                                    forces(2,j) = forces(2,j) - mean(body_force);
                                end
                            end
                        end
                    end
                    disp(j + " of " + num_points + " complete")
                end

                if is_shift_operation
                    if obj.PIV_bool
                        forces(1,:) = obj.calculate_phase_shifts(PIV_signals, measured_freqs);
                    end
                    if obj.force_bool && ~isempty(load_cell_idx)
                        forces(2,:) = obj.calculate_phase_shifts(force_signals, measured_freqs);
                    end
                end

                % Calculate gain based on range of values
                if ~is_shift_operation
                    gain = range(forces(1,:))/2;
                    errors = gain * errors;
                end

                if info.x_axis_type == "wingbeat frequency" && obj.x_norm
                    missing_wind_indices = find(~isfinite(wind_speed_acts) & points.freqs > 0);
                    for k = missing_wind_indices
                        type = points.types(k);
                        amp = points.amps(k);
                        freq = points.freqs(k);
                        name = type + "_" + amp + "deg_" + freq + "Hz";
                        d = load(obj.PIV_path + name + "_phase_avg.mat", "U", "U_act");
                        wind_speed_acts(k) = d.U_act * d.U;
                    end
                end

                [x_var, x_label] = obj.get_x_axis_values(info.x_axis_type, points, measured_freqs, wind_speed_acts);
                xlabel(ax, x_label, Interpreter="latex")

                if is_shift_operation
                    ylabel(ax, "Phase shift magnitude (cycles)")

                    if obj.PIV_bool
                        s1 = scatter(ax, x_var, forces(1,:), 125, "filled");
                        s1.Marker = char(variable_marker);
                        s1.MarkerFaceColor = original_color;
                        s1.MarkerEdgeColor = original_color;
                        s1.DisplayName = legend_label;
                    end

                    if obj.force_bool && ~isempty(load_cell_idx)
                        s2 = scatter(ax, x_var, forces(2,:), 125, "filled");
                        s2.Marker = char(variable_marker);
                        s2.MarkerFaceColor = original_color;
                        s2.DisplayName = "Force: " + legend_label;
                    end
                elseif obj.err_bool && ~isempty(load_cell_idx)
                    ylabel(ax, "Error (N)")

                    error = (forces(1,:) - forces(2,:));
                    % error = abs((forces(1,:) - forces(2,:)) ./ forces(2,:)) * 100;
                    s1 = errorbar(ax, x_var, error, errors*0.1, char(variable_marker));
                    s1.MarkerSize = 10;
                    s1.Color = original_color;
                    s1.MarkerEdgeColor = original_color;
                    s1.MarkerFaceColor = original_color;
                    s1.DisplayName = legend_label;
                else
                    ylabel(ax, obj.get_force_vars_y_label(selected_force_vars), Interpreter="latex")

                    if obj.PIV_bool
                        s1 = errorbar(ax, x_var, forces(1,:), errors, char(variable_marker));
                        s1.MarkerSize = 10;
                        s1.Color = original_color;
                        s1.MarkerEdgeColor = original_color;
                        s1.MarkerFaceColor = original_color;
                        s1.DisplayName = legend_label;
                    end

                    if obj.force_bool && ~isempty(load_cell_idx)
                        s2 = scatter(ax, x_var, forces(2,:), 125,"filled");
                        s2.Marker = char(variable_marker);
                        s2.MarkerFaceColor = original_color;
                        s2.DisplayName = "Force: " + legend_label;
                    end
                end
            end
            end

            if (obj.saveFig)
                filename = "saved_figure.fig";
                fignew = figure('Visible','off'); % Invisible figure
                fignew.Position = [500,491,800,600];
                if (exist("l", "var"))
                    copyobj([l ax], fignew); % Copy the appropriate axes
                elseif (exist("cb", "var"))
                    copyobj([ax cb], fignew); % Copy the appropriate axes
                else
                    copyobj(ax, fignew); % Copy the appropriate axes
                end
    
                % set(fignew, 'Position', [200 200 800 600])
                set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
                savefig(fignew,filename);
                delete(fignew);
            end
        end

        function phase_shifts = calculate_phase_shifts(obj, signals, frequencies)
            phase_shifts = NaN(1, length(signals));
            if nargin < 3
                frequencies = [];
            end

            valid_indices = find(cellfun(@(signal) obj.is_valid_alignment_signal(signal), signals));

            if isempty(valid_indices)
                return
            end

            lengths = cellfun(@(signal) length(signal), signals(valid_indices));
            interp_length = min(lengths);
            time_interp = (1:interp_length) / interp_length;
            interp_signals = cell(1, length(signals));

            for i = 1:length(valid_indices)
                signal_idx = valid_indices(i);
                signal = signals{signal_idx};
                signal = signal(:)';
                time = (1:length(signal)) / length(signal);
                interp_signals{signal_idx} = interp1(time, signal, time_interp, 'pchip');
            end

            reference_idx = valid_indices(1);
            reference_signal = interp_signals{reference_idx};
            default_phase_shifts = phase_shifts;
            reverse_phase_shifts = phase_shifts;
            default_phase_shifts(reference_idx) = 0;
            reverse_phase_shifts(reference_idx) = 0;

            for i = 2:length(valid_indices)
                signal_idx = valid_indices(i);
                [~, lag_in_samples] = align_signals(reference_signal, interp_signals{signal_idx});
                circular_lag_in_samples = mod(lag_in_samples, interp_length);
                reverse_lag_in_samples = mod(-lag_in_samples, interp_length);
                default_phase_shifts(signal_idx) = circular_lag_in_samples / interp_length;
                reverse_phase_shifts(signal_idx) = reverse_lag_in_samples / interp_length;
            end

            phase_shifts = obj.select_monotonic_phase_direction(default_phase_shifts, reverse_phase_shifts, frequencies);
        end

        function phase_shifts = select_monotonic_phase_direction(obj, default_phase_shifts, reverse_phase_shifts, frequencies)
            phase_shifts = default_phase_shifts;

            if nargin < 4 || isempty(frequencies) || length(frequencies) ~= length(default_phase_shifts)
                return
            end

            valid = isfinite(default_phase_shifts) & isfinite(reverse_phase_shifts) & isfinite(frequencies);
            if nnz(valid) < 2 || length(unique(frequencies(valid))) < 2
                return
            end

            default_is_monotonic = obj.is_monotonic_with_frequency(default_phase_shifts, frequencies);
            reverse_is_monotonic = obj.is_monotonic_with_frequency(reverse_phase_shifts, frequencies);

            if reverse_is_monotonic && ~default_is_monotonic
                phase_shifts = reverse_phase_shifts;
            end
        end

        function monotonic = is_monotonic_with_frequency(~, phase_shifts, frequencies)
            valid = isfinite(phase_shifts) & isfinite(frequencies);
            sorted_values = sortrows([frequencies(valid)' phase_shifts(valid)'], 1);
            frequency_diffs = diff(sorted_values(:,1));
            phase_diffs = diff(sorted_values(:,2));
            monotonic = all(phase_diffs(frequency_diffs > 0) >= 0);
        end

        function valid = is_valid_alignment_signal(~, signal)
            if isempty(signal)
                valid = false;
                return
            end

            signal = signal(:);
            valid = length(signal) > 1 && all(isfinite(signal)) && std(signal) > 0;
        end

        function signal = apply_convection_shift(~, signal, type, freq_cor)
            dist = 0.9;
            sep_dist = 0.37;
            if contains(type, "UP_two")
                dist = dist + sep_dist*2;
            elseif contains(type, "UP_one")
                dist = dist + sep_dist;
            end

            speed = 4;
            conv_time = dist / speed;
            shift = conv_time * freq_cor;
            shift_samples = round(shift*length(signal));
            signal = circshift(signal, shift_samples);
            disp("Shifted by: " + shift_samples + " / " + length(signal))
        end

        function force_variable = is_piv_force_variable(obj, force_var)
            force_index = find(obj.var_names == force_var, 1);
            force_variable = ~isempty(force_index) && force_index <= 6;
        end

        function signal = subtract_alignment_body_signal(~, signal, body_signal)
            signal = signal(:)';
            body_signal = body_signal(:)';

            if length(signal) == length(body_signal)
                signal = signal - body_signal;
                return
            end

            signal_time = (1:length(signal)) / length(signal);
            body_time = (1:length(body_signal)) / length(body_signal);
            body_signal = interp1(body_time, body_signal, signal_time, 'pchip');
            signal = signal - body_signal;
        end
    end
end