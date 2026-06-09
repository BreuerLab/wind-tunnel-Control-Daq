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

        filt_num;

        force_bool;
        force_var;
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
            obj.PIV_path = obj.root_path + "Processed Results\";
            obj.force_path = obj.root_path + "Force Measurements\";

            obj.index = 1;
            obj.box_labels = ["lift vortX", "lift vortY", "lift vel diff", "lift vel", "drag_vort", "drag_vel",...
                            "speed", "speed error", "voltage", "current", "electric power", "KE",...
                            "KE wake", "power wake", "KE Full", "enstrophy",...
                            "helicity", "avg u", "avg v", "avg w", "pitot U", "total uncertainty", "# particles", "# bins"];
            obj.var_names = ["lift.vortX", "lift.vortY", "lift.vel", "lift_vel", "drag.tot", "drag_vel",...
                "phase_avg_speed", "phase_avg_speed_error", "phase_avg_volt", "phase_avg_cur", "phase_avg_power", "KE",...
                "KE_diff", "power", "KE_tot", "enst", "hel_avg",...
                "u_avg", "v_avg", "w_avg", "U_act", "unc_avg", "numP_avg", "num_bins"];
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
                "Freestream Speed", "Uncertainty", "count", "count"];
            obj.PIV_sub = false;
            obj.force_sub = false;
            obj.filt_num = 3;
            obj.operation = "mean";

            obj.x_norm = false;
            obj.y_norm = false;
            obj.force_bool = false;
            obj.PIV_bool = true;
            obj.force_var = obj.var_names(1);
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

            [selection_types, obj.distance_labels] = obj.get_available_type_options();
            obj.sel_type = selection_types(1);
            obj.sel_amp = obj.get_first_amp(obj.sel_type);
            obj.distance_type_dict = containers.Map(cellstr(obj.distance_labels), cellstr(selection_types));
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
            drop_y1 = screen_height*0.85 - 30;
            type_dropdown = uidropdown(option_panel);
            type_dropdown.Position = [10 drop_y1 180 30];
            type_dropdown.Items = obj.distance_labels(:);

            % Dropdown box for wingbeat amplitude selection
            drop_y3 = drop_y1 - (unit_height + unit_spacing);
            amp_dropdown = uidropdown(option_panel);
            amp_dropdown.Position = [10 drop_y3 180 unit_height];
            cur_amps = obj.get_amp_options(obj.sel_type);
            amp_dropdown.Items = string(cur_amps) + " deg";
            amp_dropdown.ValueChangedFcn = @(src, event) amp_change(src, event);
            type_dropdown.ValueChangedFcn = @(src, event) type_change(src, event, amp_dropdown);

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

            add_button.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
            delete_button.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

            % Dropdown box for force variable selection
            drop_y4 = list_y - 35;
            force_var_dropdown = uidropdown(option_panel);
            force_var_dropdown.Position = [10 drop_y4 180 30];
            force_var_dropdown.Items = obj.box_labels;
            force_var_dropdown.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel);

            drop_y44 = drop_y4 - 35;
            operation_dropdown = uidropdown(option_panel);
            operation_dropdown.Position = [10 drop_y44 180 30];
            operation_dropdown.Items = obj.operations;
            operation_dropdown.ValueChangedFcn = @(src, event) operation_change(src, event, plot_panel);

            button4_y = drop_y44 - (unit_height + unit_spacing);
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
            
            function type_change(src, ~, amp_dropdown)
                obj.sel_type = string(obj.distance_type_dict(char(src.Value)));
                obj.sel_amp = obj.get_first_amp(obj.sel_type);
                obj.update_amp_dropdown(amp_dropdown);
            end

            function amp_change(src, ~)
                obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));
            end

            function force_var_change(src, ~, plot_panel)
                obj.force_var = obj.var_names(obj.box_labels == src.Value);
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
                case_name = obj.sel_type + "_" + obj.sel_amp + "deg";

                if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                    lbox.Items = [lbox.Items, case_name];
                    obj.selection = [obj.selection, case_name];
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
            selection_types = strings(0, 1);
            selection_labels = strings(0, 1);

            known_distance_labels = ["x = 0.9m"; "x = 1.3m"; "x = 1.7m"];
            for i = 1:length(obj.cur_types)
                type = obj.cur_types(i);
                if any(available_types == type)
                    selection_types(end + 1, 1) = type;
                    selection_labels(end + 1, 1) = known_distance_labels(i);
                end
            end

            other_types = setdiff(available_types, selection_types, 'stable');
            selection_types = [selection_types; other_types(:)];
            selection_labels = [selection_labels; other_types(:)];
        end

        function amps = get_amp_options(obj, selected_type)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            amps = unique(selection_amps(selection_types == string(selected_type)));
        end

        function amp = get_first_amp(obj, selected_type)
            amps = obj.get_amp_options(selected_type);
            amp = amps(1);
        end

        function update_amp_dropdown(obj, dropdown)
            amps = obj.get_amp_options(obj.sel_type);
            dropdown.Items = string(amps(:)) + " deg";
            dropdown.Value = string(obj.sel_amp) + " deg";
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

        % Update plot after user changes selected variables
        function update_plot(obj, plot_panel)
            delete(plot_panel.Children)

            uniq_types = unique(string(obj.available_selections(:,1)));
            uniq_amps = unique(cell2mat(obj.available_selections(:,2)));

            colors = getColors(1,...
                       length(uniq_types),...
                       length(uniq_amps),...
                       length(obj.selection));

            ax = axes(plot_panel);
            hold(ax, 'on');
            l = legend(ax, Location="best");
            set(ax, FontSize=18)

            is_shift_operation = strcmp(obj.operation, "shift");

            for i = 1:length(obj.selection) % Loop through each selection
                [amp, type] = parse_name(obj.selection(i));

                original_color = colors(find(uniq_amps == amp), find(uniq_types == type));

                mask = cell2mat(obj.available_selections(:,2)) == amp & strcmp(string(obj.available_selections(:,1)), type);
                freqs = cell2mat(obj.available_selections(mask,3));
                forces = zeros(2, length(freqs));
                if is_shift_operation
                    forces(:) = NaN;
                end
                errors = zeros(1, length(freqs));
                measured_freqs = freqs;
                PIV_signals = cell(1, length(freqs));
                force_signals = cell(1, length(freqs));
                
                for j = 1:length(freqs) % Loop through all wingbeat frequencies
                    if obj.PIV_bool
                        name = type + "_" + amp + "deg_" + freqs(j) + "Hz";
                        if freqs(j) == 0
                            suffix = "_time_avg";
                        else
                            suffix = "_phase_avg";
                        end
                        filepath = obj.PIV_path + name + suffix + ".mat";
                        secondary_filepath = obj.PIV_path + name + suffix + "_integral.mat";

                        if freqs(j) == 0
                            avg_type = 0;
                            measured_freqs(j) = 0;
                            errors(j) = 0;
                        else
                            avg_type = 1;
                            d = load(filepath, "U", "L", "U_act", "rho_act", "bin_std");
                            F = load(secondary_filepath, "phase_avg_speed");
                            measured_freqs(j) = mean(F.phase_avg_speed);
                            % gain = 0.01;
                            % gain = 0.001;
                            errors(j) = mean(d.bin_std);
                            % errors(j) = 0;
                            wind_speed = d.U;
                            density = d.rho_act;
                            area = d.L * d.L * 3 * 2;
                            wind_speed_act = d.U_act * d.U;
                            % errors(j) = 0.2 / length(d.bin_std);
                        end

                        if is_shift_operation && freqs(j) == 0
                            disp("Skipping 0 Hz time-average case for phase shift")
                        elseif obj.calc_bool
                            [var, err] = get_PIV_force(filepath, name, obj.force_var, avg_type, obj.y_norm, obj.y_cen);

                            if obj.PIV_sub
                                % filename = "body_time_avg.mat";
                                filename = "ring_time_avg.mat";
                                bod_filepath = obj.PIV_path + "time_avg/" + filename;
                                [bod_var, ~] = get_PIV_force(bod_filepath, "", obj.force_var, 0, obj.y_norm, obj.y_cen);
                                var = var - bod_var;
                            end
                        elseif ~is_shift_operation || freqs(j) > 0
                            if contains(obj.force_var, ".")
                                abbrv_name = extractBefore(obj.force_var, ".");
                                d = load(secondary_filepath, abbrv_name);

                                var = eval("d." + obj.force_var);
                            else
                                if obj.force_var == "U_act"
                                    d = load(filepath, obj.force_var);
                                else
                                    d = load(secondary_filepath, obj.force_var);
                                end
                                var = d.(obj.force_var);
                            end

                            % TEMPORARY for dimensionalization of power
                            % var = var * (1/2) * density * wind_speed^3 * area;

                            if obj.PIV_sub
                                % filename = "body_time_avg.mat";
                                filename = "ring_time_avg_integral.mat";
                                if contains(obj.force_var, ".")
                                    abbrv_name = extractBefore(obj.force_var, ".");
                                    bod = load(obj.PIV_path + "time_avg/" + filename, abbrv_name);
                                    bod_var = eval("bod." + obj.force_var);
                                else
                                    bod = load(obj.PIV_path + "time_avg/" + filename, obj.force_var);
                                    bod_var = bod.(obj.force_var);
                                end
                                var = var - bod_var;
                            end  
                        end
                        
                        % Calculate mean force and store in array for plotting
                        if is_shift_operation && freqs(j) > 0
                            if obj.is_piv_force_variable()
                                var = obj.apply_convection_shift(var, type, measured_freqs(j));
                            end
                            PIV_signals{j} = var;
                        elseif strcmp(obj.operation, "mean")
                            forces(1,j) = mean(var);
                        elseif strcmp(obj.operation, "range")
                            forces(1,j) = range(var);
                        end
                    end

                    if obj.force_bool && ~contains(type, "UP")
                        var_name_F = "results_lab";
                        % var_name_F = "filtered_data";
                        % var_name_F = "wingbeat_avg_forces_smoothest";
                        if freqs(j) == 0
                            var_name_F = "results_lab";
                            % var_name_F = "filtered_data";
                        end

                        if contains(obj.force_var,"drag")
                            idx = 1;
                        elseif contains(obj.force_var, "lift")
                            idx = 3;
                        end

                        if is_shift_operation && freqs(j) == 0
                            disp("Skipping 0 Hz force case for phase shift")
                        else
                            force_signal = get_force(obj.force_path, type, amp, freqs(j), idx, var_name_F);

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
                                body_force = get_force(obj.force_path, "body", body_amp, freqs(j), idx, var_name_F);
                                if is_shift_operation
                                    force_signals{j} = obj.subtract_alignment_body_signal(force_signal, body_force);
                                else
                                    forces(2,j) = forces(2,j) - mean(body_force);
                                end
                            end
                        end
                    end
                    disp(j + " of " + length(freqs) + " complete")
                end

                if is_shift_operation
                    if obj.PIV_bool
                        forces(1,:) = obj.calculate_phase_shifts(PIV_signals);
                    end
                    if obj.force_bool && ~contains(type, "UP")
                        forces(2,:) = obj.calculate_phase_shifts(force_signals);
                    end
                end

                % Calculate gain based on range of values
                if ~is_shift_operation
                    gain = range(forces(1,:))/2;
                    errors = gain * errors;
                end

                % x-axis is either wingbeat frequency or Strouhal number
                if obj.x_norm
                    Sts = freqToSt(measured_freqs, wind_speed_act, amp);
                    x_var = Sts;
                    x_label = "Strouhal Number";
                else
                    x_var = measured_freqs;
                    x_label = "Wingbeat Frequency (Hz)";
                end

                xlabel(ax, x_label, Interpreter="latex")

                if is_shift_operation
                    ylabel(ax, "Phase shift (cycles)")

                    if obj.PIV_bool
                        s1 = scatter(ax, x_var, forces(1,:), 125, "filled");
                        s1.Marker = "o";
                        s1.MarkerFaceColor = original_color;
                        s1.MarkerEdgeColor = original_color;
                        s1.DisplayName = "PIV shift: " + strrep(type,"_"," ") + ", " + amp + " deg";
                    end

                    if obj.force_bool && ~contains(type, "UP")
                        s2 = scatter(ax, x_var, forces(2,:), 125, "filled");
                        s2.Marker = "p";
                        s2.MarkerFaceColor = original_color;
                        s2.DisplayName = "Force shift: " + strrep(type,"_"," ") + ", " + amp + " deg";
                    end
                elseif obj.err_bool
                    ylabel(ax, "Error (N)")

                    error = (forces(1,:) - forces(2,:));
                    % error = abs((forces(1,:) - forces(2,:)) ./ forces(2,:)) * 100;
                    s1 = errorbar(ax, x_var, error, errors*0.1, 'o');
                    s1.MarkerSize = 10;
                    s1.Color = original_color;
                    s1.MarkerEdgeColor = original_color;
                    s1.MarkerFaceColor = original_color;
                    s1.DisplayName = strrep(type,"_"," ") + ", " + amp + " deg";
                else
                ylabel(ax, obj.y_labels(obj.var_names == obj.force_var), Interpreter="latex")

                if obj.PIV_bool
                    s1 = errorbar(ax, x_var, forces(1,:), errors, 'o');
                    s1.MarkerSize = 10;
                    s1.Color = original_color;
                    s1.MarkerEdgeColor = original_color;
                    s1.MarkerFaceColor = original_color;
                    s1.DisplayName = strrep(type,"_"," ") + ", " + amp + " deg";
                end
                
                if obj.force_bool && ~contains(type, "UP")
                    s2 = scatter(ax, x_var, forces(2,:), 125,"filled");
                    s2.Marker = "p";
                    s2.MarkerFaceColor = original_color;
                    s2.DisplayName = "Force: " + strrep(type,"_"," ") + ", " + amp + " deg";
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

        function phase_shifts = calculate_phase_shifts(obj, signals)
            phase_shifts = NaN(1, length(signals));
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
            phase_shifts(reference_idx) = 0;

            for i = 2:length(valid_indices)
                signal_idx = valid_indices(i);
                [~, lag_in_samples] = align_signals(reference_signal, interp_signals{signal_idx});
                phase_shifts(signal_idx) = lag_in_samples / interp_length;
            end
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

        function force_variable = is_piv_force_variable(obj)
            force_index = find(obj.var_names == obj.force_var, 1);
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