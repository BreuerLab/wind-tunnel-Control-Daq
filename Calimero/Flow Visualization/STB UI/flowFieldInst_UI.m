classdef flowFieldInst_UI < handle
properties (Constant, Access = private)
    ACTIVE_COLOR = [0.3010 0.7450 0.9330];
    INACTIVE_COLOR = [1 1 1];
    TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
    TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
    MIRROR_CENTER_Y = -2.26;
    secondary_vars = ["Q_x","Q_y","Q_z","|Q|","div",...
        "KE", "power"];
    OLD_FLAPPER_SOURCE_MODE = "old flapper";
    NEW_FLAPPER_SOURCE_MODE = "new flapper";
    OLD_FLAPPER_DOWNSTREAM_TYPES = ["flexible";"UP_one_flexible";"UP_two_flexible"];
    OLD_FLAPPER_DISTANCE_LABELS = ["x = 0.9m";"x = 1.3m";"x = 1.7m"];
    NEW_FLAPPER_DOWNSTREAM_TYPES = ["x1";"x2";"x3";"x4";"x5"];
    NEW_FLAPPER_DISTANCE_LABELS = ["x1";"x2";"x3";"x4";"x5"];
end

properties
    % Display and dataset selection
    mon_num;
    phase_avg_file_path;
    source_mode;
    source_modes;
    case_name;
    case_name_list;
    phase_flapper_case_name_list;
    phase_old_flapper_case_name_list;
    phase_new_flapper_case_name_list;
    phase_avg_case_ids;
    current_downstream_type;
    downstream_types;
    distance_labels;
    downstream_type_by_distance;
    old_flapper_downstream_types;
    old_flapper_distance_labels;
    old_flapper_downstream_type_by_distance;
    new_flapper_downstream_types;
    new_flapper_distance_labels;
    new_flapper_downstream_type_by_distance;

    num_bins;
    bin_ind;
    bin_count;
    frame_ind;
    play;

    % Plot and variable selection
    plot_type;
    plot_types;
    variable_name;
    var_name_list;
    movie_3D_avg_vars;

    variable_name_dict;
    label_dict;

    % Color limits
    clims;
    clim_dict;
    mean_clims;

    % UI handles that callbacks need to update
    var_dropdown;
    slider_bin;
    slider_frame;
    
    % Plot settings
    mirror_bool;
    filter_bool;
    trim_bool;

    RPCA_sparse;

    % Data cache properties
    cached_bin_ind = -1;
    cached_case_id = "";
    cached_y;
    cached_z;
    cached_data;
    cached_L;
    cached_S;
    cached_plot_idx = "";
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = flowFieldInst_UI(mon_num, file_path)
        obj.mon_num = mon_num;
        obj.case_name = "";
        obj.variable_name = "";
        obj.phase_avg_file_path = file_path + "Processed Results\phase_avg\";

        obj.num_bins = 5;
        obj.bin_ind = 1;
        obj.bin_count = 5;
        obj.frame_ind = 1;

        obj.play = false;
        obj.RPCA_sparse = false;

        obj.plot_types = ["frames", "RPCA"];
        obj.plot_type = obj.plot_types(1);
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.trim_bool = true;

        phase_avg_files = dir(obj.phase_avg_file_path + "*.mat");

        phase_avg_stems = obj.get_file_stems(phase_avg_files, "_phase_avg");
        % remove ones that have RPCA in name
        phase_avg_stems = phase_avg_stems(~contains(phase_avg_stems, "RPCA"));
        obj.phase_avg_case_ids = phase_avg_stems;

        flapper_stems = phase_avg_stems(~contains(phase_avg_stems, "turbine"));

        old_flapper_stems = obj.get_old_flapper_stems(flapper_stems);
        new_flapper_stems = obj.get_new_flapper_stems(flapper_stems);

        [obj.old_flapper_downstream_types, obj.old_flapper_distance_labels] = ...
            obj.get_available_downstream_options(old_flapper_stems, obj.OLD_FLAPPER_SOURCE_MODE);
        obj.old_flapper_downstream_type_by_distance = ...
            obj.build_downstream_type_map(obj.old_flapper_distance_labels, obj.old_flapper_downstream_types);
        [obj.new_flapper_downstream_types, obj.new_flapper_distance_labels] = ...
            obj.get_available_downstream_options(new_flapper_stems, obj.NEW_FLAPPER_SOURCE_MODE);
        obj.new_flapper_downstream_type_by_distance = ...
            obj.build_downstream_type_map(obj.new_flapper_distance_labels, obj.new_flapper_downstream_types);

        obj.phase_old_flapper_case_name_list = obj.get_flapper_case_names(...
            old_flapper_stems, obj.old_flapper_downstream_types, ...
            obj.old_flapper_distance_labels, obj.OLD_FLAPPER_SOURCE_MODE);
        obj.phase_new_flapper_case_name_list = obj.get_flapper_case_names(...
            new_flapper_stems, obj.new_flapper_downstream_types, ...
            obj.new_flapper_distance_labels, obj.NEW_FLAPPER_SOURCE_MODE);
        obj.phase_flapper_case_name_list = unique([obj.phase_old_flapper_case_name_list, obj.phase_new_flapper_case_name_list], 'stable');
        obj.source_modes = obj.get_available_source_modes();
        if isempty(obj.source_modes)
            obj.source_mode = "";
        else
            obj.source_mode = obj.source_modes(1);
        end
        obj.set_downstream_options_for_source_mode(obj.source_mode);
        obj.case_name_list = obj.get_case_name_list_for_active_plot_type();

        obj.movie_3D_avg_vars = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|","helicity", "# particles",...
                    "du/dx","du/dy","du/dz","dv/dx","dv/dy","dv/dz","dw/dx","dw/dy","dw/dz",...
                    "div", "KE", "power"];
        movie_3D_avg_values = ["u","v","w","Utot",...
        "vortX","vortY","vortZ","vortTot",...
        "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg",...
        "uncTot_phase_avg","hel_phase_avg", "numP_phase_avg",...
        "dudx_phase_avg","dudy_phase_avg","dudz_phase_avg",...
        "dvdx_phase_avg","dvdy_phase_avg","dvdz_phase_avg",...
        "dwdx_phase_avg","dwdy_phase_avg","dwdz_phase_avg",...
        "div", "KE_diff_field", "power_field"];
        
        obj.var_name_list = obj.movie_3D_avg_vars;
        obj.mean_clims = [-1.1, -0.9;...
                     -0.2, 0.2;...
                      -0.2, 0.2;...
                      -1.1, -0.9;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      0, 2;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.03;...
                      0, 0.03;...
                      0, 0.03;...
                      0, 0.03;...
                      -1, 1;...
                      0, 75;
                      -0.1, 0.1;
                      -1, 1;
                      -1, 1;
                      -0.2, 0.2;
                      -1, 1;
                      -1, 1;
                      -0.2, 0.2;
                      -1, 1;
                      -1, 1;
                      -0.3, 0.3;
                      0, 0.1;
                      0, 0.1];

        obj.clims = obj.mean_clims;
        obj.clim_dict = obj.build_clim_dict(obj.movie_3D_avg_vars, obj.mean_clims);
        movie_3D_avg_labels = ["\boldmath$\frac{u c}{U_{\infty}}$",...
                            "\boldmath$\frac{v c}{U_{\infty}}$",...
                            "\boldmath$\frac{w c}{U_{\infty}}$",...
                            "\boldmath$\frac{U c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_x c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_y c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_z c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega c}{U_{\infty}}$",...
                            "","","","",...
                            "\boldmath$\frac{u c}{U_{\infty}}$",...
                            "\boldmath$\frac{v c}{U_{\infty}}$",...
                            "\boldmath$\frac{w c}{U_{\infty}}$",...
                            "\boldmath$\frac{U c}{U_{\infty}}$",...
                            "","count",...
                            "\boldmath$\frac{\partial u}{\partial x} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial u}{\partial y} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial u}{\partial z} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial v}{\partial x} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial v}{\partial y} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial v}{\partial z} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial w}{\partial x} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial w}{\partial y} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\frac{\partial w}{\partial z} \frac{c}{U_{\infty}}$",...
                            "\boldmath$\nabla \cdot u \frac{c}{U_{\infty}}$",...
                            "KE","power"];

        keys = cellstr(obj.movie_3D_avg_vars);
        values = movie_3D_avg_values;
        labels = movie_3D_avg_labels;
        obj.variable_name_dict = containers.Map(keys, values);
        obj.label_dict = containers.Map(keys, labels);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
        pause(1.8) % wait until GUI opened

        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);

        source_dropdown_y = screen_height*0.85 - 30;
        source_dropdown = uidropdown(option_panel);
        source_dropdown.Position = [10 source_dropdown_y 180 30];
        if isempty(obj.source_modes)
            source_dropdown.Items = "No flapper data";
            source_dropdown.Value = "No flapper data";
            source_dropdown.Enable = "off";
        else
            source_dropdown.Items = obj.source_modes;
            source_dropdown.Value = obj.source_mode;
        end
        source_dropdown.ValueChangedFcn = @(src, event) source_change(src, event, plot_panel);

        % Dropdown box for which cases axes to display
        distance_dropdown_y = source_dropdown_y - 35;
        distance_dropdown = uidropdown(option_panel);
        distance_dropdown.Position = [10 distance_dropdown_y 180 30];
        distance_dropdown.ValueChangedFcn = @(src, event) distance_change(src, event, plot_panel);
        refresh_distance_dropdown();

        case_dropdown_y = distance_dropdown_y - 35;
        case_dropdown = uidropdown(option_panel);
        case_dropdown.Position = [10 case_dropdown_y 180 30];
        case_dropdown.Items = obj.case_name_list;
        obj.case_name = string(case_dropdown.Value); % use current value in box
        case_dropdown.ValueChangedFcn = @(src, event) case_change(src, event, plot_panel);

        plot_type_dropdown_y = case_dropdown_y - 35;
        plot_type_dropdown = uidropdown(option_panel);
        plot_type_dropdown.Position = [10 plot_type_dropdown_y 180 30];
        plot_type_dropdown.Items = obj.get_available_plot_types_for_current_case();
        obj.plot_type = plot_type_dropdown.Value; % use current value in box
        plot_type_dropdown.ValueChangedFcn = @(src, event) type_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        variable_dropdown_y = plot_type_dropdown_y - 35;
        obj.var_dropdown = uidropdown(option_panel);
        obj.var_dropdown.Position = [10 variable_dropdown_y 180 30];
        obj.var_dropdown.Items = obj.var_name_list;
        obj.variable_name = obj.var_dropdown.Value; % use current value in box
        obj.var_dropdown.ValueChangedFcn = @(src, event) variable_change(src, event, plot_panel);

        trim_button_y = variable_dropdown_y - 70;
        trim_button = uibutton(option_panel,"state");
        trim_button.Value = true;
        trim_button.Text = "Trim";
        trim_button.FontSize = 18;
        trim_button.Position = [30 trim_button_y 120 unit_height];
        trim_button.BackgroundColor = obj.ACTIVE_COLOR;
        trim_button.ValueChangedFcn = @(src, event) trim_change(src, event, plot_panel);

        mirror_button_y = trim_button_y - 40;
        mirror_button = uibutton(option_panel,"state");
        mirror_button.Text = "Mirror";
        mirror_button.FontSize = 18;
        mirror_button.Position = [30 mirror_button_y 120 unit_height];
        mirror_button.BackgroundColor = obj.INACTIVE_COLOR;
        mirror_button.ValueChangedFcn = @(src, event) mirror_change(src, event, plot_panel);

        filter_button_y = mirror_button_y - 35;
        filter_button = uibutton(option_panel,"state");
        filter_button.Text = "Filter";
        filter_button.FontSize = 18;
        filter_button.Position = [30 filter_button_y 120 unit_height];
        filter_button.BackgroundColor = obj.INACTIVE_COLOR;
        filter_button.ValueChangedFcn = @(src, event) filter_change(src, event, plot_panel);

        panel_width = plot_panel.Position(3);
        frame_slider_width = panel_width * (3/4);
        frame_slider_x = (panel_width - frame_slider_width)/2; % end of right monitor around 1690
        frame_slider_y = 0.05*screen_height;
        obj.slider_bin = uislider(plot_panel);
        obj.slider_bin.Position = [frame_slider_x frame_slider_y frame_slider_width 3];
        obj.slider_bin.Limits = [1 obj.num_bins];
        obj.slider_bin.Value = obj.bin_ind;
        obj.slider_bin.MajorTicks = 1:5:obj.num_bins;
        obj.slider_bin.MinorTicks = 1:obj.num_bins;
        obj.slider_bin.ValueChangedFcn = @(src, event) bin_change(src, event, plot_panel);

        panel_width = option_panel.Position(3);
        frame_slider_width = panel_width * (3/4);
        frame_slider_x = (panel_width - frame_slider_width)/2; % end of right monitor around 1690
        frame_slider_y = filter_button_y - 35;
        obj.slider_frame = uislider(option_panel);
        obj.slider_frame.Position = [frame_slider_x frame_slider_y frame_slider_width 3];
        obj.slider_frame.Limits = [1 obj.bin_count];
        obj.slider_frame.Value = obj.frame_ind;
        obj.slider_frame.MajorTicks = 1:5:obj.bin_count;
        obj.slider_frame.MinorTicks = 1:obj.bin_count;
        obj.slider_frame.ValueChangedFcn = @(src, event) frame_change(src, event, plot_panel);

        play_button_y = frame_slider_y - 60;
        play_button = uibutton(option_panel,"state");
        play_button.Text = "Play";
        play_button.FontSize = 18;
        play_button.Position = [30 play_button_y 120 unit_height];
        play_button.BackgroundColor = obj.INACTIVE_COLOR;
        play_button.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_panel);

        RPCA_button_y = play_button_y - 35;
        RPCA_button = uibutton(option_panel,"state");
        RPCA_button.Text = "Sparse Matrix";
        RPCA_button.FontSize = 18;
        RPCA_button.Position = [30 RPCA_button_y 120 unit_height];
        RPCA_button.BackgroundColor = obj.INACTIVE_COLOR;
        RPCA_button.ValueChangedFcn = @(src, event) RPCA_change(src, event, plot_panel);

        save_button_y = 0.05*screen_height;
        save_button = uibutton(option_panel,"state");
        save_button.Text = "Save Figure";
        save_button.FontSize = 18;
        save_button.Position = [30 save_button_y 120 unit_height];
        save_button.BackgroundColor = obj.INACTIVE_COLOR;
        save_button.ValueChangedFcn = @(src, event) save_figure(src, event, plot_panel);

        % Set up plot titles and axes
        obj.update_plot(plot_panel);

        % Callbacks are nested so each handler mutates this handle object.

        function source_change(src, ~, plot_panel)
            obj.source_mode = src.Value;
            refresh_distance_dropdown();
            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown();

            % Force frame and bin sliders back to 1 since not all datasets
            % have the same number of frames.
            obj.bin_ind = 1;
            obj.frame_ind = 1;
            obj.slider_bin.Value = obj.bin_ind;
            obj.slider_frame.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        function distance_change(src, ~, plot_panel)
            obj.current_downstream_type = string(obj.downstream_type_by_distance(char(src.Value)));
            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown();

            % Force frame slider back to 1 since not all datasets have the
            % same number of frames
            obj.bin_ind = 1;
            obj.slider_bin.Value = obj.bin_ind;

            obj.update_plot(plot_panel);
        end

        function case_change(src, ~, plot_panel)
            obj.case_name = string(src.Value);
            refresh_plot_type_dropdown();
            refresh_variable_dropdown();

            % Force frame slider back to 1 since not all datasets have the
            % same number of frames
            obj.bin_ind = 1;
            obj.slider_bin.Value = obj.bin_ind;

            obj.update_plot(plot_panel);
        end

        % User selected a new plot type.
        function type_change(src, ~, plot_panel)
            obj.plot_type = src.Value;

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown();

            obj.update_plot(plot_panel);
        end

        % User selected a new variable to plot.
        function variable_change(src, ~, plot_panel)
            obj.variable_name = src.Value;
            obj.update_plot(plot_panel);
        end

        function refresh_distance_dropdown()
            obj.set_downstream_options_for_source_mode(obj.source_mode);
            if isempty(obj.distance_labels)
                distance_dropdown.Items = "No downstream data";
                distance_dropdown.Value = "No downstream data";
                distance_dropdown.Visible = "off";
                distance_dropdown.Enable = "off";
            else
                distance_dropdown.Items = obj.distance_labels;
                distance_dropdown.Value = obj.distance_labels(1);
                distance_dropdown.Visible = "on";
                distance_dropdown.Enable = "on";
                obj.current_downstream_type = string(obj.downstream_type_by_distance(char(distance_dropdown.Value)));
            end
        end

        function refresh_case_dropdown()
            obj.case_name_list = obj.get_case_name_list_for_active_plot_type();
            if isempty(obj.case_name_list) && obj.plot_type ~= obj.plot_types(1)
                obj.plot_type = obj.plot_types(1);
                obj.case_name_list = obj.get_case_name_list_for_active_plot_type();
            end

            case_dropdown.Items = obj.case_name_list;
            if ~any(obj.case_name_list == obj.case_name)
                obj.case_name = string(case_dropdown.Value);
            else
                case_dropdown.Value = obj.case_name;
            end
        end

        function refresh_plot_type_dropdown()
            available_plot_types = obj.get_available_plot_types_for_current_case();
            plot_type_dropdown.Items = available_plot_types;
            if ~any(available_plot_types == obj.plot_type)
                obj.plot_type = available_plot_types(1);
            end
            plot_type_dropdown.Value = obj.plot_type;
        end

        function refresh_variable_dropdown()
            obj.var_name_list = obj.movie_3D_avg_vars;
            obj.var_dropdown.Items = obj.var_name_list;
            if ~any(obj.var_name_list == obj.variable_name)
                obj.variable_name = obj.var_dropdown.Value;
            else
                obj.var_dropdown.Value = obj.variable_name;
            end
        end

        % User toggled trimming to the wake region.
        function trim_change(src, ~, plot_panel)
            if (src.Value)
                obj.trim_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.trim_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function mirror_change(src, ~, plot_panel)
            if (src.Value)
                obj.mirror_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.mirror_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function filter_change(src, ~, plot_panel)
            if (src.Value)
                obj.filter_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.filter_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function bin_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.bin_ind = src.Value;
            obj.update_plot(plot_panel);
        end

        function frame_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.frame_ind = src.Value;
            obj.update_plot(plot_panel);
        end

        % User toggled movie playback.
        function playStop_change(src, ~, plot_panel)
            if (src.Value)
                obj.play = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
                src.Text = "Stop";
            else
                obj.play = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
                src.Text = "Play";
            end

            obj.update_plot(plot_panel);
        end

        function RPCA_change(src, ~, plot_panel)
            if (src.Value)
                obj.RPCA_sparse = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.RPCA_sparse = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            % reset frame index
            obj.frame_ind = 1;
            obj.update_plot(plot_panel);
        end

        function save_figure(~, ~, plot_panel)
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            cb = findobj(plot_panel.Children, 'Type', 'colorbar');

            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            copyobj([ax cb], fignew);
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

    end
