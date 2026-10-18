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
        time_avg_path; % steady (0 Hz) cases, saved as mean flow fields
        % steady cases saved without amplitude/frequency in the name
        % (e.g. "x3_NACA", "x3_ring"); treated as amp = 0, freq = 0
        plain_steady_types;
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
        % which steady case to subtract: "ring", "body", or "gliding"
        PIV_sub_case;
        force_sub;
        RPCA;
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
            obj.time_avg_path = obj.root_path + "Processed Results\time_avg\";
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
            obj.PIV_sub_case = "ring";
            obj.force_sub = false;
            obj.RPCA = false;
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

            % Search through files in path to get types and speeds.
            % Phase averaged cases live in phase_avg\, the 0 Hz (gliding)
            % cases are time averaged and live in time_avg\.
            contents = dir(obj.PIV_path);
            files = contents(~[contents.isdir]);
            if isfolder(obj.time_avg_path)
                contents_t = dir(obj.time_avg_path);
                contents_t = contents_t(~[contents_t.isdir]);
                % 0 Hz cases named like the flapping ones (plain-named
                % steady cases are added below)
                is_zero_hz = ~cellfun(@isempty, regexp({contents_t.name}, '_0Hz_time_avg\.mat$', 'once'));
                files = [files; contents_t(is_zero_hz)];
            end

            % Get amps, freqs, types from file names
            obj.available_selections = get_sel_from_file(files);

            % Steady cases named without amplitude/frequency (e.g.
            % x3_NACA_time_avg.mat) are added as their own type with
            % amp = 0 and freq = 0
            obj.plain_steady_types = strings(0, 1);
            if isfolder(obj.time_avg_path)
                steady_names = string({contents_t.name});
                steady_names = steady_names(endsWith(steady_names, "_time_avg.mat") &...
                                            ~contains(steady_names, "Hz"));
                steady_types = erase(steady_names, "_time_avg.mat");
                obj.plain_steady_types = unique(steady_types(:), 'stable');
                for k = 1:length(obj.plain_steady_types)
                    obj.available_selections(end+1, :) = {obj.plain_steady_types(k), 0, 0};
                end
            end

            % drop duplicate cases (e.g. a 0 Hz file present in both folders)
            if ~isempty(obj.available_selections)
                sel_keys = string(obj.available_selections(:, 1)) + "|" +...
                    string(cell2mat(obj.available_selections(:, 2))) + "|" +...
                    string(cell2mat(obj.available_selections(:, 3)));
                [~, keep] = unique(sel_keys, 'stable');
                obj.available_selections = obj.available_selections(sort(keep), :);
            end

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
            % Create a GUI figure with a grid layout. The sidebar uses
            % layout managers so controls stay accessible as the window
            % changes size instead of relying on monitor-dependent pixels.
            [option_panel, plot_panel, ~] = setupFig(obj.mon_num);
            option_panel.AutoResizeChildren = true;
            if isprop(option_panel, "Scrollable")
                option_panel.Scrollable = "on";
            end

            sidebar_grid = uigridlayout(option_panel, [21, 1]);
            sidebar_grid.ColumnWidth = {'1x'};
            sidebar_grid.RowHeight = {30, 30, 30, 30, 30, 110, 30, 30, 30, 30,...
                                      30, 30, 25, 30, 30, 30, 30, 30, 30, 30, 30};
            sidebar_grid.Padding = [10 10 10 10];
            sidebar_grid.RowSpacing = 6;
            if isprop(sidebar_grid, "Scrollable")
                sidebar_grid.Scrollable = "on";
            end

            % Dropdown box for selecting the x-axis variable
            x_axis_dropdown = uidropdown(sidebar_grid);
            x_axis_dropdown.Layout.Row = 1;
            x_axis_dropdown.Layout.Column = 1;
            x_axis_dropdown.Items = obj.x_axis_labels(:);
            x_axis_dropdown.Value = obj.get_x_axis_label(obj.x_axis_type);

            % Dropdown boxes for variables held fixed while the x-axis varies
            fixed_dropdown_1 = uidropdown(sidebar_grid);
            fixed_dropdown_1.Layout.Row = 2;
            fixed_dropdown_1.Layout.Column = 1;

            fixed_dropdown_2 = uidropdown(sidebar_grid);
            fixed_dropdown_2.Layout.Row = 3;
            fixed_dropdown_2.Layout.Column = 1;
            obj.reset_fixed_variable_defaults();
            obj.update_fixed_dropdowns(fixed_dropdown_1, fixed_dropdown_2);

            rpca_button = uibutton(sidebar_grid, "state");
            rpca_button.Layout.Row = 4;
            rpca_button.Layout.Column = 1;
            rpca_button.Text = "RPCA";
            rpca_button.FontSize = 18;
            rpca_button.BackgroundColor = obj.get_button_color(obj.RPCA);
            rpca_button.ValueChangedFcn = @(src, event) RPCA_change(src, event);

            % Button to add entry
            entry_button_grid = uigridlayout(sidebar_grid, [1, 2]);
            entry_button_grid.Layout.Row = 5;
            entry_button_grid.Layout.Column = 1;
            entry_button_grid.ColumnWidth = {'1x', '1x'};
            entry_button_grid.RowHeight = {'1x'};
            entry_button_grid.Padding = [0 0 0 0];
            entry_button_grid.ColumnSpacing = 8;

            add_button = uibutton(entry_button_grid);
            add_button.Layout.Row = 1;
            add_button.Layout.Column = 1;
            add_button.Text = "Add entry";

            % Button to remove entry
            delete_button = uibutton(entry_button_grid);
            delete_button.Layout.Row = 1;
            delete_button.Layout.Column = 2;
            delete_button.Text = "Delete entry";

            % List of cases currently displayed on the plots
            lbox = uilistbox(sidebar_grid);
            lbox.Layout.Row = 6;
            lbox.Layout.Column = 1;
            lbox.Items = strings(0);

            x_axis_dropdown.ValueChangedFcn = @(src, event) x_axis_change(src, event, fixed_dropdown_1, fixed_dropdown_2, plot_panel, lbox);
            fixed_dropdown_1.ValueChangedFcn = @(src, event) fixed_1_change(src, event, fixed_dropdown_2);
            fixed_dropdown_2.ValueChangedFcn = @(src, event) fixed_2_change(src, event);
            add_button.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
            delete_button.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

            clear_button = uibutton(sidebar_grid);
            clear_button.Layout.Row = 7;
            clear_button.Layout.Column = 1;
            clear_button.Text = "Clear Entries";
            clear_button.FontSize = 18;
            clear_button.BackgroundColor = [1 1 1];
            clear_button.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

            % Dropdown boxes for variable selection
            force_var_dropdown_1 = uidropdown(sidebar_grid);
            force_var_dropdown_1.Layout.Row = 8;
            force_var_dropdown_1.Layout.Column = 1;
            force_var_dropdown_1.Items = ["none", obj.box_labels];
            force_var_dropdown_1.Value = obj.get_force_var_label(obj.force_var);

            force_var_dropdown_2 = uidropdown(sidebar_grid);
            force_var_dropdown_2.Layout.Row = 9;
            force_var_dropdown_2.Layout.Column = 1;
            force_var_dropdown_2.Items = ["none", obj.box_labels];
            force_var_dropdown_2.Value = "none";
            force_var_dropdown_1.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, force_var_dropdown_1, force_var_dropdown_2);
            force_var_dropdown_2.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, force_var_dropdown_1, force_var_dropdown_2);

            operation_dropdown = uidropdown(sidebar_grid);
            operation_dropdown.Layout.Row = 10;
            operation_dropdown.Layout.Column = 1;
            operation_dropdown.Items = obj.operations;
            operation_dropdown.ValueChangedFcn = @(src, event) operation_change(src, event, plot_panel);

            piv_button = uibutton(sidebar_grid, "state");
            piv_button.Layout.Row = 11;
            piv_button.Layout.Column = 1;
            piv_button.Text = "Show PIV";
            piv_button.Value = true;
            piv_button.FontSize = 18;
            piv_button.BackgroundColor = obj.COLOR_ACTIVE;
            piv_button.ValueChangedFcn = @(src, event) PIV_bool_change(src, event, plot_panel);

            piv_sub_button = uibutton(sidebar_grid, "state");
            piv_sub_button.Layout.Row = 12;
            piv_sub_button.Layout.Column = 1;
            piv_sub_button.Text = "PIV Body Sub";
            piv_sub_button.FontSize = 18;
            piv_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            piv_sub_button.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

            % Steady case used for the subtraction, matched to each
            % selection's downstream position (and amplitude for body/gliding)
            piv_sub_dropdown = uidropdown(sidebar_grid);
            piv_sub_dropdown.Layout.Row = 13;
            piv_sub_dropdown.Layout.Column = 1;
            piv_sub_dropdown.Items = ["ring", "body", "gliding"];
            piv_sub_dropdown.Value = obj.PIV_sub_case;
            piv_sub_dropdown.Tooltip = "Steady case subtracted (e.g. for x3_wings_20deg_4Hz: ring = x3_ring, body = x3_body_20deg_0Hz, gliding = x3_wings_20deg_0Hz)";
            piv_sub_dropdown.ValueChangedFcn = @(src, event) PIV_sub_case_change(src, event, plot_panel);

            force_button = uibutton(sidebar_grid, "state");
            force_button.Layout.Row = 14;
            force_button.Layout.Column = 1;
            force_button.Text = "Show Force";
            force_button.FontSize = 18;
            force_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_button.ValueChangedFcn = @(src, event) force_bool_change(src, event, plot_panel);

            force_sub_button = uibutton(sidebar_grid, "state");
            force_sub_button.Layout.Row = 15;
            force_sub_button.Layout.Column = 1;
            force_sub_button.Text = "Force Body Sub";
            force_sub_button.FontSize = 18;
            force_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_sub_button.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

            x_norm_button = uibutton(sidebar_grid, "state");
            x_norm_button.Layout.Row = 16;
            x_norm_button.Layout.Column = 1;
            x_norm_button.Text = "Normalize X-axis";
            x_norm_button.FontSize = 18;
            x_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            x_norm_button.ValueChangedFcn = @(src, event) x_norm_change(src, event, plot_panel);

            y_norm_button = uibutton(sidebar_grid, "state");
            y_norm_button.Layout.Row = 17;
            y_norm_button.Layout.Column = 1;
            y_norm_button.Text = "Normalize Y-axis";
            y_norm_button.FontSize = 18;
            y_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            y_norm_button.ValueChangedFcn = @(src, event) y_norm_change(src, event, plot_panel);

            err_button = uibutton(sidebar_grid, "state");
            err_button.Layout.Row = 18;
            err_button.Layout.Column = 1;
            err_button.Text = "Error";
            err_button.FontSize = 18;
            err_button.BackgroundColor = obj.COLOR_INACTIVE;
            err_button.ValueChangedFcn = @(src, event) err_change(src, event, plot_panel);

            y_cen_field = uieditfield(sidebar_grid, 'numeric');
            y_cen_field.Layout.Row = 19;
            y_cen_field.Layout.Column = 1;
            y_cen_field.Value = obj.y_cen;
            y_cen_field.ValueChangedFcn = @(src, event) y_cen_change(src, event, plot_panel);

            calc_button = uibutton(sidebar_grid, "state");
            calc_button.Layout.Row = 20;
            calc_button.Layout.Column = 1;
            calc_button.Text = "Live Calculate";
            calc_button.FontSize = 18;
            calc_button.BackgroundColor = obj.COLOR_INACTIVE;
            calc_button.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel);

            save_fig_button = uibutton(sidebar_grid);
            save_fig_button.Layout.Row = 21;
            save_fig_button.Layout.Column = 1;
            save_fig_button.Text = "Save Fig";
            save_fig_button.FontSize = 18;
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

            function PIV_sub_case_change(src, ~, plot_panel)
                obj.PIV_sub_case = string(src.Value);
                if obj.PIV_sub
                    obj.update_plot(plot_panel);
                end
            end

            function RPCA_change(src, ~)
                obj.RPCA = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.RPCA);
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
                    if obj.RPCA
                        selection_key = selection_key + "|RPCA=true";
                    end
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
            info = struct("x_axis_type", parts(1), "type", "", "amp", NaN, "freq", NaN, "RPCA", false);

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
                    case "RPCA"
                        info.RPCA = string(value) == "true";
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

            if info.RPCA
                label = label + " | RPCA";
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

            if info.RPCA
                label = label + " - RPCA";
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

        function label = get_load_cell_legend_label(obj, curve_label, load_cell_idx)
            % The load cell gives total lift or drag, with no breakdown
            % into the STB terms
            switch load_cell_idx
                case 1
                    quantity = "drag";
                case 3
                    quantity = "lift";
                otherwise
                    quantity = "";
            end

            label = "Force: " + quantity;
            if length(obj.selection) > 1
                label = label + " - " + curve_label;
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

            % The load cell only measures total lift or drag, so several STB
            % terms (e.g. lift.vortX and lift.vortY) share one load cell
            % series. Track which ones are already on the plot so each is
            % drawn once per selection.
            plotted_load_cell_keys = strings(0);

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
                % load cell points use a lighter shade of the STB color
                % (getLightColor takes a hex color)
                force_color = getLightColor(rgb2hex(original_color));
                curve_label = obj.get_curve_label(info);
                legend_label = obj.get_plot_legend_label(curve_label, force_var, num_vars);

                % plot this load cell series only the first time it comes up
                show_load_cell = false;
                if obj.force_bool && ~isempty(load_cell_idx)
                    load_cell_key = string(i) + "|" + string(load_cell_idx);
                    if ~ismember(load_cell_key, plotted_load_cell_keys)
                        show_load_cell = true;
                        plotted_load_cell_keys(end+1) = load_cell_key;
                    end
                end
                force_legend_label = obj.get_load_cell_legend_label(curve_label, load_cell_idx);

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
                        name = obj.get_case_name(type, amp, freq);
                        % RPCA only applies to phase averaged cases
                        if info.RPCA && freq ~= 0
                            name = name + "_RPCA";
                        end
                        if freq == 0
                            suffix = "_time_avg";
                        else
                            suffix = "_phase_avg";
                        end
                        case_dir = obj.get_case_dir(name, suffix);
                        filepath = case_dir + name + suffix + ".mat";
                        secondary_filepath = case_dir + name + suffix + "_integral.mat";

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
                            [var, err] = get_PIV_force(filepath, name, force_var, avg_type, obj.y_norm, obj.get_trim_bounds());

                            if obj.PIV_sub
                                [bod_filepath, ~] = obj.get_PIV_sub_file_paths(type, amp);
                                [bod_var, ~] = get_PIV_force(bod_filepath, "", force_var, 0, obj.y_norm, obj.get_trim_bounds());
                                var = var - bod_var;
                            end
                        elseif ~is_shift_operation || freq > 0
                            % variables not defined for a case (e.g.
                            % lift.vortY for a 0 Hz mean flow field) are
                            % replaced with zero
                            if contains(force_var, ".")
                                var_file = secondary_filepath;
                            else
                                var_file = obj.get_stored_var_file(force_var, filepath, secondary_filepath);
                            end
                            var = obj.load_stored_var(var_file, force_var);

                            % TEMPORARY for dimensionalization of power
                            % var = var * (1/2) * density * wind_speed^3 * area;

                            if obj.PIV_sub
                                [~, bod_secondary_filepath] = obj.get_PIV_sub_file_paths(type, amp);
                                bod_var = obj.load_stored_var(bod_secondary_filepath, force_var);
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
                        % var_name_F = "results_lab";
                        var_name_F = "filtered_data";
                        % var_name_F = "wingbeat_avg_forces_smoothest";
                        if freq == 0
                            % var_name_F = "results_lab";
                            var_name_F = "filtered_data";
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

                            if obj.force_sub && obj.is_plain_steady_type(type)
                                disp("Force Body Sub skipped for steady case " + type)
                            elseif obj.force_sub
                                body_amp = amp;
                                if body_amp == 30
                                    body_amp = 20;
                                end
                                % keep the downstream prefix (e.g. "x3_") so get_force uses the
                                % new flapper body folder ("20 deg body") rather than the old one
                                body_type = string(regexp(char(type), '^x\d+_', 'match', 'once')) + "body";
                                body_force = get_force(obj.force_path, body_type, body_amp, freq, idx, var_name_F);
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
                        name = obj.get_case_name(type, amp, freq);
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

                    if show_load_cell
                        s2 = scatter(ax, x_var, forces(2,:), 125, "filled");
                        s2.Marker = char(variable_marker);
                        s2.MarkerFaceColor = force_color;
                        s2.MarkerEdgeColor = original_color;
                        s2.DisplayName = force_legend_label;
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

                    if show_load_cell
                        s2 = scatter(ax, x_var, forces(2,:), 125,"filled");
                        s2.Marker = char(variable_marker);
                        s2.MarkerFaceColor = force_color;
                        s2.MarkerEdgeColor = original_color;
                        s2.DisplayName = force_legend_label;
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

        function case_dir = get_case_dir(obj, name, suffix)
            % Folder holding a case: phase_avg\ first, then time_avg\
            % (where the 0 Hz mean flow field cases are saved)
            case_dir = obj.PIV_path;
            if ~isfile(case_dir + name + suffix + ".mat") &&...
                    ~isfile(case_dir + name + suffix + "_integral.mat") &&...
                    (isfile(obj.time_avg_path + name + suffix + ".mat") ||...
                     isfile(obj.time_avg_path + name + suffix + "_integral.mat"))
                case_dir = obj.time_avg_path;
            end
        end

        function file = get_stored_var_file(~, force_var, filepath, secondary_filepath)
            % a few variables are stored in the main file, the rest in
            % the secondary (integral) file
            if ismember(force_var, ["U_act", "num_bins","num_clusters","phase_spread_ratio"])
                file = filepath;
            else
                file = secondary_filepath;
            end
        end

        function var = load_stored_var(~, file, var_name)
            % Load a (possibly nested, e.g. "lift.vortY") variable from a
            % .mat file. If the file exists but the variable or field is
            % not defined for this case, return 0 and say so.
            parts = split(string(var_name), ".");
            [~, file_name] = fileparts(file);

            if ~isfile(file)
                error("timeAvg_UI:fileNotFound", "File not found: %s", file);
            end

            if ismember(char(parts(1)), who('-file', file))
                d = load(file, parts(1));
                var = d.(parts(1));
                for k = 2:numel(parts)
                    if isstruct(var) && isfield(var, parts(k))
                        var = var.(parts(k));
                    else
                        var = [];
                        break
                    end
                end
                if ~isempty(var)
                    return
                end
            end

            fprintf("%s not defined for %s, using 0\n", var_name, file_name);
            var = 0;
        end

        function bounds = get_trim_bounds(~)
            % Region of the wake kept for live-calculated forces
            % (get_PIV_force -> trim_vel_field), nondimensional (divided by L).
            % Matches the values in process_case.m used for the stored forces.
            bounds.ybounds = [-2.4 2.8];
            bounds.zbounds = [-2.9 3.1];
            bounds.y_cen = -2.06;
            bounds.z_cen = -0.35;
        end

        function tf = is_plain_steady_type(obj, type)
            tf = ismember(string(type), obj.plain_steady_types);
        end

        function name = get_case_name(obj, type, amp, freq)
            % File stem for a case: "x3_wings_20deg_4Hz", or just the type
            % for plain-named steady cases ("x3_NACA")
            if obj.is_plain_steady_type(type)
                name = string(type);
            else
                name = type + "_" + amp + "deg_" + freq + "Hz";
            end
        end

        function [file_path, secondary_file_path] = get_PIV_sub_file_paths(obj, type, amp)
            % Steady (time averaged) case subtracted from a selection when
            % "PIV Body Sub" is on. For x3_wings_20deg_4Hz:
            %   ring    -> x3_ring
            %   body    -> x3_body_20deg_0Hz
            %   gliding -> x3_wings_20deg_0Hz
            type = string(type);
            amp = string(amp);

            % downstream / upstream prefix shared by the steady cases
            prefix = string(regexp(char(type), '^(x\d+_|UP_one_|UP_two_)', 'match', 'once'));

            switch obj.PIV_sub_case
                case "ring"
                    case_names = prefix + "ring";
                case "body"
                    % older body cases were saved without an amplitude
                    case_names = [prefix + "body_" + amp + "deg_0Hz", prefix + "body"];
                case "gliding"
                    if obj.is_plain_steady_type(type)
                        % a steady case is its own gliding case
                        case_names = type;
                    else
                        case_names = type + "_" + amp + "deg_0Hz";
                    end
                otherwise
                    error("Unknown PIV subtraction case: %s", obj.PIV_sub_case);
            end

            % steady cases may sit in a time_avg subfolder (old ring
            % location), next to the phase averaged files, or in
            % Processed Results\time_avg
            search_dirs = [obj.PIV_path + "time_avg\", obj.PIV_path,...
                           obj.root_path + "Processed Results\time_avg\"];

            tried = strings(0);
            for k = 1:length(case_names)
                for m = 1:length(search_dirs)
                    file_path = search_dirs(m) + case_names(k) + "_time_avg.mat";
                    secondary_file_path = search_dirs(m) + case_names(k) + "_time_avg_integral.mat";
                    tried(end+1) = file_path; %#ok<AGROW>
                    if isfile(file_path) || isfile(secondary_file_path)
                        return
                    end
                end
            end

            error("timeAvg_UI:PIVSubNotFound",...
                "No %s subtraction case found for %s at %s deg. Looked for:\n  %s",...
                obj.PIV_sub_case, type, amp, strjoin(tried, "\n  "));
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