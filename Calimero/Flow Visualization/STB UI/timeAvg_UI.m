% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef timeAvg_UI < handle
    
    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];
        % rmse: rms of the signal minus its mean, i.e. the size of the
        % fluctuation about the mean
        operations = ["mean", "range", "rmse", "shift"];
        cur_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
        x_axis_types = ["wingbeat frequency", "wingbeat amplitude", "downstream distance"];
        x_axis_labels = ["Wingbeat Frequency", "Wingbeat Amplitude", "Downstream Distance"];
        % Load cell data options (variables saved by process_trial.m). The
        % cutoffs fc are multiples of the wingbeat frequency f (fixed
        % 10 / 10 / 4 Hz for 0 Hz trials). "phase-averaged" = the
        % wingbeat_forces arrays (data split into wingbeats), only saved
        % for flapping trials.
        load_cell_data_labels = ["raw", "fc = 10*f", "fc = 5*f", "fc = 2*f",...
            "raw phase-averaged", "fc = 10*f phase-averaged",...
            "fc = 5*f phase-averaged", "fc = 2*f phase-averaged"];
        load_cell_data_vars = ["mod_results", "filtered_data",...
            "filtered_data_smoother", "filtered_data_smoothest",...
            "wingbeat_forces_raw", "wingbeat_forces",...
            "wingbeat_forces_smoother", "wingbeat_forces_smoothest"];
        downstream_distances = [0.9; 1.3; 1.7];
        downstream_distance_labels = ["x = 0.9m"; "x = 1.3m"; "x = 1.7m"];
    end

    properties

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
        % "kinematics", "flow", "force" or "BA: force" for each variable,
        % and the type currently shown in the variable dropdowns
        var_categories;
        var_type;
        y_labels;

        % boolean, normalization/non-dimensionalization on or off
        y_norm;
        % boolean, plot the two selected variables on left/right y-axes
        separate_y_axis_bool;
        x_norm;
        x_axis_type;

        filt_num;

        % variable read from the processed load cell file for forces,
        % voltage and current (one of load_cell_data_vars)
        load_cell_data_var;
        force_var;
        force_vars;
        PIV_sub;
        % which steady case to subtract: "ring", "body", or "gliding"
        PIV_sub_case;
        force_sub;
        RPCA;
        % harmonic regression files (_hr, from bools.harmonic_reg)
        HR;
        % Difference: plot variable 1 minus variables 2 (and 3)
        diff_bool;
        calc_bool;
        % shift mode: phase shift imaging-plane (STB) signals by the wake's
        % convection time from the robot to the imaging plane
        conv_shift;
        % shift mode: unwrap the phase shifts along the x-axis (remove
        % jumps of a whole wingbeat between neighbouring points)
        unwrap_shift;

        % trim limits and center point used by Live Calculate
        % (get_PIV_force -> trim_vel_field); starts from
        % default_trim_bounds() and is adjusted in the sidebar
        trim_bounds;
        % Live Calculate uncertainty mask: points whose wingbeat-averaged
        % total uncertainty exceeds unc_mask_pct % of the freestream add
        % nothing to the force integrals (trim_bounds.unc_mask, see
        % get_PIV_force)
        unc_mask_bool;
        unc_mask_pct;

        % ------- Available parameters user can select from -------
        available_selections;

        selection; % list of selected cases
        % wingbeat frequencies in the data and the [low high] range plotted
        % when the x-axis is wingbeat frequency
        available_freqs;
        freq_range;
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
        function obj = timeAvg_UI(data_path)
            obj.root_path = data_path;
            obj.PIV_path = obj.root_path + "Processed Results\phase_avg\";
            obj.time_avg_path = obj.root_path + "Processed Results\time_avg\";
            obj.force_path = obj.root_path + "Force Measurements\";

            obj.index = 1;
            obj.box_labels = ["lift vortX", "lift vortY", "lift vel diff", "lift vel", "drag vort", "drag vel",...
                            "speed", "speed error", "voltage", "current", "electric power", "KE",...
                            "KE wake", "power wake", "KE Full", "enstrophy",...
                            "helicity", "avg u", "avg v", "avg w", "pitot U", "density", "total uncertainty",...
                            "# particles", "# bins", "# clusters", "phase spread ratio"];
            obj.var_names = ["lift.vortX", "lift.vortY", "lift.vel_diff", "lift_vel", "drag.tot", "drag_vel",...
                "phase_avg_speed", "phase_avg_speed_error", "phase_avg_volt", "phase_avg_cur", "phase_avg_power", "KE",...
                "KE_diff", "power", "KE_tot", "enst", "hel_avg",...
                "u_avg", "v_avg", "w_avg", "U_act", "rho_act", "unc_avg",...
                "numP_avg", "num_bins", "num_clusters", "phase_spread_ratio"];
            % obj.var_names = ["lift_before_avg", "lift_vel", "drag_before_avg", "drag_vel",...
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
                "Freestream Speed", "Density", "Uncertainty", "count", "count", "count", ""];

            % omega_x centroid position (flow) and bin-averaged forces
            % (BA: force, stored as lift_before_avg / drag_before_avg)
            % (no BA lift vortY: phase_avg_STB computes the per-frame lift
            % at a single convection position, so lift_before_avg has no
            % vortY field)
            % BA lift vel / drag vel are the velocity-only estimates
            % bin averaged in phase_avg_STB (lift_vel_before_avg,
            % drag_vel_before_avg)
            obj.box_labels = [obj.box_labels, "lift vortX (u avg)", "drag vort (u avg)",...
                "wx centroid y", "wx centroid z", "Q centroid y", "Q centroid z",...
                "BA: lift vortX", "BA: lift vel diff", "BA: lift vel", "BA: drag vort", "BA: drag vel",...
                "lift vortY (edge)", "lift vortX (taper)",...
                "TA: lift vortX", "TA: lift vel diff", "TA: lift vel", "TA: drag vort", "TA: drag vel",...
                "lift vel (extrap)", "drag vel (extrap)", "lift vel (extrap fill)", "drag vel (extrap fill)"];
            obj.var_names = [obj.var_names, "lift_uavg.vortX", "drag_uavg.tot",...
                "wx_y", "wx_z", "Qx_y", "Qx_z",...
                "lift_before_avg.vortX", "lift_before_avg.vel_diff", "lift_vel_before_avg",...
                "drag_before_avg.tot", "drag_vel_before_avg",...
                "lift.vortY_edge", "lift.vortX_taper",...
                "lift_tavg.vortX", "lift_tavg.vel_diff", "lift_vel_tavg", "drag_tavg.tot", "drag_vel_tavg",...
                "lift_vel_B", "drag_vel_B", "lift_vel_B_fill", "drag_vel_B_fill"];
            obj.y_labels = [obj.y_labels, "Lift (N)", "Drag (N)",...
                "$\omega_x$ centroid $y/L$", "$\omega_x$ centroid $z/L$",...
                "Q centroid $y/L$", "Q centroid $z/L$",...
                "Lift (N)", "Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)",...
                "Lift (N)", "Lift (N)",...
                "Lift (N)", "Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)",...
                "Lift (N)", "Drag (N)", "Lift (N)", "Drag (N)"];

            % Category of each variable, matching the Variable Type dropdown
            % (same groups as phaseAvg_UI)
            obj.var_categories = strings(size(obj.var_names));
            obj.var_categories(ismember(obj.var_names, ["lift_uavg.vortX", "drag_uavg.tot",...
                "lift.vortY_edge", "lift.vortX_taper"])) = "force";
            obj.var_categories(ismember(obj.var_names, ["lift.vortX", "lift.vortY", "lift.vel_diff",...
                "lift_vel", "drag.tot", "drag_vel"])) = "force";
            % velocity-only forces on the Helmholtz-extrapolated field
            % (_B: extrapolated velocity only, _B_fill: measured inside the
            % FOV). Stored in the phase-avg _integral file only, so always
            % loaded, never calculated live; 0 Hz cases read as 0.
            obj.var_categories(ismember(obj.var_names, ["lift_vel_B", "drag_vel_B",...
                "lift_vel_B_fill", "drag_vel_B_fill"])) = "force";
            obj.var_categories(startsWith(obj.var_names, ["lift_before_avg", "drag_before_avg"]) |...
                endsWith(obj.var_names, ["lift_vel_before_avg", "drag_vel_before_avg"])) = "BA: force";
            % TA: force - computed from the time-averaged (cycle-averaged)
            % velocity/vorticity field; always calculated live by
            % get_PIV_force since nothing is stored for them
            obj.var_categories(endsWith(obj.var_names, "_tavg") | contains(obj.var_names, "_tavg.")) = "TA: force";
            % Remaining kinematics from phaseAvg_UI (phase-averaged motor
            % acceleration, wing position / speed / acceleration and the
            % modeled voltage, all saved in the _integral file)
            obj.box_labels = [obj.box_labels, "acceleration", "wing position", "wing speed",...
                "wing acceleration", "modeled voltage"];
            obj.var_names = [obj.var_names, "phase_avg_acc", "phase_avg_wing_pos", "phase_avg_wing_speed",...
                "phase_avg_wing_acc", "phase_avg_volt_model"];
            obj.y_labels = [obj.y_labels, "Acceleration (Hz^2)", "Position (rad)", "Speed (rad/s)",...
                "Acceleration (rad/s^2)", "Voltage (V)"];
            obj.var_categories(end+1:length(obj.var_names)) = "";

            obj.var_categories(ismember(obj.var_names, ["phase_avg_speed", "phase_avg_speed_error",...
                "phase_avg_volt", "phase_avg_cur", "phase_avg_power",...
                "num_bins", "num_clusters", "phase_spread_ratio",...
                "phase_avg_acc", "phase_avg_wing_pos", "phase_avg_wing_speed",...
                "phase_avg_wing_acc", "phase_avg_volt_model"])) = "kinematics";
            % Load cell variables (phase-averaged when used for the
            % shift operation). Names start with "LC_".
            obj.box_labels = [obj.box_labels, "drag (LC)", "lift (LC)", "pitch (LC)",...
                "voltage (LC)", "current (LC)", "electric power (LC)",...
                "pitot U (LC)", "density (LC)"];
            obj.var_names = [obj.var_names, "LC_drag", "LC_lift", "LC_pitch",...
                "LC_volt", "LC_cur", "LC_power", "LC_U", "LC_rho"];
            obj.y_labels = [obj.y_labels, "Drag (N)", "Lift (N)", "Pitch Moment (N m)",...
                "Voltage (V)", "Current (mA)", "Power (mW)", "Freestream Speed", "Density"];
            obj.var_categories(end+1:length(obj.var_names)) = "";
            obj.var_categories(startsWith(obj.var_names, "LC_")) = "load cell";
            obj.var_categories(obj.var_categories == "") = "flow";
            obj.var_type = obj.get_var_category(obj.var_names(1));
            obj.PIV_sub = false;
            obj.PIV_sub_case = "ring";
            obj.force_sub = false;
            obj.RPCA = false;
            obj.HR = false;
            obj.filt_num = 3;
            obj.operation = "mean";

            obj.x_norm = false;
            obj.y_norm = false;
            obj.separate_y_axis_bool = false;
            obj.load_cell_data_var = "filtered_data";
            obj.force_var = obj.var_names(1);
            obj.force_vars = obj.force_var;
            obj.saveFig = false;
            obj.diff_bool = false;
            obj.calc_bool = false;
            obj.conv_shift = false;
            obj.unwrap_shift = false;
            obj.trim_bounds = default_trim_bounds();
            obj.unc_mask_bool = false;
            obj.unc_mask_pct = 4;
            obj.trim_bounds.unc_mask = 0; % off

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

            % full frequency range to start (0 to 8 Hz for the current data)
            obj.available_freqs = unique(cell2mat(obj.available_selections(:, 3)))';
            obj.freq_range = [min(obj.available_freqs), max(obj.available_freqs)];
            if obj.freq_range(1) == obj.freq_range(2)
                obj.freq_range(2) = obj.freq_range(1) + 1; % slider needs a span
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
            [option_panel, plot_panel, ~] = setupFig();
            option_panel.AutoResizeChildren = true;
            if isprop(option_panel, "Scrollable")
                option_panel.Scrollable = "on";
            end

            sidebar_grid = uigridlayout(option_panel, [25, 1]);
            sidebar_grid.ColumnWidth = {'1x'};
            sidebar_grid.RowHeight = {30, 60, 30, 30, 30, 30, 110, 30, 30, 30, 30, 30, 30, 30,...
                                      30, 25, 30, 30, 30, 30, 30, 30, 30, 160, 30};
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

            % Range of wingbeat frequencies plotted when the x-axis is
            % wingbeat frequency. Cases measured over a shorter range (e.g.
            % 30 deg, up to 6 Hz) plot whatever falls inside it.
            freq_grid = uigridlayout(sidebar_grid, [2, 1]);
            freq_grid.Layout.Row = 2;
            freq_grid.Layout.Column = 1;
            freq_grid.RowHeight = {16, '1x'};
            freq_grid.Padding = [8 0 8 0];
            freq_grid.RowSpacing = 0;

            freq_label = uilabel(freq_grid);
            freq_label.Layout.Row = 1;
            freq_label.Layout.Column = 1;
            freq_label.HorizontalAlignment = "center";

            freq_slider = uislider(freq_grid, "range");
            freq_slider.Layout.Row = 2;
            freq_slider.Layout.Column = 1;
            freq_slider.Limits = obj.freq_range;
            freq_slider.Value = obj.freq_range;
            freq_slider.MajorTicks = obj.available_freqs;
            freq_slider.MinorTicks = [];
            freq_slider.ValueChangedFcn = @(src, event) freq_range_change(src, event, freq_label, plot_panel);
            obj.update_freq_range_label(freq_label);
            obj.set_freq_slider_enable(freq_slider, freq_label);

            % Dropdown boxes for variables held fixed while the x-axis varies
            fixed_dropdown_1 = uidropdown(sidebar_grid);
            fixed_dropdown_1.Layout.Row = 3;
            fixed_dropdown_1.Layout.Column = 1;

            fixed_dropdown_2 = uidropdown(sidebar_grid);
            fixed_dropdown_2.Layout.Row = 4;
            fixed_dropdown_2.Layout.Column = 1;
            obj.reset_fixed_variable_defaults();
            obj.update_fixed_dropdowns(fixed_dropdown_1, fixed_dropdown_2);

            % RPCA and HR (harmonic regression) buttons share a row
            variant_grid = uigridlayout(sidebar_grid, [1, 2]);
            variant_grid.Layout.Row = 5;
            variant_grid.Layout.Column = 1;
            variant_grid.ColumnWidth = {'1x', '1x'};
            variant_grid.RowHeight = {'1x'};
            variant_grid.Padding = [0 0 0 0];
            variant_grid.ColumnSpacing = 8;

            rpca_button = uibutton(variant_grid, "state");
            rpca_button.Layout.Row = 1;
            rpca_button.Layout.Column = 1;
            rpca_button.Text = "RPCA";
            rpca_button.FontSize = 18;
            rpca_button.BackgroundColor = obj.get_button_color(obj.RPCA);
            rpca_button.ValueChangedFcn = @(src, event) RPCA_change(src, event);

            hr_button = uibutton(variant_grid, "state");
            hr_button.Layout.Row = 1;
            hr_button.Layout.Column = 2;
            hr_button.Text = "HR";
            hr_button.FontSize = 18;
            hr_button.Tooltip = "Harmonic regression files (_hr) for the flapping cases";
            hr_button.BackgroundColor = obj.get_button_color(obj.HR);
            hr_button.ValueChangedFcn = @(src, event) HR_change(src, event);

            % Button to add entry
            entry_button_grid = uigridlayout(sidebar_grid, [1, 2]);
            entry_button_grid.Layout.Row = 6;
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
            lbox.Layout.Row = 7;
            lbox.Layout.Column = 1;
            lbox.Items = strings(0);

            x_axis_dropdown.ValueChangedFcn = @(src, event) x_axis_change(src, event, fixed_dropdown_1, fixed_dropdown_2, plot_panel, lbox, freq_slider, freq_label);
            fixed_dropdown_1.ValueChangedFcn = @(src, event) fixed_1_change(src, event, fixed_dropdown_2);
            fixed_dropdown_2.ValueChangedFcn = @(src, event) fixed_2_change(src, event);
            add_button.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
            delete_button.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

            clear_button = uibutton(sidebar_grid);
            clear_button.Layout.Row = 8;
            clear_button.Layout.Column = 1;
            clear_button.Text = "Clear Entries";
            clear_button.FontSize = 18;
            clear_button.BackgroundColor = [1 1 1];
            clear_button.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

            % Variable type filters the two variable dropdowns below
            var_type_dropdown = uidropdown(sidebar_grid);
            var_type_dropdown.Layout.Row = 9;
            var_type_dropdown.Layout.Column = 1;
            var_type_dropdown.Items = ["kinematics", "flow", "force", "BA: force", "TA: force", "load cell"];
            var_type_dropdown.Value = obj.var_type;

            % Dropdown boxes for variable selection
            force_var_dropdown_1 = uidropdown(sidebar_grid);
            force_var_dropdown_1.Layout.Row = 10;
            force_var_dropdown_1.Layout.Column = 1;
            force_var_dropdown_1.Items = obj.get_var_dropdown_items(obj.get_force_var_label(obj.force_var));
            force_var_dropdown_1.Value = obj.get_force_var_label(obj.force_var);

            force_var_dropdown_2 = uidropdown(sidebar_grid);
            force_var_dropdown_2.Layout.Row = 11;
            force_var_dropdown_2.Layout.Column = 1;
            force_var_dropdown_2.Items = obj.get_var_dropdown_items("none");
            force_var_dropdown_2.Value = "none";

            force_var_dropdown_3 = uidropdown(sidebar_grid);
            force_var_dropdown_3.Layout.Row = 12;
            force_var_dropdown_3.Layout.Column = 1;
            force_var_dropdown_3.Items = obj.get_var_dropdown_items("none");
            force_var_dropdown_3.Value = "none";
            var_dropdowns = [force_var_dropdown_1, force_var_dropdown_2, force_var_dropdown_3];
            var_type_dropdown.ValueChangedFcn = @(src, event) var_type_change(src, event, var_dropdowns);
            for var_dropdown = var_dropdowns
                var_dropdown.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, var_dropdowns);
            end

            operation_dropdown = uidropdown(sidebar_grid);
            operation_dropdown.Layout.Row = 13;
            operation_dropdown.Layout.Column = 1;
            operation_dropdown.Items = obj.operations;
            operation_dropdown.Tooltip = "shift: phase shift of variables 2 and 3 behind variable 1 for each case (cross-correlation of the phase-averaged signals); needs two or more variables";

            % Convection shift for the shift operation (as in phaseAvg_UI
            % and flowField_UI): STB signals are shifted by the convection
            % time from the robot to the imaging plane, kinematics are not
            shift_grid = uigridlayout(sidebar_grid, [1, 2]);
            shift_grid.Layout.Row = 14;
            shift_grid.Layout.Column = 1;
            shift_grid.ColumnWidth = {'1x', '1x'};
            shift_grid.Padding = [0 0 0 0];
            shift_grid.ColumnSpacing = 4;

            conv_shift_button = uibutton(shift_grid, "state");
            conv_shift_button.Layout.Row = 1;
            conv_shift_button.Layout.Column = 1;
            conv_shift_button.Text = "Conv. Shift";
            conv_shift_button.FontSize = 14;
            conv_shift_button.Value = obj.conv_shift;
            conv_shift_button.BackgroundColor = obj.get_button_color(obj.conv_shift);
            conv_shift_button.Enable = strcmp(obj.operation, "shift");
            conv_shift_button.Tooltip = "Shift operation only: shift STB (force / flow) signals by the convection time from the robot to the imaging plane before finding the phase shift. Kinematics and load cell signals are measured at the robot and aren't shifted";
            conv_shift_button.ValueChangedFcn = @(src, event) conv_shift_change(src, event, plot_panel);

            % unwrap: phase shifts are only known modulo one wingbeat, so
            % a smooth trend can jump by 1 between neighbouring points
            unwrap_button = uibutton(shift_grid, "state");
            unwrap_button.Layout.Row = 1;
            unwrap_button.Layout.Column = 2;
            unwrap_button.Text = "Unwrap";
            unwrap_button.FontSize = 14;
            unwrap_button.Value = obj.unwrap_shift;
            unwrap_button.BackgroundColor = obj.get_button_color(obj.unwrap_shift);
            unwrap_button.Enable = strcmp(obj.operation, "shift");
            unwrap_button.Tooltip = "Shift operation only: add or subtract whole wingbeats so neighbouring points along the x-axis differ by less than half a wingbeat. Assumes the true shift changes by less than half a wingbeat between neighbouring points";
            unwrap_button.ValueChangedFcn = @(src, event) unwrap_shift_change(src, event, plot_panel);

            operation_dropdown.ValueChangedFcn = @(src, event) operation_change(src, event, plot_panel, [conv_shift_button, unwrap_button]);

            piv_sub_button = uibutton(sidebar_grid, "state");
            piv_sub_button.Layout.Row = 15;
            piv_sub_button.Layout.Column = 1;
            piv_sub_button.Text = "PIV Body Sub";
            piv_sub_button.FontSize = 18;
            piv_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            piv_sub_button.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

            % Steady case used for the subtraction, matched to each
            % selection's downstream position (and amplitude for body/gliding)
            piv_sub_dropdown = uidropdown(sidebar_grid);
            piv_sub_dropdown.Layout.Row = 16;
            piv_sub_dropdown.Layout.Column = 1;
            piv_sub_dropdown.Items = ["ring", "body", "gliding"];
            piv_sub_dropdown.Value = obj.PIV_sub_case;
            piv_sub_dropdown.Tooltip = "Steady case subtracted (e.g. for x3_wings_20deg_4Hz: ring = x3_ring, body = x3_body_20deg_0Hz, gliding = x3_wings_20deg_0Hz)";
            piv_sub_dropdown.ValueChangedFcn = @(src, event) PIV_sub_case_change(src, event, plot_panel);

            force_sub_button = uibutton(sidebar_grid, "state");
            force_sub_button.Layout.Row = 17;
            force_sub_button.Layout.Column = 1;
            force_sub_button.Text = "Force Body Sub";
            force_sub_button.FontSize = 18;
            force_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_sub_button.Tooltip = "Subtract the body load cell signal from the load cell forces / moment (load cell variables)";
            force_sub_button.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

            % Which processed load cell data the load cell variables read
            % (forces, voltage, current)
            load_cell_data_dropdown = uidropdown(sidebar_grid);
            load_cell_data_dropdown.Layout.Row = 18;
            load_cell_data_dropdown.Layout.Column = 1;
            load_cell_data_dropdown.Items = obj.load_cell_data_labels;
            load_cell_data_dropdown.Value = obj.load_cell_data_labels(obj.load_cell_data_vars == obj.load_cell_data_var);
            load_cell_data_dropdown.Tooltip = "Load cell data used for the load cell variables (phase-averaged version of the chosen filter for the shift operation)";
            load_cell_data_dropdown.Enable = "off";
            load_cell_data_dropdown.ValueChangedFcn = @(src, event) load_cell_data_change(src, event, plot_panel);

            x_norm_button = uibutton(sidebar_grid, "state");
            x_norm_button.Layout.Row = 19;
            x_norm_button.Layout.Column = 1;
            x_norm_button.Text = "Normalize X-axis";
            x_norm_button.FontSize = 18;
            x_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            x_norm_button.ValueChangedFcn = @(src, event) x_norm_change(src, event, plot_panel);

            y_norm_button = uibutton(sidebar_grid, "state");
            y_norm_button.Layout.Row = 20;
            y_norm_button.Layout.Column = 1;
            y_norm_button.Text = "Normalize Y-axis";
            y_norm_button.FontSize = 18;
            y_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            y_norm_button.ValueChangedFcn = @(src, event) y_norm_change(src, event, plot_panel);

            % Put the two selected variables on separate left/right y-axes
            separate_y_button = uibutton(sidebar_grid, "state");
            separate_y_button.Layout.Row = 21;
            separate_y_button.Layout.Column = 1;
            separate_y_button.Text = "Separate Y-Axis";
            separate_y_button.FontSize = 18;
            separate_y_button.BackgroundColor = obj.COLOR_INACTIVE;
            separate_y_button.ValueChangedFcn = @(src, event) separate_y_axis_change(src, event, plot_panel);

            diff_button = uibutton(sidebar_grid, "state");
            diff_button.Layout.Row = 22;
            diff_button.Layout.Column = 1;
            diff_button.Text = "Difference";
            diff_button.FontSize = 18;
            diff_button.BackgroundColor = obj.COLOR_INACTIVE;
            diff_button.Tooltip = "Plot variable 1 minus variable 2 (and minus variable 3), e.g. lift vortX - lift (LC). Mean / range / rmse operations";
            diff_button.ValueChangedFcn = @(src, event) diff_change(src, event, plot_panel);

            calc_button = uibutton(sidebar_grid, "state");
            calc_button.Layout.Row = 23;
            calc_button.Layout.Column = 1;
            calc_button.Text = "Live Calculate";
            calc_button.FontSize = 18;
            calc_button.BackgroundColor = obj.COLOR_INACTIVE;

            % Trim limits and center point for Live Calculate,
            % nondimensional (divided by L)
            bounds_panel = uipanel(sidebar_grid);
            bounds_panel.Layout.Row = 24;
            bounds_panel.Layout.Column = 1;
            bounds_panel.Title = "Live Calc Bounds (y/L, z/L)";
            bounds_panel.TitlePosition = 'centertop';

            bounds_grid = uigridlayout(bounds_panel, [4, 3]);
            bounds_grid.ColumnWidth = {45, '1x', '1x'};
            bounds_grid.RowHeight = {25, 25, 25, 25};
            bounds_grid.Padding = [6 4 6 4];
            bounds_grid.RowSpacing = 4;
            bounds_grid.ColumnSpacing = 4;

            % {row label, [field, field] names, tooltips}
            bounds_rows = {"y", ["ymin", "ymax"], ["y lower bound", "y upper bound"];
                           "z", ["zmin", "zmax"], ["z lower bound", "z upper bound"];
                           "center", ["y_cen", "z_cen"], ["y center (new origin)", "z center (new origin)"]};
            bounds_fields = gobjects(0);
            for r = 1:size(bounds_rows, 1)
                row_label = uilabel(bounds_grid);
                row_label.Layout.Row = r;
                row_label.Layout.Column = 1;
                row_label.Text = bounds_rows{r, 1};
                for c = 1:2
                    bound_name = bounds_rows{r, 2}(c);
                    bound_field = uieditfield(bounds_grid, 'numeric');
                    bound_field.Layout.Row = r;
                    bound_field.Layout.Column = c + 1;
                    bound_field.Value = obj.get_trim_bound_value(bound_name);
                    bound_field.Tooltip = bounds_rows{r, 3}(c);
                    bound_field.ValueChangedFcn = @(src, event) trim_bound_change(src, event, bound_name, plot_panel);
                    bounds_fields(end+1) = bound_field; %#ok<AGROW>
                end
            end
            % Uncertainty mask: threshold (% of freestream) and on/off
            unc_label = uilabel(bounds_grid);
            unc_label.Layout.Row = 4;
            unc_label.Layout.Column = 1;
            unc_label.Text = "unc %";

            unc_field = uieditfield(bounds_grid, 'numeric');
            unc_field.Layout.Row = 4;
            unc_field.Layout.Column = 2;
            unc_field.Limits = [0 Inf];
            unc_field.Value = obj.unc_mask_pct;
            unc_field.Tooltip = "Uncertainty mask threshold, % of the freestream speed";
            unc_field.ValueChangedFcn = @(src, event) unc_mask_pct_change(src, event, plot_panel);
            bounds_fields(end+1) = unc_field;

            unc_button = uibutton(bounds_grid, "state");
            unc_button.Layout.Row = 4;
            unc_button.Layout.Column = 3;
            unc_button.Text = "Unc Mask";
            unc_button.Value = obj.unc_mask_bool;
            unc_button.BackgroundColor = obj.get_button_color(obj.unc_mask_bool);
            unc_button.Tooltip = "Leave out of the live force integrals the points whose total uncertainty, averaged over the wingbeat, is above this % of the freestream speed (they are treated as undisturbed freestream)";
            unc_button.ValueChangedFcn = @(src, event) unc_mask_change(src, event, plot_panel);
            bounds_fields(end+1) = unc_button;

            set(bounds_fields, 'Enable', 'off'); % only used with Live Calculate
            calc_button.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel, bounds_fields);

            save_fig_button = uibutton(sidebar_grid);
            save_fig_button.Layout.Row = 25;
            save_fig_button.Layout.Column = 1;
            save_fig_button.Text = "Save Fig";
            save_fig_button.FontSize = 18;
            save_fig_button.BackgroundColor = [1 1 1];
            save_fig_button.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

            % Set up plot titles and axes
            obj.update_plot(plot_panel);

            % ===== Nested Callback Functions =====
            
            function x_axis_change(src, ~, fixed_dropdown_1, fixed_dropdown_2, plot_panel, lbox, freq_slider, freq_label)
                obj.x_axis_type = obj.get_x_axis_type(src.Value);
                obj.set_freq_slider_enable(freq_slider, freq_label);
                obj.reset_fixed_variable_defaults();
                obj.update_fixed_dropdowns(fixed_dropdown_1, fixed_dropdown_2);
                obj.selection = strings(0);
                lbox.Items = strings(0);
                obj.update_plot(plot_panel);
            end

            function freq_range_change(src, ~, freq_label, plot_panel)
                % snap both ends to measured frequencies
                new_range = obj.snap_to_available_freqs(src.Value);
                src.Value = new_range;
                obj.freq_range = new_range;
                obj.update_freq_range_label(freq_label);
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

            function var_type_change(src, ~, var_dropdowns)
                % show the chosen type's variables; a variable already
                % selected from another type stays selected
                obj.var_type = string(src.Value);
                for k = 1:length(var_dropdowns)
                    var_dropdowns(k).Items = obj.get_var_dropdown_items(string(var_dropdowns(k).Value));
                end
            end

            function force_var_change(~, ~, plot_panel, var_dropdowns)
                selected_values = string({var_dropdowns.Value});
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

                % the load cell data choice also applies to load cell variables
                set_load_cell_data_enable();
                obj.update_plot(plot_panel);
            end

            function operation_change(src, ~, plot_panel, shift_buttons)
                obj.operation = src.Value;
                % convection shift and unwrap only apply to the shift operation
                for b = shift_buttons
                    b.Enable = strcmp(obj.operation, "shift");
                end
                obj.update_plot(plot_panel);
            end

            function unwrap_shift_change(src, ~, plot_panel)
                obj.unwrap_shift = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.unwrap_shift);
                if strcmp(obj.operation, "shift")
                    obj.update_plot(plot_panel);
                end
            end

            function conv_shift_change(src, ~, plot_panel)
                obj.conv_shift = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.conv_shift);
                if strcmp(obj.operation, "shift")
                    obj.update_plot(plot_panel);
                end
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

            function HR_change(src, ~)
                obj.HR = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.HR);
            end

            function force_sub_change(src, ~, plot_panel)
                obj.force_sub = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.force_sub);
                obj.update_plot(plot_panel);
            end

            function set_load_cell_data_enable()
                % only the load cell variables use it
                if any(obj.is_load_cell_var(obj.get_active_force_vars()))
                    load_cell_data_dropdown.Enable = "on";
                else
                    load_cell_data_dropdown.Enable = "off";
                end
            end

            function load_cell_data_change(src, ~, plot_panel)
                obj.load_cell_data_var = obj.load_cell_data_vars(obj.load_cell_data_labels == string(src.Value));
                if any(obj.is_load_cell_var(obj.get_active_force_vars()))
                    obj.update_plot(plot_panel);
                end
            end

            function x_norm_change(src, ~, plot_panel)
                obj.x_norm = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.x_norm);
                obj.update_plot(plot_panel);
            end

            function separate_y_axis_change(src, ~, plot_panel)
                obj.separate_y_axis_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.separate_y_axis_bool);
                obj.update_plot(plot_panel);
            end

            function y_norm_change(src, ~, plot_panel)
                obj.y_norm = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.y_norm);
                obj.update_plot(plot_panel);
            end

            function diff_change(src, ~, plot_panel)
                obj.diff_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.diff_bool);
                obj.update_plot(plot_panel);
            end
            
            function calc_change(src, ~, plot_panel, bounds_fields)
                obj.calc_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.calc_bool);
                if obj.calc_bool
                    set(bounds_fields, 'Enable', 'on');
                else
                    set(bounds_fields, 'Enable', 'off');
                end
                obj.update_plot(plot_panel);
            end

            function addToList(~, ~, plot_panel, lbox)
                selection_keys = obj.get_current_selection_keys();

                for n = 1:length(selection_keys)
                    selection_key = selection_keys(n);
                    if obj.HR
                        selection_key = selection_key + "|HR=true";
                    end
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

            function trim_bound_change(src, event, bound_name, plot_panel)
                obj.set_trim_bound_value(bound_name, src.Value);
                b = obj.trim_bounds;
                if b.ybounds(1) >= b.ybounds(2) || b.zbounds(1) >= b.zbounds(2)
                    % reject: put the previous value back
                    obj.set_trim_bound_value(bound_name, event.PreviousValue);
                    src.Value = event.PreviousValue;
                    disp("Live Calc Bounds: lower bound must be below upper bound, value not changed")
                    return
                end
                if obj.calc_bool
                    obj.update_plot(plot_panel);
                end
            end

            function unc_mask_change(src, ~, plot_panel)
                obj.unc_mask_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.unc_mask_bool);
                obj.set_unc_mask_bound();
                if obj.calc_bool
                    obj.update_plot(plot_panel);
                end
            end

            function unc_mask_pct_change(src, ~, plot_panel)
                obj.unc_mask_pct = src.Value;
                obj.set_unc_mask_bound();
                if obj.calc_bool && obj.unc_mask_bool
                    obj.update_plot(plot_panel);
                end
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
            info = struct("x_axis_type", parts(1), "type", "", "amp", NaN, "freq", NaN, "RPCA", false, "HR", false);

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
                    case "HR"
                        info.HR = string(value) == "true";
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

            if info.HR
                label = label + " | HR";
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
                    % keep frequencies inside the selected range; cases
                    % measured over a shorter range (30 deg: up to 6 Hz)
                    % just contribute what they have
                    in_range = freqs >= obj.freq_range(1) - 1e-9 & freqs <= obj.freq_range(2) + 1e-9;
                    if ~any(in_range) && ~isempty(freqs)
                        fprintf("%s, %g deg: measured %g-%g Hz, nothing in %g-%g Hz, not plotted\n",...
                            info.type, info.amp, min(freqs), max(freqs), obj.freq_range(1), obj.freq_range(2));
                    end
                    freqs = freqs(in_range);
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

            if info.HR
                label = label + " - HR";
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

        function category = get_var_category(obj, var_name)
            category = obj.var_categories(obj.var_names == string(var_name));
            if isempty(category)
                category = "flow";
            end
        end

        function items = get_var_dropdown_items(obj, current_label)
            % "none" plus the variables of the current type, keeping the
            % current selection listed if it belongs to another type
            items = ["none", obj.box_labels(obj.var_categories == obj.var_type)];
            current_label = string(current_label);
            if current_label ~= "none" && ~ismember(current_label, items)
                items = [items, current_label];
            end
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

            % some labels carry the formula after a colon, e.g.
            % "Drag (N): $...$"; if the full labels differ, compare just the
            % quantity before it (drag (LC) + drag vel -> "Drag (N)")
            base_labels = y_labels;
            has_formula = contains(base_labels, ":");
            base_labels(has_formula) = strtrim(extractBefore(base_labels(has_formula), ":"));

            if isempty(y_labels)
                y_label = "";
            elseif all(y_labels == y_labels(1))
                y_label = y_labels(1);
            elseif all(base_labels == base_labels(1))
                y_label = base_labels(1);
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

        function U = get_nominal_speed(~, filepath)
            % nominal freestream speed the STB "pitot U" (U_act) is
            % normalised by; 4 m/s unless the case file says otherwise
            U = 4;
            if strlength(filepath) > 0 && isfile(filepath) &&...
                    ismember('U', who('-file', filepath))
                d = load(filepath, "U");
                U = d.U;
            end
        end

        % Update plot after user changes selected variables
        function update_plot(obj, plot_panel)
            % When saving, draw straight into a hidden figure rather than
            % copying the on-screen axes: copyobj can't copy axes that use
            % yyaxis (Separate Y-Axis). The on-screen plot is left as is.
            if obj.saveFig
                fignew = figure('Visible','off'); % Invisible figure
                fignew.Position = [500,491,800,600];
                ax = axes(fignew);
            else
                delete(plot_panel.Children)
                ax = axes(plot_panel);
            end
            hold(ax, 'on');
            l = legend(ax, Location="best");
            set(ax, FontSize=18)

            selected_force_vars = obj.get_active_force_vars();

            % shift: phase shift between the two selected variables
            if strcmp(obj.operation, "shift")
                obj.plot_variable_phase_shift(ax, selected_force_vars);
                if obj.saveFig
                    obj.save_hidden_figure(fignew);
                end
                return
            end

            num_vars = length(selected_force_vars);
            num_sel = length(obj.selection);
            curve_colors = lines(max(1, num_sel * max(1, num_vars)));

            % Difference: variable 1 minus variable 2 (and minus variable
            % 3), e.g. lift vortX - lift (LC) for the STB error
            diff_plot = obj.diff_bool && num_vars >= 2;
            if obj.diff_bool && num_vars < 2
                title(ax, "Select two or more variables to plot their difference", ...
                    FontSize=14, FontWeight="normal")
            end

            % With "Separate Y-Axis" on and two variables selected, the
            % first goes on the left y-axis and the second on the right
            split_y_axes = obj.separate_y_axis_bool && num_vars == 2 && ~diff_plot;

            % One value per point for each variable and selection, then
            % plotted below (directly, or as differences)
            values = cell(num_vars, num_sel);
            errors = cell(num_vars, num_sel);
            x_vals = cell(num_vars, num_sel);

            for var_idx = 1:num_vars % Loop through each selected variable
                force_var = selected_force_vars(var_idx);
                % The load cell is measured at one position, so selections
                % that differ only in downstream position (or RPCA / HR) share
                % one load cell series: their points are merged into the
                % first such selection's series, each case once (positions
                % may cover different frequencies). Difference mode still
                % needs it for every selection.
                merge_lc = obj.is_load_cell_var(force_var) && ~diff_plot;
                lc_group_keys = strings(0); % group key per series
                lc_group_sel = [];          % selection holding that series
                lc_point_keys = strings(0); % cases already in a series

            for i = 1:num_sel % Loop through each selection
                info = obj.decode_selection(obj.selection(i));
                % with downstream distance on the x-axis each point is a
                % position, so there the series is left as is
                merge_this = merge_lc && info.x_axis_type ~= "downstream distance";
                points = obj.get_selection_points(info);
                num_points = length(points.freqs);

                if num_points == 0
                    continue
                end

                vals = NaN(1, num_points);
                errs = zeros(1, num_points);
                measured_freqs = points.freqs;
                wind_speed_acts = NaN(1, num_points);
                keep = true(1, num_points);
                
                for j = 1:num_points % Loop through all matching cases
                    type = points.types(j);
                    amp = points.amps(j);
                    freq = points.freqs(j);

                    if merge_this
                        point_key = obj.get_load_cell_point_key(type, amp, freq);
                        if ismember(point_key, lc_point_keys)
                            keep(j) = false; % already plotted from another position
                            continue
                        end
                        lc_point_keys(end+1) = point_key;
                    end

                    name = obj.get_case_name(type, amp, freq);
                    % RPCA and HR only apply to phase averaged cases
                    if freq ~= 0
                        name = obj.add_variant_suffix(name, info.HR, info.RPCA);
                    end
                    if freq == 0
                        suffix = "_time_avg";
                    else
                        suffix = "_phase_avg";
                    end
                    file_base = obj.get_case_file_base(name, suffix);
                    filepath = file_base + ".mat";
                    secondary_filepath = file_base + "_integral.mat";

                    if freq == 0
                        avg_type = 0;
                        measured_freqs(j) = 0;
                        errs(j) = 0;
                    else
                        avg_type = 1;
                        d = load(filepath, "U", "L", "U_act", "rho_act", "bin_std");
                        F = load(secondary_filepath, "freq_avg");
                        measured_freqs(j) = mean(F.freq_avg);
                        % gain = 0.01;
                        % gain = 0.001;
                        errs(j) = mean(d.bin_std);
                        % errs(j) = 0;
                        wind_speed = d.U;
                        density = d.rho_act;
                        area = d.L * d.L * 3 * 2;
                        wind_speed_acts(j) = d.U_act * d.U;
                        % errs(j) = 0.2 / length(d.bin_std);
                    end

                    if obj.is_load_cell_var(force_var)
                        var = obj.get_load_cell_signal(force_var, type, amp, freq, false);
                    elseif (obj.calc_bool && obj.is_piv_force_variable(force_var)) || obj.is_tavg_force_var(force_var)
                        [var, err] = get_PIV_force(filepath, name, force_var, avg_type, obj.y_norm, obj.trim_bounds);

                        if obj.PIV_sub
                            [bod_filepath, ~] = obj.get_PIV_sub_file_paths(type, amp);
                            [bod_var, ~] = get_PIV_force(bod_filepath, "", force_var, 0, obj.y_norm, obj.trim_bounds);
                            var = var - bod_var;
                        end
                    else
                        % variables not defined for a case (e.g.
                        % lift.vortY for a 0 Hz mean flow field) are
                        % replaced with zero
                        % look in the expected file first, then the other
                        if contains(force_var, ".")
                            var_files = [secondary_filepath, filepath];
                        else
                            var_file = obj.get_stored_var_file(force_var, filepath, secondary_filepath);
                            var_files = [var_file, setdiff([filepath, secondary_filepath], var_file)];
                        end
                        var = obj.load_stored_var(var_files, force_var);

                        % omega_x centroid: drop bins where the net
                        % omega_x is near zero (ratio blows up there)
                        if ismember(force_var, ["wx_y", "wx_z"])
                            vortX_avg = obj.load_stored_var(var_files, "vortX_avg");
                            var = mask_vortex_centroid(var, vortX_avg, name);
                        end

                        % TEMPORARY for dimensionalization of power
                        % var = var * (1/2) * density * wind_speed^3 * area;

                        if obj.PIV_sub
                            [bod_filepath, bod_secondary_filepath] = obj.get_PIV_sub_file_paths(type, amp);
                            bod_var = obj.load_stored_var([bod_secondary_filepath, bod_filepath], force_var);
                            var = var - bod_var;
                        end
                    end

                    % Calculate mean force and store in array for plotting
                    vals(j) = obj.reduce_signal(var);
                    disp(j + " of " + num_points + " complete")
                end

                % Calculate gain based on range of values
                finite_vals = vals(isfinite(vals));
                if isempty(finite_vals)
                    gain = 0;
                else
                    gain = range(finite_vals)/2;
                end
                errs = gain * errs;
                if obj.is_load_cell_var(force_var)
                    errs(:) = 0; % the bin spread is an STB quantity
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
                x_var = x_var(keep);
                vals = vals(keep);
                errs = errs(keep);

                target = i;
                if merge_this
                    group_key = obj.get_load_cell_selection_key(info);
                    g = find(lc_group_keys == group_key, 1);
                    if isempty(g)
                        lc_group_keys(end+1) = group_key;
                        lc_group_sel(end+1) = i;
                    else
                        target = lc_group_sel(g); % add to that series
                    end
                end
                if isempty(vals) && target ~= i
                    continue
                end
                x_all = [x_vals{var_idx, target}, x_var(:)'];
                v_all = [values{var_idx, target}, vals(:)'];
                e_all = [errors{var_idx, target}, errs(:)'];
                [x_vals{var_idx, target}, order] = sort(x_all);
                values{var_idx, target} = v_all(order);
                errors{var_idx, target} = e_all(order);
            end
            end

            if diff_plot
                labels = arrayfun(@(v) obj.get_force_var_label(v), selected_force_vars);
                for i = 1:num_sel
                    if isempty(values{1, i})
                        continue
                    end
                    curve_label = obj.get_curve_label(obj.decode_selection(obj.selection(i)));
                    for k = 2:num_vars
                        color = curve_colors((i - 1) * num_vars + k, :);
                        s1 = plot(ax, x_vals{1, i}, values{1, i} - values{k, i}, ...
                            char(obj.get_variable_marker(k)), LineStyle="none", MarkerSize=10, ...
                            Color=color, MarkerFaceColor=color);
                        s1.DisplayName = labels(1) + " - " + labels(k);
                        if num_sel > 1
                            s1.DisplayName = curve_label + ": " + s1.DisplayName;
                        end
                    end
                end
                yl = yline(ax, 0, "k");
                yl.HandleVisibility = "off";
                ylabel(ax, "Difference: " + obj.get_force_vars_y_label(selected_force_vars), Interpreter="latex")
            else
            for var_idx = 1:num_vars
                force_var = selected_force_vars(var_idx);
                if split_y_axes
                    if var_idx == 1
                        yyaxis(ax, 'left')
                    else
                        yyaxis(ax, 'right')
                    end
                    hold(ax, 'on');
                    % neutral axis color, the markers tell the variables apart
                    ax.YAxis(var_idx).Color = [0.15 0.15 0.15];
                    y_label_vars = force_var;
                else
                    y_label_vars = selected_force_vars;
                end
                ylabel(ax, obj.get_force_vars_y_label(y_label_vars), Interpreter="latex")
                variable_marker = obj.get_variable_marker(var_idx);

                for i = 1:num_sel
                    if isempty(values{var_idx, i})
                        continue
                    end
                    original_color = curve_colors((i - 1) * num_vars + var_idx, :);
                    info = obj.decode_selection(obj.selection(i));
                    if obj.is_load_cell_var(force_var)
                        curve_label = obj.get_curve_label(obj.strip_load_cell_position(info));
                    else
                        curve_label = obj.get_curve_label(info);
                    end

                    s1 = errorbar(ax, x_vals{var_idx, i}, values{var_idx, i}, errors{var_idx, i}, char(variable_marker));
                    s1.MarkerSize = 10;
                    s1.Color = original_color;
                    s1.MarkerEdgeColor = original_color;
                    s1.MarkerFaceColor = original_color;
                    s1.DisplayName = obj.get_plot_legend_label(curve_label, force_var, num_vars);
                end
            end
            end

            if (obj.saveFig)
                obj.save_hidden_figure(fignew);
            end
        end

        function save_hidden_figure(~, fignew)
            filename = "saved_figure.fig";
            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

        function valid = is_valid_alignment_signal(~, signal)
            if isempty(signal)
                valid = false;
                return
            end

            signal = signal(:);
            valid = length(signal) > 1 && all(isfinite(signal)) && std(signal) > 0;
        end

        % Phase shift of each selected variable relative to the first, for
        % each case (shift operation): how far variable k lags variable 1,
        % in wingbeats, from the circular cross-correlation of their
        % phase-averaged signals. 0 Hz (gliding) cases have no wingbeat
        % and are skipped.
        function plot_variable_phase_shift(obj, ax, force_vars)
            if length(force_vars) < 2
                title(ax, "Select two or more variables to plot the phase shift between them", ...
                    FontSize=14, FontWeight="normal")
                return
            end

            num_vars = length(force_vars);
            labels = arrayfun(@(v) obj.get_force_var_label(v), force_vars);
            num_series = length(obj.selection) * (num_vars - 1);
            colors = lines(max(1, num_series));

            for i = 1:length(obj.selection)
                info = obj.decode_selection(obj.selection(i));
                points = obj.get_selection_points(info);
                num_points = length(points.freqs);
                if num_points == 0
                    continue
                end

                shifts = NaN(num_vars, num_points);
                measured_freqs = points.freqs;
                wind_speed_acts = NaN(1, num_points);
                for j = 1:num_points
                    type = points.types(j);
                    amp = points.amps(j);
                    freq = points.freqs(j);
                    if freq == 0
                        disp("Skipping 0 Hz case " + type + " for phase shift")
                        continue
                    end

                    sigs = cell(1, num_vars);
                    for k = 1:num_vars
                        [sigs{k}, measured_freqs(j), wind_speed_acts(j)] = ...
                            obj.get_phase_avg_signal(force_vars(k), type, amp, freq, info.RPCA, info.HR);
                        if obj.conv_shift
                            sigs{k} = obj.apply_convection_shift(sigs{k}, force_vars(k), type, measured_freqs(j));
                        end
                    end

                    for k = 2:num_vars
                        shifts(k, j) = obj.circular_phase_shift(sigs{1}, sigs{k});
                        fprintf('%s %g deg %g Hz: %s lags %s by %.3f wingbeats\n', ...
                            type, amp, freq, labels(k), labels(1), shifts(k, j));
                    end
                end

                [x_var, x_label] = obj.get_x_axis_values(info.x_axis_type, points, measured_freqs, wind_speed_acts);
                xlabel(ax, x_label, Interpreter="latex")

                if obj.unwrap_shift
                    for k = 2:num_vars
                        shifts(k,:) = obj.unwrap_phase_shifts(x_var, shifts(k,:));
                    end
                end

                for k = 2:num_vars
                    color = colors((i - 1) * (num_vars - 1) + k - 1, :);
                    s1 = scatter(ax, x_var, shifts(k,:), 125, "filled");
                    s1.Marker = char(obj.get_variable_marker(k));
                    s1.MarkerFaceColor = color;
                    s1.MarkerEdgeColor = color;
                    if length(obj.selection) > 1
                        s1.DisplayName = obj.get_curve_label(info) + " - " + labels(k);
                    else
                        s1.DisplayName = labels(k);
                    end
                end
            end

            yl = yline(ax, 0, "k");
            yl.HandleVisibility = "off";
            ylabel(ax, "Phase shift (wingbeats)")
            title(ax, "Lag behind " + labels(1), FontSize=14, FontWeight="normal")
        end

        % Unwrap phase shifts (in wingbeats) along x: going through the
        % points in order of x, add or subtract whole wingbeats so each
        % differs from the previous by less than half a wingbeat. The
        % series is then moved by a whole number of wingbeats so its mean
        % is as close to zero as possible. Points with equal x keep their
        % order; NaNs are left out.
        function shifts = unwrap_phase_shifts(~, x, shifts)
            valid = find(isfinite(x) & isfinite(shifts));
            if numel(valid) < 2
                return
            end
            [~, order] = sort(x(valid));
            idx = valid(order);
            y = shifts(idx);
            for n = 2:numel(y)
                y(n) = y(n) - round(y(n) - y(n-1));
            end
            y = y - round(mean(y));
            shifts(idx) = y;
        end

        % Phase-averaged signal of a variable for one flapping case, with
        % the case's measured wingbeat frequency and wind speed
        function [var, measured_freq, wind_speed_act] = get_phase_avg_signal(obj, force_var, type, amp, freq, RPCA, HR)
            if nargin < 7, HR = false; end
            name = obj.get_case_name(type, amp, freq);
            name = obj.add_variant_suffix(name, HR, RPCA);
            suffix = "_phase_avg";
            file_base = obj.get_case_file_base(name, suffix);
            filepath = file_base + ".mat";
            secondary_filepath = file_base + "_integral.mat";

            d = load(filepath, "U", "U_act");
            F = load(secondary_filepath, "freq_avg");
            measured_freq = mean(F.freq_avg);
            wind_speed_act = d.U_act * d.U;

            if obj.is_load_cell_var(force_var)
                % phase-averaged load cell signal, measured at the robot
                var = obj.get_load_cell_signal(force_var, type, amp, freq, true);
                var = double(var(:)');
                return
            elseif (obj.calc_bool && obj.is_piv_force_variable(force_var)) || obj.is_tavg_force_var(force_var)
                var = get_PIV_force(filepath, name, force_var, 1, obj.y_norm, obj.trim_bounds);
            else
                if contains(force_var, ".")
                    var_files = [secondary_filepath, filepath];
                else
                    var_file = obj.get_stored_var_file(force_var, filepath, secondary_filepath);
                    var_files = [var_file, setdiff([filepath, secondary_filepath], var_file)];
                end
                var = obj.load_stored_var(var_files, force_var);
                if ismember(force_var, ["wx_y", "wx_z"])
                    vortX_avg = obj.load_stored_var(var_files, "vortX_avg");
                    var = mask_vortex_centroid(var, vortX_avg, name);
                end
            end
            var = double(var(:)');

            % old flapper 10 deg flexible case started at mid-downstroke
            % rather than mid-upstroke: same half-cycle correction as
            % phaseAvg_UI applies to its STB curves (not the load cell)
            if amp == 10 && ~contains(type, "UP") && strlength(get_downstream_prefix(type)) == 0
                var = circshift(var, round(0.5*length(var)));
            end
        end

        function tf = is_load_cell_var(~, force_var)
            tf = startsWith(string(force_var), "LC_");
        end

        % Selection without what the load cell doesn't depend on: the
        % downstream position prefix (x1_, MPS_, ...; get_force strips it
        % too), RPCA and HR
        function info = strip_load_cell_position(~, info)
            prefix = get_downstream_prefix(info.type);
            if strlength(prefix) > 0
                info.type = extractAfter(info.type, strlength(prefix));
            end
            info.RPCA = false;
            info.HR = false;
        end

        % Case name with the processing-variant suffixes in the order
        % phase_avg_STB saves them: <case>_hr_RPCA_phase_avg.mat
        % (harmonic regression with the default version name, then RPCA)
        function name = add_variant_suffix(~, name, HR, RPCA)
            if HR
                name = name + "_hr";
            end
            if RPCA
                name = name + "_RPCA";
            end
        end

        % Selections with the same key have the same load cell series
        % (sprintf, not "+": a NaN amp / freq would make a <missing>
        % string, which never matches)
        function key = get_load_cell_selection_key(obj, info)
            info = obj.strip_load_cell_position(info);
            key = string(sprintf("%s|%s|%g|%g", info.x_axis_type, info.type, info.amp, info.freq));
        end

        % One load cell case: wing type without the position prefix,
        % amplitude and frequency
        function key = get_load_cell_point_key(~, type, amp, freq)
            prefix = get_downstream_prefix(type);
            if strlength(prefix) > 0
                type = extractAfter(type, strlength(prefix));
            end
            key = string(sprintf("%s|%g|%g", type, amp, freq));
        end

        % Load cell row(s) and quantity for a load cell variable: rows of
        % the processed data are [Fx Fy Fz Mx My Mz; home; voltage; current]
        function [idx, quantity] = get_load_cell_var_row(~, force_var)
            switch string(force_var)
                case "LC_drag"
                    idx = 1; quantity = "drag";
                case "LC_lift"
                    idx = 3; quantity = "lift";
                case "LC_pitch"
                    idx = 5; quantity = "pitch";
                case "LC_volt"
                    idx = 8; quantity = "voltage";
                case "LC_cur"
                    idx = 9; quantity = "current";
                case "LC_power"
                    idx = [8 9]; quantity = "electric power";
                case "LC_U" % tunnel speed saved in the load cell file
                    idx = 1; quantity = "wind speed";
                case "LC_rho" % density saved in the load cell file
                    idx = 1; quantity = "density";
                otherwise
                    error("timeAvg_UI:unknownLoadCellVar", "Unknown load cell variable %s", force_var)
            end
        end

        % Load cell signal for a load cell variable and case: the selected
        % load cell data, or its wingbeat-averaged version (phase_avg).
        % Force Body Sub subtracts the body signal from forces / moments.
        % NaN if there is no load cell data for the case.
        function signal = get_load_cell_signal(obj, force_var, type, amp, freq, phase_avg)
            signal = NaN;
            [idx, quantity] = obj.get_load_cell_var_row(force_var);
            if contains(type, "UP")
                disp("No load cell data for upstream case " + type)
                return
            end
            if quantity == "wind speed"
                var_name_F = "U_act";
            elseif quantity == "density"
                var_name_F = "rho_act";
            elseif phase_avg
                var_name_F = obj.get_wingbeat_avg_load_cell_var();
            else
                var_name_F = obj.load_cell_data_var;
            end

            try
                signal = get_force(obj.force_path, type, amp, freq, idx, var_name_F);
            catch ME
                if ~startsWith(ME.identifier, "get_force:")
                    rethrow(ME)
                end
                disp(ME.message + " - point not plotted")
                signal = NaN;
                return
            end
            if quantity == "electric power" && size(signal, 1) == 2
                signal = signal(1,:) .* signal(2,:); % V x mA = mW
            end
            if quantity == "wind speed"
                % load cell saves m/s; STB "pitot U" is U_act / U, so put
                % it on the same scale (nominal U from the STB file, else 4)
                name = obj.get_case_name(type, amp, freq);
                if freq == 0
                    suffix = "_time_avg";
                else
                    suffix = "_phase_avg";
                end
                signal = signal / obj.get_nominal_speed(obj.get_case_file_base(name, suffix) + ".mat");
            end

            if obj.force_sub && ismember(quantity, ["drag", "lift", "pitch"])
                if obj.is_plain_steady_type(type)
                    disp("Force Body Sub skipped for steady case " + type)
                else
                    body_amp = amp;
                    if body_amp == 30
                        body_amp = 20;
                    end
                    body_type = get_downstream_prefix(type) + "body";
                    body_signal = get_force(obj.force_path, body_type, body_amp, freq, idx, var_name_F);
                    signal = obj.subtract_alignment_body_signal(signal, body_signal);
                end
            end
        end

        % Wingbeat-averaged load cell variable matching the selected load
        % cell data filter (as used by phaseAvg_UI)
        function var_name = get_wingbeat_avg_load_cell_var(obj)
            switch obj.load_cell_data_var
                case {"mod_results", "wingbeat_forces_raw"}
                    var_name = "wingbeat_avg_forces_raw";
                case {"filtered_data", "wingbeat_forces"}
                    var_name = "wingbeat_avg_forces";
                case {"filtered_data_smoother", "wingbeat_forces_smoother"}
                    var_name = "wingbeat_avg_forces_smoother";
                otherwise
                    var_name = "wingbeat_avg_forces_smoothest";
            end
        end

        % How far sig_2 lags sig_1, in wingbeats, in [-0.5, 0.5): the
        % circular cross-correlation peak (both treated as one periodic
        % wingbeat), refined to a fraction of a bin with a parabola through
        % the peak. Signals are resampled to a common length first. NaN if
        % either signal is constant, too short or has no data.
        function shift = circular_phase_shift(obj, sig_1, sig_2)
            shift = NaN;
            sig_1 = obj.fill_periodic_gaps(sig_1);
            sig_2 = obj.fill_periodic_gaps(sig_2);
            if ~obj.is_valid_alignment_signal(sig_1) || ~obj.is_valid_alignment_signal(sig_2)
                disp("Phase shift: a signal is constant or missing, skipped")
                return
            end

            N = max(length(sig_1), length(sig_2));
            sig_1 = obj.resample_periodic(sig_1, N);
            sig_2 = obj.resample_periodic(sig_2, N);
            sig_1 = (sig_1 - mean(sig_1)) / std(sig_1);
            sig_2 = (sig_2 - mean(sig_2)) / std(sig_2);

            % corr(k+1) = sum(sig_1 .* circshift(sig_2, k)); if sig_2 is
            % sig_1 delayed by d bins, the peak is at k = -d
            corr = zeros(1, N);
            for k = 0:N-1
                corr(k+1) = sum(sig_1 .* circshift(sig_2, k));
            end
            [~, k_max] = max(corr);
            c_m = corr(mod(k_max - 2, N) + 1);
            c_0 = corr(k_max);
            c_p = corr(mod(k_max, N) + 1);
            denom = c_m - 2*c_0 + c_p;
            delta = 0;
            if denom < 0
                delta = 0.5 * (c_m - c_p) / denom;
            end
            lag = (k_max - 1) + delta;
            shift = mod(-lag / N + 0.5, 1) - 0.5;
        end

        % Fill NaN bins (e.g. masked vortex centroid) by periodic linear
        % interpolation; [] if fewer than half the bins have data
        function signal = fill_periodic_gaps(~, signal)
            signal = signal(:)';
            valid = isfinite(signal);
            if nnz(valid) < max(2, numel(signal) / 2)
                signal = [];
                return
            end
            if all(valid)
                return
            end
            N = numel(signal);
            idx = 1:N;
            x = [idx(valid) - N, idx(valid), idx(valid) + N];
            y = repmat(signal(valid), 1, 3);
            signal(~valid) = interp1(x, y, idx(~valid), "linear");
        end

        % Resample one periodic wingbeat (bin k at (k-1)/n) to N bins
        function signal = resample_periodic(~, signal, N)
            n = numel(signal);
            if n == N
                return
            end
            t = (0:n) / n;
            t_q = (0:N-1) / N;
            signal = interp1(t, [signal, signal(1)], t_q, "pchip");
        end

        % Convection shift of an STB signal (force / flow variables): the
        % time for the wake to convect from the robot to the imaging plane,
        % as a fraction of a wingbeat. Kinematics are measured at the
        % robot and are returned unchanged. Same distances and speed as
        % phaseAvg_UI / flowField_UI.
        function signal = apply_convection_shift(obj, signal, force_var, type, freq_cor)
            if ismember(obj.get_var_category(force_var), ["kinematics", "load cell"])
                return % measured at the robot
            end
            dist = obj.get_robot_to_plane_dist(type);
            if isnan(dist)
                disp("No downstream distance defined for " + type + ", not shifted")
                return
            end
            conv_speed = 4; % m/s
            shift_samples = round(dist / conv_speed * freq_cor * length(signal));
            signal = circshift(signal, shift_samples);
            disp("Shifted " + obj.get_force_var_label(force_var) + " by: " + shift_samples + ...
                " / " + length(signal) + " (" + dist + " m downstream)")
        end

        % Streamwise distance (m) from the robot to the imaging plane for a
        % case type: x3 = 0.9 m with 0.37 m between positions, MPS = 1 m;
        % old flapper 0.9 m, UP_one / UP_two one / two positions further
        function dist = get_robot_to_plane_dist(~, type)
            prefix = regexprep(get_downstream_prefix(type, true), "_$", ""); % e.g. "x3", "UP_one"
            x_pos = regexp(char(prefix), '^x(\d+)$', 'tokens', 'once');
            if ~isempty(x_pos)
                dist = 0.9 + (str2double(x_pos{1}) - 3) * 0.37;
            elseif prefix == "MPS"
                dist = 1.0;
            elseif prefix == "UP_one"
                dist = 0.9 + 0.37;
            elseif prefix == "UP_two"
                dist = 0.9 + 2*0.37;
            elseif contains(type, "turbine")
                dist = NaN;
            else
                dist = 0.9; % old flapper
            end
        end

        % forces from the time-averaged field (TA: force), not stored in
        % the files, so always calculated by get_PIV_force
        function tf = is_tavg_force_var(obj, force_var)
            tf = any(obj.var_names == string(force_var)) &&...
                obj.get_var_category(force_var) == "TA: force";
        end

        function force_variable = is_piv_force_variable(obj, force_var)
            force_index = find(obj.var_names == force_var, 1);
            % the first 6 variables, plus the (u avg) forces, can be live
            % calculated by get_PIV_force
            force_variable = ~isempty(force_index) &&...
                (force_index <= 6 || startsWith(force_var, ["lift_uavg", "drag_uavg"]) ||...
                 ismember(force_var, ["lift.vortY_edge", "lift.vortX_taper"]));
        end

        % Path (without .mat) to a case's file. RPCA cases not found in
        % phase_avg\ or time_avg\ are looked for in the phase_avg\RPCA\
        % subfolder. Either way the file name must contain _RPCA.
        function file_base = get_case_file_base(obj, name, suffix)
            name = string(name);
            file_base = obj.get_case_dir(name, suffix) + name + suffix;
            if isfile(file_base + ".mat") || isfile(file_base + "_integral.mat") || ~endsWith(name, "_RPCA")
                return
            end
            rpca_base = obj.PIV_path + "RPCA\" + name + suffix;
            if isfile(rpca_base + ".mat") || isfile(rpca_base + "_integral.mat")
                file_base = rpca_base;
            end
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
            if ismember(force_var, ["U_act", "rho_act", "num_bins","num_clusters","phase_spread_ratio"])
                file = filepath;
            else
                file = secondary_filepath;
            end
        end

        function var = load_stored_var(~, files, var_name)
            % Load a (possibly nested, e.g. "lift.vortY") variable from the
            % first of the given .mat files that has it (a case's main
            % file and its _integral file hold different variables). If
            % none of them define it for this case, return 0 and say so.
            requested = string(files);
            files = requested(isfile(requested));
            if isempty(files)
                error("timeAvg_UI:fileNotFound", "None of these files were found:\n  %s",...
                    strjoin(requested, "\n  "));
            end

            parts = split(string(var_name), ".");
            for f = 1:numel(files)
                if ~ismember(char(parts(1)), who('-file', files(f)))
                    continue
                end
                d = load(files(f), parts(1));
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

            [~, file_name] = fileparts(files(1));
            fprintf("%s not defined for %s, using 0\n", var_name, file_name);
            var = 0;
        end

        % Uncertainty mask threshold passed to get_PIV_force with the trim
        % bounds (fraction of the freestream; 0 = off)
        function set_unc_mask_bound(obj)
            if obj.unc_mask_bool
                obj.trim_bounds.unc_mask = obj.unc_mask_pct / 100;
            else
                obj.trim_bounds.unc_mask = 0;
            end
        end

        function value = get_trim_bound_value(obj, field_name)
            % sidebar field name -> value in obj.trim_bounds
            switch field_name
                case "ymin", value = obj.trim_bounds.ybounds(1);
                case "ymax", value = obj.trim_bounds.ybounds(2);
                case "zmin", value = obj.trim_bounds.zbounds(1);
                case "zmax", value = obj.trim_bounds.zbounds(2);
                otherwise,   value = obj.trim_bounds.(field_name);
            end
        end

        function set_trim_bound_value(obj, field_name, value)
            switch field_name
                case "ymin", obj.trim_bounds.ybounds(1) = value;
                case "ymax", obj.trim_bounds.ybounds(2) = value;
                case "zmin", obj.trim_bounds.zbounds(1) = value;
                case "zmax", obj.trim_bounds.zbounds(2) = value;
                otherwise,   obj.trim_bounds.(field_name) = value;
            end
        end

        function new_range = snap_to_available_freqs(obj, value)
            % move each end of the slider to the nearest measured frequency
            new_range = value;
            for k = 1:2
                [~, idx] = min(abs(obj.available_freqs - value(k)));
                new_range(k) = obj.available_freqs(idx);
            end
            new_range = sort(new_range);
        end

        function update_freq_range_label(obj, freq_label)
            freq_label.Text = sprintf("Frequencies: %g - %g Hz", obj.freq_range(1), obj.freq_range(2));
        end

        function set_freq_slider_enable(obj, freq_slider, freq_label)
            % the range only applies to the wingbeat frequency x-axis
            if obj.x_axis_type == "wingbeat frequency"
                state = "on";
            else
                state = "off";
            end
            freq_slider.Enable = state;
            freq_label.Enable = state;
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
            prefix = get_downstream_prefix(type, true); % x1-x5, MPS, UP_one, UP_two

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

        % Reduce a signal (PIV or load cell) to one value per point
        % according to the selected operation
        function val = reduce_signal(obj, signal)
            signal = signal(:);
            switch obj.operation
                case "mean"
                    val = mean(signal, "omitnan");
                case "range"
                    val = range(signal);
                case "rmse"
                    val = sqrt(mean((signal - mean(signal, "omitnan")).^2, "omitnan"));
                otherwise
                    error("timeAvg_UI:unknownOperation", "Unknown operation: %s", obj.operation)
            end
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