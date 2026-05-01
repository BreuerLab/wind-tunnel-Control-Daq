classdef STB_UI < handle
properties (Constant, Access = private)
    ACTIVE_COLOR = [0.3010 0.7450 0.9330];
    INACTIVE_COLOR = [1 1 1];
    TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
    TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
    MIRROR_CENTER_Y = -2.26;
end

properties
    % Display and dataset selection
    mon_num;
    file_path;
    file_suffix;
    case_name;
    case_name_list;
    current_downstream_type;
    downstream_types;
    distance_labels;
    downstream_type_by_distance;

    num_bins;
    frame_ind;
    play;

    % Plot and variable selection
    plot_type;
    plot_types;
    variable_name;
    var_name_list;
    movie_3D_avg_vars;
    movie_3D_std_vars;
    hist_vars;
    freq_vars;
    force_vars;

    variable_name_dict;
    label_dict;

    std_var_name_dict;
    std_label_dict;

    hist_var_name_dict;
    hist_label_dict;

    freq_var_name_dict;
    freq_label_dict;

    force_var_name_dict;
    force_label_dict;

    % Color limits for each variable list
    clims;
    mean_clims;
    std_clims;
    clim_scale;

    % UI handles that callbacks need to update
    param_panel;
    var_dropdown;
    clim_slider;
    slider;
    play_button;
    iso_slider;
    
    % 3D plot settings
    plot_hold_bool;
    iso_val;
    iso_var;
    iso_var_list;
    mirror_bool;
    filter_bool;
    trim_bool;
    num_cycles;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = STB_UI(mon_num, file_path)
        obj.mon_num = mon_num;
        obj.case_name = "";
        obj.variable_name = "";
        obj.file_path = file_path;

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;

        obj.plot_types = ["time avg","phase avg: movie", "phase std: movie", "phase avg: 3D plot",...
            "image wingbeat phase", "wingbeat frequency","wake forces","phase avg: planar avg"];
        obj.plot_hold_bool = false;
        obj.iso_var_list = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                            "Q_x","Q_y","Q_z","|Q|", "helicity"];
        obj.iso_var = "|Q|";
        obj.iso_val = 0.05;
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.num_cycles = 1;
        obj.trim_bool = true;

        files = dir(obj.file_path + "*.mat");

        obj.file_suffix = "_phase_avg.mat";

        % Convert file names to a string array
        fileNames = string({files.name});
        
        % Create a logical mask: true where the suffix exists
        hasSuffix = contains(fileNames, obj.file_suffix);
        
        % Only apply extractBefore to the matching files
        fileNames(hasSuffix) = extractBefore(fileNames(hasSuffix), obj.file_suffix);

        available_selections = get_sel_from_file(files);

        obj.downstream_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
        if ~isequal(sort(obj.downstream_types), sort(unique(string(available_selections(:, 1)))))
            error("Downstream type mismatch. Check types...")
        end
        
        obj.current_downstream_type = obj.downstream_types(1);
        obj.distance_labels = ["x = 0.9m","x = 1.3m","x = 1.7m"];

        obj.downstream_type_by_distance = containers.Map(obj.distance_labels, obj.downstream_types);

        cleaned_case_names = extractAfter(erase(fileNames, obj.downstream_types), "_");
        obj.case_name_list = unique(cleaned_case_names);

        obj.movie_3D_avg_vars = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|","helicity", "# particles"];
        movie_3D_avg_values = ["u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
        "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg",...
        "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg","uncTot_phase_avg","hel_phase_avg", "numP_phase_avg"];
        
        obj.movie_3D_std_vars = [obj.movie_3D_avg_vars(1:8) obj.movie_3D_avg_vars(13:end)];
        movie_3D_std_values = ["u_phase_std","v_phase_std","w_phase_std","Utot_phase_std",...
        "vortX_phase_std","vortY_phase_std","vortZ_phase_std","vortTot_phase_std",...
        "uncU_phase_std","uncV_phase_std","uncW_phase_std","uncTot_phase_std","hel_phase_std", "numP_phase_std"];

        obj.hist_vars = ["bin counts","bin SD","distribution"];
        hist_vals = ["bin_count", "bin_std","tick_frame_pos"];
        hist_labels = ["Number of frames per bin", "Phase variability per bin (% cycle)","Number of frames per tick"];

        obj.freq_vars = ["frequency","bin counts", "bin SD"];
        freq_vals = ["phase_avg_speed", "bin_count_speed", "bin_std_speed"];
        freq_labels = ["Wingbeat Frequency (Hz)", "Number of samples per bin", "Phase variability per bin (% cycle)"];

        obj.force_vars = ["lift_vort", "lift_vel", "drag_vort", "drag_vel"];
        force_vals = ["lift", "lift_vel", "drag", "drag_vel"];
        force_labels = ["Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)"];

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
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      -1, 1;...
                      0, 50];

        % for std plots
        obj.std_clims = [0, 0.1;...
                     0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 1;...
                      0, 1;...
                      0, 1;...
                      0, 1;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      -1, 1];

        obj.clims = obj.mean_clims;
        obj.clim_scale = 2;
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
                            "","count"];
        movie_3D_std_labels = [movie_3D_avg_labels(1:8) movie_3D_avg_labels(13:end)];

        keys = cellstr([obj.movie_3D_avg_vars obj.hist_vars]);
        values = [movie_3D_avg_values hist_vals];
        labels = [movie_3D_avg_labels hist_labels];
        obj.variable_name_dict = containers.Map(keys, values);
        obj.label_dict = containers.Map(keys, labels);

        std_keys = cellstr(obj.movie_3D_std_vars);
        obj.std_var_name_dict = containers.Map(std_keys, movie_3D_std_values);
        obj.std_label_dict = containers.Map(std_keys, movie_3D_std_labels);

        hist_keys = cellstr(obj.hist_vars);
        obj.hist_var_name_dict = containers.Map(hist_keys, hist_vals);
        obj.hist_label_dict = containers.Map(hist_keys, hist_labels);

        freq_keys = cellstr(obj.freq_vars);
        obj.freq_var_name_dict = containers.Map(freq_keys, freq_vals);
        obj.freq_label_dict = containers.Map(freq_keys, freq_labels);

        force_keys = cellstr(obj.force_vars);
        obj.force_var_name_dict = containers.Map(force_keys, force_vals);
        obj.force_label_dict = containers.Map(force_keys, force_labels);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
        pause(1.8) % wait until GUI opened

        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);

        % Dropdown box for which cases axes to display
        distance_dropdown_y = screen_height*0.85 - 30;
        distance_dropdown = uidropdown(option_panel);
        distance_dropdown.Position = [10 distance_dropdown_y 180 30];
        distance_dropdown.Items = obj.distance_labels;
        distance_dropdown.ValueChangedFcn = @(src, event) distance_change(src, event, plot_panel);

        case_dropdown_y = distance_dropdown_y - 35;
        case_dropdown = uidropdown(option_panel);
        case_dropdown.Position = [10 case_dropdown_y 180 30];
        case_dropdown.Items = obj.case_name_list;
        obj.case_name = case_dropdown.Value; % use current value in box
        case_dropdown.ValueChangedFcn = @(src, event) case_change(src, event, plot_panel);

        plot_type_dropdown_y = case_dropdown_y - 35;
        plot_type_dropdown = uidropdown(option_panel);
        plot_type_dropdown.Position = [10 plot_type_dropdown_y 180 30];
        plot_type_dropdown.Items = obj.plot_types;
        obj.plot_type = plot_type_dropdown.Value; % use current value in box
        plot_type_dropdown.ValueChangedFcn = @(src, event) type_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        variable_dropdown_y = plot_type_dropdown_y - 35;
        obj.var_dropdown = uidropdown(option_panel);
        obj.var_dropdown.Position = [10 variable_dropdown_y 180 30];
        obj.var_dropdown.Items = obj.var_name_list;
        obj.variable_name = obj.var_dropdown.Value; % use current value in box
        obj.var_dropdown.ValueChangedFcn = @(src, event) variable_change(src, event, plot_panel);

        clim_y = variable_dropdown_y - 35;
        obj.clim_slider = uislider(option_panel,"range");
        obj.clim_slider.Position = [10 clim_y 180 3];
        clim_center = mean(obj.clims(1,:));
        clim_range = (obj.clim_scale/2)*diff(obj.clims(1,:));
        obj.clim_slider.Limits = [clim_center - clim_range, clim_center + clim_range];
        obj.clim_slider.Value = obj.clims(1,:);
        obj.clim_slider.ValueChangedFcn = @(src, event) clim_change(src, event, plot_panel);

        trim_button_y = clim_y - 70;
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
        obj.slider = uislider(plot_panel);
        obj.slider.Position = [frame_slider_x frame_slider_y frame_slider_width 3];
        obj.slider.Limits = [1 obj.num_bins];
        obj.slider.Value = obj.frame_ind;
        obj.slider.MajorTicks = 1:5:obj.num_bins;
        obj.slider.MinorTicks = 1:obj.num_bins;
        obj.slider.ValueChangedFcn = @(src, event) frame_change(src, event, plot_panel);

        play_button_y = frame_slider_y + 50;
        obj.play_button = uibutton(plot_panel,"state");
        obj.play_button.Text = "Play";
        obj.play_button.FontSize = 18;
        obj.play_button.Position = [30 play_button_y 120 unit_height];
        obj.play_button.BackgroundColor = obj.INACTIVE_COLOR;
        obj.play_button.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_panel);

        param_panel_height = 380;
        param_panel_width = 180;
        param_panel_y = trim_button_y - 150 - param_panel_height;
        obj.param_panel = uipanel(option_panel);
        obj.param_panel.Visible = "off";
        obj.param_panel.Title = "3D Plot Parameters";
        obj.param_panel.TitlePosition = 'centertop';
        obj.param_panel.Position = [10 param_panel_y param_panel_width param_panel_height];

        l1_y = param_panel_height - 50;
        l1_x = 55;
        l1_w = 70;
        l1 = uilabel(obj.param_panel);
        l1.HorizontalAlignment = 'center';
        l1.Position = [l1_x l1_y l1_w unit_height];
        l1.Text = 'Q isovalue:';

        iso_slider_y = l1_y - 5;
        iso_slider_w = param_panel_width - 2*10;
        obj.iso_slider = uislider(obj.param_panel);
        obj.iso_slider.Position = [5 iso_slider_y iso_slider_w 3];
        obj.iso_slider.Limits = [0.005 0.1];
        obj.iso_slider.Value = obj.iso_val;
        obj.iso_slider.MajorTicks = 0:0.025:0.1; % 0:0.05:0.5
        obj.iso_slider.MinorTicks = 0.005:0.005:0.1; % 0.01:0.01:0.5
        obj.iso_slider.ValueChangedFcn = @(src, event) iso_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        iso_var_dropdown_y = iso_slider_y - 70;
        iso_var_dropdown = uidropdown(obj.param_panel);
        iso_var_dropdown.Position = [30 iso_var_dropdown_y 120 30];
        iso_var_dropdown.Items = obj.iso_var_list;
        iso_var_dropdown.Value = obj.iso_var;
        iso_var_dropdown.ValueChangedFcn = @(src, event) iso_var_change(src, event, plot_panel);

        l2_y = iso_var_dropdown_y - 35;
        l2 = uilabel(obj.param_panel);
        l2.HorizontalAlignment = 'center';
        l2.Position = [30 l2_y 120 unit_height];
        l2.Text = 'Number of Wingbeats';

        num_cycles_slider_y = l2_y - 10;
        num_cycles_slider = uislider(obj.param_panel);
        num_cycles_slider.Position = [30 num_cycles_slider_y 120 3];
        num_cycles_slider.Limits = [1 5];
        num_cycles_slider.Value = obj.num_cycles;
        num_cycles_slider.MajorTicks = 1:5;
        num_cycles_slider.MinorTicks = [];
        num_cycles_slider.ValueChangedFcn = @(src, event) num_cycles_change(src, event, plot_panel);

        view_button_group_y = num_cycles_slider_y - 120;
        % View buttons rotate the current 3D axes without redrawing data.
        view_button_group = uibuttongroup(obj.param_panel, ...
            'Position', [30 view_button_group_y 124 2*(unit_height+5)], ...
            'BorderType', 'none', ...
            'BackgroundColor', option_panel.BackgroundColor, ...
            'SelectionChangedFcn', @(bg, event) view_change_handler(event, plot_panel));
        
        % Dimensions for buttons relative to the group
        view_button_width = 32;
        view_button_spacing = (120 - 3*view_button_width)/2;
        pad = 2;
        view_button_row_spacing = (unit_height+5);
        uitogglebutton(view_button_group, 'Text', '+xy', 'Position', [pad pad+view_button_row_spacing view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);
        uitogglebutton(view_button_group, 'Text', '+yz', 'Position', [pad + view_button_width + view_button_spacing pad+view_button_row_spacing view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);
        uitogglebutton(view_button_group, 'Text', '+xz', 'Position', [pad + 2*(view_button_width + view_button_spacing) pad+view_button_row_spacing view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);
        uitogglebutton(view_button_group, 'Text', '-xy', 'Position', [pad pad view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);
        uitogglebutton(view_button_group, 'Text', '-yz', 'Position', [pad + view_button_width + view_button_spacing pad view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);
        uitogglebutton(view_button_group, 'Text', '-xz', 'Position', [pad + 2*(view_button_width + view_button_spacing) pad view_button_width unit_height], 'BackgroundColor', obj.INACTIVE_COLOR);

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

        function distance_change(src, ~, plot_panel)
            obj.current_downstream_type = obj.downstream_type_by_distance(src.Value);
            obj.update_plot(plot_panel);
        end

        function case_change(src, ~, plot_panel)
            obj.case_name = src.Value;
            obj.update_plot(plot_panel);
        end

        % User selected a new plot type.
        function type_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.plot_type = src.Value;
            obj.plot_hold_bool = false;

            movie_like_plots = obj.plot_types([1 2 4 8]);
            plot_family_changed = ~(ismember(previous_plot_type, movie_like_plots) && ...
                ismember(obj.plot_type, movie_like_plots));

            if plot_family_changed
                if strcmp(obj.plot_type, obj.plot_types(3))
                    obj.var_name_list = obj.movie_3D_std_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(5))
                    obj.var_name_list = obj.hist_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(6))
                    obj.var_name_list = obj.freq_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(7))
                    obj.var_name_list = obj.force_vars;
                else
                    obj.var_name_list = obj.movie_3D_avg_vars;
                end
                obj.var_dropdown.Items = obj.var_name_list;
                obj.variable_name = obj.var_dropdown.Value;
            end

            if strcmp(previous_plot_type, obj.plot_types(3))
                obj.clims = obj.mean_clims;
            elseif strcmp(obj.plot_type, obj.plot_types(3))
                obj.clims = obj.std_clims;
            end

            obj.update_color_limit_slider();

            if strcmp(obj.plot_type, obj.plot_types(4))
                obj.param_panel.Visible = "on";
            else
                obj.param_panel.Visible = "off";
            end

            obj.update_plot(plot_panel);
        end

        % User selected a new variable to plot.
        function variable_change(src, ~, plot_panel)
            obj.variable_name = src.Value;
            obj.update_color_limit_slider();
            obj.update_plot(plot_panel);
        end

        function clim_change(src, ~, plot_panel)
            ticks = obj.clim_slider.MinorTicks;

            % ensure that slider snapped to minor tick value
            newMin = interp1(ticks, ticks, src.Value(1), 'nearest', 'extrap');
            newMax = interp1(ticks, ticks, src.Value(2), 'nearest', 'extrap');
            
            % Update the slider to the snapped positions
            src.Value = [newMin, newMax];
    
            var_idx = find(obj.variable_name == obj.var_name_list);

            % update color limits
            obj.clims(var_idx,:) = [src.Value(1) src.Value(2)];
    
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

        function iso_change(src, ~, plot_panel)
            precision = 0.005;
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value / precision) * precision;

            obj.iso_val = src.Value;
            obj.update_plot(plot_panel);
        end

        % User selected new desired isosurface variable for 3D plot
        function iso_var_change(src, ~, plot_panel)
            obj.iso_var = src.Value;

            var_idx = find(obj.iso_var == obj.var_name_list);

            new_limits = obj.clims(var_idx, :);
            range_width = new_limits(2) - new_limits(1);

            obj.iso_slider.Limits = new_limits;
            obj.iso_val = mean(new_limits) + range_width/4;
            obj.iso_slider.Value = obj.iso_val;
            
            % Aim for roughly five major ticks using a readable interval.
            raw_step = range_width / 5;
            magnitude = 10^floor(log10(raw_step));
            clean_step = round(raw_step / magnitude) * magnitude;
            
            % Start ticks at a multiple of the step.
            first_tick = ceil(new_limits(1) / clean_step) * clean_step;
            obj.iso_slider.MajorTicks = first_tick : clean_step : new_limits(2);
            
            obj.iso_slider.MinorTicks = first_tick : (clean_step / 5) : new_limits(2);

            obj.update_plot(plot_panel);
        end

        % User pressed mirror button to mirror 3D wake to reconstruct left
        % wing
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

        function view_change_handler(event, plot_panel)
            selected_text = event.NewValue.Text;

            ax = findobj(plot_panel.Children, 'Type', 'axes');
            
            switch selected_text
                case "+xz"
                    view(ax, [0 0 1])
                case "+xy"
                    view(ax, [1 0 0])
                case "+yz"
                    view(ax, [0 1 0])
                case "-xz"
                    view(ax, [0 0 -1])
                case "-xy"
                    view(ax, [-1 0 0])
                case "-yz"
                    view(ax, [0 -1 0])
            end
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

        function num_cycles_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.num_cycles = src.Value;
            obj.update_plot(plot_panel);
        end

        function frame_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.frame_ind = src.Value;
            obj.update_plot(plot_panel);
        end

    end
end

methods (Access = private)
    % Update the active plot after a selection or display setting changes.
    function update_plot(obj, plot_panel)
        ax = findobj(plot_panel.Children, 'Type', 'axes');

        % Reuse the existing 3D patch when only its surface data changes.
        if obj.plot_hold_bool
            p = findobj(ax, 'Type', 'patch');
        else
            delete(ax);
        end

        plot_idx = find(obj.plot_types == obj.plot_type);

        if ismember(plot_idx, [1, 2, 4, 8])
            var_name = obj.variable_name_dict(obj.variable_name);
            var_idx = find(obj.variable_name == obj.var_name_list);

            vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
        end
        
        if plot_idx == 4 || plot_idx == 8 % 3D plot
            iso_var_name = obj.variable_name_dict(obj.iso_var);
            vars{end+1} = iso_var_name;
        elseif plot_idx == 3
            var_name = obj.std_var_name_dict(obj.variable_name);
            var_idx = find(obj.variable_name == obj.var_name_list);

            vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
        elseif plot_idx == 5
            var_name = obj.hist_var_name_dict(obj.variable_name);

            vars = {var_name};
            if (obj.variable_name == obj.hist_vars(3))
                x_var_name = "full_cycle";
                vars{end+1} = x_var_name;
            end
        elseif plot_idx == 6
            var_name = obj.freq_var_name_dict(obj.variable_name);

            vars = {var_name};
            if obj.variable_name == obj.freq_vars(1)
                x_var_name = "norm_time_speed";
                vars{end+1} = x_var_name;
                std_name = "phase_std_speed";
                vars{end+1} = std_name;
            end
        elseif plot_idx == 7
            var_name = obj.force_var_name_dict(obj.variable_name);
            vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
        end
        full_file_path = obj.file_path + obj.current_downstream_type + "_" + obj.case_name + obj.file_suffix;
        d = load(full_file_path, vars{:});

        if plot_idx == 2 || plot_idx == 3 || plot_idx == 4
            obj.slider.Visible = "on";
            obj.play_button.Visible = "on";
            % Adjust slider for number of bins
            if d.num_bins ~= obj.num_bins
                obj.num_bins = d.num_bins;
                obj.slider.Limits = [1 d.num_bins];
                obj.slider.MajorTicks = 1:5:d.num_bins;
                obj.slider.MinorTicks = 1:d.num_bins;
            end
        else
            obj.slider.Visible = "off";
            obj.play_button.Visible = "off";
        end

        if plot_idx ~= 7
            val = d.(var_name);
        end

        if ismember(plot_idx, [1, 2, 3, 4, 8])
            y = squeeze(d.y(3,:,:));
            z = squeeze(d.z(3,:,:));
            val = squeeze(val(3,:,:,:));

            params.U = d.U;

            if min(obj.clims(var_idx,:)) < -1
                params.zero = -1;
            elseif min(obj.clims(var_idx,:)) < 0.5
                params.zero = 0;
            else
                params.zero = 1;
            end
    
            if plot_idx == 4
                params.cb_lab = obj.label_dict(obj.variable_name);
                cFlip = false;
            else
                params.cb_lab = obj.label_dict(obj.variable_name);
    
                if any(contains(["v","ω_z","ω_x"],obj.variable_name))
                    cFlip = true;
                else
                    cFlip = false;
                end
            end

            if obj.trim_bool
                y_idx = find(y(:,1) > obj.TRIM_Y_BOUNDS(1) & y(:,1) < obj.TRIM_Y_BOUNDS(2));
                z_idx = find(z(1,:) > obj.TRIM_Z_BOUNDS(1) & z(1,:) < obj.TRIM_Z_BOUNDS(2));
                
                y = y(y_idx, z_idx);
                z = z(y_idx, z_idx);
                val = val(y_idx,z_idx,:);
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
                if cFlip
                    val_add = flip(-val(2:end,:,:),1);
                else
                    val_add = flip(val(2:end,:,:),1);
                end
                y = [y_add; y];
                z = [z_add; z];
                val = [val_add; val]; 
            end

            if obj.filter_bool
                val = medfilt3(val);
            end
        end

        if plot_idx == 4 || plot_idx == 8
            Q = d.(iso_var_name);
            Q = squeeze(Q(3,:,:,:));

            if obj.trim_bool
                Q = Q(y_idx,z_idx,:);
            end
            if obj.mirror_bool
                Q = Q(y_idx_m,:,:);
                Q_add = flip(Q(2:end,:,:),1);
                Q = [Q_add; Q];
            end
            if obj.filter_bool
                Q = medfilt3(Q);
            end
        end
        
        % Create a fresh axes unless the 3D patch can be updated in place.
        if ~obj.plot_hold_bool
            ax = axes(plot_panel);
        end

        if plot_idx == 1
            params.clims = obj.clims(var_idx,:);

            mean_val = mean(val,3);
            PIV_plot(y, z, mean_val, params, ax);
        elseif plot_idx == 2 || plot_idx == 3

        params.clims = obj.clims(var_idx,:);

        val_tr = val(:,:,obj.frame_ind);
        h = PIV_plot(y, z, val_tr, params, ax);
        t = title(ax, ["Bin number: " + obj.frame_ind], FontSize=18);

        while obj.play && (obj.frame_ind < obj.num_bins)
            obj.frame_ind = obj.frame_ind + 1;
            obj.slider.Value = obj.frame_ind;

            % Cap the data so it stays within the current color limits.
            tmp_data = val(:,:,obj.frame_ind);
            tmp_data(tmp_data < params.clims(1)) = params.clims(1);
            tmp_data(tmp_data > params.clims(2)) = params.clims(2);
    
            % Update the existing contour instead of recreating axes.
            set(h, 'ZData', tmp_data); 
            set(t, 'String', ["Bin number: " + obj.frame_ind]);
    
            drawnow;

            pause(0.05);

            if obj.frame_ind == obj.num_bins
            obj.frame_ind = 0; % reset for next loop iteration
            end
        end
        elseif plot_idx == 4
            params.num_bins = d.num_bins;
            params.clims = obj.clims(var_idx,:);
            params.movie = false;
            params.L = d.L;
            params.shift = obj.frame_ind - 1;
            params.isoValue = obj.iso_val; % 0.05
            params.num_cycles = obj.num_cycles;

            [xlims, surface_data, color_data] = stack_vortices_3D(y, z, val, Q, d.cycle_freq, params);
            setColorBar(ax, params)
            xlim(ax,xlims) % otherwise when plotting multiple wingbeats awkward extra space added

            while obj.play && (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;
                params.shift = obj.frame_ind;
        
                [~, surface_data, color_data] = stack_vortices_3D(y, z, val, Q, d.cycle_freq, params);
                p.Vertices = surface_data.vertices;
                p.Faces = surface_data.faces;
                p.FaceVertexCData = color_data;
        
                pause(0.1);

                if obj.frame_ind == obj.num_bins
                    obj.frame_ind = 0; % reset for next loop iteration
                end
            end

            if obj.plot_hold_bool
                p.Vertices = surface_data.vertices;
                p.Faces = surface_data.faces;
                p.FaceVertexCData = color_data;
            else
                plot_3D(ax, surface_data, color_data, params);
                obj.plot_hold_bool = true;
            end
        elseif plot_idx == 5
            if (obj.variable_name == obj.hist_vars(3))
                histogram(ax, val, d.(x_var_name))
                xlabel(ax, "Tick number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
            else
                bar(ax, val)
                xlabel(ax, "Bin number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
            end
        elseif plot_idx == 6
            if (obj.variable_name == obj.freq_vars(1))
                phase_avg_speed = val;
                phase_std_speed = d.(std_name);
                norm_time_speed = d.(x_var_name);

                lower_results = phase_avg_speed - phase_std_speed;
                upper_results = phase_avg_speed + phase_std_speed;
                
                original_color = "#7f2704"; % hex, some dark red
                lighter_color = getLightColor(original_color); % RGB
                
                xconf = [norm_time_speed, norm_time_speed(end:-1:1)];
                yconf = [upper_results, lower_results(end:-1:1)];
                
                hold(ax,'on')

                p = fill(ax, xconf, yconf, lighter_color);
                p.HandleVisibility = 'off';
                p.EdgeColor = 'none';
                
                l = plot(ax, norm_time_speed, phase_avg_speed);
                l.Color = original_color;
                l.LineWidth = 2;

                xlabel(ax, "Wingbeat phase", FontSize=16)
                ylabel(ax, obj.freq_label_dict(obj.variable_name), FontSize=16)
            else
                bar(ax, val)
                xlabel(ax, "Bin number", FontSize=16)
                ylabel(ax, obj.freq_label_dict(obj.variable_name), FontSize=16)
            end
        elseif plot_idx == 7
            avg_type = 1;
            norm_bool = false;
            case_id = obj.current_downstream_type + "_" + obj.case_name;
            val = get_PIV_force(full_file_path, case_id, var_name, avg_type, norm_bool);

            plot(ax, val)
            hold(ax, "on")
            yline(ax, mean(val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.force_label_dict(obj.variable_name), FontSize=16)
        elseif plot_idx == 8
            val(Q <= 0.025) = NaN;

            mean_val = squeeze(mean(val, [1 2], "omitnan"));

            plot(ax, mean_val)
            hold(ax, "on")
            yline(ax, mean(mean_val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.label_dict(obj.variable_name), FontSize=16, Interpreter="latex")
        end
    end

    function update_color_limit_slider(obj)
        var_idx = find(obj.variable_name == obj.var_name_list);
        center = mean(obj.clims(var_idx,:));
        range = (obj.clim_scale/2)*diff(obj.clims(var_idx,:));
        obj.clim_slider.Limits = [center - range, center + range];
        obj.clim_slider.Value = obj.clims(var_idx,:);
    end
end

end