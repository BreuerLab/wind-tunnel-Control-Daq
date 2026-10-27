classdef flowField_UI < handle
properties (Constant, Access = private)
    ACTIVE_COLOR = [0.3010 0.7450 0.9330];
    INACTIVE_COLOR = [1 1 1];
    Q_ISO_RANGE = [0.005 0.1];  % Q isovalue slider range (negated by "+/-")
    Q_ISO_DEFAULT = 0.05;       % Q isovalue slider default
    % Tag on the 3D plot's stroke lines / shading / labels (Label Stroke),
    % so they can be found and removed without touching the isosurface
    STROKE_TAG = "stroke_label_3D";
    % Derived variable: lift integrand from the wake, computed on the fly
    % from stored fields (term1 in get_wake_lift: -U .* y .* -vortX, with y
    % measured from the mirror centerline)
    LIFT_WX_VAR = "lift (U y ω_x)"; % name shown in the variable dropdown
    LIFT_WX_FIELD = "lift_wx_field"; % internal name, not stored in files
    % Trim bounds and mirror centerline for each flapper source mode.
    % The active set is copied into trim_y_bounds / trim_z_bounds /
    % mirror_center_y by set_trim_settings_for_source_mode().
    OLD_FLAPPER_TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
    OLD_FLAPPER_TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
    OLD_FLAPPER_MIRROR_CENTER_Y = -2.26;
    NEW_FLAPPER_TRIM_Y_BOUNDS = [-2.4 2.8];
    NEW_FLAPPER_TRIM_Z_BOUNDS = [-2.9 3.1];
    NEW_FLAPPER_MIRROR_CENTER_Y = -2.06;
    secondary_vars = ["Q_x","Q_y","Q_z","|Q|","div",...
        "KE", "power"];
    OLD_FLAPPER_SOURCE_MODE = "old flapper";
    NEW_FLAPPER_SOURCE_MODE = "new flapper";
    TURBINE_SOURCE_MODE = "turbine";
    OLD_FLAPPER_DOWNSTREAM_TYPES = ["flexible";"UP_one_flexible";"UP_two_flexible"];
    OLD_FLAPPER_DISTANCE_LABELS = ["x = 0.9m";"x = 1.3m";"x = 1.7m"];
    NEW_FLAPPER_DOWNSTREAM_TYPES = ["x1";"x2";"x3";"x4";"x5";"MPS"];
    NEW_FLAPPER_DISTANCE_LABELS = ["x1";"x2";"x3";"x4";"x5";"MPS"];
    % Streamwise separation (m) between the robot and the imaging plane,
    % used for the convection phase shift (same values as phaseAvg_UI).
    % Entries line up with OLD_/NEW_FLAPPER_DOWNSTREAM_TYPES. Set an entry
    % to NaN if unknown (no shift applied).
    OLD_FLAPPER_DOWNSTREAM_DISTS = [0.9; 0.9 + 0.37; 0.9 + 2*0.37]; % flexible, UP_one, UP_two
    NEW_FLAPPER_DOWNSTREAM_DISTS = [0.9 - 2*0.37; 0.9 - 0.37; 0.9; 0.9 + 0.37; 0.9 + 2*0.37; 1.0]; % x1-x5, MPS
    CONV_SPEED = 4; % m/s, convection speed of the wake
end