end

methods (Access = private)
    function file_stems = get_file_stems(~, files, suffix)
        file_names = string({files.name});
        avg_files = endsWith(file_names, suffix + ".mat");
        file_stems = erase(file_names(avg_files), suffix + ".mat");
    end

    function old_flapper_stems = get_old_flapper_stems(obj, flapper_stems)
        flapper_stems = string(flapper_stems);
        old_flapper_stems = flapper_stems(~obj.is_new_flapper_stem(flapper_stems));
    end

    function new_flapper_stems = get_new_flapper_stems(obj, flapper_stems)
        flapper_stems = string(flapper_stems);
        new_flapper_stems = flapper_stems(obj.is_new_flapper_stem(flapper_stems));
    end

    function mask = is_new_flapper_stem(obj, stems)
        stems = string(stems);
        mask = false(size(stems));
        for i = 1:length(obj.NEW_FLAPPER_DOWNSTREAM_TYPES)
            downstream_type = obj.NEW_FLAPPER_DOWNSTREAM_TYPES(i);
            mask = mask | stems == downstream_type | startsWith(stems, downstream_type + "_");
        end
    end

    function set_downstream_options_for_source_mode(obj, source_mode)
        [obj.downstream_types, obj.distance_labels, obj.downstream_type_by_distance] = ...
            obj.get_downstream_options_for_source_mode(source_mode);
        if isempty(obj.downstream_types)
            obj.current_downstream_type = "";
        else
            obj.current_downstream_type = obj.downstream_types(1);
        end
    end

    function [downstream_types, distance_labels, downstream_type_by_distance] = get_downstream_options_for_source_mode(obj, source_mode)
        if source_mode == obj.OLD_FLAPPER_SOURCE_MODE
            downstream_types = obj.old_flapper_downstream_types;
            distance_labels = obj.old_flapper_distance_labels;
            downstream_type_by_distance = obj.old_flapper_downstream_type_by_distance;
        elseif source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            downstream_types = obj.new_flapper_downstream_types;
            distance_labels = obj.new_flapper_distance_labels;
            downstream_type_by_distance = obj.new_flapper_downstream_type_by_distance;
        else
            downstream_types = strings(0, 1);
            distance_labels = strings(0, 1);
            downstream_type_by_distance = obj.build_downstream_type_map(distance_labels, downstream_types);
        end
    end

    function downstream_type_by_distance = build_downstream_type_map(~, distance_labels, downstream_types)
        if isempty(distance_labels)
            downstream_type_by_distance = containers.Map('KeyType', 'char', 'ValueType', 'char');
        else
            downstream_type_by_distance = containers.Map(cellstr(distance_labels), cellstr(downstream_types));
        end
    end

    function [downstream_types, distance_labels] = get_available_downstream_options(obj, flapper_stems, source_mode)
        downstream_types = strings(0, 1);
        distance_labels = strings(0, 1);

        [known_downstream_types, known_distance_labels] = obj.get_known_downstream_options(source_mode);
        for i = 1:length(known_downstream_types)
            downstream_type = known_downstream_types(i);
            matching_stems = obj.get_downstream_stems_for_type(flapper_stems, downstream_type, source_mode);
            if ~isempty(matching_stems)
                downstream_types(end + 1, 1) = downstream_type;
                distance_labels(end + 1, 1) = known_distance_labels(i);
            end
        end
    end

    function [downstream_types, distance_labels] = get_known_downstream_options(obj, source_mode)
        if source_mode == obj.OLD_FLAPPER_SOURCE_MODE
            downstream_types = obj.OLD_FLAPPER_DOWNSTREAM_TYPES;
            distance_labels = obj.OLD_FLAPPER_DISTANCE_LABELS;
        elseif source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            downstream_types = obj.NEW_FLAPPER_DOWNSTREAM_TYPES;
            distance_labels = obj.NEW_FLAPPER_DISTANCE_LABELS;
        else
            downstream_types = strings(0, 1);
            distance_labels = strings(0, 1);
        end
    end

    function matching_stems = get_downstream_stems_for_type(obj, flapper_stems, downstream_type, source_mode)
        flapper_stems = string(flapper_stems);
        prefix = downstream_type + "_";
        mask = flapper_stems == downstream_type | startsWith(flapper_stems, prefix);

        if source_mode == obj.OLD_FLAPPER_SOURCE_MODE && downstream_type == obj.OLD_FLAPPER_DOWNSTREAM_TYPES(1)
            mask = mask | obj.is_legacy_default_distance_stem(flapper_stems);
        end

        matching_stems = flapper_stems(mask);
    end

    function mask = is_legacy_default_distance_stem(obj, stems)
        stems = string(stems);
        mask = ~obj.starts_with_any_downstream_type(stems, obj.OLD_FLAPPER_DOWNSTREAM_TYPES) & ...
               ~obj.is_new_flapper_stem(stems);
    end

    function mask = starts_with_any_downstream_type(~, stems, downstream_types)
        stems = string(stems);
        mask = false(size(stems));
        for i = 1:length(downstream_types)
            downstream_type = downstream_types(i);
            mask = mask | stems == downstream_type | startsWith(stems, downstream_type + "_");
        end
    end

    function source_modes = get_available_source_modes(obj)
        source_modes = strings(0);

        if ~isempty(obj.phase_old_flapper_case_name_list)
            source_modes(end + 1) = obj.OLD_FLAPPER_SOURCE_MODE;
        end

        if ~isempty(obj.phase_new_flapper_case_name_list)
            source_modes(end + 1) = obj.NEW_FLAPPER_SOURCE_MODE;
        end
    end

    function case_names = get_case_name_list_for_active_plot_type(obj)
        case_names = obj.get_case_name_list(obj.source_mode);
    end

    function case_names = get_case_name_list(obj, source_mode)
        if source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            case_names = obj.phase_new_flapper_case_name_list;
        else
            case_names = obj.phase_old_flapper_case_name_list;
        end
    end

    function case_names = get_flapper_case_names(obj, phase_avg_stems, downstream_types, distance_labels, source_mode)
        case_names = strings(0);

        for i = 1:length(downstream_types)
            downstream_type = downstream_types(i);
            prefix = downstream_type + "_";
            matching_stems = phase_avg_stems(phase_avg_stems == downstream_type | startsWith(phase_avg_stems, prefix));
            if source_mode == obj.OLD_FLAPPER_SOURCE_MODE && ...
                    i <= length(distance_labels) && distance_labels(i) == obj.OLD_FLAPPER_DISTANCE_LABELS(1)
                matching_stems = unique([matching_stems, phase_avg_stems(obj.is_legacy_default_distance_stem(phase_avg_stems))], 'stable');
            end
            case_names = [case_names, obj.get_case_names_from_stems(matching_stems, downstream_type)];
        end
        case_names = unique(case_names, 'stable');
    end

    function case_names = get_case_names_from_stems(~, stems, downstream_type)
        case_names = strings(size(stems));
        prefix = downstream_type + "_";

        for i = 1:length(stems)
            if stems(i) == downstream_type || ~startsWith(stems(i), prefix)
                case_names(i) = stems(i);
            else
                case_names(i) = extractAfter(stems(i), prefix);
            end
        end
    end

    function case_id = get_current_case_id(obj)
        case_name = string(obj.case_name);
        current_downstream_type = string(obj.current_downstream_type);

        if current_downstream_type == case_name && ...
                any(obj.phase_avg_case_ids == case_name)
            case_id = case_name;
        elseif strlength(case_name) == 0
            case_id = current_downstream_type;
        else
            case_id = current_downstream_type + "_" + case_name;
        end
    end

    function plot_types = get_available_plot_types_for_current_case(obj)
            plot_types = obj.plot_types;
    end

    % Update the active plot after a selection or display setting changes.
    function update_plot(obj, plot_panel)
        ax = findobj(plot_panel.Children, 'Type', 'axes');
        delete(ax);

        plot_idx = find(obj.plot_types == obj.plot_type);

        var_name = obj.variable_name_dict(obj.variable_name);

        var_clims = obj.get_color_limits(obj.variable_name);

        if strlength(obj.case_name) == 0
            return
        end

        RPCA_bool = false;
        U = 4;
        L = 0.07; % guess of mean aerodynamic chord

        PIV_case_name = obj.get_current_case_id();
        fields = get_STB_processing_fields();

        % Check if the bin_ind or case has changed since the last plot
        if obj.bin_ind ~= obj.cached_bin_ind || PIV_case_name ~= obj.cached_case_id || plot_idx ~= obj.cached_plot_idx

        file_path = get_PIV_paths(PIV_case_name);

        % Define the field names in the order they are returned by the function
        fNames = {'freq_avg', 'norm_time_speed', 'phase_avg_pos', 'phase_std_pos', ...
                  'phase_avg_speed', 'phase_std_speed',...
                  'phase_avg_acc', 'phase_std_acc',...
                  'phase_avg_wing_pos', 'phase_std_wing_pos',...
                  'phase_avg_wing_speed', 'phase_std_wing_speed',...
                  'phase_avg_wing_acc', 'phase_std_wing_acc',...
                  'bin_count_speed', 'bin_std_speed',...
                  'phase_avg_volt', 'phase_std_volt',...
                  'phase_avg_cur', 'phase_std_cur'};

        % Capture all outputs into a cell array
        outputs = cell(1, numel(fNames));
        [outputs{:}] = speed_phase_avg(PIV_case_name, false);
        
        % Map cell array to struct fields
        for i = 1:numel(fNames)
            D.(fNames{i}) = outputs{i};
        end

        num_images = 2500;
        disp("Assuming num images = " + num_images)
        % get bin number associated with each frame from DAQ measurements
        [norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq, num_clusters, phase_spread_ratio]...
            = frame_to_bin(PIV_case_name, num_images, D.freq_avg, false, false);
        
        bin_indices = find(bin_ind_arr == obj.bin_ind);
        [B, I] = sort(tick_frame_pos(bin_indices));
        bin_indices_sorted = bin_indices(I);
        bin_count = length(bin_indices);
        bin_std = std(norm_frame_pos(bin_indices))*100;
    
        % Import data (since bin_ind or case changed)
        [x, y, z, data{1:length(fields)}] = ...
            import_STB_data(file_path, true, U, L, bin_indices_sorted, RPCA_bool);

        if plot_idx == 2
        [L, S] = RPCA_vel(x,y,z,data{strcmp(fields, 'u')},...
                data{strcmp(fields, 'v')},data{strcmp(fields, 'w')});
        end
        
        obj.slider_bin.Visible = "on";
        % Adjust slider for number of bins
        if num_bins ~= obj.num_bins
            obj.num_bins = num_bins;
            obj.slider_bin.Limits = [1 obj.num_bins];
            obj.slider_bin.MajorTicks = 1:5:obj.num_bins;
            obj.slider_bin.MinorTicks = 1:obj.num_bins;
        end
        if bin_count ~= obj.bin_count
            obj.bin_count = bin_count;
            obj.slider_frame.Limits = [1 obj.bin_count];
            obj.slider_frame.MajorTicks = 1:5:obj.bin_count;
            obj.slider_frame.MinorTicks = 1:obj.bin_count;
        end

        % Update cache
        obj.cached_bin_ind = obj.bin_ind;
        obj.cached_case_id = PIV_case_name;
        obj.cached_plot_idx = plot_idx;
        obj.cached_y = y;
        obj.cached_z = z;
        obj.cached_data = data;
        if plot_idx == 2
        obj.cached_L = L;
        obj.cached_S = S;
        end
        else
        % Load from cache
        y = obj.cached_y;
        z = obj.cached_z;
        data = obj.cached_data;
        if plot_idx == 2
        L = obj.cached_L;
        S = obj.cached_S;
        end
        end
        
        if plot_idx == 1
            x_idx = 3;
            % Extract the desired variable
            val = data{strcmp(fields, var_name)};
        else
            x_idx = 2;
            if obj.RPCA_sparse
            val = S{strcmp(fields, var_name)};
            else
            val = L{strcmp(fields, var_name)};
            end
        end

        % Select a single plane and a single frame
        y_tr = squeeze(y(x_idx,:,:));
        z_tr = squeeze(z(x_idx,:,:));
        val_tr = squeeze(val(x_idx,:,:,:));

        params.U = U;

        if obj.trim_bool
            y_idx = find(y_tr(:,1) > obj.TRIM_Y_BOUNDS(1) & y_tr(:,1) < obj.TRIM_Y_BOUNDS(2));
            z_idx = find(z_tr(1,:) > obj.TRIM_Z_BOUNDS(1) & z_tr(1,:) < obj.TRIM_Z_BOUNDS(2));

            y_tr = y_tr(y_idx, z_idx);
            z_tr = z_tr(y_idx, z_idx);

            val_tr = val_tr(y_idx,z_idx,:);
            
        end
        if obj.mirror_bool
            % Mirror across the centerline to reconstruct the opposite side of the wake.
            y_idx_m = find(y(:,1) > obj.MIRROR_CENTER_Y);

            y = y(y_idx_m, :);
            z = z(y_idx_m, :);

            val = val(y_idx_m,:,:);

            % Shift so the mirror center is the origin.
            y = y - min(y, [], "all");

            % Reflect and skip the first row to avoid double-counting the centerline.
            y_add = flip(-y(2:end,:),1);
            z_add = flip(z(2:end,:),1);

            val_add = flip(val(2:end,:,:),1);

            y = [y_add; y];
            z = [z_add; z];
            val = [val_add; val];
        end

        if obj.filter_bool
            val = medfilt3(val);
        end

        % sparse matrix values are much smaller
        if obj.RPCA_sparse
        var_clims = [min(val_tr,[],"all") max(val_tr,[],"all")];
        end

        if min(var_clims) < -1
            params.zero = -1;
        elseif min(var_clims) < 0.5
            params.zero = 0;
        else
            params.zero = 1;
        end
        
        ax = axes(plot_panel);
        params.cb_lab = obj.label_dict(obj.variable_name);
        params.clims = var_clims;

        val_tr_fr = squeeze(val_tr(:,:,obj.frame_ind));
        h = PIV_plot(y_tr, z_tr, val_tr_fr, params, ax);
        t = title(ax, "Bin number: " + obj.bin_ind + ", frame number: " + obj.frame_ind, FontSize=18);

        while obj.play && (obj.frame_ind < obj.bin_count)
            obj.frame_ind = obj.frame_ind + 1;
            obj.slider_frame.Value = obj.frame_ind;

            % Cap the data so it stays within the current color limits.
            tmp_data = val_tr(:,:,obj.frame_ind);
            tmp_data(tmp_data < params.clims(1)) = params.clims(1);
            tmp_data(tmp_data > params.clims(2)) = params.clims(2);
    
            % Update the existing contour instead of recreating axes.
            set(h, 'ZData', tmp_data); 
            set(t, 'String', "Bin number: " + obj.bin_ind + ", frame number: " + obj.frame_ind);
    
            drawnow;

            pause(0.1);

            if obj.frame_ind == obj.bin_count
            obj.frame_ind = 0; % reset for next loop iteration
            end
        end
    end

    function clim_dict = build_clim_dict(~, var_names, clim_values)
        keys = cellstr(var_names);
        values = mat2cell(clim_values, ones(1, size(clim_values, 1)), size(clim_values, 2));
        clim_dict = containers.Map(keys, values);
    end

    function clims = get_color_limits(obj, var_name)
        key = char(var_name);
        if isKey(obj.clim_dict, key)
            clims = obj.clim_dict(key);
            return
        end

        var_idx = find(string(var_name) == obj.var_name_list, 1);
        if isempty(var_idx)
            error("No color limits defined for " + string(var_name))
        end
        clims = obj.clims(var_idx,:);
    end
end

end