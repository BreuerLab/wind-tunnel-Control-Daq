classdef flowField_UI < handle
properties (Constant, Access = private)
    ACTIVE_COLOR = [0.3010 0.7450 0.9330];
    INACTIVE_COLOR = [1 1 1];
    TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
    TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
    MIRROR_CENTER_Y = -2.26;
    secondary_vars = ["Q_x","Q_y","Q_z","|Q|","div",...
        "KE", "power"];
    UPSTREAM_DISTANCE_MARKERS = ["";"UP_one_";"UP_two_"];
    KNOWN_DISTANCE_LABELS = ["x = 0.9m";"x = 1.3m";"x = 1.7m"];
end

properties
    % Display and dataset selection
    mon_num;
    file_path;
    phase_avg_file_path;
    time_avg_file_path;
    file_suffix;
    source_mode;
    source_modes;
    case_name;
    case_name_list;
    flapper_case_name_list;
    turbine_case_name_list;
    phase_flapper_case_name_list;
    phase_turbine_case_name_list;
    time_flapper_case_name_list;
    time_turbine_case_name_list;
    phase_avg_case_ids;
    time_avg_case_ids;
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
    time_avg_var_name_dict;
    label_dict;

    std_var_name_dict;
    std_label_dict;

    hist_var_name_dict;
    hist_label_dict;

    freq_var_name_dict;
    freq_label_dict;

    force_var_name_dict;
    force_label_dict;

    dict_B;

    % Color limits for each variable list
    clims;
    clim_dict;
    mean_clims;
    mean_clim_dict;
    std_clims;
    std_clim_dict;
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
    extrapolate_bool;
    floor_bool;
    thresh;
    q_mask_bool;
    q_mask_thresh;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = flowField_UI(mon_num, file_path)
        obj.mon_num = mon_num;
        obj.case_name = "";
        obj.variable_name = "";
        obj.phase_avg_file_path = file_path + "Processed Results\phase_avg\";
        obj.time_avg_file_path = file_path + "Processed Results\time_avg\";
        obj.file_path = obj.phase_avg_file_path;
        obj.source_modes = strings(0);
        obj.source_mode = "";

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;

        obj.plot_types = ["time avg","phase avg: movie", "phase std: movie", "phase avg: 3D plot",...
            "image wingbeat phase", "wingbeat frequency","wake forces","phase avg: planar avg"];
        obj.plot_type = obj.plot_types(1);
        obj.plot_hold_bool = false;
        obj.iso_var_list = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                            "Q_x","Q_y","Q_z","|Q|", "helicity",...
                            "du/dx","du/dy","du/dz","dv/dx","dv/dy",...
                            "dv/dz","dw/dx","dw/dy","dw/dz"];
        obj.iso_var = "|Q|";
        obj.iso_val = 0.05;
        % obj.iso_val = -0.05;
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.num_cycles = 1;
        obj.trim_bool = true;
        obj.extrapolate_bool = false;
        obj.floor_bool = false;
        obj.thresh = 0.1;
        obj.q_mask_bool = false;
        obj.q_mask_thresh = 0.025;

        obj.file_suffix = "_phase_avg";

        phase_avg_files = dir(obj.phase_avg_file_path + "*.mat");
        time_avg_files = dir(obj.time_avg_file_path + "*.mat");

        phase_avg_stems = obj.get_file_stems(phase_avg_files, "_phase_avg");
        time_avg_stems = obj.get_file_stems(time_avg_files, "_time_avg");
        obj.phase_avg_case_ids = phase_avg_stems;
        obj.time_avg_case_ids = time_avg_stems;

        turbine_stems = phase_avg_stems(contains(phase_avg_stems, "turbine"));
        flapper_stems = phase_avg_stems(~contains(phase_avg_stems, "turbine"));
        time_turbine_stems = time_avg_stems(contains(time_avg_stems, "turbine"));
        time_flapper_stems = time_avg_stems(~contains(time_avg_stems, "turbine"));

        [obj.downstream_types, obj.distance_labels] = obj.get_available_downstream_options([flapper_stems, time_flapper_stems]);
        if isempty(obj.downstream_types)
            obj.current_downstream_type = "";
            obj.downstream_type_by_distance = containers.Map('KeyType', 'char', 'ValueType', 'char');
        else
            obj.current_downstream_type = obj.downstream_types(1);
            obj.downstream_type_by_distance = containers.Map(obj.distance_labels, obj.downstream_types);
        end

        obj.phase_flapper_case_name_list = obj.get_flapper_case_names(flapper_stems);
        obj.phase_turbine_case_name_list = obj.get_turbine_case_names(turbine_stems);
        obj.time_flapper_case_name_list = obj.get_flapper_case_names(time_flapper_stems);
        obj.time_turbine_case_name_list = obj.get_turbine_case_names(time_turbine_stems);
        obj.source_modes = obj.get_available_source_modes();
        if isempty(obj.source_modes)
            error("No STB average files found. Expected *_phase_avg.mat files in %s or *_time_avg.mat files in %s.", obj.phase_avg_file_path, obj.time_avg_file_path)
        end
        obj.source_mode = obj.source_modes(1);
        obj.case_name_list = obj.get_case_name_list_for_active_plot_type();
        obj.flapper_case_name_list = obj.get_case_name_list("flapper", obj.plot_type);
        obj.turbine_case_name_list = obj.get_case_name_list("turbine", obj.plot_type);

        obj.movie_3D_avg_vars = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|",...
                    "u'u'", "v'v'", "w'w'","u'v'","u'w'","v'w'","helicity", "# particles",...
                    "du/dx","du/dy","du/dz","dv/dx","dv/dy","dv/dz","dw/dx","dw/dy","dw/dz",...
                    "div", "KE", "power"];
        movie_3D_avg_values = ["u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
        "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg",...
        "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg",...
        "uncTot_phase_avg","uu_stress","vv_stress","ww_stress","uv_stress",...
        "uw_stress","vw_stress","hel_phase_avg", "numP_phase_avg",...
        "dudx_phase_avg","dudy_phase_avg","dudz_phase_avg",...
        "dvdx_phase_avg","dvdy_phase_avg","dvdz_phase_avg",...
        "dwdx_phase_avg","dwdy_phase_avg","dwdz_phase_avg",...
        "div", "KE_diff_field", "power_field"];
        time_avg_values = ["mean_u","mean_v","mean_w","mean_Utot",...
        "mean_vortX","mean_vortY","mean_vortZ","mean_vortTot",...
        "Qx","Qy","Qz","Q","mean_uncU","mean_uncV","mean_uncW",...
        "mean_uncTot","mean_uu_stress","mean_vv_stress","mean_ww_stress",...
        "mean_uv_stress","mean_uw_stress","mean_vw_stress","mean_hel",...
        "mean_numP","mean_dudx","mean_dudy","mean_dudz",...
        "mean_dvdx","mean_dvdy","mean_dvdz",...
        "mean_dwdx","mean_dwdy","mean_dwdz",...
        "div", "KE_diff_field", "power_field"];
        
        obj.movie_3D_std_vars = [obj.movie_3D_avg_vars(1:8) obj.movie_3D_avg_vars(13:end)];
        movie_3D_std_values = [movie_3D_avg_values(1:8) movie_3D_avg_values(13:end)];
        movie_3D_std_values = strrep(movie_3D_std_values,"avg","std");
        % ["u_phase_std","v_phase_std","w_phase_std","Utot_phase_std",...
        % "vortX_phase_std","vortY_phase_std","vortZ_phase_std","vortTot_phase_std",...
        % "uncU_phase_std","uncV_phase_std","uncW_phase_std","uncTot_phase_std","hel_phase_std", "numP_phase_std"];

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
                      0, 0.03;...
                      0, 0.03;...
                      0, 0.03;...
                      0, 0.03;...
                      0, 0.01;...
                      0, 0.01;...
                      0, 0.01;...
                      0, 0.005;...
                      0, 0.005;...
                      0, 0.005;...
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
                      -1, 1;...%
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...% no std saved for Re stress
                      -1, 1;...
                      0, 50;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      -1, 1;
                      0, 0.1;
                      0, 0.1];

        obj.mean_clim_dict = obj.build_clim_dict(obj.movie_3D_avg_vars, obj.mean_clims);
        obj.std_clim_dict = obj.build_clim_dict(obj.movie_3D_std_vars, obj.std_clims);
        obj.clims = obj.mean_clims;
        obj.clim_dict = obj.mean_clim_dict;
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
                            "u'u'","v'v'","w'w'","u'v'","u'w'","v'w'" "","count",...
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
        movie_3D_std_labels = [movie_3D_avg_labels(1:8) movie_3D_avg_labels(13:end)];

        keys = cellstr(obj.movie_3D_avg_vars);
        values = movie_3D_avg_values;
        labels = movie_3D_avg_labels;
        obj.variable_name_dict = containers.Map(keys, values);
        obj.time_avg_var_name_dict = containers.Map(keys, time_avg_values);
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

        keys_B = cellstr(movie_3D_avg_values(1:3));
        vals_B = ["velX_B", "velY_B", "velZ_B"];
        obj.dict_B = containers.Map(keys_B, vals_B);
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
        source_dropdown.Items = obj.source_modes;
        source_dropdown.Value = obj.source_mode;
        source_dropdown.ValueChangedFcn = @(src, event) source_change(src, event, plot_panel);

        % Dropdown box for which cases axes to display
        distance_dropdown_y = source_dropdown_y - 35;
        distance_dropdown = uidropdown(option_panel);
        distance_dropdown.Position = [10 distance_dropdown_y 180 30];
        if isempty(obj.distance_labels)
            distance_dropdown.Items = "No Calimero data";
            distance_dropdown.Value = "No Calimero data";
            distance_dropdown.Visible = "off";
            distance_dropdown.Enable = "off";
        else
            distance_dropdown.Items = obj.distance_labels;
            distance_dropdown.Value = obj.distance_labels(1);
            if obj.source_mode == "turbine"
                distance_dropdown.Visible = "off";
            end
        end
        distance_dropdown.ValueChangedFcn = @(src, event) distance_change(src, event, plot_panel);

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

        extrapolate_button_y = filter_button_y - 35;
        extrapolate_button = uibutton(option_panel,"state");
        extrapolate_button.Text = "Extrapolate";
        extrapolate_button.FontSize = 18;
        extrapolate_button.Position = [30 extrapolate_button_y 120 unit_height];
        extrapolate_button.BackgroundColor = obj.INACTIVE_COLOR;
        extrapolate_button.ValueChangedFcn = @(src, event) extrapolate_change(src, event, plot_panel);

        floor_button_y = extrapolate_button_y - 35;
        floor_button = uibutton(option_panel,"state");
        floor_button.Text = "Noise Floor";
        floor_button.FontSize = 18;
        floor_button.Position = [30 floor_button_y 120 unit_height];
        floor_button.BackgroundColor = obj.INACTIVE_COLOR;
        floor_button.ValueChangedFcn = @(src, event) floor_change(src, event, plot_panel);

        edit1_y = floor_button_y - 35;
        floor_field = uieditfield(option_panel, 'numeric');
        floor_field.Value = obj.thresh;
        floor_field.Position = [20 edit1_y 160 unit_height];
        floor_field.ValueChangedFcn = @(src, event) thresh_change(src, event, plot_panel);

        q_mask_button_y = edit1_y - 35;
        q_mask_button = uibutton(option_panel,"state");
        q_mask_button.Text = "Q-mask";
        q_mask_button.FontSize = 18;
        q_mask_button.Position = [30 q_mask_button_y 120 unit_height];
        q_mask_button.BackgroundColor = obj.INACTIVE_COLOR;
        q_mask_button.ValueChangedFcn = @(src, event) q_mask_change(src, event, plot_panel);

        q_mask_field_y = q_mask_button_y - 35;
        q_mask_field = uieditfield(option_panel, 'numeric');
        q_mask_field.Value = obj.q_mask_thresh;
        q_mask_field.Position = [20 q_mask_field_y 160 unit_height];
        q_mask_field.ValueChangedFcn = @(src, event) q_mask_thresh_change(src, event, plot_panel);

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
        param_panel_y = q_mask_field_y - 10 - param_panel_height;
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
        % obj.iso_slider.Limits = [-0.1 -0.005];
        obj.iso_slider.Value = obj.iso_val;
        obj.iso_slider.MajorTicks = 0:0.025:0.1; % 0:0.05:0.5
        obj.iso_slider.MinorTicks = 0.005:0.005:0.1; % 0.01:0.01:0.5
        % obj.iso_slider.MajorTicks = -0.1:0.025:0; % 0:0.05:0.5
        % obj.iso_slider.MinorTicks = -0.1:0.005:0.005; % 0.01:0.01:0.5
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

        function source_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.source_mode = src.Value;
            if obj.source_mode == "turbine"
                distance_dropdown.Visible = "off";
            else
                distance_dropdown.Visible = "on";
                obj.current_downstream_type = string(obj.downstream_type_by_distance(distance_dropdown.Value));
            end

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            % Force frame slider back to 1 since not all datasets have the
            % same number of frames
            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        function distance_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.current_downstream_type = string(obj.downstream_type_by_distance(src.Value));
            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            % Force frame slider back to 1 since not all datasets have the
            % same number of frames
            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        function case_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.case_name = string(src.Value);
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            % Force frame slider back to 1 since not all datasets have the
            % same number of frames
            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        % User selected a new plot type.
        function type_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.plot_type = src.Value;
            obj.plot_hold_bool = false;

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            obj.update_plot(plot_panel);
        end

        % User selected a new variable to plot.
        function variable_change(src, ~, plot_panel)
            obj.variable_name = src.Value;
            obj.update_color_limit_slider();
            obj.update_plot(plot_panel);
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

        function refresh_variable_dropdown(previous_plot_type)
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

            obj.set_active_color_limit_set();
            obj.update_color_limit_slider();

            if strcmp(obj.plot_type, obj.plot_types(4))
                obj.param_panel.Visible = "on";
            else
                obj.param_panel.Visible = "off";
            end
        end

        function clim_change(src, ~, plot_panel)
            ticks = obj.clim_slider.MinorTicks;

            % ensure that slider snapped to minor tick value
            newMin = interp1(ticks, ticks, src.Value(1), 'nearest', 'extrap');
            newMax = interp1(ticks, ticks, src.Value(2), 'nearest', 'extrap');
            
            % Update the slider to the snapped positions
            src.Value = [newMin, newMax];
    
            % update color limits
            obj.set_color_limits(obj.variable_name, [src.Value(1) src.Value(2)]);
    
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

            new_limits = obj.get_color_limits(obj.iso_var);
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

        function extrapolate_change(src, ~, plot_panel)
            if (src.Value)
                obj.extrapolate_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.extrapolate_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function floor_change(src, ~, plot_panel)
            if (src.Value)
                obj.floor_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.floor_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function thresh_change(src, ~, plot_panel)
            obj.thresh = src.Value;
            obj.update_plot(plot_panel);
        end

        function q_mask_change(src, ~, plot_panel)
            if (src.Value)
                obj.q_mask_bool = true;
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                obj.q_mask_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            obj.update_plot(plot_panel);
        end

        function q_mask_thresh_change(src, ~, plot_panel)
            obj.q_mask_thresh = src.Value;
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
    function file_stems = get_file_stems(~, files, suffix)
        file_names = string({files.name});
        avg_files = endsWith(file_names, suffix + ".mat");
        file_stems = erase(file_names(avg_files), suffix + ".mat");
    end

    function [downstream_types, distance_labels] = get_available_downstream_options(obj, flapper_stems)
        downstream_types = strings(0, 1);
        distance_labels = strings(0, 1);

        for i = 1:length(obj.UPSTREAM_DISTANCE_MARKERS)
            matching_stems = obj.get_downstream_stems_for_distance(flapper_stems, i);
            downstream_type = obj.get_downstream_type_from_stems(matching_stems);
            if strlength(downstream_type) > 0
                downstream_types(end + 1, 1) = downstream_type;
                distance_labels(end + 1, 1) = obj.KNOWN_DISTANCE_LABELS(i);
            end
        end
    end

    function matching_stems = get_downstream_stems_for_distance(obj, flapper_stems, distance_index)
        one_up_marker = obj.UPSTREAM_DISTANCE_MARKERS(2);
        two_up_marker = obj.UPSTREAM_DISTANCE_MARKERS(3);

        switch distance_index
            case 1
                mask = ~contains(flapper_stems, one_up_marker) & ~contains(flapper_stems, two_up_marker);
            case 2
                mask = contains(flapper_stems, one_up_marker);
            case 3
                mask = contains(flapper_stems, two_up_marker);
            otherwise
                mask = false(size(flapper_stems));
        end

        matching_stems = flapper_stems(mask);
    end

    function downstream_type = get_downstream_type_from_stems(obj, stems)
        downstream_type = "";
        for i = 1:length(stems)
            type = obj.get_downstream_type_from_stem(stems(i));
            if strlength(type) > 0
                downstream_type = type;
                return
            end
        end
    end

    function downstream_type = get_downstream_type_from_stem(~, stem)
        name_parts = split(stem, "_");
        case_start_index = find(contains(name_parts, "deg") | contains(name_parts, "Hz"), 1);

        if isempty(case_start_index)
            downstream_type = stem;
        elseif case_start_index == 1
            downstream_type = "";
        else
            downstream_type = strjoin(name_parts(1:case_start_index - 1), "_");
        end
    end

    function source_modes = get_available_source_modes(obj)
        source_modes = strings(0);

        if ~isempty(obj.phase_flapper_case_name_list) || ~isempty(obj.time_flapper_case_name_list)
            source_modes(end + 1) = "flapper";
        end

        if ~isempty(obj.phase_turbine_case_name_list) || ~isempty(obj.time_turbine_case_name_list)
            source_modes(end + 1) = "turbine";
        end
    end

    function case_names = get_case_name_list_for_active_plot_type(obj)
        case_names = obj.get_case_name_list(obj.source_mode, obj.plot_type);
    end

    function case_names = get_case_name_list(obj, source_mode, plot_type)
        if source_mode == "turbine"
            phase_case_names = obj.phase_turbine_case_name_list;
            time_case_names = obj.time_turbine_case_name_list;
        else
            phase_case_names = obj.phase_flapper_case_name_list;
            time_case_names = obj.time_flapper_case_name_list;
        end

        if plot_type == obj.plot_types(1)
            case_names = unique([phase_case_names, time_case_names], 'stable');
        else
            case_names = phase_case_names;
        end
    end

    function case_names = get_flapper_case_names(obj, phase_avg_stems)
        case_names = strings(0);
        downstream_types = obj.downstream_types;
        distance_labels = obj.distance_labels;
        if isempty(downstream_types)
            [downstream_types, distance_labels] = obj.get_available_downstream_options(phase_avg_stems);
        end

        for i = 1:length(downstream_types)
            downstream_type = downstream_types(i);
            prefix = downstream_type + "_";
            matching_stems = phase_avg_stems(phase_avg_stems == downstream_type | startsWith(phase_avg_stems, prefix));
            if i <= length(distance_labels) && distance_labels(i) == obj.KNOWN_DISTANCE_LABELS(1)
                default_distance_stems = obj.get_downstream_stems_for_distance(phase_avg_stems, 1);
                bare_default_stems = default_distance_stems(~contains(default_distance_stems, "_"));
                matching_stems = unique([matching_stems, bare_default_stems], 'stable');
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

    function case_names = get_turbine_case_names(~, phase_avg_stems)
        case_names = strings(size(phase_avg_stems));
        for i = 1:length(phase_avg_stems)
            case_name = phase_avg_stems(i);
            if startsWith(case_name, "turbine_")
                case_name = extractAfter(case_name, "turbine_");
            end
            case_names(i) = case_name;
        end
        case_names = unique(case_names, 'stable');
    end

    function case_id = get_current_case_id(obj)
        case_name = string(obj.case_name);
        current_downstream_type = string(obj.current_downstream_type);

        if obj.source_mode == "turbine"
            if startsWith(case_name, "turbine")
                case_id = case_name;
            else
                case_id = "turbine_" + case_name;
            end
        else
            if obj.plot_type == obj.plot_types(1) && any(obj.time_avg_case_ids == case_name)
                case_id = case_name;
            elseif current_downstream_type == case_name && ...
                    (any(obj.phase_avg_case_ids == case_name) || any(obj.time_avg_case_ids == case_name))
                case_id = case_name;
            elseif strlength(case_name) == 0
                case_id = current_downstream_type;
            else
                case_id = current_downstream_type + "_" + case_name;
            end
        end
    end

    function file_base = get_current_file_base(obj)
        if obj.is_time_avg_file_selected()
            file_base = obj.time_avg_file_path + obj.get_current_case_id() + "_time_avg";
        else
            file_base = obj.phase_avg_file_path + obj.get_current_case_id() + "_phase_avg";
        end
    end

    function tf = current_case_has_phase_avg(obj)
        tf = any(obj.phase_avg_case_ids == obj.get_current_case_id());
    end

    function tf = current_case_has_time_avg(obj)
        tf = any(obj.time_avg_case_ids == obj.get_current_case_id());
    end

    function tf = is_time_avg_file_selected(obj)
        tf = obj.plot_type == obj.plot_types(1) && obj.current_case_has_time_avg();
    end

    function plot_types = get_available_plot_types_for_current_case(obj)
        if obj.is_time_avg_file_selected() || ~obj.current_case_has_phase_avg()
            plot_types = obj.plot_types(1);
        else
            plot_types = obj.plot_types;
        end
    end

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
        using_time_avg_file = obj.is_time_avg_file_selected();
        use_extrapolated_data = obj.extrapolate_bool && ~using_time_avg_file;
        q_mask_enabled = obj.q_mask_bool && ismember(plot_idx, [1, 2]) && ~use_extrapolated_data;
        q_mask_var_name = "Q";

        cur_secondary_vars = {};

        if ismember(plot_idx, [1, 2, 4, 8])
            if using_time_avg_file
                var_name = obj.time_avg_var_name_dict(obj.variable_name);
                vars = {"L","U","z","y"};
            else
                var_name = obj.variable_name_dict(obj.variable_name);
                vars = {"L","U","num_bins","cycle_freq","z","y"};
            end
            var_clims = obj.get_color_limits(obj.variable_name);

            if use_extrapolated_data
                var_name = obj.dict_B(var_name);
                vars = {"L","U","num_bins","cycle_freq"};
                cur_secondary_vars = {"z_B","y_B"};
            end

            if contains(obj.variable_name, obj.secondary_vars) || use_extrapolated_data
                cur_secondary_vars{end+1} = var_name;
            else
                vars{end+1} = var_name;
            end

            if q_mask_enabled && ~any(strcmp(string(cur_secondary_vars), q_mask_var_name))
                cur_secondary_vars{end+1} = q_mask_var_name;
            end
        end
        
        if plot_idx == 4 || plot_idx == 8 % 3D plot
            iso_var_name = obj.variable_name_dict(obj.iso_var);

            if contains(obj.iso_var, obj.secondary_vars)
                cur_secondary_vars{end+1} = iso_var_name;
            else
                vars{end+1} = iso_var_name;
            end
        elseif plot_idx == 3
            var_name = obj.std_var_name_dict(obj.variable_name);
            var_clims = obj.get_color_limits(obj.variable_name);

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
                cur_secondary_vars{end+1} = x_var_name;
                std_name = "phase_std_speed";
                cur_secondary_vars{end+1} = std_name;
            end
        elseif plot_idx == 7
            var_name = obj.force_var_name_dict(obj.variable_name);
            vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
        end

        if strlength(obj.case_name) == 0
            return
        end

        full_file_path = obj.get_current_file_base();

        if ~isempty(cur_secondary_vars)
            d1 = load(full_file_path + "_integral.mat", cur_secondary_vars{:});
            d2 = load(full_file_path + ".mat", vars{:});
    
            % Combine by converting to cell arrays of names/values and back to struct
            d = cell2struct([struct2cell(d1); struct2cell(d2)], [fieldnames(d1); fieldnames(d2)], 1);
        else
            d = load(full_file_path + ".mat", vars{:});
        end

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

        if q_mask_enabled
            q_mask_val = d.(q_mask_var_name);
        end

        if ismember(plot_idx, [1, 2, 3, 4, 8])
            if use_extrapolated_data
                y = d.y_B;
                z = d.z_B;
                val = permute(val, [2 3 1]); % time dimension moved
                if contains(var_name, "X")
                    val = val - 1; % add back freestream
                end
            elseif using_time_avg_file
                y = squeeze(d.y(3,:,:));
                z = squeeze(d.z(3,:,:));
                val = squeeze(val(3,:,:));
                if q_mask_enabled
                    q_mask_val = squeeze(q_mask_val(3,:,:));
                end
            else
                y = squeeze(d.y(3,:,:));
                z = squeeze(d.z(3,:,:));
                val = squeeze(val(3,:,:,:));
                if q_mask_enabled
                    q_mask_val = squeeze(q_mask_val(3,:,:,:));
                end
            end

            params.U = d.U;

            if min(var_clims) < -1
                params.zero = -1;
            elseif min(var_clims) < 0.5
                params.zero = 0;
            else
                params.zero = 1;
            end
    
            cFlip = false;
            if plot_idx == 4
                if any(contains(["v","ω_z","ω_x"],obj.variable_name))
                    cFlip = true;
                end
            end

            if obj.trim_bool && ~use_extrapolated_data
                y_idx = find(y(:,1) > obj.TRIM_Y_BOUNDS(1) & y(:,1) < obj.TRIM_Y_BOUNDS(2));
                z_idx = find(z(1,:) > obj.TRIM_Z_BOUNDS(1) & z(1,:) < obj.TRIM_Z_BOUNDS(2));
                
                y = y(y_idx, z_idx);
                z = z(y_idx, z_idx);
                if using_time_avg_file
                    val = val(y_idx,z_idx);
                    if q_mask_enabled
                        q_mask_val = q_mask_val(y_idx,z_idx);
                    end
                else
                    val = val(y_idx,z_idx,:);
                    if q_mask_enabled
                        q_mask_val = q_mask_val(y_idx,z_idx,:);
                    end
                end
            end
            if obj.mirror_bool && ~use_extrapolated_data
                % Mirror across the centerline to reconstruct the opposite side of the wake.
                y_idx_m = find(y(:,1) > obj.MIRROR_CENTER_Y);
                
                y = y(y_idx_m, :);
                z = z(y_idx_m, :);
                if using_time_avg_file
                    val = val(y_idx_m,:);
                    if q_mask_enabled
                        q_mask_val = q_mask_val(y_idx_m,:);
                    end
                else
                    val = val(y_idx_m,:,:);
                    if q_mask_enabled
                        q_mask_val = q_mask_val(y_idx_m,:,:);
                    end
                end
                
                % Shift so the mirror center is the origin.
                y = y - min(y, [], "all");
                
                % Reflect and skip the first row to avoid double-counting the centerline.
                y_add = flip(-y(2:end,:),1);
                z_add = flip(z(2:end,:),1);
                if cFlip
                    if using_time_avg_file
                        val_add = flip(-val(2:end,:),1);
                    else
                        val_add = flip(-val(2:end,:,:),1);
                    end
                else
                    if using_time_avg_file
                        val_add = flip(val(2:end,:),1);
                    else
                        val_add = flip(val(2:end,:,:),1);
                    end
                end
                y = [y_add; y];
                z = [z_add; z];
                val = [val_add; val]; 
                if q_mask_enabled
                    if using_time_avg_file
                        q_mask_val_add = flip(q_mask_val(2:end,:),1);
                    else
                        q_mask_val_add = flip(q_mask_val(2:end,:,:),1);
                    end
                    q_mask_val = [q_mask_val_add; q_mask_val];
                end
            end

            if obj.filter_bool
                if using_time_avg_file
                    val = medfilt2(val);
                    if q_mask_enabled
                        q_mask_val = medfilt2(q_mask_val);
                    end
                else
                    val = medfilt3(val);
                    if q_mask_enabled
                        q_mask_val = medfilt3(q_mask_val);
                    end
                end
            end

            if obj.floor_bool
                val(val < (params.zero + obj.thresh) & val > (params.zero - obj.thresh)) = params.zero;
            end

            if q_mask_enabled && plot_idx == 2
                val(q_mask_val <= obj.q_mask_thresh) = NaN;
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

        switch plot_idx
        case {1,2,4}
            params.cb_lab = obj.label_dict(obj.variable_name);
        case 3
            params.cb_lab = obj.std_label_dict(obj.variable_name);
        end

        if plot_idx == 1
            params.clims = var_clims;

            if using_time_avg_file
                mean_val = val;
                if q_mask_enabled
                    q_mask_plot_val = q_mask_val;
                end
            else
                mean_val = mean(val,3);
                if q_mask_enabled
                    q_mask_plot_val = mean(q_mask_val,3);
                end
            end

            if q_mask_enabled
                mean_val(q_mask_plot_val <= obj.q_mask_thresh) = NaN;
            end

            PIV_plot(y, z, mean_val, params, ax);
        elseif plot_idx == 2 || plot_idx == 3

        params.clims = var_clims;

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
            params.clims = var_clims;
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
            case_id = obj.get_current_case_id();
            val = get_PIV_force(full_file_path, case_id, var_name, avg_type, norm_bool);

            plot(ax, val)
            hold(ax, "on")
            yline(ax, mean(val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.force_label_dict(obj.variable_name), FontSize=16)
        elseif plot_idx == 8
            val(Q <= 0.025) = NaN;

            mean_val = squeeze(mean(val, [1 2], "omitnan"));
            % mean_val = mean_trapz(val);
            disp("mean: " + mean(mean_val))

            plot(ax, mean_val)
            hold(ax, "on")
            yline(ax, mean(mean_val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.label_dict(obj.variable_name), FontSize=16, Interpreter="latex")
        end
    end

    function clim_dict = build_clim_dict(~, var_names, clim_values)
        keys = cellstr(var_names);
        values = mat2cell(clim_values, ones(1, size(clim_values, 1)), size(clim_values, 2));
        clim_dict = containers.Map(keys, values);
    end

    function set_active_color_limit_set(obj)
        if strcmp(obj.plot_type, obj.plot_types(3))
            obj.clims = obj.std_clims;
            obj.clim_dict = obj.std_clim_dict;
        else
            obj.clims = obj.mean_clims;
            obj.clim_dict = obj.mean_clim_dict;
        end
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

    function set_color_limits(obj, var_name, new_clims)
        key = char(var_name);
        if isKey(obj.clim_dict, key)
            obj.clim_dict(key) = new_clims;
        end

        var_idx = find(string(var_name) == obj.var_name_list, 1);
        if ~isempty(var_idx)
            obj.clims(var_idx,:) = new_clims;
        end

        if strcmp(obj.plot_type, obj.plot_types(3))
            obj.std_clims = obj.update_clim_matrix(obj.movie_3D_std_vars, obj.std_clims, var_name, new_clims);
            if isKey(obj.std_clim_dict, key)
                obj.std_clim_dict(key) = new_clims;
            end
        else
            obj.mean_clims = obj.update_clim_matrix(obj.movie_3D_avg_vars, obj.mean_clims, var_name, new_clims);
            if isKey(obj.mean_clim_dict, key)
                obj.mean_clim_dict(key) = new_clims;
            end
        end
    end

    function clim_values = update_clim_matrix(~, var_names, clim_values, var_name, new_clims)
        var_idx = find(string(var_name) == var_names, 1);
        if ~isempty(var_idx)
            clim_values(var_idx,:) = new_clims;
        end
    end

    function update_color_limit_slider(obj)
        if ~isKey(obj.clim_dict, char(obj.variable_name))
            obj.clim_slider.Enable = "off";
            return
        end

        obj.clim_slider.Enable = "on";
        cur_clims = obj.get_color_limits(obj.variable_name);
        center = mean(cur_clims);
        range = (obj.clim_scale/2)*diff(cur_clims);
        obj.clim_slider.Limits = [center - range, center + range];
        obj.clim_slider.Value = cur_clims;
    end
end

end