properties
    % Display and dataset selection
    file_path;
    phase_avg_file_path;
    time_avg_file_path;
    file_suffix;
    source_mode;
    source_modes;
    trim_y_bounds;    % active trim/mirror settings, set per source mode
    trim_z_bounds;
    mirror_center_y;
    case_name;
    case_name_list;
    flapper_case_name_list;
    turbine_case_name_list;
    phase_flapper_case_name_list;
    phase_old_flapper_case_name_list;
    phase_new_flapper_case_name_list;
    phase_turbine_case_name_list;
    time_flapper_case_name_list;
    time_old_flapper_case_name_list;
    time_new_flapper_case_name_list;
    time_turbine_case_name_list;
    % file stems (no _hr / _RPCA) per source, for the case list of the
    % selected downstream position
    phase_old_flapper_stems;
    phase_new_flapper_stems;
    time_old_flapper_stems;
    time_new_flapper_stems;
    phase_avg_case_ids;
    time_avg_case_ids;
    phase_avg_RPCA_file_path;   % optional subfolder phase_avg\RPCA\
    phase_avg_main_case_ids;    % case ids found directly in phase_avg\
    phase_avg_RPCA_case_ids;    % case ids found in phase_avg\RPCA\ (must end in _RPCA)
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
    RPCA;
    HR;    % harmonic regression files (_hr, from bools.harmonic_reg)

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
    section_vars;     % "time avg: section avg" plot: number of y sections
    section_count;    %   the selected one (section_dropdown)
    section_force_vars; % forces it can break down (wake forces minus the omega_y lift terms)
    section_dropdown;
    frozen_vars;      % "frozen flow" plot: slab dw/dx vs (1/U) dw/dt
    frozen_label_dict;
    frozen_clims;
    frozen_clim_dict;

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
    iso_sign_button;   % "+/-": flips the Q isovalue slider to negative values
    iso_value_label;   % "Q isovalue:" label above the slider
    
    % 3D plot settings
    plot_hold_bool;
    iso_val;
    iso_neg;           % true: Q isovalue slider uses negative values (shear dominated, Q < 0)
    iso_var;
    iso_var_list;
    mirror_bool;
    filter_bool;
    trim_bool;
    num_cycles;
    % 3D plot x-axis in convective units (x/c = U t / c) instead of t/T
    conv_units_bool;
    % x/c per unit of t/T on the current 3D plot (U / (f L) * (N-1)/N),
    % used to switch the x-axis units without redrawing
    conv_scale;
    % shift the 3D plot's phase by the wake's convection time from the
    % robot to the imaging plane, so all cases start at the same wing phase
    conv_shift;
    % with conv_shift, shift the 3D plot further so the upstroke is
    % centred instead of the downstroke ("+/-" button, see
    % get_stroke_flip_bins)
    stroke_flip;
    % inputs of the last 3D plot, so "+/-" can shift the surface without a
    % full redraw (see shift_3D_surface); ext = cached surface over one
    % extra wingbeat, built on the first "+/-" press
    surf_3D;
    % processed iso variable (Q) and isosurface of the last 3D plot, with
    % the settings they depend on (key), so changing only the colour
    % variable doesn't reload Q or recompute the isosurface
    geom_3D;
    % mark stroke reversals on the 3D plot (2D views showing the x-axis)
    label_stroke;
    % stroke reversals for the current 3D plot, [] if unavailable:
    % top / bottom (bin, 1-based, conv-shifted frame), N (bins),
    % frame_shift (bins the plot is shifted by on top of the conv shift)
    stroke_3D;
    extrapolate_bool;
    floor_bool;
    thresh;
    q_mask_bool;
    q_mask_thresh;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = flowField_UI(file_path)
        obj.case_name = "";
        obj.variable_name = "";
        obj.phase_avg_file_path = file_path + "Processed Results\phase_avg\";
        obj.time_avg_file_path = file_path + "Processed Results\time_avg\";
        obj.phase_avg_RPCA_file_path = obj.phase_avg_file_path + "RPCA\";
        obj.file_path = obj.phase_avg_file_path;
        obj.source_modes = strings(0);
        obj.source_mode = "";
        obj.RPCA = false;
        obj.HR = false;

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;

        obj.plot_types = ["time avg of phase avg","phase avg: movie", "time avg of phase std","phase std: movie", "phase avg: 3D plot",...
            "image wingbeat phase", "wingbeat frequency","wake forces","phase avg: planar avg",...
            "time avg: section avg", "frozen flow"];
        obj.plot_type = obj.plot_types(1);
        obj.plot_hold_bool = false;
        obj.iso_var_list = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                            "Q_x","Q_y","Q_z","|Q|", "helicity",...
                            "du/dx","du/dy","du/dz","dv/dx","dv/dy",...
                            "dv/dz","dw/dx","dw/dy","dw/dz",...
                            "<Qx> inst", "<Qy> inst", "<Qz> inst", "<Q> inst"];
        obj.iso_var = "|Q|";
        obj.iso_val = obj.Q_ISO_DEFAULT;
        obj.iso_neg = false;
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.num_cycles = 1;
        obj.conv_units_bool = false;
        obj.conv_scale = [];
        obj.conv_shift = false;
        obj.stroke_flip = false;
        obj.surf_3D = [];
        obj.geom_3D = [];
        obj.label_stroke = false;
        obj.stroke_3D = [];
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

        % RPCA phase averages may also live in a phase_avg\RPCA\ subfolder.
        % Only files named *_RPCA_phase_avg.mat are used as RPCA cases.
        obj.phase_avg_main_case_ids = phase_avg_stems;
        rpca_files = dir(obj.phase_avg_RPCA_file_path + "*.mat");
        obj.phase_avg_RPCA_case_ids = obj.get_file_stems(rpca_files, "_RPCA_phase_avg") + "_RPCA";
        phase_avg_stems = unique([phase_avg_stems, obj.phase_avg_RPCA_case_ids], 'stable');
        obj.phase_avg_case_ids = phase_avg_stems;
        obj.time_avg_case_ids = time_avg_stems;

        % _hr / _RPCA cases are picked with the HR / RPCA buttons, so they
        % aren't listed separately
        phase_avg_display_stems = unique(obj.strip_variant_suffix(phase_avg_stems), 'stable');
        time_avg_display_stems = unique(obj.strip_variant_suffix(time_avg_stems), 'stable');

        turbine_stems = phase_avg_display_stems(contains(phase_avg_display_stems, "turbine"));
        flapper_stems = phase_avg_display_stems(~contains(phase_avg_display_stems, "turbine"));
        time_turbine_stems = time_avg_display_stems(contains(time_avg_display_stems, "turbine"));
        time_flapper_stems = time_avg_display_stems(~contains(time_avg_display_stems, "turbine"));

        old_flapper_stems = obj.get_old_flapper_stems(flapper_stems);
        new_flapper_stems = obj.get_new_flapper_stems(flapper_stems);
        time_old_flapper_stems = obj.get_old_flapper_stems(time_flapper_stems);
        time_new_flapper_stems = obj.get_new_flapper_stems(time_flapper_stems);
        obj.phase_old_flapper_stems = old_flapper_stems;
        obj.phase_new_flapper_stems = new_flapper_stems;
        obj.time_old_flapper_stems = time_old_flapper_stems;
        obj.time_new_flapper_stems = time_new_flapper_stems;

        [obj.old_flapper_downstream_types, obj.old_flapper_distance_labels] = ...
            obj.get_available_downstream_options([old_flapper_stems, time_old_flapper_stems], obj.OLD_FLAPPER_SOURCE_MODE);
        obj.old_flapper_downstream_type_by_distance = ...
            obj.build_downstream_type_map(obj.old_flapper_distance_labels, obj.old_flapper_downstream_types);
        [obj.new_flapper_downstream_types, obj.new_flapper_distance_labels] = ...
            obj.get_available_downstream_options([new_flapper_stems, time_new_flapper_stems], obj.NEW_FLAPPER_SOURCE_MODE);
        obj.new_flapper_downstream_type_by_distance = ...
            obj.build_downstream_type_map(obj.new_flapper_distance_labels, obj.new_flapper_downstream_types);

        obj.phase_old_flapper_case_name_list = obj.get_flapper_case_names(...
            old_flapper_stems, obj.old_flapper_downstream_types, ...
            obj.old_flapper_distance_labels, obj.OLD_FLAPPER_SOURCE_MODE);
        obj.phase_new_flapper_case_name_list = obj.get_flapper_case_names(...
            new_flapper_stems, obj.new_flapper_downstream_types, ...
            obj.new_flapper_distance_labels, obj.NEW_FLAPPER_SOURCE_MODE);
        obj.phase_flapper_case_name_list = unique([obj.phase_old_flapper_case_name_list, obj.phase_new_flapper_case_name_list], 'stable');
        obj.phase_turbine_case_name_list = obj.get_turbine_case_names(turbine_stems);
        obj.time_old_flapper_case_name_list = obj.get_flapper_case_names(...
            time_old_flapper_stems, obj.old_flapper_downstream_types, ...
            obj.old_flapper_distance_labels, obj.OLD_FLAPPER_SOURCE_MODE);
        obj.time_new_flapper_case_name_list = obj.get_flapper_case_names(...
            time_new_flapper_stems, obj.new_flapper_downstream_types, ...
            obj.new_flapper_distance_labels, obj.NEW_FLAPPER_SOURCE_MODE);
        obj.time_flapper_case_name_list = unique([obj.time_old_flapper_case_name_list, obj.time_new_flapper_case_name_list], 'stable');
        obj.time_turbine_case_name_list = obj.get_turbine_case_names(time_turbine_stems);
        obj.source_modes = obj.get_available_source_modes();
        if isempty(obj.source_modes)
            error("No STB average files found. Expected *_phase_avg.mat files in %s or *_time_avg.mat files in %s.", obj.phase_avg_file_path, obj.time_avg_file_path)
        end
        obj.source_mode = obj.source_modes(1);
        obj.set_downstream_options_for_source_mode(obj.source_mode);
        obj.set_trim_settings_for_source_mode(obj.source_mode);
        obj.case_name_list = obj.get_case_name_list_for_active_plot_type();
        obj.flapper_case_name_list = unique([...
            obj.get_case_name_list(obj.OLD_FLAPPER_SOURCE_MODE, obj.plot_type), ...
            obj.get_case_name_list(obj.NEW_FLAPPER_SOURCE_MODE, obj.plot_type)], 'stable');
        obj.turbine_case_name_list = obj.get_case_name_list(obj.TURBINE_SOURCE_MODE, obj.plot_type);

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
        % divergence std: per-frame divergence std saved in the main file
        % by phase_avg_STB (bools.div_std = true)
        movie_3D_std_values(obj.movie_3D_std_vars == "div") = "div_phase_std";

        % Derived variables (computed in update_plot, not loaded directly).
        % Appended after the std list is built since they have no std field.
        obj.movie_3D_avg_vars(end+1) = obj.LIFT_WX_VAR;
        movie_3D_avg_values(end+1) = obj.LIFT_WX_FIELD;
        time_avg_values(end+1) = obj.LIFT_WX_FIELD;
        % Q computed per frame, then averaged (saved in the main
        % phase / time average files by phase_avg_STB / time_avg_STB)
        % (names avoid "Q_x" etc. so they load from the main file, not
        % the _integral file like the secondary_vars)
        obj.movie_3D_avg_vars = [obj.movie_3D_avg_vars, "<Qx> inst", "<Qy> inst", "<Qz> inst", "<Q> inst"];
        movie_3D_avg_values = [movie_3D_avg_values, "Qx_inst_avg", "Qy_inst_avg", "Qz_inst_avg", "Q_inst_avg"];
        time_avg_values = [time_avg_values, "Qx_inst_avg", "Qy_inst_avg", "Qz_inst_avg", "Q_inst_avg"];
        % frame-to-frame standard deviation of that Q within each bin
        % (phase_avg_STB with bools.Q_inst = true)
        obj.movie_3D_std_vars = [obj.movie_3D_std_vars, "<Qx> inst", "<Qy> inst", "<Qz> inst", "<Q> inst"];
        movie_3D_std_values = [movie_3D_std_values, "Qx_inst_std", "Qy_inst_std", "Qz_inst_std", "Q_inst_std"];
        % ["u_phase_std","v_phase_std","w_phase_std","Utot_phase_std",...
        % "vortX_phase_std","vortY_phase_std","vortZ_phase_std","vortTot_phase_std",...
        % "uncU_phase_std","uncV_phase_std","uncW_phase_std","uncTot_phase_std","hel_phase_std", "numP_phase_std"];

        % "phase variability": range of phase within each bin as % of the
        % bin width (bin_std from findBestNumBins2, see frame_to_bin)
        % "bin placement": centroid of the frames in each bin minus the bin
        % centre, % of bin width (+ = late in bin)
        obj.hist_vars = ["bin counts","phase variability","distribution","bin placement"];
        hist_vals = ["bin_count", "bin_phase_var","tick_frame_pos","bin_placement"];
        hist_labels = ["Number of frames per bin", "Phase variability per bin (% bin width)",...
            "Number of frames per tick", "Centroid offset from bin centre (% bin width)"];

        obj.freq_vars = ["frequency","bin counts", "bin SD"];
        freq_vals = ["phase_avg_speed", "bin_count_speed", "bin_std_speed"];
        freq_labels = ["Wingbeat Frequency (Hz)", "Number of samples per bin", "Phase variability per bin (% cycle)"];

        % Vorticity-based estimates come back from get_wake_lift as a
        % struct of terms, so each entry names the field to plot
        % (get_PIV_force resolves the dotted path).
        obj.force_vars = ["lift_vort", "lift_vort: ω_x term", "lift_vort: ω_y term", "lift_vort: ω_y term (edge)", "lift_vort: ω_x term (taper)", "lift_vort: vel diff term", ...
            "lift_vel", ...
            "drag_vort", "drag_vort: ω_y term", "drag_vort: ω_z term", "drag_vort: bernoulli term", ...
            "drag_vel"];
        force_vals = ["lift.tot", "lift.vortX", "lift.vortY", "lift.vortY_edge", "lift.vortX_taper", "lift.vel_diff", ...
            "lift_vel", ...
            "drag.tot", "drag.vortY", "drag.vortZ", "drag.bernoulli", ...
            "drag_vel"];
        force_labels = ["Lift (N)", "Lift, ω_x term (N)", "Lift, ω_y term (N)", "Lift, ω_y term, with edge terms (N)", "Lift, ω_x term, tapered (N)", "Lift, vel diff term (N)", ...
            "Lift (N)", ...
            "Drag (N)", "Drag, ω_y term (N)", "Drag, ω_z term (N)", "Drag, bernoulli term (N)", ...
            "Drag (N)"];

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
                      0, 0.04;...
                      0, 0.04;...
                      0, 0.04;...
                      0, 0.04;...
                      0, 0.01;...
                      0, 0.01;...
                      0, 0.01;...
                      0, 0.005;...
                      0, 0.005;...
                      0, 0.005;...
                      -1, 1;...
                      0, 150;
                      -0.1, 0.1;
                      -1, 1;
                      -1, 1;
                      -0.2, 0.2;
                      -1, 1;
                      -1, 1;
                      -0.2, 0.2;
                      -1, 1;
                      -1, 1;
                      -0.1, 0.1;
                      0, 0.1;
                      0, 0.1;
                      -20, 20;... % lift (U y ω_x), dimensional (m^2/s^2)
                      0, 0.1;...  % <Qx> inst
                      0, 0.1;...  % <Qy> inst
                      0, 0.1;...  % <Qz> inst
                      0, 0.1];    % <Q> inst

        % for std plots
        obj.std_clims = [0, 0.05;...
                     0, 0.05;...
                      0, 0.05;...
                      0, 0.05;...
                      0, 0.5;...
                      0, 0.5;...
                      0, 0.5;...
                      0, 0.5;...
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
                      0, 1;
                      0, 0.1;
                      0, 0.1;
                      0, 0.1;...  % σ(Qx) inst
                      0, 0.1;...  % σ(Qy) inst
                      0, 0.1;...  % σ(Qz) inst
                      0, 0.1];    % σ(Q) inst

        obj.mean_clim_dict = obj.build_clim_dict(obj.movie_3D_avg_vars, obj.mean_clims);
        obj.std_clim_dict = obj.build_clim_dict(obj.movie_3D_std_vars, obj.std_clims);
        obj.clims = obj.mean_clims;
        obj.clim_dict = obj.mean_clim_dict;
        obj.clim_scale = 2;
        movie_3D_avg_labels = ["\boldmath$\frac{u}{U_{\infty}}$",...
                            "\boldmath$\frac{v}{U_{\infty}}$",...
                            "\boldmath$\frac{w}{U_{\infty}}$",...
                            "\boldmath$\frac{U}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_x c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_y c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_z c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega c}{U_{\infty}}$",...
                            "","","","",...
                            "\boldmath$\frac{u}{U_{\infty}}$",...
                            "\boldmath$\frac{v}{U_{\infty}}$",...
                            "\boldmath$\frac{w}{U_{\infty}}$",...
                            "\boldmath$\frac{U}{U_{\infty}}$",...
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
        movie_3D_std_labels = [movie_3D_std_labels,...
            "\boldmath$\sigma_{Q_x} \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\sigma_{Q_y} \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\sigma_{Q_z} \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\sigma_{Q} \frac{c^2}{U_{\infty}^2}$"];
        movie_3D_avg_labels(end+1) = "\boldmath$U_{\infty}\, y\, \omega_x \; (\mathrm{m^2/s^2})$";
        movie_3D_avg_labels = [movie_3D_avg_labels,...
            "\boldmath$\langle Q_x \rangle \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\langle Q_y \rangle \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\langle Q_z \rangle \frac{c^2}{U_{\infty}^2}$",...
            "\boldmath$\langle Q \rangle \frac{c^2}{U_{\infty}^2}$"];

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

        % Frozen-flow check of the slab-normal derivative (centre plane):
        % movies of each estimate, then pointwise rms ratio / correlation
        % over the wingbeat. All nondimensional like dwdx_phase_avg.
        obj.frozen_vars = ["dw/dx (slab)", "(1/U) dw/dt", "rms ratio", "correlation over phase"];
        obj.section_vars = ["5 sections", "3 sections", "10 sections", "20 sections", "every column"];
        obj.section_count = obj.section_vars(1);
        frozen_labels = ["\boldmath$\frac{\partial w}{\partial x}\frac{c}{U_{\infty}}$", ...
            "\boldmath$\frac{1}{U}\frac{\partial w}{\partial t}\frac{c}{U_{\infty}}$", ...
            "\boldmath$\frac{\mathrm{rms}(\partial_x w)}{\mathrm{rms}(\partial_t w / U)}$", ...
            "\boldmath$\rho$"];
        obj.frozen_clims = [-0.2 0.2; -0.2 0.2; 0 1.5; -1 1];
        obj.frozen_label_dict = containers.Map(cellstr(obj.frozen_vars), frozen_labels);
        obj.frozen_clim_dict = obj.build_clim_dict(obj.frozen_vars, obj.frozen_clims);

        force_keys = cellstr(obj.force_vars);
        obj.force_var_name_dict = containers.Map(force_keys, force_vals);
        % the omega_y lift terms are time integrals of a rate, not plane
        % integrals, so they can't be split across the plane
        obj.section_force_vars = obj.force_vars(~ismember(force_vals, ["lift.vortY", "lift.vortY_edge"]));
        obj.force_label_dict = containers.Map(force_keys, force_labels);

        keys_B = cellstr(movie_3D_avg_values(1:3));
        vals_B = ["velX_B", "velY_B", "velZ_B"];
        obj.dict_B = containers.Map(keys_B, vals_B);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        pause(1.8) % wait until GUI opened
        % Create a GUI figure with layout managers so controls stay
        % reachable as the window or monitor size changes.
        [option_panel, plot_panel, ~] = setupFig();
        option_panel.AutoResizeChildren = true;
        if isprop(option_panel, "Scrollable")
            option_panel.Scrollable = "on";
        end
        pause(1) % wait until GUI opened

        sidebar_grid = uigridlayout(option_panel, [17, 1]);
        sidebar_grid.ColumnWidth = {'1x'};
        sidebar_grid.RowHeight = {30, 30, 30, 30, 30, 30, 35, 30, 30, 30, 30, 30, 30, 30, 30, 0, 30};
        sidebar_grid.Padding = [10 10 10 10];
        sidebar_grid.RowSpacing = 6;
        if isprop(sidebar_grid, "Scrollable")
            sidebar_grid.Scrollable = "on";
        end

        plot_grid = uigridlayout(plot_panel, [3, 1]);
        plot_grid.ColumnWidth = {'1x'};
        plot_grid.RowHeight = {'1x', 45, 40};
        plot_grid.Padding = [10 10 10 10];
        plot_grid.RowSpacing = 6;

        plot_area_panel = uipanel(plot_grid);
        plot_area_panel.Layout.Row = 1;
        plot_area_panel.Layout.Column = 1;
        plot_area_panel.BorderType = "none";

        source_dropdown = uidropdown(sidebar_grid);
        source_dropdown.Layout.Row = 1;
        source_dropdown.Layout.Column = 1;
        source_dropdown.Items = obj.source_modes;
        source_dropdown.Value = obj.source_mode;
        source_dropdown.ValueChangedFcn = @(src, event) source_change(src, event, plot_area_panel);

        % Dropdown box for which cases axes to display
        distance_dropdown = uidropdown(sidebar_grid);
        distance_dropdown.Layout.Row = 2;
        distance_dropdown.Layout.Column = 1;
        distance_dropdown.ValueChangedFcn = @(src, event) distance_change(src, event, plot_area_panel);
        refresh_distance_dropdown();

        case_dropdown = uidropdown(sidebar_grid);
        case_dropdown.Layout.Row = 3;
        case_dropdown.Layout.Column = 1;
        case_dropdown.Items = obj.case_name_list;
        obj.case_name = string(case_dropdown.Value); % use current value in box
        case_dropdown.ValueChangedFcn = @(src, event) case_change(src, event, plot_area_panel);

        % RPCA and HR (harmonic regression) buttons share a row
        variant_grid = uigridlayout(sidebar_grid, [1, 2]);
        variant_grid.Layout.Row = 4;
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
        rpca_button.ValueChangedFcn = @(src, event) RPCA_change(src, event, plot_area_panel);

        hr_button = uibutton(variant_grid, "state");
        hr_button.Layout.Row = 1;
        hr_button.Layout.Column = 2;
        hr_button.Text = "HR";
        hr_button.FontSize = 18;
        hr_button.Tooltip = "Harmonic regression files (_hr)";
        hr_button.BackgroundColor = obj.get_button_color(obj.HR);
        hr_button.ValueChangedFcn = @(src, event) HR_change(src, event, plot_area_panel);

        plot_type_dropdown = uidropdown(sidebar_grid);
        plot_type_dropdown.Layout.Row = 5;
        plot_type_dropdown.Layout.Column = 1;
        plot_type_dropdown.Items = obj.get_available_plot_types_for_current_case();
        obj.plot_type = plot_type_dropdown.Value; % use current value in box
        plot_type_dropdown.ValueChangedFcn = @(src, event) type_change(src, event, plot_area_panel);

        % Dropdown box for which variables to display
        obj.var_dropdown = uidropdown(sidebar_grid);
        obj.var_dropdown.Layout.Row = 6;
        obj.var_dropdown.Layout.Column = 1;
        obj.var_dropdown.Items = obj.var_name_list;
        obj.variable_name = obj.var_dropdown.Value; % use current value in box
        obj.var_dropdown.ValueChangedFcn = @(src, event) variable_change(src, event, plot_area_panel);

        obj.clim_slider = uislider(sidebar_grid, "range");
        obj.clim_slider.Layout.Row = 7;
        obj.clim_slider.Layout.Column = 1;
        clim_center = mean(obj.clims(1,:));
        clim_range = (obj.clim_scale/2)*diff(obj.clims(1,:));
        obj.clim_slider.Limits = [clim_center - clim_range, clim_center + clim_range];
        obj.clim_slider.Value = obj.clims(1,:);
        obj.clim_slider.ValueChangedFcn = @(src, event) clim_change(src, event, plot_area_panel);

        % Number of y sections for "time avg: section avg" (shares the
        % colour-limit slider's row; only one of them is shown)
        obj.section_dropdown = uidropdown(sidebar_grid);
        obj.section_dropdown.Layout.Row = 7;
        obj.section_dropdown.Layout.Column = 1;
        obj.section_dropdown.Items = obj.section_vars;
        obj.section_dropdown.Value = obj.section_count;
        obj.section_dropdown.Visible = "off";
        obj.section_dropdown.ValueChangedFcn = @(src, event) section_count_change(src, event, plot_area_panel);

        trim_button = uibutton(sidebar_grid, "state");
        trim_button.Layout.Row = 8;
        trim_button.Layout.Column = 1;
        trim_button.Value = true;
        trim_button.Text = "Trim";
        trim_button.FontSize = 18;
        trim_button.BackgroundColor = obj.ACTIVE_COLOR;
        trim_button.ValueChangedFcn = @(src, event) trim_change(src, event, plot_area_panel);

        mirror_button = uibutton(sidebar_grid, "state");
        mirror_button.Layout.Row = 9;
        mirror_button.Layout.Column = 1;
        mirror_button.Text = "Mirror";
        mirror_button.FontSize = 18;
        mirror_button.BackgroundColor = obj.INACTIVE_COLOR;
        mirror_button.ValueChangedFcn = @(src, event) mirror_change(src, event, plot_area_panel);

        filter_button = uibutton(sidebar_grid, "state");
        filter_button.Layout.Row = 10;
        filter_button.Layout.Column = 1;
        filter_button.Text = "Filter";
        filter_button.FontSize = 18;
        filter_button.BackgroundColor = obj.INACTIVE_COLOR;
        filter_button.ValueChangedFcn = @(src, event) filter_change(src, event, plot_area_panel);

        extrapolate_button = uibutton(sidebar_grid, "state");
        extrapolate_button.Layout.Row = 11;
        extrapolate_button.Layout.Column = 1;
        extrapolate_button.Text = "Extrapolate";
        extrapolate_button.FontSize = 18;
        extrapolate_button.BackgroundColor = obj.INACTIVE_COLOR;
        extrapolate_button.ValueChangedFcn = @(src, event) extrapolate_change(src, event, plot_area_panel);
        % Extrapolate forces mirroring (helm_decomp mirrors the wake), so
        % the Mirror button is switched on and locked while it is active.
        % This remembers what Mirror was before, to restore it afterwards.
        mirror_before_extrapolate = obj.mirror_bool;

        floor_button = uibutton(sidebar_grid, "state");
        floor_button.Layout.Row = 12;
        floor_button.Layout.Column = 1;
        floor_button.Text = "Noise Floor";
        floor_button.FontSize = 18;
        floor_button.BackgroundColor = obj.INACTIVE_COLOR;
        floor_button.ValueChangedFcn = @(src, event) floor_change(src, event, plot_area_panel);

        floor_field = uieditfield(sidebar_grid, 'numeric');
        floor_field.Layout.Row = 13;
        floor_field.Layout.Column = 1;
        floor_field.Value = obj.thresh;
        floor_field.ValueChangedFcn = @(src, event) thresh_change(src, event, plot_area_panel);

        q_mask_button = uibutton(sidebar_grid, "state");
        q_mask_button.Layout.Row = 14;
        q_mask_button.Layout.Column = 1;
        q_mask_button.Text = "Q-mask";
        q_mask_button.FontSize = 18;
        q_mask_button.BackgroundColor = obj.INACTIVE_COLOR;
        q_mask_button.ValueChangedFcn = @(src, event) q_mask_change(src, event, plot_area_panel);

        q_mask_field = uieditfield(sidebar_grid, 'numeric');
        q_mask_field.Layout.Row = 15;
        q_mask_field.Layout.Column = 1;
        q_mask_field.Value = obj.q_mask_thresh;
        q_mask_field.ValueChangedFcn = @(src, event) q_mask_thresh_change(src, event, plot_area_panel);

        obj.slider = uislider(plot_grid);
        obj.slider.Layout.Row = 2;
        obj.slider.Layout.Column = 1;
        obj.slider.Limits = [1 obj.num_bins];
        obj.slider.Value = obj.frame_ind;
        obj.slider.MajorTicks = 1:5:obj.num_bins;
        obj.slider.MinorTicks = 1:obj.num_bins;
        obj.slider.ValueChangedFcn = @(src, event) frame_change(src, event, plot_area_panel);

        obj.play_button = uibutton(plot_grid, "state");
        obj.play_button.Layout.Row = 3;
        obj.play_button.Layout.Column = 1;
        obj.play_button.Text = "Play";
        obj.play_button.FontSize = 18;
        obj.play_button.BackgroundColor = obj.INACTIVE_COLOR;
        obj.play_button.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_area_panel);

        obj.param_panel = uipanel(sidebar_grid);
        obj.param_panel.Layout.Row = 16;
        obj.param_panel.Layout.Column = 1;
        obj.param_panel.Visible = "off";
        obj.param_panel.Title = "3D Plot Parameters";
        obj.param_panel.TitlePosition = 'centertop';

        param_grid = uigridlayout(obj.param_panel, [11, 1]);
        param_grid.ColumnWidth = {'1x'};
        param_grid.RowHeight = {22, 55, 30, 22, 55, 30, 30, 30, 50, 18, 24};
        param_grid.Padding = [10 8 10 8];
        param_grid.RowSpacing = 6;

        % Label with a "+/-" button beside it that flips the Q isovalue
        % slider between positive (vortex cores, Q > 0) and negative
        % (strain/shear dominated, Q < 0) values over the same range
        iso_header_grid = uigridlayout(param_grid, [1, 2]);
        iso_header_grid.Layout.Row = 1;
        iso_header_grid.Layout.Column = 1;
        iso_header_grid.ColumnWidth = {'1x', 44};
        iso_header_grid.RowHeight = {'1x'};
        iso_header_grid.Padding = [0 0 0 0];
        iso_header_grid.ColumnSpacing = 4;

        obj.iso_value_label = uilabel(iso_header_grid);
        obj.iso_value_label.Layout.Row = 1;
        obj.iso_value_label.Layout.Column = 1;
        obj.iso_value_label.HorizontalAlignment = 'center';
        obj.iso_value_label.Text = 'Q isovalue:';

        obj.iso_sign_button = uibutton(iso_header_grid, "state");
        obj.iso_sign_button.Layout.Row = 1;
        obj.iso_sign_button.Layout.Column = 2;
        obj.iso_sign_button.Text = "+/-";
        obj.iso_sign_button.Value = obj.iso_neg;
        obj.iso_sign_button.BackgroundColor = obj.get_button_color(obj.iso_neg);
        obj.iso_sign_button.Tooltip = "Flip the Q isovalue to negative values (Q < 0: strain/shear dominated flow)";
        obj.iso_sign_button.ValueChangedFcn = @(src, event) iso_sign_change(src, event, plot_area_panel);

        obj.iso_slider = uislider(param_grid);
        obj.iso_slider.Layout.Row = 2;
        obj.iso_slider.Layout.Column = 1;
        obj.iso_slider.ValueChangedFcn = @(src, event) iso_change(src, event, plot_area_panel);
        obj.set_Q_iso_slider(false);

        % Dropdown box for which variables to display
        iso_var_dropdown = uidropdown(param_grid);
        iso_var_dropdown.Layout.Row = 3;
        iso_var_dropdown.Layout.Column = 1;
        iso_var_dropdown.Items = obj.iso_var_list;
        iso_var_dropdown.Value = obj.iso_var;
        iso_var_dropdown.ValueChangedFcn = @(src, event) iso_var_change(src, event, plot_area_panel);

        l2 = uilabel(param_grid);
        l2.Layout.Row = 4;
        l2.Layout.Column = 1;
        l2.HorizontalAlignment = 'center';
        l2.Text = 'Number of Wingbeats';

        num_cycles_slider = uislider(param_grid);
        num_cycles_slider.Layout.Row = 5;
        num_cycles_slider.Layout.Column = 1;
        num_cycles_slider.Limits = [1 5];
        num_cycles_slider.Value = obj.num_cycles;
        num_cycles_slider.MajorTicks = 1:5;
        num_cycles_slider.MinorTicks = [];
        num_cycles_slider.ValueChangedFcn = @(src, event) num_cycles_change(src, event, plot_area_panel);

        % x-axis as wingbeat time (t/T) or convective distance (x/c = U t / c)
        conv_units_button = uibutton(param_grid, "state");
        conv_units_button.Layout.Row = 6;
        conv_units_button.Layout.Column = 1;
        conv_units_button.Text = "x-axis: t/T";
        conv_units_button.FontSize = 16;
        conv_units_button.Value = obj.conv_units_bool;
        conv_units_button.BackgroundColor = obj.INACTIVE_COLOR;
        conv_units_button.Tooltip = "Toggle the 3D plot x-axis between wingbeat time t/T and convective units x/c = U t / c";
        conv_units_button.ValueChangedFcn = @(src, event) conv_units_change(src, event, plot_area_panel);

        % Phase shift by the convection time from the robot to the imaging
        % plane (same as phaseAvg_UI's Convection Shift button), and next
        % to it "+/-": a further half wingbeat, so the upstroke is centred
        % instead of the downstroke
        conv_shift_grid = uigridlayout(param_grid, [1, 2]);
        conv_shift_grid.Layout.Row = 7;
        conv_shift_grid.Layout.Column = 1;
        conv_shift_grid.ColumnWidth = {'1x', 32};
        conv_shift_grid.RowHeight = {'1x'};
        conv_shift_grid.Padding = [0 0 0 0];
        conv_shift_grid.ColumnSpacing = 4;

        conv_shift_button = uibutton(conv_shift_grid, "state");
        conv_shift_button.Layout.Row = 1;
        conv_shift_button.Layout.Column = 1;
        conv_shift_button.Text = "Convection Shift";
        conv_shift_button.FontSize = 12;
        conv_shift_button.Value = obj.conv_shift;
        conv_shift_button.BackgroundColor = obj.get_button_color(obj.conv_shift);
        conv_shift_button.Tooltip = "Phase shift the 3D plot by the convection time from the robot to the imaging plane, so cases at different frequencies start at the same wing phase";
        conv_shift_button.ValueChangedFcn = @(src, event) conv_shift_change(src, event, plot_area_panel);

        stroke_flip_button = uibutton(conv_shift_grid, "state");
        stroke_flip_button.Layout.Row = 1;
        stroke_flip_button.Layout.Column = 2;
        stroke_flip_button.Text = "+/-";
        stroke_flip_button.FontSize = 12;
        stroke_flip_button.Value = obj.stroke_flip;
        stroke_flip_button.Enable = obj.conv_shift;
        stroke_flip_button.BackgroundColor = obj.get_button_color(obj.stroke_flip);
        stroke_flip_button.Tooltip = "Off: downstroke centred. On: shifted so the upstroke is centred instead (shift from the stroke reversals in the wing position, since the strokes differ in length). Requires Convection Shift";
        stroke_flip_button.ValueChangedFcn = @(src, event) stroke_flip_change(src, event, plot_area_panel);

        % Stroke reversal lines, downstroke shading and up/downstroke
        % labels; drawn only in the 2D views that show the x-axis
        % (+/-yz, +/-xz). Needs the convection shift, like phaseAvg_UI.
        label_stroke_button = uibutton(param_grid, "state");
        label_stroke_button.Layout.Row = 8;
        label_stroke_button.Layout.Column = 1;
        label_stroke_button.Text = "Label Stroke";
        label_stroke_button.FontSize = 16;
        label_stroke_button.Value = obj.label_stroke;
        label_stroke_button.Enable = obj.conv_shift;
        label_stroke_button.BackgroundColor = obj.get_button_color(obj.label_stroke);
        label_stroke_button.Tooltip = "Mark stroke reversals (from the phase-averaged wing position) and label upstroke / downstroke in the +/-yz and +/-xz views. Requires Convection Shift";
        label_stroke_button.ValueChangedFcn = @(src, event) label_stroke_change(src, event, plot_area_panel);

        % View buttons rotate the current 3D axes without redrawing data.
        view_grid = uigridlayout(param_grid, [2, 3]);
        view_grid.Layout.Row = 9;
        view_grid.Layout.Column = 1;
        view_grid.RowHeight = {'1x', '1x'};
        view_grid.ColumnWidth = {'1x', '1x', '1x'};
        view_grid.Padding = [0 0 0 0];
        view_grid.RowSpacing = 4;
        view_grid.ColumnSpacing = 4;

        view_labels = ["+xy", "+yz", "+xz"; "-xy", "-yz", "-xz"];
        for view_row = 1:2
            for view_col = 1:3
                view_button = uibutton(view_grid);
                view_button.Layout.Row = view_row;
                view_button.Layout.Column = view_col;
                view_button.Text = view_labels(view_row, view_col);
                view_button.BackgroundColor = obj.INACTIVE_COLOR;
                view_button.ButtonPushedFcn = @(src, event) view_change_handler(src.Text, plot_area_panel);
            end
        end

        % Isometric views from above: camera along (+/-1, +/-1, 1); button
        % text is the sign of the camera's x, y, z.
        iso_label = uilabel(param_grid);
        iso_label.Layout.Row = 10;
        iso_label.Layout.Column = 1;
        iso_label.HorizontalAlignment = 'center';
        iso_label.Text = 'Iso views';

        iso_grid = uigridlayout(param_grid, [1, 4]);
        iso_grid.Layout.Row = 11;
        iso_grid.Layout.Column = 1;
        iso_grid.RowHeight = {'1x'};
        iso_grid.ColumnWidth = {'1x', '1x', '1x', '1x'};
        iso_grid.Padding = [0 0 0 0];
        iso_grid.RowSpacing = 4;
        iso_grid.ColumnSpacing = 4;

        iso_labels = ["+++", "-++", "--+", "+-+"];
        for iso_row = 1
            for iso_col = 1:4
                iso_button = uibutton(iso_grid);
                iso_button.Layout.Row = iso_row;
                iso_button.Layout.Column = iso_col;
                iso_button.Text = iso_labels(iso_row, iso_col);
                iso_button.BackgroundColor = obj.INACTIVE_COLOR;
                iso_button.Tooltip = "Isometric view, camera at (x, y, z) signs " + iso_labels(iso_row, iso_col);
                iso_button.ButtonPushedFcn = @(src, event) view_change_handler(src.Text, plot_area_panel);
            end
        end

        save_button = uibutton(sidebar_grid, "state");
        save_button.Layout.Row = 17;
        save_button.Layout.Column = 1;
        save_button.Text = "Save Figure";
        save_button.FontSize = 18;
        save_button.BackgroundColor = obj.INACTIVE_COLOR;
        save_button.ValueChangedFcn = @(src, event) save_figure(src, event, plot_area_panel);

        % Set up plot titles and axes
        set_param_panel_visibility(strcmp(obj.plot_type, obj.plot_types(5)));
        obj.set_section_controls();
        obj.update_plot(plot_area_panel);

        % Callbacks are nested so each handler mutates this handle object.

        function source_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.source_mode = src.Value;
            obj.set_trim_settings_for_source_mode(obj.source_mode);
            refresh_distance_dropdown();

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
            obj.current_downstream_type = string(obj.downstream_type_by_distance(char(src.Value)));
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

        function RPCA_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.RPCA = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.RPCA);

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        function HR_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            obj.HR = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.HR);

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

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

        function refresh_distance_dropdown()
            obj.set_downstream_options_for_source_mode(obj.source_mode);
            if isempty(obj.distance_labels)
                distance_dropdown.Items = "No downstream data";
                distance_dropdown.Value = "No downstream data";
                distance_dropdown.Enable = "off";
            else
                distance_dropdown.Items = obj.distance_labels;
                distance_dropdown.Value = obj.distance_labels(1);
                distance_dropdown.Enable = "on";
                obj.current_downstream_type = string(obj.downstream_type_by_distance(char(distance_dropdown.Value)));
            end
            set_distance_dropdown_visibility();
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
            phase_avg_plots = obj.plot_types([1 2 5 9]);
            phase_std_plots = obj.plot_types([3 4]);
            same_phase_avg_family = ismember(previous_plot_type, phase_avg_plots) && ...
                ismember(obj.plot_type, phase_avg_plots);
            same_phase_std_family = ismember(previous_plot_type, phase_std_plots) && ...
                ismember(obj.plot_type, phase_std_plots);
            plot_family_changed = ~(same_phase_avg_family || same_phase_std_family);

            if plot_family_changed
                if ismember(obj.plot_type, phase_std_plots)
                    obj.var_name_list = obj.movie_3D_std_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(6))
                    obj.var_name_list = obj.hist_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(7))
                    obj.var_name_list = obj.freq_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(8))
                    obj.var_name_list = obj.force_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(10))
                    obj.var_name_list = obj.section_force_vars;
                elseif strcmp(obj.plot_type, obj.plot_types(11))
                    obj.var_name_list = obj.frozen_vars;
                else
                    obj.var_name_list = obj.movie_3D_avg_vars;
                end
                obj.var_dropdown.Items = obj.var_name_list;
                obj.variable_name = obj.var_dropdown.Value;
            end

            obj.set_active_color_limit_set();
            obj.update_color_limit_slider();

            set_param_panel_visibility(strcmp(obj.plot_type, obj.plot_types(5)));
            obj.set_section_controls();
        end

        function section_count_change(src, ~, plot_panel)
            obj.section_count = string(src.Value);
            obj.update_plot(plot_panel);
        end

        function set_distance_dropdown_visibility()
            is_visible = obj.is_flapper_source_mode(obj.source_mode) && ~isempty(obj.distance_labels);
            row_heights = sidebar_grid.RowHeight;
            if is_visible
                distance_dropdown.Visible = "on";
                row_heights{2} = 30;
            else
                distance_dropdown.Visible = "off";
                row_heights{2} = 0;
            end
            sidebar_grid.RowHeight = row_heights;
        end

        function set_param_panel_visibility(is_visible)
            row_heights = sidebar_grid.RowHeight;
            if is_visible
                obj.param_panel.Visible = "on";
                row_heights{16} = 523;
            else
                obj.param_panel.Visible = "off";
                row_heights{16} = 0;
            end
            sidebar_grid.RowHeight = row_heights;
        end

        function clim_change(src, event, plot_panel)
            ticks = obj.clim_slider.MinorTicks;

            % ensure that slider snapped to minor tick value. Only the
            % thumb that moved is snapped, so dragging the upper limit
            % can't shift the lower one (e.g. off 0 when 0 isn't a tick).
            newMin = src.Value(1);
            newMax = src.Value(2);
            if ~isempty(ticks)
                if newMin ~= event.PreviousValue(1)
                    newMin = interp1(ticks, ticks, newMin, 'nearest', 'extrap');
                end
                if newMax ~= event.PreviousValue(2)
                    newMax = interp1(ticks, ticks, newMax, 'nearest', 'extrap');
                end
            end
            if newMin >= newMax
                newMin = event.PreviousValue(1);
                newMax = event.PreviousValue(2);
            end
            
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

        % "+/-": flip the Q isovalue between positive and negative values,
        % keeping its magnitude
        function iso_sign_change(src, ~, plot_panel)
            obj.iso_neg = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.iso_neg);
            obj.set_Q_iso_slider(true);
            obj.update_plot(plot_panel);
        end

        % User selected new desired isosurface variable for 3D plot
        function iso_var_change(src, ~, plot_panel)
            obj.iso_var = src.Value;

            % Q variants (Q_x, Q_y, Q_z, |Q|, <Q> inst ...) all use the
            % fixed Q range and default, in the current +/- sign
            if obj.is_Q_iso_var(obj.iso_var)
                obj.iso_sign_button.Enable = "on";
                obj.set_Q_iso_slider(false);
                obj.update_plot(plot_panel);
                return
            end

            % other variables: range from their colour limits, and the
            % +/- flip doesn't apply
            obj.iso_neg = false;
            obj.iso_sign_button.Value = false;
            obj.iso_sign_button.BackgroundColor = obj.get_button_color(false);
            obj.iso_sign_button.Enable = "off";
            obj.iso_value_label.Text = 'Isovalue:';

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

                % Extrapolation always mirrors the wake: show Mirror as on
                % and lock it until Extrapolate is turned off
                mirror_before_extrapolate = obj.mirror_bool;
                obj.mirror_bool = true;
                mirror_button.Value = true;
                mirror_button.BackgroundColor = obj.ACTIVE_COLOR;
                mirror_button.Enable = "off";
            else
                obj.extrapolate_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;

                % Give Mirror back to the user in the state it was in
                obj.mirror_bool = mirror_before_extrapolate;
                mirror_button.Value = mirror_before_extrapolate;
                mirror_button.BackgroundColor = obj.get_button_color(mirror_before_extrapolate);
                mirror_button.Enable = "on";
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

        function view_change_handler(selected_text, plot_panel)
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
                otherwise
                    % isometric: text is the sign of camera x, y, z
                    if strlength(selected_text) == 3 && all(ismember(char(selected_text), '+-'))
                        view(ax, 1 - 2 * (char(selected_text) == '-'))
                    end
            end

            % stroke labels only show in the views that show the x-axis
            obj.draw_stroke_labels_3D(ax);
        end

        function save_figure(~, ~, plot_panel)
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            cb = findobj(plot_panel.Children, 'Type', 'colorbar');

            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            % copyobj can't copy axes with two y axes (yyaxis, e.g. the
            % section avg plot), so those are rebuilt side by side
            is_yy = arrayfun(@(a) numel(a.YAxis) > 1, ax);
            if any(~is_yy) || ~isempty(cb)
                copyobj([ax(~is_yy); cb(:)], fignew);
            end
            for a = ax(is_yy)'
                obj.copy_yyaxis_axes(a, fignew);
            end
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

        function conv_units_change(src, ~, plot_panel)
            obj.conv_units_bool = src.Value;
            if obj.conv_units_bool
                src.Text = "x-axis: x/c = U t / c";
                src.BackgroundColor = obj.ACTIVE_COLOR;
            else
                src.Text = "x-axis: t/T";
                src.BackgroundColor = obj.INACTIVE_COLOR;
            end

            % The two axes differ only by a constant factor, so rescale the
            % existing isosurface in place (keeps the current view and
            % avoids reloading the data). Redraw only if there's no 3D plot.
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            p = obj.find_isosurface_patch(ax);
            if obj.plot_type ~= obj.plot_types(5) || ~isscalar(ax) || ~isscalar(p) || isempty(obj.conv_scale)
                obj.plot_hold_bool = false;
                obj.update_plot(plot_panel);
                return
            end

            if obj.conv_units_bool
                scale = obj.conv_scale;
            else
                scale = 1 / obj.conv_scale;
            end
            p.Vertices(:,1) = p.Vertices(:,1) * scale;
            ax.XLim = ax.XLim * scale;

            if obj.conv_units_bool
                xlabel(ax, "x/c = U t / c", FontSize=16)
                daspect(ax, [1 1 1]) % true shapes: all axes in chords
            else
                xlabel(ax, "t/T", FontSize=16)
                ax.DataAspectRatioMode = 'auto';
            end
            obj.draw_stroke_labels_3D(ax); % redraw in the new units
        end

        function conv_shift_change(src, ~, plot_panel)
            obj.conv_shift = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.conv_shift);

            % Label Stroke follows Convection Shift (as in phaseAvg_UI): on
            % when it is turned on, off and disabled when it is turned off
            obj.label_stroke = obj.conv_shift;
            label_stroke_button.Value = obj.label_stroke;
            label_stroke_button.Enable = obj.conv_shift;
            label_stroke_button.BackgroundColor = obj.get_button_color(obj.label_stroke);

            % +/- (centred stroke) only means something in the wing phase,
            % so it needs the convection shift too; reset when it goes off
            if ~obj.conv_shift
                obj.stroke_flip = false;
                stroke_flip_button.Value = false;
            end
            stroke_flip_button.Enable = obj.conv_shift;
            stroke_flip_button.BackgroundColor = obj.get_button_color(obj.stroke_flip);

            if obj.plot_type == obj.plot_types(5)
                obj.update_plot(plot_panel);
            end
        end

        function stroke_flip_change(src, ~, plot_panel)
            obj.stroke_flip = src.Value && obj.conv_shift;
            src.Value = obj.stroke_flip;
            src.BackgroundColor = obj.get_button_color(obj.stroke_flip);
            if obj.plot_type ~= obj.plot_types(5)
                return
            end
            % only the phase changes, so move the existing surface instead
            % of reloading and recomputing it; full redraw if that can't
            % be done (e.g. while playing)
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            if ~obj.shift_3D_surface(ax)
                obj.update_plot(plot_panel);
            end
        end

        function label_stroke_change(src, ~, plot_panel)
            obj.label_stroke = src.Value && obj.conv_shift;
            src.Value = obj.label_stroke;
            src.BackgroundColor = obj.get_button_color(obj.label_stroke);
            % stroke reversals are already loaded with the 3D plot, so
            % just add / remove the labels on the current axes
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            obj.draw_stroke_labels_3D(ax);
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

    function tf = is_Q_iso_var(~, iso_var)
        tf = contains(string(iso_var), "Q");
    end

    % Q isovalue slider: the fixed range Q_ISO_RANGE (0.005 to 0.1), or the
    % same range negated when obj.iso_neg is set (shear dominated, Q < 0).
    % keep_magnitude keeps the current |isovalue| (used by "+/-");
    % otherwise the slider goes to the default (+/-0.05).
    function set_Q_iso_slider(obj, keep_magnitude)
        lims = obj.Q_ISO_RANGE;
        major = 0:0.025:lims(2);
        minor = lims(1):0.005:lims(2);
        if keep_magnitude
            mag = min(max(abs(obj.iso_val), lims(1)), lims(2));
        else
            mag = obj.Q_ISO_DEFAULT;
        end

        if obj.iso_neg
            lims = -fliplr(lims);
            major = -fliplr(major);
            minor = -fliplr(minor);
            obj.iso_val = -mag;
            obj.iso_value_label.Text = 'Q isovalue (Q < 0):';
        else
            obj.iso_val = mag;
            obj.iso_value_label.Text = 'Q isovalue:';
        end

        obj.iso_slider.Limits = lims;
        obj.iso_slider.MajorTicks = major;
        obj.iso_slider.MinorTicks = minor;
        obj.iso_slider.Value = obj.iso_val;
    end

    % File stems are <case>[_hr][_RPCA] (phase_avg_STB adds _hr to the
    % version name, then _RPCA). These strip / add the suffixes.
    function stems = strip_variant_suffix(~, stems)
        stems = regexprep(string(stems), "_RPCA$", "");
        stems = regexprep(stems, "_hr$", "");
    end

    function case_id = with_variant_suffix(obj, case_id)
        case_id = obj.strip_variant_suffix(case_id);
        if strlength(case_id) == 0
            return
        end
        if obj.HR
            case_id = case_id + "_hr";
        end
        if obj.RPCA
            case_id = case_id + "_RPCA";
        end
    end

    function tf = has_case_id(obj, case_ids, case_id)
        tf = any(string(case_ids) == obj.with_variant_suffix(case_id));
    end

    % Outline the measured (original) field of view on an extrapolated plot
    % with a black dashed box. Extrapolation (helm_decomp) trims the
    % measured plane with default_trim_bounds (trim_vel_field), mirrors it
    % about the centreline and centres it, by index, in a larger zero-padded
    % grid (y_B, z_B). The same steps are repeated here to find where the
    % measured points sit on that grid.
    function draw_original_fov_box(~, ax, d)
        if ~all(isfield(d, {'y', 'z', 'y_B', 'z_B'}))
            return
        end

        bounds = default_trim_bounds();
        y_meas = d.y(1,:,1);
        z_meas = squeeze(d.z(1,1,:));
        y_keep = y_meas(y_meas > bounds.ybounds(1) & y_meas < bounds.ybounds(2));
        num_y = sum(y_keep >= bounds.y_cen);   % one side of the centreline
        num_z = sum(z_meas > bounds.zbounds(1) & z_meas < bounds.zbounds(2));
        num_y = 2*num_y - 1;                   % mirrored, centreline once

        y_arr = d.y_B(:,1);
        z_arr = d.z_B(1,:);
        Ny = numel(y_arr);
        Nz = numel(z_arr);
        if num_y < 1 || num_z < 1 || Ny < 2 || Nz < 2
            return
        end

        % index placement used in helm_decomp
        y_first = max(floor((Ny - num_y) / 2) + 1, 1);
        z_first = max(floor((Nz - num_z) / 2) + 1, 1);
        y_last = min(y_first + num_y - 1, Ny);
        z_last = min(z_first + num_z - 1, Nz);

        % box at the outer edges of the measured cells
        dy = abs(y_arr(2) - y_arr(1));
        dz = abs(z_arr(2) - z_arr(1));
        y_lims = [min(y_arr([y_first y_last])) - dy/2, max(y_arr([y_first y_last])) + dy/2];
        z_lims = [min(z_arr([z_first z_last])) - dz/2, max(z_arr([z_first z_last])) + dz/2];

        hold(ax, 'on')
        plot(ax, y_lims([1 2 2 1 1]), z_lims([1 1 2 2 1]), 'k--', ...
            'LineWidth', 1.5, 'HandleVisibility', 'off', 'Tag', "original_fov_box");
    end

    function color = get_button_color(obj, is_active)
        if is_active
            color = obj.ACTIVE_COLOR;
        else
            color = obj.INACTIVE_COLOR;
        end
    end

    function tf = is_flapper_source_mode(obj, source_mode)
        tf = source_mode == obj.OLD_FLAPPER_SOURCE_MODE || source_mode == obj.NEW_FLAPPER_SOURCE_MODE;
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

    % The 3D plot's isosurface patch (not the Label Stroke shading)
    function p = find_isosurface_patch(obj, ax)
        p = findobj(ax, 'Type', 'patch', '-not', 'Tag', obj.STROKE_TAG);
    end

    % Stroke reversals for the 3D plot from the phase-averaged wing
    % position (max = top of the stroke, upstroke -> downstroke; min =
    % bottom, downstroke -> upstroke), in flow bins. [] if not saved.
    function S = get_stroke_info_3D(obj, file_base, num_bins)
        S = [];
        integral_file = file_base + "_integral.mat";
        wing_pos = [];
        if isfile(integral_file)
            vars = who("-file", integral_file);
            if ismember("phase_avg_wing_pos", vars)
                d = load(integral_file, "phase_avg_wing_pos");
                wing_pos = d.phase_avg_wing_pos(:)';
            end
        end
        if isempty(wing_pos)
            if obj.label_stroke
                disp("No wing position for " + obj.get_current_case_id() + ", stroke not labeled")
            end
            return
        end

        N_w = length(wing_pos);
        [~, i_top] = max(wing_pos);
        [~, i_bottom] = min(wing_pos);
        % same bin <-> phase convention as phaseAvg_UI (bin i at i/N), so
        % rescale if the wing position has a different number of bins
        S.top = i_top * num_bins / N_w;
        S.bottom = i_bottom * num_bins / N_w;
        S.N = num_bins;
        S.frame_shift = 0;
    end

    % Everything the 3D plot's iso variable (after trim / mirror / filter)
    % and isosurface depend on, i.e. all plot settings except the colour
    % variable and colour limits
    function key = get_3D_geometry_key(obj, use_extrapolated_data)
        % file modification times too, so a reprocessed case isn't reused
        file_base = string(obj.get_current_file_base());
        stamps = strings(1, 2);
        files = file_base + [".mat", "_integral.mat"];
        for k = 1:2
            info = dir(files(k));
            if ~isempty(info)
                stamps(k) = sprintf("%.10f", info(1).datenum);
            end
        end
        parts = [file_base, stamps, string(obj.iso_var), ...
            sprintf("%.10g", obj.iso_val), string(obj.num_cycles), ...
            string(obj.conv_units_bool), string(obj.trim_bool), ...
            mat2str(obj.trim_y_bounds), mat2str(obj.trim_z_bounds), ...
            string(obj.mirror_bool), mat2str(obj.mirror_center_y), ...
            string(obj.filter_bool), string(use_extrapolated_data), ...
            string(obj.frame_ind), string(obj.conv_shift), string(obj.stroke_flip)];
        key = strjoin(parts, "|");
    end

    % Re-phase the current 3D plot for a new "+/-" setting without
    % reloading or recomputing it for the shift. A circular shift of the
    % periodic wake is the same as sliding the plotted window along it, so
    % the isosurface is computed once over one extra wingbeat (unshifted,
    % cached) and then just translated along x, with the axes limits
    % clipping it to the plotted wingbeats. Returns false if the plot
    % can't be updated this way (caller does a full redraw).
    function ok = shift_3D_surface(obj, ax)
        ok = false;
        S3 = obj.surf_3D;
        if obj.play || isempty(S3) || isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
            return
        end
        p = obj.find_isosurface_patch(ax);
        if ~isscalar(p)
            return
        end

        params = S3.params;
        N = params.num_bins;
        n = params.num_cycles;

        if isempty(S3.ext)
            params_ext = params;
            params_ext.num_cycles = n + 1;
            params_ext.shift = 0;
            [xl_ext, s_ext, c_ext] = stack_vortices_3D(S3.y, S3.z, S3.val, S3.Q, S3.cycle_freq, params_ext);
            S3.ext = struct('vertices', s_ext.vertices, 'faces', s_ext.faces, 'cdata', c_ext, ...
                'dz', xl_ext(2) / ((n + 1) * N - 1)); % bin spacing on the x-axis
            obj.surf_3D = S3;
        end

        flip_bins = 0;
        if obj.conv_shift && obj.stroke_flip
            flip_bins = obj.get_stroke_flip_bins(N);
        end
        shift = mod(S3.base_shift + flip_bins, N);

        % plotted bin k holds original bin k - shift (circshift), which is
        % bin k - shift + N of the unshifted extended surface
        verts = S3.ext.vertices;
        verts(:,1) = verts(:,1) + (shift - N) * S3.ext.dz;

        % drop faces entirely outside the plotted window (the axes clip
        % the ones crossing its ends)
        xl = S3.xlims;
        fx = reshape(verts(S3.ext.faces, 1), size(S3.ext.faces));
        keep = any(fx >= xl(1), 2) & any(fx <= xl(2), 2);

        p.Vertices = verts;
        p.Faces = S3.ext.faces(keep, :);
        p.FaceVertexCData = S3.ext.cdata;
        p.Clipping = 'on';
        xlim(ax, xl)

        obj.set_stroke_frame_shift(S3.base_shift - S3.conv_shift_bins + flip_bins);
        obj.draw_stroke_labels_3D(ax);
        ok = true;
    end

    % Bins to shift the 3D plot by so the middle of the upstroke lands
    % where the middle of the downstroke is without the shift. The strokes
    % differ in length, so this comes from the stroke reversals in the
    % wing position (downstroke: top -> bottom, upstroke: bottom -> top);
    % half a wingbeat if the wing position isn't saved.
    function flip_bins = get_stroke_flip_bins(obj, num_bins)
        S = obj.stroke_3D;
        if isempty(S)
            flip_bins = round(num_bins / 2);
            disp("No wing position for " + obj.get_current_case_id() + ", upstroke centred assuming equal strokes")
            return
        end
        N = S.N;
        down_len = mod(S.bottom - S.top, N);
        up_len = N - down_len;
        down_mid = S.top + down_len / 2;
        up_mid = S.bottom + up_len / 2;
        flip_bins = round(mod(down_mid - up_mid, N));
        disp(sprintf("Downstroke %.0f%% / upstroke %.0f%% of the wingbeat: upstroke centred with a %d / %d bin shift", ...
            100 * down_len / N, 100 * up_len / N, flip_bins, N))
    end

    function set_stroke_frame_shift(obj, frame_shift)
        if ~isempty(obj.stroke_3D)
            obj.stroke_3D.frame_shift = frame_shift;
        end
    end

    % Whether the 3D axes is in a view that shows the x-axis edge on:
    % looking along y (+/-yz: az = 0 or 180, el = 0) or along z (+/-xz:
    % el = +/-90)
    function [along_y, along_z, az, el] = get_stroke_view(~, ax)
        [az, el] = view(ax);
        tol = 0.5; % deg
        along_y = abs(el) < tol && abs(mod(az + tol, 180) - tol) < tol;
        along_z = abs(abs(el) - 90) < tol;
    end

    % Remove the stroke labels as soon as the 3D view is rotated away from
    % a supported view (mouse rotation, or any other view change). The
    % listeners live as long as the axes. View and CameraPosition are
    % both watched since which one interactive rotation sets depends on
    % the MATLAB version; if a property can't be listened to, the labels
    % are still cleared at the next plot refresh.
    function add_stroke_view_listeners(obj, ax)
        for prop = ["View", "CameraPosition"]
            try
                addlistener(ax, prop, 'PostSet', @(~, ~) obj.clear_stroke_labels_if_rotated(ax));
            catch
            end
        end
    end

    function clear_stroke_labels_if_rotated(obj, ax)
        if ~isvalid(ax)
            return
        end
        labels = findall(ax, 'Tag', obj.STROKE_TAG);
        if isempty(labels)
            return
        end
        [along_y, along_z] = obj.get_stroke_view(ax);
        if ~along_y && ~along_z
            delete(labels);
        end
    end

    % Black lines at the stroke reversals, light gray shading over the
    % downstroke and "upstroke" / "downstroke" text, on the 3D plot. Only
    % drawn in the 2D views that show the x-axis (looking along y: +/-yz,
    % or along z: +/-xz); removed in any other view. Lines and text go on
    % the face of the plot box nearest the camera, the shading on the far
    % face (behind the isosurface).
    function draw_stroke_labels_3D(obj, ax)
        if isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
            return
        end
        % findall: the labels have HandleVisibility off, so findobj misses them
        delete(findall(ax, 'Tag', obj.STROKE_TAG));

        S = obj.stroke_3D;
        if ~obj.label_stroke || ~obj.conv_shift || isempty(S) || obj.plot_type ~= obj.plot_types(5)
            return
        end

        [along_y, along_z, az, el] = obj.get_stroke_view(ax);
        if ~along_y && ~along_z
            return
        end
        % camera direction (from target) and screen-up for MATLAB's view
        cam = [sind(az)*cosd(el), -cosd(az)*cosd(el), sind(el)];
        up = [-sind(az)*sind(el), cosd(az)*sind(el), cosd(el)];

        xl = ax.XLim; yl = ax.YLim; zl = ax.ZLim;

        % reversal positions in wingbeat phase [0, 1) of the plotted data:
        % bin k (1-based) is plotted at index mod(k - 1 + frame_shift, N)
        N = S.N;
        to_phase = @(k) mod(k - 1 + S.frame_shift, N) / N;
        p_top = to_phase(S.top);
        p_bottom = to_phase(S.bottom);

        % one wingbeat on the x-axis (stack_vortices_3D: N bins span
        % (N-1)/(N-1) = 1, so a full period is N/(N-1))
        period = N / (N - 1);
        if obj.conv_units_bool
            period = period * obj.conv_scale;
        end

        cycles = -1:obj.num_cycles;
        down = clip_intervals([p_top + cycles; p_bottom + cycles + (p_bottom < p_top)]' * period);
        up_iv = clip_intervals([p_bottom + cycles; p_top + cycles + (p_top < p_bottom)]' * period);
        rev_x = [p_top + cycles, p_bottom + cycles] * period;
        rev_x = rev_x(rev_x >= xl(1) & rev_x <= xl(2));

        if along_y
            near = yl(1 + (cam(2) > 0)); far = yl(2 - (cam(2) > 0));
        else
            near = zl(1 + (cam(3) > 0)); far = zl(2 - (cam(3) > 0));
        end

        % downstroke shading on the far face
        for k = 1:size(down, 1)
            xs = down(k, [1 2 2 1]);
            if along_y
                h = patch(ax, xs, far * ones(1,4), zl([1 1 2 2]), [0.8 0.8 0.8]);
            else
                h = patch(ax, xs, yl([1 1 2 2]), far * ones(1,4), [0.8 0.8 0.8]);
            end
            h.FaceAlpha = 0.35;
            h.EdgeColor = 'none';
            style(h)
        end

        % reversal lines on the near face
        for t = rev_x
            if along_y
                h = line(ax, [t t], [near near], zl);
            else
                h = line(ax, [t t], yl, [near near]);
            end
            h.Color = 'k';
            h.LineWidth = 1.5;
            style(h)
        end

        % labels near the top of the screen, same font as the axis labels
        if along_y
            v_lim = zl; v_up = up(3);
        else
            v_lim = yl; v_up = up(2);
        end
        if v_up >= 0
            v_text = v_lim(2) - 0.03 * diff(v_lim);
        else
            v_text = v_lim(1) + 0.03 * diff(v_lim);
        end
        add_labels(down, "downstroke");
        add_labels(up_iv, "upstroke");

        function add_labels(intervals, label)
            for m = 1:size(intervals, 1)
                if diff(intervals(m,:)) < 0.06 * period % too narrow for text
                    continue
                end
                x_mid = mean(intervals(m,:));
                if along_y
                    h_t = text(ax, x_mid, near, v_text, label);
                else
                    h_t = text(ax, x_mid, v_text, near, label);
                end
                h_t.HorizontalAlignment = "center";
                h_t.VerticalAlignment = "top";
                h_t.FontName = ax.XLabel.FontName;
                h_t.FontSize = ax.XLabel.FontSize;
                h_t.Interpreter = ax.XLabel.Interpreter;
                h_t.Color = "k";
                h_t.Clipping = "on";
                style(h_t)
            end
        end

        function iv = clip_intervals(iv)
            iv(:,1) = max(iv(:,1), xl(1));
            iv(:,2) = min(iv(:,2), xl(2));
            iv = iv(iv(:,2) > iv(:,1), :);
        end

        function style(h)
            h.Tag = obj.STROKE_TAG;
            h.HandleVisibility = 'off';
            h.PickableParts = 'none';
        end
    end

    % Streamwise distance (m) from the robot to the imaging plane for the
    % current case, NaN if unknown (e.g. turbine cases)
    function dist = get_downstream_dist(obj)
        dist = NaN;
        downstream_type = string(obj.current_downstream_type);
        if obj.source_mode == obj.OLD_FLAPPER_SOURCE_MODE
            idx = find(obj.OLD_FLAPPER_DOWNSTREAM_TYPES == downstream_type, 1);
            if ~isempty(idx)
                dist = obj.OLD_FLAPPER_DOWNSTREAM_DISTS(idx);
            end
        elseif obj.source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            idx = find(obj.NEW_FLAPPER_DOWNSTREAM_TYPES == downstream_type, 1);
            if ~isempty(idx)
                dist = obj.NEW_FLAPPER_DOWNSTREAM_DISTS(idx);
            end
        end
    end

    % Number of phase bins to circshift phase-averaged data by so that it
    % lines up with the wing phase at the robot (convection time from the
    % robot to the imaging plane as a fraction of a wingbeat). Same shift
    % as phaseAvg_UI applies to its flow curves. 0 if the shift is off or
    % the distance is unknown.
    function shift_bins = get_conv_shift_bins(obj, cycle_freq, num_bins)
        shift_bins = 0;
        if ~obj.conv_shift
            return
        end

        dist = obj.get_downstream_dist();
        if isnan(dist)
            disp("No downstream distance defined for " + obj.get_current_case_id() + ", not shifted")
            return
        end

        conv_time = dist / obj.CONV_SPEED;
        shift = conv_time * cycle_freq; % shift as a portion of a cycle
        shift_bins = round(shift * num_bins);
        disp("Shifted " + obj.get_current_case_id() + " by: " + shift_bins + " / " + num_bins + ...
            " (" + dist + " m downstream)")
    end

    function A = nan_safe_medfilt(~, A)
        % medfilt2/medfilt3 have undefined behaviour with NaN input: NaNs
        % spread through the volume and results differ run to run, which
        % slices isosurfaces at random places. Fill NaNs with their nearest
        % neighbours before filtering, then restore them afterwards.
        nan_mask = isnan(A);
        if any(nan_mask, "all")
            for dim = 1:ndims(A)
                A = fillmissing(A, "nearest", dim);
            end
            A(isnan(A)) = 0; % only reached if an entire array is NaN
        end

        if ismatrix(A)
            A = medfilt2(A);
        else
            A = medfilt3(A);
        end

        A(nan_mask) = NaN;
    end

    function set_trim_settings_for_source_mode(obj, source_mode)
        % Old flapper uses its own set; new flapper and turbine share the
        % new-flapper set (turbine previously used these same values).
        if source_mode == obj.OLD_FLAPPER_SOURCE_MODE
            obj.trim_y_bounds = obj.OLD_FLAPPER_TRIM_Y_BOUNDS;
            obj.trim_z_bounds = obj.OLD_FLAPPER_TRIM_Z_BOUNDS;
            obj.mirror_center_y = obj.OLD_FLAPPER_MIRROR_CENTER_Y;
        else
            obj.trim_y_bounds = obj.NEW_FLAPPER_TRIM_Y_BOUNDS;
            obj.trim_z_bounds = obj.NEW_FLAPPER_TRIM_Z_BOUNDS;
            obj.mirror_center_y = obj.NEW_FLAPPER_MIRROR_CENTER_Y;
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

        if ~isempty(obj.phase_old_flapper_case_name_list) || ~isempty(obj.time_old_flapper_case_name_list)
            source_modes(end + 1) = obj.OLD_FLAPPER_SOURCE_MODE;
        end

        if ~isempty(obj.phase_new_flapper_case_name_list) || ~isempty(obj.time_new_flapper_case_name_list)
            source_modes(end + 1) = obj.NEW_FLAPPER_SOURCE_MODE;
        end

        if ~isempty(obj.phase_turbine_case_name_list) || ~isempty(obj.time_turbine_case_name_list)
            source_modes(end + 1) = obj.TURBINE_SOURCE_MODE;
        end
    end

    % Cases for the dropdown: for the flappers, only those at the selected
    % downstream position
    function case_names = get_case_name_list_for_active_plot_type(obj)
        case_names = obj.get_case_name_list(obj.source_mode, obj.plot_type, obj.current_downstream_type);
    end

    % downstream_type (optional): only cases at that downstream position
    % (flapper sources); omitted or "" lists every position
    function case_names = get_case_name_list(obj, source_mode, plot_type, downstream_type)
        if nargin >= 4 && strlength(string(downstream_type)) > 0 && obj.is_flapper_source_mode(source_mode)
            if source_mode == obj.NEW_FLAPPER_SOURCE_MODE
                phase_stems = obj.phase_new_flapper_stems;
                time_stems = obj.time_new_flapper_stems;
            else
                phase_stems = obj.phase_old_flapper_stems;
                time_stems = obj.time_old_flapper_stems;
            end
            downstream_type = string(downstream_type);
            [known_types, known_labels] = obj.get_known_downstream_options(source_mode);
            label = known_labels(known_types == downstream_type);
            phase_case_names = obj.get_flapper_case_names(phase_stems, downstream_type, label, source_mode);
            time_case_names = obj.get_flapper_case_names(time_stems, downstream_type, label, source_mode);
        elseif source_mode == obj.TURBINE_SOURCE_MODE
            phase_case_names = obj.phase_turbine_case_name_list;
            time_case_names = obj.time_turbine_case_name_list;
        elseif source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            phase_case_names = obj.phase_new_flapper_case_name_list;
            time_case_names = obj.time_new_flapper_case_name_list;
        else
            phase_case_names = obj.phase_old_flapper_case_name_list;
            time_case_names = obj.time_old_flapper_case_name_list;
        end

        % time averaged (0 Hz) cases have "time avg of phase avg" and the
        % section plot only
        if plot_type == obj.plot_types(1) || plot_type == obj.plot_types(10)
            case_names = unique([phase_case_names, time_case_names], 'stable');
        else
            case_names = phase_case_names;
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

        if obj.source_mode == obj.TURBINE_SOURCE_MODE
            if startsWith(case_name, "turbine")
                base_case_id = case_name;
            else
                base_case_id = "turbine_" + case_name;
            end
        else
            if obj.plot_type == obj.plot_types(1) && obj.has_case_id(obj.time_avg_case_ids, case_name)
                base_case_id = case_name;
            elseif current_downstream_type == case_name && ...
                    (obj.has_case_id(obj.phase_avg_case_ids, case_name) || obj.has_case_id(obj.time_avg_case_ids, case_name))
                base_case_id = case_name;
            elseif strlength(case_name) == 0
                base_case_id = current_downstream_type;
            else
                base_case_id = current_downstream_type + "_" + case_name;
            end
        end

        case_id = obj.with_variant_suffix(base_case_id);
    end

    function file_base = get_current_file_base(obj)
        if obj.is_time_avg_file_selected()
            file_base = obj.time_avg_file_path + obj.get_current_case_id() + "_time_avg";
        else
            case_id = obj.get_current_case_id();
            if ~any(obj.phase_avg_main_case_ids == case_id) && any(obj.phase_avg_RPCA_case_ids == case_id)
                file_base = obj.phase_avg_RPCA_file_path + case_id + "_phase_avg";
            else
                file_base = obj.phase_avg_file_path + case_id + "_phase_avg";
            end
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
            % the section plot also works on time averaged (0 Hz) files
            if obj.current_case_has_time_avg()
                plot_types(end+1) = obj.plot_types(10);
            end
        else
            plot_types = obj.plot_types;
        end
    end

    % Update the active plot after a selection or display setting changes.
    function update_plot(obj, plot_panel)
        ax = findobj(plot_panel.Children, 'Type', 'axes');

        % Reuse the existing 3D patch when only its surface data changes.
        if obj.plot_hold_bool
            p = obj.find_isosurface_patch(ax);
        else
            delete(ax);
        end

        plot_idx = find(obj.plot_types == obj.plot_type);
        using_time_avg_file = obj.is_time_avg_file_selected();
        use_extrapolated_data = obj.extrapolate_bool && ~using_time_avg_file;
        q_mask_enabled = obj.q_mask_bool && ismember(plot_idx, [1, 2]) && ~use_extrapolated_data;
        q_mask_var_name = "Q";

        cur_secondary_vars = {};

        if plot_idx == 10
            obj.plot_section_force(plot_panel);
            return
        end

        if plot_idx == 11
            obj.plot_frozen_flow(plot_panel);
            return
        end

        if ismember(plot_idx, [1, 2, 5, 9])
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
                % measured y/z are only needed to outline the original
                % field of view on the extrapolated grid
                vars = {"L","U","num_bins","cycle_freq","y","z"};
                cur_secondary_vars = {"z_B","y_B"};
            end

            if strcmp(var_name, obj.LIFT_WX_FIELD)
                % derived field: load the stored fields it is built from
                vars = [vars, obj.get_lift_wx_inputs(using_time_avg_file)];
            elseif contains(obj.variable_name, obj.secondary_vars) || use_extrapolated_data
                cur_secondary_vars{end+1} = var_name;
            else
                vars{end+1} = var_name;
            end

            if q_mask_enabled && ~any(strcmp(string(cur_secondary_vars), q_mask_var_name))
                cur_secondary_vars{end+1} = q_mask_var_name;
            end
        elseif plot_idx == 3
            var_name = obj.std_var_name_dict(obj.variable_name);
            var_clims = obj.get_color_limits(obj.variable_name);

            vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
        end
        
        geom_hit = false;
        if plot_idx == 5 || plot_idx == 9 % 3D plot or planar average
            iso_var_name = obj.variable_name_dict(obj.iso_var);

            % 3D plot: the iso variable and isosurface don't depend on the
            % colour variable, so reuse them if nothing they depend on
            % changed
            if plot_idx == 5
                geom_key = obj.get_3D_geometry_key(use_extrapolated_data);
                geom_hit = ~isempty(obj.geom_3D) && obj.geom_3D.key == geom_key;
            end

            if geom_hit
                % already processed, not loaded again
            elseif contains(obj.iso_var, obj.secondary_vars)
                cur_secondary_vars{end+1} = iso_var_name;
            else
                vars{end+1} = iso_var_name;
            end
        elseif plot_idx == 4
            var_name = obj.std_var_name_dict(obj.variable_name);
            var_clims = obj.get_color_limits(obj.variable_name);

            vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
        elseif plot_idx == 6
            var_name = obj.hist_var_name_dict(obj.variable_name);

            vars = {var_name};
            if (obj.variable_name == obj.hist_vars(2))
                vars{end+1} = "phase_res";
            elseif (obj.variable_name == obj.hist_vars(3))
                x_var_name = "full_cycle";
                vars{end+1} = x_var_name;
                vars{end+1} = "bin_ind_arr"; % which bin each frame went to
            end
        elseif plot_idx == 7
            var_name = obj.freq_var_name_dict(obj.variable_name);

            vars = {};
            cur_secondary_vars = {var_name};
            if obj.variable_name == obj.freq_vars(1)
                x_var_name = "norm_time_speed";
                cur_secondary_vars{end+1} = x_var_name;
                std_name = "phase_std_speed";
                cur_secondary_vars{end+1} = std_name;
            end
        elseif plot_idx == 8
            % get_PIV_force loads its own data, so nothing is loaded here
            var_name = obj.force_var_name_dict(obj.variable_name);
        end

        if strlength(obj.case_name) == 0
            return
        end

        if ~obj.current_case_has_phase_avg() && ~obj.current_case_has_time_avg()
            return
        end

        full_file_path = obj.get_current_file_base();

        if plot_idx == 8
            % wake forces: data is loaded by get_PIV_force below
        elseif ~isempty(cur_secondary_vars)
            d1 = load(full_file_path + "_integral.mat", cur_secondary_vars{:});
            if ~isempty(vars)
            d2 = load(full_file_path + ".mat", vars{:});
    
            % Combine by converting to cell arrays of names/values and back to struct
            d = cell2struct([struct2cell(d1); struct2cell(d2)], [fieldnames(d1); fieldnames(d2)], 1);
            else
                d = d1;
            end
        else
            d = load(full_file_path + ".mat", vars{:});
        end

        if plot_idx == 2 || plot_idx == 4 || plot_idx == 5
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

        if ismember(plot_idx, [1, 2, 5, 9]) && strcmp(var_name, obj.LIFT_WX_FIELD)
            d.(var_name) = obj.compute_lift_wx_field(d, using_time_avg_file);
        end

        if plot_idx ~= 8
            if ~isfield(d, var_name)
                error("flowField_UI:missingVariable",...
                    "%s is not in the processed file for %s. Reprocess the case (Q*_inst fields need bools.Q_inst = true, div_phase_std needs bools.div_std = true).",...
                    var_name, obj.case_name)
            end
            val = d.(var_name);
            planeIdx = (size(val,1) + 1) / 2;
        end

        if q_mask_enabled
            q_mask_val = d.(q_mask_var_name);
        end

        if ismember(plot_idx, [1, 2, 3, 4, 5, 9])
            if use_extrapolated_data
                y = d.y_B;
                z = d.z_B;
                val = permute(val, [2 3 1]); % time dimension moved
                if contains(var_name, "X")
                    val = val - 1; % add back freestream
                end
            elseif using_time_avg_file
                y = squeeze(d.y(planeIdx,:,:));
                z = squeeze(d.z(planeIdx,:,:));
                val = squeeze(val(planeIdx,:,:));
                if q_mask_enabled
                    q_mask_val = squeeze(q_mask_val(planeIdx,:,:));
                end
            else
                y = squeeze(d.y(planeIdx,:,:));
                z = squeeze(d.z(planeIdx,:,:));
                val = squeeze(val(planeIdx,:,:,:));
                if q_mask_enabled
                    q_mask_val = squeeze(q_mask_val(planeIdx,:,:,:));
                end
            end

            params.U = d.U;

            if strcmp(var_name, obj.LIFT_WX_FIELD)
                params.zero = 0; % signed field centred on zero
            elseif min(var_clims) < -1
                params.zero = -1;
            elseif min(var_clims) < 0.5
                params.zero = 0;
            else
                params.zero = 1;
            end
    
            cFlip = false;
            if plot_idx == 5
                if any(contains(["v","ω_z","ω_x"],obj.variable_name))
                    cFlip = true;
                end
            end

            if obj.trim_bool && ~use_extrapolated_data
                y_idx = find(y(:,1) > obj.trim_y_bounds(1) & y(:,1) < obj.trim_y_bounds(2));
                z_idx = find(z(1,:) > obj.trim_z_bounds(1) & z(1,:) < obj.trim_z_bounds(2));
                
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
                y_idx_m = find(y(:,1) > obj.mirror_center_y);
                
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
                val = obj.nan_safe_medfilt(val);
                if q_mask_enabled
                    q_mask_val = obj.nan_safe_medfilt(q_mask_val);
                end
            end

            if obj.floor_bool
                val(val < (params.zero + obj.thresh) & val > (params.zero - obj.thresh)) = params.zero;
            end

            if q_mask_enabled && plot_idx == 2
                val(q_mask_val <= obj.q_mask_thresh) = NaN;
            end
        end

        if geom_hit
            Q = obj.geom_3D.Q;
        elseif plot_idx == 5 || plot_idx == 9
            Q = d.(iso_var_name);
            Q = squeeze(Q(planeIdx,:,:,:));

            if obj.trim_bool
                Q = Q(y_idx,z_idx,:);
            end
            if obj.mirror_bool && ~use_extrapolated_data
                Q = Q(y_idx_m,:,:);
                Q_add = flip(Q(2:end,:,:),1);
                Q = [Q_add; Q];
            end
            if obj.filter_bool
                Q = obj.nan_safe_medfilt(Q);
            end
        end
        
        % Create a fresh axes unless the 3D patch can be updated in place.
        if ~obj.plot_hold_bool
            ax = axes(plot_panel);
        end

        switch plot_idx
        case {1,2,5}
            params.cb_lab = obj.label_dict(obj.variable_name);
        case {3,4}
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
            if use_extrapolated_data
                obj.draw_original_fov_box(ax, d);
            end
        elseif plot_idx == 3
            params.clims = var_clims;

            mean_val = mean(val,3);
            PIV_plot(y, z, mean_val, params, ax);
        elseif plot_idx == 2 || plot_idx == 4

        params.clims = var_clims;

        val_tr = val(:,:,obj.frame_ind);
        h = PIV_plot(y, z, val_tr, params, ax);
        if use_extrapolated_data && plot_idx == 2
            % drawn once; playing only updates the contour's ZData
            obj.draw_original_fov_box(ax, d);
        end
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
        elseif plot_idx == 5
            params.num_bins = d.num_bins;
            params.clims = var_clims;
            params.movie = false;
            params.L = d.L;
            conv_shift_bins = obj.get_conv_shift_bins(d.cycle_freq, d.num_bins);

            % Stroke reversals (Label Stroke and "+/-"). The wing position
            % is measured at the robot, so it only lines up with the flow
            % once the convection shift is applied.
            obj.stroke_3D = [];
            if obj.conv_shift
                obj.stroke_3D = obj.get_stroke_info_3D(full_file_path, d.num_bins);
            end

            % "+/-": shift so the upstroke is centred where the downstroke
            % is otherwise. It moves the flow and the wing phase together,
            % so unlike the convection shift it is part of the stroke
            % labels' shift too.
            stroke_flip_bins = 0;
            if obj.conv_shift && obj.stroke_flip
                stroke_flip_bins = obj.get_stroke_flip_bins(d.num_bins);
            end
            params.shift = obj.frame_ind - 1 + conv_shift_bins + stroke_flip_bins;
            params.isoValue = obj.iso_val; % 0.05
            params.num_cycles = obj.num_cycles;
            params.conv_units = obj.conv_units_bool;
            % stack_vortices_3D's t/T axis is the convective axis divided by
            % its maximum, U * (N-1) / (f N) / L
            obj.conv_scale = d.U * (d.num_bins - 1) / (d.cycle_freq * d.num_bins * d.L);

            if geom_hit
                params.surface = obj.geom_3D.surface; % only recolour it
            end
            [xlims, surface_data, color_data] = stack_vortices_3D(y, z, val, Q, d.cycle_freq, params);
            params.surface = []; % frames while playing need their own surface
            obj.geom_3D = struct('key', geom_key, 'surface', surface_data, 'Q', Q);
            setColorBar(ax, params)
            xlim(ax,xlims) % otherwise when plotting multiple wingbeats awkward extra space added

            % kept so "+/-" can shift this plot without a full redraw
            obj.surf_3D = struct('y', y, 'z', z, 'val', val, 'Q', Q, ...
                'cycle_freq', d.cycle_freq, 'params', params, 'xlims', xlims, ...
                'base_shift', obj.frame_ind - 1 + conv_shift_bins, ...
                'conv_shift_bins', conv_shift_bins, 'ext', []);

            while obj.play && (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;
                params.shift = obj.frame_ind - 1 + conv_shift_bins + stroke_flip_bins; % same as the slider (frame 1 = no shift)
        
                [~, surface_data, color_data] = stack_vortices_3D(y, z, val, Q, d.cycle_freq, params);
                p.Vertices = surface_data.vertices;
                p.Faces = surface_data.faces;
                p.FaceVertexCData = color_data;
                obj.set_stroke_frame_shift(params.shift - conv_shift_bins);
                obj.draw_stroke_labels_3D(ax);
        
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
                obj.add_stroke_view_listeners(ax);
                obj.plot_hold_bool = true;
            end
            obj.set_stroke_frame_shift(params.shift - conv_shift_bins);
            obj.draw_stroke_labels_3D(ax);
        elseif plot_idx == 6
            if (obj.variable_name == obj.hist_vars(3))
                if isfield(d, "bin_ind_arr")
                    obj.plot_tick_distribution(ax, val, d.(x_var_name), d.bin_ind_arr);
                else
                    histogram(ax, val, d.(x_var_name))
                end
                xlabel(ax, "Tick number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
            else
                if obj.variable_name == obj.hist_vars(1) % bin counts
                    bar(ax, val)
                else % per-bin values, not counts: points joined by a line
                    h = plot(ax, val, '-o', 'MarkerSize', 4);
                    h.MarkerFaceColor = h.Color; % filled markers
                    xlim(ax, [0.5, numel(val) + 0.5])
                end
                xlabel(ax, "Bin number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
                if obj.variable_name == obj.hist_vars(2) % phase variability
                    % resolution = best achievable variability (one DAQ
                    % sample / encoder pulse), both as % of the bin width
                    hold(ax, 'on')
                    yline(ax, d.phase_res, '--k', 'resolution', ...
                        'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
                    cap_note = obj.cap_outlier_bars(ax, val);
                    title_str = string(sprintf("Phase variability: mean %.2f%% of bin, resolution %.2f%% of bin", ...
                        mean(val, "omitnan"), d.phase_res));
                    if strlength(cap_note) > 0
                        title_str = [title_str; cap_note];
                    end
                    title(ax, title_str, FontSize=14)
                elseif obj.variable_name == obj.hist_vars(4) % bin placement
                    hold(ax, 'on')
                    yline(ax, 0, '-k', 'HandleVisibility', 'off');
                    title(ax, sprintf("Bin placement: mean %+.2f%%, mean |offset| %.2f%% of bin (+ = late in bin)", ...
                        mean(val, "omitnan"), mean(abs(val), "omitnan")), FontSize=14)
                end
            end
        elseif plot_idx == 7
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
        elseif plot_idx == 8
            avg_type = 1;
            norm_bool = false;
            case_id = obj.get_current_case_id();
            val = get_PIV_force(full_file_path, case_id, var_name, avg_type, norm_bool, default_trim_bounds());

            plot(ax, val)
            hold(ax, "on")
            yline(ax, mean(val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.force_label_dict(obj.variable_name), FontSize=16)
        elseif plot_idx == 9
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

    % Show the section-count dropdown instead of the colour-limit slider
    % for the "time avg: section avg" plot
    function set_section_controls(obj)
        is_section = obj.plot_type == obj.plot_types(10);
        if is_section
            obj.section_dropdown.Visible = "on";
            obj.clim_slider.Visible = "off";
        else
            obj.section_dropdown.Visible = "off";
            obj.clim_slider.Visible = "on";
        end
    end

    % "time avg: section avg" plot type: where across the span a wake
    % force comes from. The variable dropdown picks the force (the same
    % list as "wake forces", minus the omega_y lift terms, which are time
    % integrals rather than plane integrals); the dropdown under it picks
    % how many vertical slices of the field of view (equal widths in y).
    % Each bar is the cycle-averaged force from its slice, so the bars add
    % up to the total, e.g. for lift.vortX = 2*rho*U * int int y*omega_x,
    % noise at large y (weighted heavily) shows up as large or erratic
    % outer bars. The line (right axis) is the force per unit span, the
    % integrand integrated over z, column by column.
    %
    % The integrand comes from get_PIV_force / get_wake_lift (third
    % output), so the field, trim (default_trim_bounds), dimensions and
    % formula are exactly those of the "wake forces" plot, and the total
    % equals that plot's cycle mean. Computed live, nothing reprocessed.
    function plot_section_force(obj, plot_panel)
        obj.slider.Visible = "off";
        obj.play_button.Visible = "off";
        if strlength(obj.case_name) == 0 || ~ismember(obj.variable_name, obj.section_force_vars)
            return
        end
        % phase averaged file if there is one, else the time averaged file
        % (0 Hz cases): mean_* fields, freestream U and rho = 1.225, as in
        % timeAvg_UI. For a time average the nonlinear terms (lift_vel,
        % vel diff, bernoulli, drag_vel) use the mean velocity, not the
        % mean of the per-frame products.
        case_id = obj.get_current_case_id();
        if obj.current_case_has_phase_avg()
            file_base = obj.get_current_file_base(); % phase_avg\ (or its RPCA\ subfolder)
            avg_type = 1;
            avg_label = "Time averaged";
        elseif obj.current_case_has_time_avg()
            file_base = obj.time_avg_file_path + case_id + "_time_avg";
            avg_type = 0;
            avg_label = "Time averaged (0 Hz file)";
        else
            return
        end

        ax = axes(plot_panel);
        force_var = obj.force_var_name_dict(char(obj.variable_name));
        [~, ~, I] = get_PIV_force(file_base, case_id, force_var, avg_type, false, default_trim_bounds());
        if isempty(I.field)
            text(ax, 0.5, 0.5, string(obj.variable_name) + " is not a plane integral", ...
                'HorizontalAlignment', 'center', FontSize=16);
            axis(ax, 'off');
            return
        end

        % cycle average (bins weighted equally, like the wake forces mean)
        field = mean(I.field, 3, "omitnan");   % N/m^2, [ny nz]
        y_nd = I.y(:);                          % y/c from the centreline
        y = y_nd * I.L;                         % m
        z = I.z(:) * I.L;

        % force per unit span of each column, N/m
        dL_dy = trapz(z, field, 2);
        nan_cols = sum(isnan(dL_dy));

        % trapz weights along y, so the slices add up to trapz over y
        dy = diff(y);
        w = ([dy; 0] + [0; dy]) / 2;
        col_lift = w .* dL_dy;                  % N, each column's share
        total = sum(col_lift, "omitnan");       % = cycle mean in "wake forces"

        % slices: equal widths in y ("every column": one per column)
        n_sec = sscanf(char(obj.section_count), '%d');
        if isempty(n_sec)
            edges = [y_nd(1) - (y_nd(2) - y_nd(1))/2; ...
                     (y_nd(1:end-1) + y_nd(2:end))/2; ...
                     y_nd(end) + (y_nd(end) - y_nd(end-1))/2];
            sec_lift = col_lift;
        else
            edges = linspace(y_nd(1), y_nd(end), n_sec + 1)';
            sec_idx = discretize(y_nd, edges);
            sec_lift = accumarray(sec_idx, col_lift, [n_sec 1], @(v) sum(v, "omitnan"), 0);
        end
        n = numel(edges) - 1;

        % bars as patches so each spans its slice exactly
        yyaxis(ax, 'left')
        hold(ax, 'on')
        c = ax.ColorOrder(1, :);
        for k = 1:n
            patch(ax, [edges(k) edges(k+1) edges(k+1) edges(k)], [0 0 sec_lift(k) sec_lift(k)], c, ...
                'FaceAlpha', 0.5, 'EdgeColor', c);
        end
        if n <= 20 && abs(total) > 0
            for k = 1:n
                if sec_lift(k) >= 0, va = 'bottom'; else, va = 'top'; end
                text(ax, (edges(k) + edges(k+1))/2, sec_lift(k), sprintf("%.0f%%", 100*sec_lift(k)/total), ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', va, FontSize=12);
            end
        end
        yline(ax, 0, '-k', 'HandleVisibility', 'off');
        force_label = obj.force_label_dict(char(obj.variable_name));   % e.g. "Lift, ω_x term (N)"
        ylabel(ax, erase(force_label, " (N)") + " from section (N)", FontSize=16)
        lim_l = obj.zero_based_limits(sec_lift);

        yyaxis(ax, 'right')
        plot(ax, y_nd, dL_dy, '-', 'LineWidth', 1.5);
        ylabel(ax, "per unit span (N/m)", FontSize=16)
        lim_r = obj.zero_based_limits(dL_dy);

        % same zero height on both axes
        [lim_l, lim_r] = obj.align_zero_limits(lim_l, lim_r);
        yyaxis(ax, 'left');  ylim(ax, lim_l);
        yyaxis(ax, 'right'); ylim(ax, lim_r);
        yyaxis(ax, 'left');

        xlim(ax, [edges(1), edges(end)])
        xlabel(ax, "y/c (from centreline)", FontSize=16)
        title_str = string(sprintf("%s %s: %.4f N total, %d sections", ...
            avg_label, string(obj.variable_name), total, n));
        if nan_cols > 0
            title_str = title_str + sprintf(" (%d NaN columns left out)", nan_cols);
        end
        title(ax, title_str, FontSize=16, Interpreter="none") % names contain "_"
    end

    % Copy an axes with left and right y axes (yyaxis) into fig, which
    % copyobj doesn't support: copies each side's plotted objects, limits
    % and labels into a new yyaxis axes at the same position
    function dst = copy_yyaxis_axes(~, src, fig)
        dst = axes(fig, 'Units', src.Units, 'Position', src.Position, 'FontSize', src.FontSize);
        sides = ["left", "right"];
        for k = 1:2
            yyaxis(src, sides(k));
            yyaxis(dst, sides(k));
            hold(dst, 'on');
            if ~isempty(src.Children)
                copyobj(flipud(src.Children), dst);
            end
            ylim(dst, ylim(src));
            dst.YAxis(k).Color = src.YAxis(k).Color;
            ylabel(dst, src.YLabel.String, 'FontSize', src.YLabel.FontSize, ...
                'Interpreter', src.YLabel.Interpreter);
        end
        yyaxis(src, 'left');
        yyaxis(dst, 'left');
        xlim(dst, xlim(src));
        xlabel(dst, src.XLabel.String, 'FontSize', src.XLabel.FontSize, 'Interpreter', src.XLabel.Interpreter);
        title(dst, src.Title.String, 'FontSize', src.Title.FontSize, 'Interpreter', src.Title.Interpreter);
        box(dst, src.Box);
    end

    % [lo hi] covering the data and zero, padded 10%
    function lim = zero_based_limits(~, v)
        lo = min([0; v(:)], [], "omitnan");
        hi = max([0; v(:)], [], "omitnan");
        if hi == lo, hi = lo + 1; end
        pad = 0.1 * (hi - lo);
        lim = [lo - pad*(lo < 0), hi + pad*(hi > 0)];
    end

    % Stretch two [lo hi] ranges so zero sits at the same height on both
    function [a, b] = align_zero_limits(~, a, b)
        fa = -a(1) / diff(a);   % fraction of the axis below zero
        fb = -b(1) / diff(b);
        f = max(fa, fb);
        if f >= 1 - 1e-6
            a(2) = 0.05*diff(a); b(2) = 0.05*diff(b);   % all negative
            return
        end
        % lower the bottom of the axis with less below zero
        if fa < f, a(1) = -f/(1 - f) * a(2); end
        if fb < f, b(1) = -f/(1 - f) * b(2); end
    end

    % "frozen flow" plot type: compares the slab-normal derivative dw/dx on
    % the centre plane with the frozen-flow estimate (1/U) dw/dt from the
    % phase series (x points upstream, so dw/dx = (1/U) dw/dt). Both are
    % nondimensional, (L/U) * derivative, like dwdx_phase_avg. Same check
    % as helper functions/slab_derivative_map.m.
    function plot_frozen_flow(obj, plot_panel)
        if strlength(obj.case_name) == 0 || ~obj.current_case_has_phase_avg()
            return
        end
        file = obj.get_current_file_base() + ".mat";
        have = who('-file', file);

        ax = axes(plot_panel);
        if ~all(ismember({'dwdx_phase_avg', 'w_phase_avg'}, have))
            text(ax, 0.5, 0.5, "dwdx\_phase\_avg or w\_phase\_avg not in this file", ...
                'HorizontalAlignment', 'center', FontSize=16);
            axis(ax, 'off');
            obj.slider.Visible = "off"; obj.play_button.Visible = "off";
            return
        end

        vars = {"L", "U", "num_bins", "cycle_freq", "y", "z", "dwdx_phase_avg", "w_phase_avg"};
        if ismember('U_act', have), vars{end+1} = "U_act"; end
        if ismember('bin_placement', have), vars{end+1} = "bin_placement"; end
        d = load(file, vars{:});
        U_conv = d.U;
        if isfield(d, 'U_act'), U_conv = d.U_act * d.U; end

        nb = size(d.w_phase_avg, 4);
        placement = [];
        if isfield(d, 'bin_placement'), placement = d.bin_placement; end
        period = 1 / d.cycle_freq;
        tb = bin_times(nb, period, placement);   % actual (mean-phase) bin times
        planeIdx = (size(d.w_phase_avg, 1) + 1) / 2;
        y = squeeze(d.y(planeIdx,:,:));
        z = squeeze(d.z(planeIdx,:,:));
        dwdx = squeeze(d.dwdx_phase_avg(planeIdx,:,:,:));
        w    = squeeze(d.w_phase_avg(planeIdx,:,:,:));
        for k = 1:nb
            dwdx(:,:,k) = fill3D(dwdx(:,:,k));
            w(:,:,k)    = fill3D(w(:,:,k));
        end
        dwdt_U = periodic_ddt(w, tb, period, 3) * (d.L / U_conv);

        if obj.trim_bool
            y_idx = find(y(:,1) > obj.trim_y_bounds(1) & y(:,1) < obj.trim_y_bounds(2));
            z_idx = find(z(1,:) > obj.trim_z_bounds(1) & z(1,:) < obj.trim_z_bounds(2));
            y = y(y_idx, z_idx);  z = z(y_idx, z_idx);
            dwdx = dwdx(y_idx, z_idx, :);  dwdt_U = dwdt_U(y_idx, z_idx, :);
        end

        params.U = d.U;
        params.zero = 0;
        params.clims = obj.get_color_limits(obj.variable_name);
        params.cb_lab = obj.frozen_label_dict(char(obj.variable_name));

        is_movie = ismember(obj.variable_name, obj.frozen_vars(1:2));
        if is_movie
            obj.slider.Visible = "on";
            obj.play_button.Visible = "on";
            if d.num_bins ~= obj.num_bins
                obj.num_bins = d.num_bins;
                obj.slider.Limits = [1 d.num_bins];
                obj.slider.MajorTicks = 1:5:d.num_bins;
                obj.slider.MinorTicks = 1:d.num_bins;
            end
            obj.frame_ind = min(max(obj.frame_ind, 1), obj.num_bins);
            if obj.variable_name == obj.frozen_vars(1)
                val = dwdx;
            else
                val = dwdt_U;
            end

            h = PIV_plot(y, z, val(:,:,obj.frame_ind), params, ax);
            t = title(ax, "Bin number: " + obj.frame_ind, FontSize=18);
            while obj.play && (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;
                tmp = val(:,:,obj.frame_ind);
                tmp(tmp < params.clims(1)) = params.clims(1);
                tmp(tmp > params.clims(2)) = params.clims(2);
                set(h, 'ZData', tmp);
                set(t, 'String', "Bin number: " + obj.frame_ind);
                drawnow;
                pause(0.05);
                if obj.frame_ind == obj.num_bins
                    obj.frame_ind = 0; % reset for next loop iteration
                end
            end
            return
        end

        obj.slider.Visible = "off";
        obj.play_button.Visible = "off";
        a = dwdx   - mean(dwdx, 3, 'omitnan');
        b = dwdt_U - mean(dwdt_U, 3, 'omitnan');
        if obj.variable_name == obj.frozen_vars(3)
            val = std(a, 0, 3, 'omitnan') ./ std(b, 0, 3, 'omitnan');
        else
            val = sum(a.*b, 3, 'omitnan') ./ sqrt(sum(a.^2, 3, 'omitnan') .* sum(b.^2, 3, 'omitnan'));
        end
        PIV_plot(y, z, val, params, ax);
        title(ax, string(obj.variable_name) + sprintf(" (median %.2f)", median(val(:), 'omitnan')), FontSize=18);
    end

    function plot_tick_distribution(~, ax, ticks, edges, bin_ind)
        % Histogram of frame encoder ticks, coloured by the phase bin each
        % frame was averaged into (alternating colours), with dotted lines
        % at the boundaries between neighbouring bins. Bins are assigned on
        % a time-based phase in frame_to_bin, so their extent in ticks is
        % taken from the frames themselves; overlapping neighbours mean
        % frames at the same tick ended up in different bins.
        ticks = double(ticks(:));
        bin_ind = double(bin_ind(:));
        valid = isfinite(ticks) & isfinite(bin_ind) & bin_ind > 0;
        edges = double(edges(:))';
        centers = (edges(1:end-1) + edges(2:end)) / 2;
        P = edges(end) - edges(1); % ticks per cycle

        is_odd = mod(bin_ind, 2) == 1;
        c_odd = histcounts(ticks(valid & is_odd), edges);
        c_even = histcounts(ticks(valid & ~is_odd), edges);

        hold(ax, 'on')
        b = bar(ax, centers, [c_odd(:), c_even(:)], 1, 'stacked', 'EdgeColor', 'none');
        b(1).FaceColor = [0 0.4470 0.7410];
        b(2).FaceColor = [0.8500 0.3250 0.0980];
        b(1).DisplayName = "odd bins";
        b(2).DisplayName = "even bins";

        % tick extent of each bin (unwrapped across the 0 / P seam)
        num_bins = max(bin_ind(valid));
        lo = NaN(1, num_bins);
        hi = NaN(1, num_bins);
        for k = 1:num_bins
            t = ticks(valid & bin_ind == k);
            if isempty(t)
                continue
            end
            if max(t) - min(t) > P/2
                t(t < P/2) = t(t < P/2) + P;
            end
            lo(k) = min(t);
            hi(k) = max(t);
        end

        % boundary between bin k and the next bin: midway between the last
        % tick of k and the first tick of k+1
        boundaries = NaN(1, num_bins);
        num_overlap = 0;
        for k = 1:num_bins
            k_next = mod(k, num_bins) + 1;
            if isnan(hi(k)) || isnan(lo(k_next))
                continue
            end
            next_lo = lo(k_next);
            while next_lo < hi(k) - P/2
                next_lo = next_lo + P; % next bin starts after the seam
            end
            if next_lo < hi(k)
                num_overlap = num_overlap + 1;
            end
            boundaries(k) = mod((hi(k) + next_lo) / 2, P);
        end
        boundaries = boundaries(isfinite(boundaries));
        xline(ax, boundaries, ':', 'Color', [0.25 0.25 0.25], 'HandleVisibility', 'off');

        xlim(ax, [edges(1), edges(end)])
        legend(ax, 'Location', 'best')
        title(ax, sprintf("%d bins (dotted: bin boundaries), %d of %d neighbouring bins overlap in ticks",...
            num_bins, num_overlap, num_bins), FontSize=12)
    end

    function note = cap_outlier_bars(~, ax, val)
        % Limit the y-axis to 2x the mean so the spread of the typical bins
        % is visible; bars above that are marked with their value. Returns
        % a note for the title ("" if nothing was capped).
        note = "";
        val = double(val(:))';
        cap = 2 * mean(val, "omitnan");
        if ~(cap > 0) || max(val) <= cap
            return
        end

        ylim(ax, [0, cap])
        outliers = find(val > cap);
        hold(ax, 'on')
        plot(ax, outliers, 0.97 * cap * ones(size(outliers)), 'v',...
            'MarkerFaceColor', [0.85 0.1 0.1], 'MarkerEdgeColor', [0.85 0.1 0.1],...
            'HandleVisibility', 'off');
        for k = outliers
            text(ax, k, 0.92 * cap, sprintf('%.3g', val(k)),...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top',...
                'FontSize', 10, 'Color', [0.85 0.1 0.1]);
        end
        note = sprintf("y-axis limited to 2x mean; %d bin(s) above (value shown)", numel(outliers));
    end

    function inputs = get_lift_wx_inputs(~, using_time_avg_file)
        % Stored fields needed for the derived lift field, on top of the
        % y, U and L already loaded for every 2D/3D plot
        if using_time_avg_file
            inputs = {"mean_vortX"};
        else
            inputs = {"U_act","vortX_phase_avg"};
        end
    end

    function field = compute_lift_wx_field(obj, d, using_time_avg_file)
        % Lift integrand from the wake, matching term1 in get_wake_lift:
        %   term1 = -U .* y .* -vortX
        % with y and vortX made dimensional the same way (y*L, vortX*U/L)
        % and the same speed get_PIV_force passes in (U_act*U for phase
        % averages, U for time averages). Integrating 2*rho*term1 over the
        % y-z plane gives the lift.vortX value. Units: m^2/s^2.
        %
        % y is measured from the mirror centerline, as in the stored force
        % calculation (calc_secondary_vals_common -> prepare_STB_wake_field
        % -> trim_vel_field subtracts y_cen before get_wake_lift).
        if using_time_avg_file
            speed = d.U;
            vortX = d.mean_vortX;
        else
            speed = d.U_act * d.U;
            vortX = d.vortX_phase_avg;
        end

        y = (d.y - obj.mirror_center_y) * d.L;
        vortX = vortX / (d.L / speed);

        % y is [x y z]; phase averaged vortX has a trailing bin dimension,
        % so implicit expansion applies y to every bin
        field = -speed .* y .* -vortX;
    end

    function clim_dict = build_clim_dict(~, var_names, clim_values)
        keys = cellstr(var_names);
        values = mat2cell(clim_values, ones(1, size(clim_values, 1)), size(clim_values, 2));
        clim_dict = containers.Map(keys, values);
    end

    function set_active_color_limit_set(obj)
        if ismember(obj.plot_type, obj.plot_types([3 4]))
            obj.clims = obj.std_clims;
            obj.clim_dict = obj.std_clim_dict;
        elseif obj.plot_type == obj.plot_types(11)
            obj.clims = obj.frozen_clims;
            obj.clim_dict = obj.frozen_clim_dict;
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

        if obj.plot_type == obj.plot_types(11)
            obj.frozen_clims = obj.update_clim_matrix(obj.frozen_vars, obj.frozen_clims, var_name, new_clims);
        elseif ismember(obj.plot_type, obj.plot_types([3 4]))
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