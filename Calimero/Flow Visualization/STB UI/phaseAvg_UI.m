% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef phaseAvg_UI < handle

    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];

        OLD_FLAPPER_SOURCE_MODE = "old flapper";
        NEW_FLAPPER_SOURCE_MODE = "new flapper";
        DEFAULT_VERSION_LABEL = "default";
        cur_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
        downstream_distance_labels = ["x = 0.9m"; "x = 1.3m"; "x = 1.7m"];
        new_flapper_downstream_types = ["x1";"x2";"x3";"x4";"x5"];
        new_flapper_distance_labels = ["x1";"x2";"x3";"x4";"x5"];
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

    force_var_types = ["y*w_x", "x*w_y", "(u-U)*w", "u*w",...
        "Drag - Vorticity", "z*w_y", "y*w_z", "(u-U)*u"];
    flow_var_types = ["u", "v", "w", "wx", "wy", "wz", "hel", "wx - z", "wx - y", ...
                "wx - stretch", "wx - y-tilt", "wx - z-tilt", ...
                "u'u'","v'v'","w'w'","u'v'","u'w'","v'w'", "u'w_x'","u'w_y'"];
    kin_var_types = ["Speed", "Speed Error", "Acceleration",...
                "Wing Position", "Wing Speed", "Wing Acceleration",...
                "Voltage", "Modeled Voltage", "Current", "Power"];

    force_var_names = ["lift.vortX", "lift.vortY", "lift.vel", "lift_vel",...
                    "drag.tot", "drag.vortY", "drag.vortZ", "drag_vel"];
    flow_var_names = ["u_avg", "v_avg", "w_avg",...
                    "vortX_avg", "vortY_avg","vortZ_avg", "hel_avg",...
                    "wx_z", "wx_y","wx_stretch","wx_tilt_y","wx_tilt_z",...
                    "uu_avg","vv_avg","ww_avg","uv_avg","uw_avg","vw_avg",...
                    "uwx_avg","uwy_avg"];
    kin_var_names = ["phase_avg_speed", "phase_avg_speed_error",...
                         "phase_avg_acc", "phase_avg_wing_pos",...
                         "phase_avg_wing_speed", "phase_avg_wing_acc",...
                         "phase_avg_volt", "phase_avg_volt_model", "phase_avg_cur", "phase_avg_volt"];

    force_y_labels = ["Lift (N)","Lift (N)","Lift (N)","Lift (N)",...
        "Drag (N)", "Drag (N)", "Drag (N)", "Drag (N)"];
    flow_y_labels = ["$\overline{u} \; / \; U$", "$\overline{v} \; / \; U$",...
                    "$\overline{w} \; / \; U$", "\boldmath$\frac{\omega_x c}{U_{\infty}}$",...
                    "\boldmath$\frac{\omega_y c}{U_{\infty}}$", "\boldmath$\frac{\omega_z c}{U_{\infty}}$",...
                    "helicity", "z/L", "y/L", ...
                    "$\omega_x \frac{\partial u}{\partial x}$",...
                    "$\omega_y \frac{\partial u}{\partial y}$",...
                    "$\omega_z \frac{\partial u}{\partial z}$",...
                    "$\overline{u'u'} \; / \; U^2$",...
                    "$\overline{v'v'} \; / \; U^2$",...
                    "$\overline{w'w'} \; / \; U^2$",...
                    "$\overline{u'v'} \; / \; U^2$",...
                    "$\overline{u'w'} \; / \; U^2$",...
                    "$\overline{v'w'} \; / \; U^2$",...
                    "$\overline{u'\omega_x'} \; \frac{c}{U_{\infty}^2}$",...
                    "$\overline{u'\omega_y'} \; \frac{c}{U_{\infty}^2}$"];
    kin_y_labels = ["Speed (Hz)", "Speed Error (Hz)", "Acceleration (Hz^2)", ...
        "Position (rad)", "Speed (rad/s)", "Acceleration (rad/s^2)",...
        "Voltage (V)", "Current (mA)", "Power (mW)"];

    load_cell_types = ["no filter", "fc = 10*fw", "fc = 5*fw", "fc = 2*fw"];
    load_cell_names = ["wingbeat_avg_forces_raw",...
                     "wingbeat_avg_forces",...
                     "wingbeat_avg_forces_smoother",...
                     "wingbeat_avg_forces_smoothest"];
    load_cell_dict;


    % boolean, normalization/non-dimensionalization on or off
    norm;
    % boolean, normalization for x-axis (divided by period)
    norm_period;
    % boolean, move pitch moment from center of transducer to LE
    pitch_shift;
    % boolean, subtraction on or off
    PIV_sub;
    force_sub;
    RPCA;
    load_cell_force_var;
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
    force_index;
    separate_y_axis_bool;
    mean_subtraction_bool;
    % used to calculate forces from vector field data

    % ------- Available parameters user can select from -------
    available_selections;
    source_mode;
    source_modes;

    selection; % list of selected cases
    sel_type;
    sel_freq;
    sel_amp;
    sel_version;

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
        obj.RPCA = false;
        obj.load_cell_force_var = "wingbeat_avg_forces_smoothest";
        obj.freq_scale = false;
        obj.log_scale = false;
        obj.filt_num = 3;
        obj.saveFig = false;
        obj.y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L;

        obj.force_index = [];
        obj.calc_bool = false;
        obj.align_bool = false;
        obj.separate_y_axis_bool = false;
        obj.mean_subtraction_bool = false;

        obj.load_cell_dict = containers.Map(cellstr(obj.load_cell_types), cellstr(obj.load_cell_names));

        % Search through files in path to get types and speeds

        contents = dir(obj.PIV_path + "phase_avg\");
        files = contents(~[contents.isdir]);

        % Get types, amplitudes, frequencies, and file versions from names.
        obj.available_selections = obj.get_phase_avg_selections_from_files(files);

        if isempty(obj.available_selections)
            error("No STB files found in %s. Expected *_phase_avg.mat or *_time_avg.mat files.", obj.PIV_path + "phase_avg\")
        end

        obj.source_modes = obj.get_available_source_modes();
        if isempty(obj.source_modes)
            error("No old or new flapper STB files found in %s.", obj.PIV_path + "phase_avg\")
        end
        obj.source_mode = obj.source_modes(1);

        obj.plot_curves = [];
        % attachFileListsToBird(path, cur_bird);

        obj.reset_type_options_for_source();
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout.  The option sidebar uses
        % layout managers so controls stay accessible as the window changes
        % size instead of relying on monitor-dependent pixel positions.
        [option_panel, plot_panel, ~] = setupFig(obj.mon_num);
        option_panel.AutoResizeChildren = true;
        if isprop(option_panel, "Scrollable")
            option_panel.Scrollable = "on";
        end

        sidebar_grid = uigridlayout(option_panel, [20, 1]);
        sidebar_grid.ColumnWidth = {'1x'};
        sidebar_grid.RowHeight = {30, 30, 30, 30, 30, 30, 30, 110, 30, 230, 30, 0, 30, 30, 30, 30, 24, 30, 30, 30};
        sidebar_grid.Padding = [10 10 10 10];
        sidebar_grid.RowSpacing = 6;
        if isprop(sidebar_grid, "Scrollable")
            sidebar_grid.Scrollable = "on";
        end

        % Dropdown box for old/new flapper source selection
        source_dropdown = uidropdown(sidebar_grid);
        source_dropdown.Layout.Row = 1;
        source_dropdown.Layout.Column = 1;
        source_dropdown.Items = obj.source_modes;
        source_dropdown.Value = obj.source_mode;

        % Dropdown box for flapper type selection
        d1 = uidropdown(sidebar_grid);
        d1.Layout.Row = 2;
        d1.Layout.Column = 1;
        d1.Items = [obj.distance_labels(:); "all"];

        % Dropdown box for wingbeat frequency selection
        d2 = uidropdown(sidebar_grid);
        d2.Layout.Row = 3;
        d2.Layout.Column = 1;
        cur_freqs = obj.get_freq_options(obj.sel_type, obj.sel_amp);
        freqs_string = string(cur_freqs(:)) + " Hz";
        d2.Items = [freqs_string; "all"];

        % Dropdown box for wingbeat amplitude selection
        d3 = uidropdown(sidebar_grid);
        d3.Layout.Row = 4;
        d3.Layout.Column = 1;
        cur_amps = obj.get_amp_options(obj.sel_type, obj.sel_freq);
        d3.Items = [string(cur_amps(:)) + " deg"; "all"];

        % Dropdown box for file version selection
        d4 = uidropdown(sidebar_grid);
        d4.Layout.Row = 5;
        d4.Layout.Column = 1;
        obj.update_version_dropdown(d4);

        source_dropdown.ValueChangedFcn = @(src, event) source_change(src, event, d1, d2, d3, d4, plot_panel);
        d1.ValueChangedFcn = @(src, event) type_change(src, event, d2, d3, d4);
        d2.ValueChangedFcn = @(src, event) freq_change(src, event, d3, d4);
        d3.ValueChangedFcn = @(src, event) amp_change(src, event, d2, d4);
        d4.ValueChangedFcn = @(src, event) version_change(src, event);

        rpca_button = uibutton(sidebar_grid, "state");
        rpca_button.Layout.Row = 6;
        rpca_button.Layout.Column = 1;
        rpca_button.Text = "RPCA";
        rpca_button.FontSize = 18;
        rpca_button.BackgroundColor = obj.get_button_color(obj.RPCA);
        rpca_button.ValueChangedFcn = @(src, event) RPCA_change(src, event);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        entry_button_grid = uigridlayout(sidebar_grid, [1, 2]);
        entry_button_grid.Layout.Row = 7;
        entry_button_grid.Layout.Column = 1;
        entry_button_grid.ColumnWidth = {'1x', '1x'};
        entry_button_grid.RowHeight = {'1x'};
        entry_button_grid.Padding = [0 0 0 0];
        entry_button_grid.ColumnSpacing = 8;

        b2 = uibutton(entry_button_grid);
        b2.Layout.Row = 1;
        b2.Layout.Column = 1;
        b2.BackgroundColor = [1 1 1];
        b2.Text = "Add entry";

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b3 = uibutton(entry_button_grid);
        b3.Layout.Row = 1;
        b3.Layout.Column = 2;
        b3.BackgroundColor = [1 1 1];
        b3.Text = "Delete entry";

        % List of cases currently displayed on the plots
        lbox = uilistbox(sidebar_grid);
        lbox.Layout.Row = 8;
        lbox.Layout.Column = 1;
        lbox.Items = strings(0);

        b2.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
        b3.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

        b33 = uibutton(sidebar_grid);
        b33.Layout.Row = 9;
        b33.Layout.Column = 1;
        b33.Text = "Clear Entries";
        b33.FontSize = 18;
        b33.BackgroundColor = [1 1 1];
        b33.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

        param_panel = uipanel(sidebar_grid);
        param_panel.Layout.Row = 10;
        param_panel.Layout.Column = 1;
        param_panel.Title = "Plot Parameters";
        param_panel.TitlePosition = 'centertop';

        param_grid = uigridlayout(param_panel, [7, 1]);
        param_grid.ColumnWidth = {'1x'};
        param_grid.RowHeight = {22, 25, 22, 25, 22, 25, 30};
        param_grid.Padding = [10 8 10 8];
        param_grid.RowSpacing = 4;

        var_type_label = uilabel(param_grid);
        var_type_label.Layout.Row = 1;
        var_type_label.Layout.Column = 1;
        var_type_label.Text = "Variable Type";

        var_type_dropdown = uidropdown(param_grid);
        var_type_dropdown.Layout.Row = 2;
        var_type_dropdown.Layout.Column = 1;
        var_type_dropdown.Items = ["kinematics", "flow", "force", "BA: force"];
        var_type_dropdown.Value = "kinematics";

        [init_types, ~, ~] = obj.get_variable_options(var_type_dropdown.Value);
        init_options = ["none", init_types];

        var_label1 = uilabel(param_grid);
        var_label1.Layout.Row = 3;
        var_label1.Layout.Column = 1;
        var_label1.Text = "Variable 1";

        var_dropdown1 = uidropdown(param_grid);
        var_dropdown1.Layout.Row = 4;
        var_dropdown1.Layout.Column = 1;
        var_dropdown1.Items = init_options;
        var_dropdown1.Value = "none";

        var_label2 = uilabel(param_grid);
        var_label2.Layout.Row = 5;
        var_label2.Layout.Column = 1;
        var_label2.Text = "Variable 2";

        var_dropdown2 = uidropdown(param_grid);
        var_dropdown2.Layout.Row = 6;
        var_dropdown2.Layout.Column = 1;
        var_dropdown2.Items = init_options;
        var_dropdown2.Value = "none";

        b6 = uibutton(param_grid, "state");
        b6.Layout.Row = 7;
        b6.Layout.Column = 1;
        b6.Text = "PIV Body Sub";
        b6.FontSize = 18;
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

        var_dropdown1.ValueChangedFcn = @(src, event) updateVariableSelection(src, event, plot_panel, var_dropdown1, var_dropdown2);
        var_dropdown2.ValueChangedFcn = @(src, event) updateVariableSelection(src, event, plot_panel, var_dropdown1, var_dropdown2);
        var_type_dropdown.ValueChangedFcn = @(src, event) updateVariableType(src, event, plot_panel, var_dropdown1, var_dropdown2);

        load_cell_toggle = uibutton(sidebar_grid, "state");
        load_cell_toggle.Layout.Row = 11;
        load_cell_toggle.Layout.Column = 1;
        load_cell_toggle.Text = phaseAvg_UI.get_button_text(false, "Load Cell");
        load_cell_toggle.FontSize = 18;
        load_cell_toggle.BackgroundColor = [1 1 1];

        load_cell_panel = uipanel(sidebar_grid);
        load_cell_panel.Layout.Row = 12;
        load_cell_panel.Layout.Column = 1;
        load_cell_panel.Title = "Load Cell";
        load_cell_panel.TitlePosition = 'centertop';
        load_cell_panel.Visible = "off";

        load_cell_grid = uigridlayout(load_cell_panel, [5, 1]);
        load_cell_grid.ColumnWidth = {'1x'};
        load_cell_grid.RowHeight = {22, 25, 22, 25, 30};
        load_cell_grid.Padding = [10 8 10 8];
        load_cell_grid.RowSpacing = 4;

        force_label = uilabel(load_cell_grid);
        force_label.Layout.Row = 1;
        force_label.Layout.Column = 1;
        force_label.Text = "Force Component";

        force_dropdown = uidropdown(load_cell_grid);
        force_dropdown.Layout.Row = 2;
        force_dropdown.Layout.Column = 1;
        force_dropdown.Items = ["none", "drag", "lift", "pitch"];
        force_dropdown.Value = "none";
        force_dropdown.ValueChangedFcn = @(src, event) force_selection_change(src, event, plot_panel);

        force_data_label = uilabel(load_cell_grid);
        force_data_label.Layout.Row = 3;
        force_data_label.Layout.Column = 1;
        force_data_label.Text = "Force Data";

        force_data_dropdown = uidropdown(load_cell_grid);
        force_data_dropdown.Layout.Row = 4;
        force_data_dropdown.Layout.Column = 1;
        force_data_dropdown.Items = obj.load_cell_types;
        force_data_dropdown.Value = obj.load_cell_types(end);
        force_data_dropdown.ValueChangedFcn = @(src, event) load_cell_force_var_change(src, event, plot_panel);

        b7 = uibutton(load_cell_grid, "state");
        b7.Layout.Row = 5;
        b7.Layout.Column = 1;
        b7.Text = "Force Body Sub";
        b7.FontSize = 18;
        b7.BackgroundColor = [1 1 1];
        b7.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

        load_cell_toggle.ValueChangedFcn = @(src, event) load_cell_toggle_change(src, event, load_cell_panel);

        b77 = uibutton(sidebar_grid, "state");
        b77.Layout.Row = 13;
        b77.Layout.Column = 1;
        b77.Text = "Live Calculate";
        b77.FontSize = 18;
        b77.BackgroundColor = [1 1 1];
        b77.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel);

        b88 = uibutton(sidebar_grid, "state");
        b88.Layout.Row = 14;
        b88.Layout.Column = 1;
        b88.Text = "Align";
        b88.FontSize = 18;
        b88.BackgroundColor = [1 1 1];
        b88.ValueChangedFcn = @(src, event) align_change(src, event, plot_panel);

        b99 = uibutton(sidebar_grid, "state");
        b99.Layout.Row = 15;
        b99.Layout.Column = 1;
        b99.Text = "Separate Y-Axis";
        b99.FontSize = 18;
        b99.BackgroundColor = [1 1 1];
        b99.ValueChangedFcn = @(src, event) separate_y_axis_change(src, event, plot_panel);

        b100 = uibutton(sidebar_grid, "state");
        b100.Layout.Row = 16;
        b100.Layout.Column = 1;
        b100.Text = "Mean Subtraction";
        b100.FontSize = 18;
        b100.BackgroundColor = [1 1 1];
        b100.ValueChangedFcn = @(src, event) mean_subtraction_change(src, event, plot_panel);


        % Remaining file output controls.
        fnl = uilabel(sidebar_grid);
        fnl.Layout.Row = 17;
        fnl.Layout.Column = 1;
        fnl.HorizontalAlignment = "center";
        fnl.Text = "File Name";

        ef = uieditfield(sidebar_grid);
        ef.Layout.Row = 18;
        ef.Layout.Column = 1;
        ef.Placeholder = "test";

        % Button to export data on plot to .mat file
        b10 = uibutton(sidebar_grid);
        b10.Layout.Row = 19;
        b10.Layout.Column = 1;
        b10.Text = "Export Data";
        b10.ButtonPushedFcn = @(src, event) exportData(src, event, ef);

        b4 = uibutton(sidebar_grid);
        b4.Layout.Row = 20;
        b4.Layout.Column = 1;
        b4.Text = "Save Fig";
        b4.FontSize = 18;
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

        % update source mode and refresh dependent dropdowns
        function source_change(src, ~, type_dropdown, freq_dropdown, amp_dropdown, version_dropdown, plot_panel)
            obj.source_mode = string(src.Value);
            obj.reset_type_options_for_source();
            refresh_type_dropdown(type_dropdown);
            obj.update_frequency_dropdown(freq_dropdown);
            obj.update_amp_dropdown(amp_dropdown);
            obj.update_version_dropdown(version_dropdown);
            obj.update_plot(plot_panel);
        end

        function refresh_type_dropdown(type_dropdown)
            if isempty(obj.distance_labels)
                type_dropdown.Items = "No flapper data";
                type_dropdown.Value = "No flapper data";
                type_dropdown.Enable = "off";
                return
            end

            type_dropdown.Enable = "on";
            type_dropdown.Items = [obj.distance_labels(:); "all"];
            if obj.sel_type == "all"
                type_dropdown.Value = "all";
            else
                type_dropdown.Value = string(obj.type_distance_dict(char(obj.sel_type)));
            end
        end

        % update type variable with new value selected by user
        function type_change(src, ~, freq_dropdown, amp_dropdown, version_dropdown)
            if src.Value == "all"
                obj.sel_type = string(src.Value);
            else
                obj.sel_type = string(obj.distance_type_dict(char(src.Value)));
            end

            [obj.sel_amp, obj.sel_freq] = obj.get_first_selection(obj.sel_type);
            obj.update_frequency_dropdown(freq_dropdown);
            obj.update_amp_dropdown(amp_dropdown);
            obj.update_version_dropdown(version_dropdown);
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~, amp_dropdown, version_dropdown)
            if strcmp(src.Value, "all")
            obj.sel_freq = -1;
            else
            obj.sel_freq = str2double(regexp(src.Value, '\d+', 'match'));
            end
            
            obj.update_amp_dropdown(amp_dropdown);
            obj.update_version_dropdown(version_dropdown);
        end

        % update speed variable with new value selected by user
        function amp_change(src, ~, freq_dropdown, version_dropdown)
            if strcmp(src.Value, "all")
                obj.sel_amp = -1;
            else
                obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));
            end

            obj.update_frequency_dropdown(freq_dropdown);
            obj.update_version_dropdown(version_dropdown);
        end

        function version_change(src, ~)
            obj.sel_version = string(src.Value);
        end

        function PIV_sub_change(src, ~, plot_panel)
            obj.PIV_sub = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.PIV_sub);
            obj.update_plot(plot_panel);
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

        function mean_subtraction_change(src, ~, plot_panel)
            obj.mean_subtraction_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.mean_subtraction_bool);
            obj.update_plot(plot_panel);
        end

        function load_cell_toggle_change(src, ~, load_cell_panel)
            src.Text = phaseAvg_UI.get_button_text(src.Value, "Load Cell");
            src.BackgroundColor = obj.get_button_color(src.Value);
            row_heights = sidebar_grid.RowHeight;
            if src.Value
                load_cell_panel.Visible = "on";
                row_heights{12} = 180;
            else
                load_cell_panel.Visible = "off";
                row_heights{12} = 0;
            end
            sidebar_grid.RowHeight = row_heights;
        end

        function addToList(~, ~, plot_panel, lbox)
            selection_types = string(obj.available_selections(:,1));
            selection_amps = cell2mat(obj.available_selections(:,2));
            selection_freqs = cell2mat(obj.available_selections(:,3));
            selection_versions = string(obj.available_selections(:,4));

            type_mask = obj.get_source_type_mask(selection_types);
            if obj.sel_type ~= "all"
                type_mask = type_mask & selection_types == obj.sel_type;
            end

            amp_mask = true(size(selection_amps));
            if obj.sel_amp ~= -1
                amp_mask = selection_amps == obj.sel_amp;
            end

            freq_mask = true(size(selection_freqs));
            if obj.sel_freq ~= -1
                freq_mask = selection_freqs == obj.sel_freq;
            end

            version_mask = obj.get_version_mask(selection_versions, obj.sel_version);

            matching_indices = find(type_mask & amp_mask & freq_mask & version_mask);
            type_order = obj.get_type_sort_order(selection_types(matching_indices));
            version_order = obj.get_version_sort_order(selection_versions(matching_indices));
            [~, sort_order] = sortrows([type_order(:),...
                                        selection_amps(matching_indices),...
                                        selection_freqs(matching_indices),...
                                        version_order(:)]);
            matching_indices = matching_indices(sort_order);

            for n = 1:length(matching_indices)
                cur_idx = matching_indices(n);
                case_name = selection_types(cur_idx) + "_" + string(selection_amps(cur_idx)) +...
                    "deg_" + string(selection_freqs(cur_idx)) + "Hz" +...
                    obj.get_version_suffix(selection_versions(cur_idx));
                if obj.RPCA
                    case_name = case_name + "_RPCA";
                end

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

        function force_selection_change(src, ~, plot_panel)
            obj.force_index = obj.get_force_dropdown_index(src.Value);
            obj.update_plot(plot_panel);
        end

        function load_cell_force_var_change(src, ~, plot_panel)
            obj.load_cell_force_var = obj.load_cell_dict(src.Value);
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
    function reset_type_options_for_source(obj)
        [selection_types, obj.distance_labels] = obj.get_available_type_options();
        obj.distance_type_dict = obj.build_string_map(obj.distance_labels, selection_types);
        obj.type_distance_dict = obj.build_string_map(selection_types, obj.distance_labels);

        if isempty(selection_types)
            obj.sel_type = "";
            obj.sel_amp = -1;
            obj.sel_freq = -1;
            obj.sel_version = obj.DEFAULT_VERSION_LABEL;
            return
        end

        obj.sel_type = selection_types(1);
        [obj.sel_amp, obj.sel_freq] = obj.get_first_selection(obj.sel_type);
        obj.sel_version = obj.get_first_version(obj.sel_type, obj.sel_amp, obj.sel_freq);
    end

    function map = build_string_map(~, keys, values)
        if isempty(keys)
            map = containers.Map('KeyType', 'char', 'ValueType', 'char');
        else
            map = containers.Map(cellstr(keys), cellstr(values));
        end
    end

    function available_selections = get_phase_avg_selections_from_files(obj, files)
        available_selections = cell(length(files), 4);

        for i = 1:length(files)
            name = string(files(i).name);

            % Skip body/ring cases and secondary files.
            if ~contains(name, "Hz") || contains(name, "integral")
                continue
            end

            name = erase(name, ["_time_avg.mat", "_phase_avg.mat"]);
            [base_name, version] = obj.extract_file_version(name);
            [amp, type, freq] = parse_name(base_name);

            available_selections{i, 1} = type;
            available_selections{i, 2} = amp;
            available_selections{i, 3} = freq;
            available_selections{i, 4} = version;
        end

        available_selections(all(cellfun(@isempty, available_selections), 2), :) = [];
    end

    function [base_name, version] = extract_file_version(obj, name)
        base_name = string(name);
        version = obj.DEFAULT_VERSION_LABEL;
        version_match = regexp(char(base_name), '_v\d+$', 'match', 'once');

        if ~isempty(version_match)
            version = erase(string(version_match), "_");
            base_name = string(regexprep(char(base_name), '_v\d+$', ''));
        end
    end

    function source_modes = get_available_source_modes(obj)
        selection_types = string(obj.available_selections(:, 1));
        selection_types = selection_types(strlength(selection_types) > 0);
        source_modes = strings(0, 1);

        if any(~obj.is_new_flapper_type(selection_types))
            source_modes(end + 1, 1) = obj.OLD_FLAPPER_SOURCE_MODE;
        end

        if any(obj.is_new_flapper_type(selection_types))
            source_modes(end + 1, 1) = obj.NEW_FLAPPER_SOURCE_MODE;
        end
    end

    function mask = get_source_type_mask(obj, selection_types)
        selection_types = string(selection_types);
        if obj.source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            mask = obj.is_new_flapper_type(selection_types);
        else
            mask = ~obj.is_new_flapper_type(selection_types);
        end
    end

    function [selection_types, selection_labels] = get_available_type_options(obj)
        available_types = unique(string(obj.available_selections(:, 1)), 'stable');
        available_types = available_types(strlength(available_types) > 0);
        available_types = available_types(obj.get_source_type_mask(available_types));
        selection_types = obj.get_ordered_type_options(available_types);
        selection_labels = strings(length(selection_types), 1);

        for i = 1:length(selection_types)
            selection_labels(i) = obj.get_type_label(selection_types(i));
        end

        selection_labels = obj.disambiguate_duplicate_type_labels(selection_types, selection_labels);
    end

    function mask = get_type_mask(~, selection_types, selected_type)
        if string(selected_type) == "all"
            mask = true(size(selection_types));
        else
            mask = selection_types == string(selected_type);
        end
    end

    function [amp, freq] = get_first_selection(obj, selected_type)
        selection_types = string(obj.available_selections(:, 1));
        mask = obj.get_source_type_mask(selection_types) & obj.get_type_mask(selection_types, selected_type);
        first_index = find(mask, 1);

        amp = obj.available_selections{first_index, 2};
        freq = obj.available_selections{first_index, 3};
    end

    function version = get_first_version(obj, selected_type, selected_amp, selected_freq)
        versions = obj.get_version_options(selected_type, selected_amp, selected_freq);
        if isempty(versions)
            version = obj.DEFAULT_VERSION_LABEL;
        else
            version = versions(1);
        end
    end

    function freqs = get_freq_options(obj, selected_type, selected_amp)
        selection_types = string(obj.available_selections(:, 1));
        selection_amps = cell2mat(obj.available_selections(:, 2));
        selection_freqs = cell2mat(obj.available_selections(:, 3));

        mask = obj.get_source_type_mask(selection_types) & obj.get_type_mask(selection_types, selected_type);
        if selected_amp ~= -1
            mask = mask & selection_amps == selected_amp;
        end

        freqs = unique(selection_freqs(mask));
    end

    function amps = get_amp_options(obj, selected_type, selected_freq)
        selection_types = string(obj.available_selections(:, 1));
        selection_amps = cell2mat(obj.available_selections(:, 2));
        selection_freqs = cell2mat(obj.available_selections(:, 3));

        mask = obj.get_source_type_mask(selection_types) & obj.get_type_mask(selection_types, selected_type);
        if selected_freq ~= -1
            mask = mask & selection_freqs == selected_freq;
        end

        amps = unique(selection_amps(mask));
    end

    function versions = get_version_options(obj, selected_type, selected_amp, selected_freq)
        selection_types = string(obj.available_selections(:, 1));
        selection_amps = cell2mat(obj.available_selections(:, 2));
        selection_freqs = cell2mat(obj.available_selections(:, 3));
        selection_versions = string(obj.available_selections(:, 4));

        mask = obj.get_source_type_mask(selection_types) & obj.get_type_mask(selection_types, selected_type);
        if selected_amp ~= -1
            mask = mask & selection_amps == selected_amp;
        end

        if selected_freq ~= -1
            mask = mask & selection_freqs == selected_freq;
        end

        versions = obj.sort_version_options(selection_versions(mask));
    end

    function update_frequency_dropdown(obj, dropdown)
        freqs = obj.get_freq_options(obj.sel_type, obj.sel_amp);
        dropdown.Items = [string(freqs(:)) + " Hz"; "all"];
        if obj.sel_freq == -1
            dropdown.Value = "all";
        elseif isempty(freqs)
            obj.sel_freq = -1;
            dropdown.Value = "all";
        elseif ~ismember(obj.sel_freq, freqs)
            obj.sel_freq = freqs(1);
            dropdown.Value = string(obj.sel_freq) + " Hz";
        else
            dropdown.Value = string(obj.sel_freq) + " Hz";
        end
    end

    function update_amp_dropdown(obj, dropdown)
        amps = obj.get_amp_options(obj.sel_type, obj.sel_freq);
        dropdown.Items = [string(amps(:)) + " deg"; "all"];
        if obj.sel_amp == -1
            dropdown.Value = "all";
        elseif isempty(amps)
            obj.sel_amp = -1;
            dropdown.Value = "all";
        elseif ~ismember(obj.sel_amp, amps)
            obj.sel_amp = amps(1);
            dropdown.Value = string(obj.sel_amp) + " deg";
        else
            dropdown.Value = string(obj.sel_amp) + " deg";
        end
    end

    function update_version_dropdown(obj, dropdown)
        versions = obj.get_version_options(obj.sel_type, obj.sel_amp, obj.sel_freq);
        if isempty(versions)
            obj.sel_version = obj.DEFAULT_VERSION_LABEL;
            dropdown.Items = obj.DEFAULT_VERSION_LABEL;
            dropdown.Value = obj.DEFAULT_VERSION_LABEL;
            return
        end

        dropdown.Items = [versions(:); "all"];
        if obj.sel_version == "all"
            dropdown.Value = "all";
        elseif ~ismember(obj.sel_version, versions)
            obj.sel_version = versions(1);
            dropdown.Value = obj.sel_version;
        else
            dropdown.Value = obj.sel_version;
        end
    end

    function mask = get_version_mask(obj, selection_versions, selected_version)
        if string(selected_version) == "all"
            mask = true(size(selection_versions));
        else
            mask = string(selection_versions) == string(selected_version);
        end
    end

    function versions = sort_version_options(obj, versions)
        versions = unique(string(versions), 'stable');
        versions = versions(strlength(versions) > 0);
        default_versions = versions(versions == obj.DEFAULT_VERSION_LABEL);
        numbered_versions = versions(versions ~= obj.DEFAULT_VERSION_LABEL);
        numbered_versions = numbered_versions(:);
        version_numbers = zeros(size(numbered_versions));

        for i = 1:length(numbered_versions)
            version_number = regexp(char(numbered_versions(i)), '^v(\d+)$', 'tokens', 'once');
            if isempty(version_number)
                version_numbers(i) = inf;
            else
                version_numbers(i) = str2double(version_number{1});
            end
        end

        [~, sort_order] = sort(version_numbers);
        versions = [default_versions(:); numbered_versions(sort_order(:))];
    end

    function version_order = get_version_sort_order(obj, versions)
        versions = string(versions);
        ordered_versions = obj.sort_version_options(versions);
        [~, version_order] = ismember(versions, ordered_versions);
        version_order(version_order == 0) = length(ordered_versions) + 1;
    end

    function suffix = get_version_suffix(obj, version)
        version = string(version);
        if version == obj.DEFAULT_VERSION_LABEL
            suffix = "";
        else
            suffix = "_" + version;
        end
    end

    function selection_types = get_ordered_type_options(obj, available_types)
        available_types = unique(string(available_types(:)), 'stable');
        available_types = available_types(strlength(available_types) > 0);
        selection_types = strings(0, 1);

        for i = 1:length(obj.cur_types)
            type = obj.cur_types(i);
            if any(available_types == type)
                selection_types(end + 1, 1) = type;
            end
        end

        for i = 1:length(obj.new_flapper_downstream_types)
            downstream_type = obj.new_flapper_downstream_types(i);
            matching_types = available_types(obj.is_new_flapper_type(available_types, downstream_type));
            selection_types = [selection_types; matching_types(:)];
        end

        other_types = setdiff(available_types(:), selection_types, 'stable');
        selection_types = [selection_types; other_types(:)];
    end

    function type_order = get_type_sort_order(obj, types)
        types = string(types);
        ordered_types = obj.get_ordered_type_options(types);
        [~, type_order] = ismember(types, ordered_types);
        type_order(type_order == 0) = length(ordered_types) + 1;
    end

    function label = get_type_label(obj, type)
        type = string(type);
        type_index = find(obj.cur_types == type, 1);
        if ~isempty(type_index)
            label = obj.downstream_distance_labels(type_index);
            return
        end

        downstream_index = obj.get_new_flapper_downstream_index(type);
        if ~isempty(downstream_index)
            label = obj.new_flapper_distance_labels(downstream_index);
            return
        end

        label = type;
    end

    function labels = disambiguate_duplicate_type_labels(~, types, labels)
        types = string(types);
        labels = string(labels);
        original_labels = labels;

        for i = 1:length(labels)
            if sum(original_labels == original_labels(i)) > 1
                labels(i) = labels(i) + " (" + strrep(types(i), "_", " ") + ")";
            end
        end
    end

    function mask = is_new_flapper_type(obj, types, downstream_type)
        types = string(types);
        if nargin < 3
            mask = false(size(types));
            for i = 1:length(obj.new_flapper_downstream_types)
                mask = mask | obj.is_new_flapper_type(types, obj.new_flapper_downstream_types(i));
            end
            return
        end

        downstream_type = string(downstream_type);
        mask = types == downstream_type | startsWith(types, downstream_type + "_");
    end

    function downstream_index = get_new_flapper_downstream_index(obj, type)
        downstream_index = [];
        for i = 1:length(obj.new_flapper_downstream_types)
            if obj.is_new_flapper_type(type, obj.new_flapper_downstream_types(i))
                downstream_index = i;
                return
            end
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

    function [types, names, labels] = get_all_variable_options(obj)
        ba_force_types = "BA: " + obj.force_var_types;
        ba_force_names = regexprep(obj.force_var_names, '\.', "_phase_avg" + ".");

        types = [obj.force_var_types, ba_force_types, obj.flow_var_types, obj.kin_var_types];
        names = [obj.force_var_names, ba_force_names, obj.flow_var_names, obj.kin_var_names];
        labels = [obj.force_y_labels, obj.force_y_labels, obj.flow_y_labels, obj.kin_y_labels];
    end

    function [types, names, labels] = get_variable_options(obj, var_type)
        if strcmp(var_type, "kinematics")
            types = obj.kin_var_types;
            names = obj.kin_var_names;
            labels = obj.kin_y_labels;
        elseif strcmp(var_type, "flow")
            types = obj.flow_var_types;
            names = obj.flow_var_names;
            labels = obj.flow_y_labels;
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

    function is_rpca = is_RPCA_selection(~, cur_sel)
        is_rpca = contains(string(cur_sel), "_RPCA");
    end

    function case_label = get_case_label(obj, cur_sel)
        [amp, type, freq] = parse_name(cur_sel);
        distance_label = obj.get_type_label(type);
        version = obj.get_selection_version(cur_sel);

        case_label = strrep(distance_label + ", " + amp + " deg, " + freq + " Hz", "_", " ");
        if version ~= obj.DEFAULT_VERSION_LABEL
            case_label = case_label + ", " + version;
        end

        if obj.is_RPCA_selection(cur_sel)
            case_label = case_label + " - RPCA";
        end
    end

    function version = get_selection_version(obj, selection)
        selection = string(selection);
        selection = regexprep(char(selection), '_RPCA$', '');
        version_match = regexp(selection, '_v\d+$', 'match', 'once');

        if isempty(version_match)
            version = obj.DEFAULT_VERSION_LABEL;
        else
            version = erase(string(version_match), "_");
        end
    end

    function legend_entry = get_aligned_legend_entry(obj, cur_sel, index, is_force)
        case_label = obj.get_case_label(cur_sel);
        index_label = obj.active_types(index);

        if is_force
            force_label = obj.get_force_legend_label();
            if length(obj.selection) > 1 && length(obj.inds) > 1
                legend_entry = case_label + " - " + index_label + " - " + force_label;
            elseif length(obj.selection) > 1
                legend_entry = case_label + " - " + force_label;
            elseif length(obj.inds) > 1
                legend_entry = index_label + " - " + force_label;
            else
                legend_entry = case_label + " - " + force_label;
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

    function force_label = get_force_legend_label(obj)
        if isempty(obj.force_index)
            force_label = "Force";
        elseif obj.force_index == 1
            force_label = "Drag force";
        elseif obj.force_index == 3
            force_label = "Lift force";
        elseif obj.force_index == 5
            force_label = "Pitch force";
        else
            force_label = "Force " + string(obj.force_index);
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

    function force_idx = get_force_dropdown_index(~, force_selection)
        switch string(force_selection)
            case "drag"
                force_idx = 1;
            case "lift"
                force_idx = 3;
            case "pitch"
                force_idx = 5;
            otherwise
                force_idx = [];
        end
    end

    function split_axis = should_split_load_cell_axis(obj)
        split_axis = obj.separate_y_axis_bool &&...
                     ~isempty(obj.force_index) &&...
                     ~isempty(obj.inds);
    end

    function [time_F, force] = get_load_cell_force(obj, type, amp, freq)
        time_F = [];
        force = [];
        if isempty(obj.force_index) || contains(type, "UP")
            return
        end

        var_name_F = obj.load_cell_force_var;
        force = get_force(obj.force_path, type, amp, freq, obj.force_index, var_name_F);

        if obj.force_sub
            body_amp = amp;
            if body_amp == 30
                body_amp = 20;
            end
            body_force = get_force(obj.force_path, "body", body_amp, freq, obj.force_index, var_name_F);
            force = force - body_force;
        end

        force = obj.subtract_signal_mean(force);

        time_F = 1:length(force);
        time_F = time_F / length(force);
    end

    function dual_plot = should_use_separate_y_axes(obj)
        dual_plot = false;
        if obj.should_split_load_cell_axis()
            dual_plot = true;
            return
        end

        if length(obj.inds) < 2
            return
        end

        force_indices = arrayfun(@(index) obj.is_force_index(index), obj.inds);
        dual_plot = obj.separate_y_axis_bool || ~all(force_indices);
    end

    function signal = subtract_signal_mean(obj, signal)
        if obj.mean_subtraction_bool && ~isempty(signal)
            signal = signal - mean(signal);
        end
    end

    function y_label = get_plot_parameter_axis_label(obj)
        if isempty(obj.inds)
            y_label = "";
            return
        end

        if all(arrayfun(@(index) obj.is_force_index(index), obj.inds))
            y_label = "Plot Parameter Force (N)";
            return
        end

        labels = obj.active_labels(obj.inds);
        if all(labels == labels(1))
            y_label = labels(1);
        else
            y_label = "Plot Parameter Values";
        end
    end

    function ylabs = get_y_axis_labels(obj, dual_plot)
        ylabs = strings(1,2);
        if ~dual_plot
            return
        end

        if obj.should_split_load_cell_axis()
            ylabs(1) = obj.get_plot_parameter_axis_label();
            ylabs(2) = "Load Cell Force (N)";
        else
            ylabs(1) = obj.active_labels(obj.inds(1));
            ylabs(2) = obj.active_labels(obj.inds(2));
        end
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
            use_selection_colors = false;
        else
            selection_types = string(cur_selections(:,1));
            selection_amps = cell2mat(cur_selections(:,2));
            selection_freqs = cell2mat(cur_selections(:,3));
            uniq_types = unique(selection_types);
            uniq_amps = unique(selection_amps);
            uniq_freqs = unique(selection_freqs);
            case_color_keys = selection_types + "_" + string(selection_amps) + "deg_" +...
                              string(selection_freqs) + "Hz";
            use_selection_colors = length(uniq_types) > 1 ||...
                                   length(unique(case_color_keys)) < length(obj.selection);
            if use_selection_colors
                colors = strings(0);
            else
                colors = getColors(1,...
                                   length(uniq_amps),...
                                   length(uniq_freqs),...
                                   length(obj.selection));
            end
        end

        selection_colors = obj.get_default_selection_colors(length(obj.selection));
        color_params.uniq_freqs = uniq_freqs;
        color_params.uniq_amps = uniq_amps;
        color_params.colors = colors;
        color_params.use_selection_colors = use_selection_colors;
        color_params.selection_names = string(obj.selection);
        color_params.selection_colors = selection_colors;

        align_plot_bool = obj.align_bool &&...
                          ~isempty(obj.inds) &&...
                          ~isempty(obj.selection);
        aligned_curves = struct('val', {}, 'time', {}, 'index', {},...
                                'plot_idx', {}, 'cur_sel', {},...
                                'legend_entry', {}, 'line_style', {},...
                                'marker', {}, 'y_axis', {});

        % ----------------------------------------

        dual_plot = obj.should_use_separate_y_axes();
        ylabs = obj.get_y_axis_labels(dual_plot);

        ax = axes(plot_panel);
        hold(ax, 'on');
        hold(ax_target, 'on');

        if isempty(obj.inds) && ~isempty(obj.force_index)
            for i = 1:length(obj.selection)
                cur_sel = obj.selection(i);
                [amp, type, freq] = parse_name(cur_sel);
                [time_F, force] = obj.get_load_cell_force(type, amp, freq);

                if ~isempty(force)
                    obj.plot_load_cell_force(ax, ax_target, time_F, force, cur_sel, color_params);
                end
            end
        end

        for j = 1:length(obj.inds)
            index = obj.inds(j);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);

            [amp, type, freq] = parse_name(cur_sel);

            filename = cur_sel + "_phase_avg";
            file_path = obj.PIV_path  + "phase_avg\" + filename + ".mat";
            secondary_file_path = obj.PIV_path  + "phase_avg\" + filename + "_integral.mat";

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
            conv_shift = false;
            if obj.is_force_index(index) && conv_shift
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

            var = obj.subtract_signal_mean(var);

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
                    'marker', obj.get_piv_force_marker(index),...
                    'y_axis', "");
            end

            [time_F, force] = obj.get_load_cell_force(type, amp, freq);

            if align_plot_bool && ~isempty(force)
                aligned_curves(end+1) = struct(...
                    'val', force,...
                    'time', time_F,...
                    'index', index,...
                    'plot_idx', j,...
                    'cur_sel', cur_sel,...
                    'legend_entry', obj.get_aligned_legend_entry(cur_sel, index, true),...
                    'line_style', "-",...
                    'marker', "none",...
                    'y_axis', "right");
            end

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
            plot_options.y_axis = aligned_curves(i).y_axis;
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

    function legend_entry = get_load_cell_legend_entry(obj, cur_sel)
        case_label = obj.get_case_label(cur_sel);
        legend_entry = case_label + " - " + obj.get_force_legend_label();
    end

    function plot_load_cell_force(obj, ax, ax_target, time_F, force, cur_sel, color_params)
        original_color = obj.get_curve_color(cur_sel, color_params);
        legend_entry = obj.get_load_cell_legend_entry(cur_sel);

        line = plot(ax, time_F, force);
        line.DisplayName = legend_entry;
        line.Color = original_color;
        line.LineWidth = 2;
        line.LineStyle = "-";
        disp(legend_entry + ": " + mean(force))

        line_h = plot(ax_target, time_F, force);
        line_h.DisplayName = legend_entry;
        line_h.Color = original_color;
        line_h.LineWidth = 2;
        line_h.LineStyle = "-";

        xlabel(ax, "Time over Wingbeat Period (t/T)", Interpreter="latex")
        xlabel(ax_target, "Time over Wingbeat Period (t/T)", Interpreter="latex")
        ylabel(ax, "Load Cell Force (N)", Interpreter="latex")
        ylabel(ax_target, "Load Cell Force (N)", Interpreter="latex")
        grid(ax, 'on');
        legend(ax, Location="best", Interpreter="latex");
        grid(ax_target, 'on');
        legend(ax_target, Location="best", Interpreter="latex");

        ax.FontSize = 18;
        ax_target.FontSize = 18;
    end

    function plot_data(obj, ax, ax_target, time, var, time_F, force, index, dual_plot, plot_idx, cur_sel, color_params, ylabs, plot_options)
        if nargin < 14 || isempty(plot_options)
            plot_options = struct();
        end

        has_legend_override = isfield(plot_options, 'legend_entry') && strlength(string(plot_options.legend_entry)) > 0;
        has_line_style = isfield(plot_options, 'line_style') && strlength(string(plot_options.line_style)) > 0;
        has_marker = isfield(plot_options, 'marker') && strlength(string(plot_options.marker)) > 0;
        has_y_axis = isfield(plot_options, 'y_axis') && strlength(string(plot_options.y_axis)) > 0;

        [amp, type, freq] = parse_name(cur_sel);
        % Get color for this case name
        original_color = obj.get_curve_color(cur_sel, color_params);

        if dual_plot
            if has_y_axis
                axis_side = string(plot_options.y_axis);
            elseif obj.should_split_load_cell_axis()
                axis_side = "left";
            elseif plot_idx == 1
                axis_side = "left";
            else
                axis_side = "right";
            end

            if axis_side == "left"
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

            if ~isempty(obj.force_index) && ~contains(type, "UP") && ~isempty(force)
                if dual_plot && obj.should_split_load_cell_axis()
                    yyaxis(ax, 'right')
                    yyaxis(ax_target, 'right')
                end

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
            legend(ax, Location="best", Interpreter="latex");
            % for hidden figure for saving
            grid(ax_target, 'on');
            legend(ax_target, Location="best", Interpreter="latex");
            xlabel(ax, "Time over Wingbeat Period (t/T)", Interpreter="latex")
            xlabel(ax_target, "Time over Wingbeat Period (t/T)", Interpreter="latex")

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
                ylabel(ax, ylabs(1), Interpreter="latex")
                ax.YAxis(1).Color = 'k';
                yyaxis(ax, 'right')
                ylabel(ax, ylabs(2), Interpreter="latex")
                ax.YAxis(2).Color = 'k';

                % for hidden figure for saving
                yyaxis(ax_target, 'left')
                ylabel(ax_target, ylabs(1), Interpreter="latex")
                ax_target.YAxis(1).Color = 'k';
                yyaxis(ax_target, 'right')
                ylabel(ax_target, ylabs(2), Interpreter="latex")
                ax_target.YAxis(2).Color = 'k';
            elseif ~isempty(obj.inds)
                ylabel(ax, obj.get_single_axis_label(), Interpreter="latex")
                % for hidden figure for saving
                ylabel(ax_target, obj.get_single_axis_label(), Interpreter="latex")
            end
            
        ax.FontSize = 18;
        ax_target.FontSize = 18;
    end
end
end