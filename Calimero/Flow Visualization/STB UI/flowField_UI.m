classdef flowField_UI < handle
properties (Constant, Access = private)
    ACTIVE_COLOR = [0.3010 0.7450 0.9330];
    INACTIVE_COLOR = [1 1 1];
    MOVIE_FRAME_DELAY = 0.1;    % s between frames of the .gif from Save Movie
    MOVIE_CROP_PAD = 10;        % px of margin kept around the plot when Save Movie crops the frames
    Q_ISO_RANGE = [0.005 0.1];  % Q isovalue slider range (negated by "+/-")
    Q_ISO_DEFAULT = 0.05;       % Q isovalue slider default
    % Tag on the 3D plot's stroke lines / shading / labels (Label Stroke),
    % so they can be found and removed without touching the isosurface
    STROKE_TAG = "stroke_label_3D";
    % "Card Style" on the 3D plot (lit isosurface, red-green diverging
    % colormap, dark background, no axes). Purely cosmetic and fully
    % reversible: the original look is stored on the axes when the style
    % is applied and restored when it is turned off.
    CARD_TAG = "card_style_3D";             % tag on the card style's lights
    CARD_BG = [0.035 0.055 0.11];           % deep navy background
    % lights relative to the camera: [azimuth elevation] (deg), and colours
    CARD_LIGHT_POS = [35 30; -75 5];        % warm key light, cool fill light
    CARD_LIGHT_COLOR = [1 0.95 0.86; 0.40 0.46 0.58];
    % colormap anchors, negative -> zero -> positive (e.g. ω_x < 0 green,
    % ω_x > 0 red): pine green, cream, cranberry
    CARD_CMAP_ANCHORS = [0.05 0.33 0.20; 0.30 0.60 0.40; 0.93 0.89 0.78; ...
                         0.85 0.30 0.30; 0.60 0.05 0.13];
    % "Remove Small" default: hide isosurface pieces with fewer
    % triangles than this % of the largest piece (0 = keep everything)
    REMOVE_SMALL_DEFAULT = 2;
    % Derived variable: lift integrand from the wake, computed on the fly
    % from stored fields (term1 in get_wake_lift: -U .* y .* -vortX, with y
    % measured from the mirror centerline)
    LIFT_WX_VAR = "lift (U y ω_x)"; % name shown in the variable dropdown
    LIFT_WX_FIELD = "lift_wx_field"; % internal name, not stored in files
    % Extrapolated minus measured velocity on the field of view, saved in
    % the phase-avg _integral file by the Helmholtz extrapolation
    % (calc_secondary_vals_common). Plotted on their own grid
    % (y_B_fov, z_B_fov), time avg / movie only.
    EXTRAP_DIFF_VARS = ["u: extrap - meas", "v: extrap - meas", "w: extrap - meas"];
    EXTRAP_DIFF_FIELDS = ["velX_B_diff", "velY_B_diff", "velZ_B_diff"];
    % Derived variables: stretching/tilting terms of the vorticity
    % transport equation, omega_j du_i/dx_j, computed on the fly as the
    % stored (nondimensional) vorticity times the stored gradient, so in
    % units of U^2/c^2. Fields line up with transport_term_list.
    % Dropdown names: the term, then what it does to omega_i (row i =
    % equation for omega_i). "stretch" = omega_i stretched/compressed
    % along its own axis; "ω_j→ω_i tilt" = existing omega_j rotated
    % into the i direction. Sign is the rate of change of omega_i itself
    % (not of |omega_i|): see transport_labels.
    TRANSPORT_VARS = ["ω_x du/dx (ω_x stretch)", "ω_y du/dy (ω_y→ω_x tilt)", "ω_z du/dz (ω_z→ω_x tilt)", ...
        "ω_x dv/dx (ω_x→ω_y tilt)", "ω_y dv/dy (ω_y stretch)", "ω_z dv/dz (ω_z→ω_y tilt)", ...
        "ω_x dw/dx (ω_x→ω_z tilt)", "ω_y dw/dy (ω_y→ω_z tilt)", "ω_z dw/dz (ω_z stretch)"];
    TRANSPORT_FIELDS = ["transport_wx_stretch", "transport_wx_tilt_y", "transport_wx_tilt_z", ...
        "transport_wy_tilt_x", "transport_wy_stretch", "transport_wy_tilt_z", ...
        "transport_wz_tilt_x", "transport_wz_tilt_y", "transport_wz_stretch"];
    % Combined terms, per component omega_i (still derived on the fly):
    %   net source  sum_j omega_j du_i/dx_j (one row of the 9 terms above,
    %               = inviscid D(omega_i)/Dt; single terms depend on the
    %               axes and can cancel, e.g. in an inclined vortex)
    %   growth      omega_i * net source = 1/2 D(omega_i^2)/Dt, positive
    %               where |omega_i| is growing, negative where shrinking
    %               (units U^3/c^3)
    TRANSPORT_SUM_VARS = ["ω_j du/dx_j (net ω_x source)", ...
        "ω_j dv/dx_j (net ω_y source)", ...
        "ω_j dw/dx_j (net ω_z source)", ...
        "ω_x ω_j du/dx_j (|ω_x| growth)", ...
        "ω_y ω_j dv/dx_j (|ω_y| growth)", ...
        "ω_z ω_j dw/dx_j (|ω_z| growth)"];
    TRANSPORT_SUM_FIELDS = ["transport_wx_total", "transport_wy_total", "transport_wz_total", ...
        "transport_wx_growth", "transport_wy_growth", "transport_wz_growth"];
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
    % (set in plane_downstream_dists, shared with phaseAvg_UI / timeAvg_UI)
    OLD_FLAPPER_DOWNSTREAM_DISTS = plane_downstream_dists("old"); % flexible, UP_one, UP_two
    NEW_FLAPPER_DOWNSTREAM_DISTS = plane_downstream_dists("new"); % x1-x5, MPS
    CONV_SPEED = plane_downstream_dists("conv_speed"); % m/s, convection speed of the wake
    % "phase avg: 3D all planes": the frozen-flow 3D wakes of one case at
    % every downstream position, joined into one reconstruction (see
    % plot_merged_3D). Positions listed here are left out (MPS sits
    % between x3 and x4 and isn't part of the x1-x5 traverse).
    MERGED_3D_PLOT = "phase avg: 3D all planes";
    % particle-track method the HRPP button selects (particle pool fit
    % with harmonic regression, as in timeAvg_UI)
    HRPP_METHOD = "particle_pool_hr20";
    MERGED_3D_EXCLUDE_TYPES = ["MPS"];
    MERGED_3D_MARKER_TAG = "merged_3D_plane";  % plane outlines / labels on that plot
    % "seam comparison": at the seam where the frozen-flow reconstruction
    % behind one plane (as on "phase avg: 3D all planes") meets the next
    % plane downstream, the measured field there minus the reconstruction,
    % averaged over the wingbeat (see plot_seam_comparison). Uses the same
    % planes, settings and convection speed U_c as the all-planes plot.
    SEAM_PLOT = "seam comparison";
    % statistic over the wingbeat of the seam difference: "mean" (signed;
    % equals the difference of the two planes' time averages, independent
    % of U_c), "rms" (sensitive to the phase alignment, i.e. to U_c)
    SEAM_STATS = ["mean", "rms"];
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
    % Data roots (e.g. ["C:\...\STB Processed Results\", "W:\STB Round 1\"]), the folder of each
    % time-averaged case (keyed "time|<case id>", get_case_dir) and the
    % files of each phase-averaged case (keyed by case id, a stb_file_paths
    % struct). The first root is the primary one; a case found in several
    % roots is taken from the first.
    data_roots;
    case_dir_map;
    phase_case_map;
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
    HRPP;  % particle pool + harmonic regression files (_<HRPP_METHOD>); not combined with HR / RPCA

    num_bins;
    frame_ind;
    play;
    movie_frame_fcn;   % called after each bin is drawn by the 2D movie loop (Save Movie), [] otherwise

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
    % last field loaded for the section plots (key + data), so moving the
    % frame slider of "phase avg: section avg" doesn't recompute it
    section_cache = struct('key', "", 'data', []);
    section_count;    %   the selected one (section_dropdown)
    section_force_vars; % forces it can break down (wake forces minus the omega_y lift terms)
    section_flow_vars;  % flow variables it can average by section (velocities, vorticity)
    section_plot_vars;  % the variable list it shows: section_force_vars then section_flow_vars
    section_dropdown;
    % section plots' uncertainty mask (unc_mask_region): on / off,
    % threshold (% of the freestream speed) and mode ("threshold": every
    % point above it; "outer": outside the largest region enclosed by its
    % contour). Starts as the forces use it (default_trim_bounds).
    section_unc_bool;
    section_unc_pct;
    section_unc_mode;
    section_grid;      % row with the section count and these controls
    % section plots' PIV Body Sub: subtract a steady (time averaged) case's
    % field before the sections are formed, as timeAvg_UI's PIV Body Sub
    % ("ring", "body", "gliding", "freestream"; see get_section_sub_case)
    section_sub_bool;
    section_sub_case;
    section_sub_cache = struct('key', "", 'data', []);
    frozen_vars;      % "frozen flow" plot: slab d/dx vs (1/U) d/dt, for frozen_quantities
    frozen_quantities; %   du/dx, dv/dx, dw/dx, omega_y, omega_z, div u (labels)
    frozen_keys;       %   their field names in get_frozen_flow_fields (dudx, ... vortZ, div)
    frozen_kinds;      %   per quantity: slab map, frozen map, rms ratio, correlation
    frozen_label_dict;
    frozen_clims;
    frozen_clim_dict;

    variable_name_dict;
    time_avg_var_name_dict;
    label_dict;

    std_var_name_dict;
    time_std_var_name_dict; % std variables in time average files (std_u, ...)
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
    % with conv_shift, order of the strokes across the 3D plot's wingbeat
    % (dropdown next to Convection Shift, see get_stroke_shift_bins):
    % "UDU" downstroke centred (no extra shift), "DUD" upstroke centred,
    % "DU" starts at the top of the stroke, "UD" at the bottom
    stroke_order;
    % inputs of the last 3D plot, so the stroke order can shift the surface without a
    % full redraw (see shift_3D_surface); ext = cached surface over one
    % extra wingbeat, built on the first stroke order change
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
    % "Card Style" toggle for the 3D plot (see CARD_TAG)
    card_style;
    % plot panel background before the card style darkened it, [] if the
    % panel isn't darkened (the panel outlives the axes, so it is kept here)
    card_panel_color;
    % "Remove Small": hide small disconnected isosurface pieces, those with
    % fewer triangles than remove_small_pct % of the largest piece
    remove_small_bool;
    remove_small_pct;
    extrapolate_bool;
    full_section_bool; % with Extrapolate: show the whole test section, not just the field of view
    floor_bool;
    thresh;
    q_mask_bool;
    q_mask_thresh;
    % 3D plot uncertainty mask: hide points whose wingbeat-averaged total
    % uncertainty (uncTot_phase_avg, nondimensional) exceeds
    % unc_mask_thresh percent of the freestream speed
    unc_mask_bool;
    unc_mask_thresh;
    % 3D plot: hide the isosurface inside a y-z box (e.g. the wake of the
    % robot's wires below the wing wake), [ymin ymax zmin zmax] in chords,
    % y from the mirror centreline and z as plotted. Display only.
    crop_box_bool;
    crop_box;
    % 2D plots (time avg / movie of phase avg and phase std): thin black
    % isolines of the wingbeat-averaged total uncertainty at
    % unc_contour_levels percent of the freestream speed
    unc_contour_bool;
    unc_contour_levels;
    % 2D time avg / phase avg movie: black dot at the centroid of the
    % plotted field (field_centroid), computed live
    centroid_bool;
    % uncertainty mask threshold for the centroid, % of the freestream
    % (0 = no mask); mask mode from default_trim_bounds
    centroid_unc_pct;
    % 3D plot "Fix Limits": hold the y and z axis limits (y/c, z/c) at
    % fix_ylim / fix_zlim so cases can be compared on the same axes;
    % fix_lims_set is true once limits were entered or taken from a plot
    fix_lims_bool;
    fix_ylim;
    fix_zlim;
    fix_lims_set;
    % "phase avg: 3D all planes": per-plane fields (trimmed / mirrored /
    % filtered) of the last plot and the settings they depend on (key),
    % so moving through the bins only rebuilds the isosurfaces
    merged_3D;
    % convection speed (m/s) of the frozen-flow reconstruction on that
    % plot; [] = each file's freestream U. merged_conv_field: its box.
    merged_conv_speed;
    merged_conv_field;
    % "seam comparison": selected seam (1 = between the first and second
    % plane found for the case, ...), statistic over the wingbeat
    % (SEAM_STATS), and its controls (seam_grid sits in the frame slider's
    % row, which that plot doesn't use; seam_conv_field mirrors
    % merged_conv_field)
    seam_ind;
    seam_stat;
    seam_grid;
    seam_slider;
    seam_conv_field;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = flowField_UI(file_path)
        % file_path: one data root, or several as a string array (e.g. the
        % new flapper data and the old flapper STB Round 1 folder)
        obj.data_roots = string(file_path(:))';
        file_path = obj.data_roots(1);
        obj.case_name = "";
        obj.variable_name = "";
        obj.phase_avg_file_path = processed_results_dir(file_path) + "phase_avg\";
        obj.time_avg_file_path = processed_results_dir(file_path) + "time_avg\";
        obj.file_path = obj.phase_avg_file_path;
        obj.source_modes = strings(0);
        obj.source_mode = "";
        obj.RPCA = false;
        obj.HR = false;
        obj.HRPP = false;

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;
        obj.movie_frame_fcn = [];

        obj.plot_types = ["time avg of phase avg","phase avg: movie", "time avg of phase std","phase std: movie", "phase avg: 3D plot",...
            "image wingbeat phase", "wingbeat frequency","wake forces","phase avg: planar avg",...
            "time avg: section avg", "frozen flow", obj.MERGED_3D_PLOT,...
            "phase avg: section avg",... % 13: listed after "time avg: section avg" (order_plot_types)
            obj.SEAM_PLOT]; % 14: listed after "phase avg: 3D all planes" (order_plot_types)
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
        obj.stroke_order = "UDU";
        obj.surf_3D = [];
        obj.geom_3D = [];
        obj.label_stroke = false;
        obj.stroke_3D = [];
        obj.merged_3D = [];
        obj.merged_conv_speed = [];
        obj.seam_ind = 1;
        obj.seam_stat = obj.SEAM_STATS(1);
        obj.card_style = false;
        obj.card_panel_color = [];
        obj.remove_small_bool = false;
        obj.remove_small_pct = obj.REMOVE_SMALL_DEFAULT;
        obj.unc_mask_bool = false;
        obj.unc_mask_thresh = 4; % % of freestream
        obj.crop_box_bool = false;
        obj.crop_box = [-1.4 1.4 -3.5 -1.2];
        obj.unc_contour_bool = false;
        obj.unc_contour_levels = 1:4; % % of freestream
        obj.centroid_bool = false;
        b_def = default_trim_bounds();
        obj.centroid_unc_pct = 100 * b_def.unc_mask; % starts as the forces use it
        obj.fix_lims_bool = false;
        obj.fix_ylim = [-5 5];
        obj.fix_zlim = [-3 3];
        obj.fix_lims_set = false;
        obj.trim_bool = true;
        obj.extrapolate_bool = false;
        obj.full_section_bool = false;
        obj.floor_bool = false;
        obj.thresh = 0.1;
        obj.q_mask_bool = false;
        obj.q_mask_thresh = 0.025;

        obj.file_suffix = "_phase_avg";

        % Cases from every data root. Phase averages: one per
        % <stem>_<method>_fields.mat (+ _shared, _integral), under the case
        % id stb_list_phase_avg gives it (its label, e.g.
        % x2_wings_20deg_8Hz_hr); time averages: *_time_avg.mat.
        obj.case_dir_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
        obj.phase_case_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
        phase_avg_stems = strings(1, 0);
        time_avg_stems = strings(1, 0);
        for r = 1:numel(obj.data_roots)
            phase_dir = processed_results_dir(obj.data_roots(r)) + "phase_avg\";
            time_dir = processed_results_dir(obj.data_roots(r)) + "time_avg\";
            cases = stb_list_phase_avg(phase_dir);
            for k = 1:numel(cases)
                if ~isKey(obj.phase_case_map, char(cases(k).label))
                    obj.phase_case_map(char(cases(k).label)) = cases(k).files;
                end
            end
            phase_avg_stems = [phase_avg_stems, reshape(string({cases.label}), 1, [])]; %#ok<AGROW>
            stems = obj.get_file_stems(dir(time_dir + "*.mat"), "_time_avg");
            obj.register_case_dirs("time", stems, time_dir);
            time_avg_stems = [time_avg_stems, stems]; %#ok<AGROW>
        end
        phase_avg_stems = unique(phase_avg_stems, 'stable');
        time_avg_stems = unique(time_avg_stems, 'stable');

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
            error("No STB average files found. Expected *_<method>_fields.mat or *_time_avg.mat files in Processed Results\\phase_avg\\ or time_avg\\ of %s.", strjoin(obj.data_roots, ", "))
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
        obj.movie_3D_avg_vars = [obj.movie_3D_avg_vars, obj.EXTRAP_DIFF_VARS];
        movie_3D_avg_values = [movie_3D_avg_values, obj.EXTRAP_DIFF_FIELDS];
        time_avg_values = [time_avg_values, obj.EXTRAP_DIFF_FIELDS]; % not in time-avg files
        % vorticity transport terms (derived, see TRANSPORT_FIELDS)
        obj.movie_3D_avg_vars = [obj.movie_3D_avg_vars, obj.TRANSPORT_VARS, obj.TRANSPORT_SUM_VARS];
        movie_3D_avg_values = [movie_3D_avg_values, obj.TRANSPORT_FIELDS, obj.TRANSPORT_SUM_FIELDS];
        time_avg_values = [time_avg_values, obj.TRANSPORT_FIELDS, obj.TRANSPORT_SUM_FIELDS];
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
            "drag_vel", ...
            "lift_vort: ω_y term (frozen)", "lift_vort: ω_y term (edge, frozen)", ...
            "drag_vort (frozen)", "drag_vort: ω_y term (frozen)", "drag_vort: ω_z term (frozen)"];
        % (frozen): omega_y, omega_z rebuilt with the frozen-flow d/dx =
        % (1/U) d/dt instead of the slab derivative (frozen_flow_gradients)
        force_vals = ["lift.tot", "lift.vortX", "lift.vortY", "lift.vortY_edge", "lift.vortX_taper", "lift.vel_diff", ...
            "lift_vel", ...
            "drag.tot", "drag.vortY", "drag.vortZ", "drag.bernoulli", ...
            "drag_vel", ...
            "lift_ff.vortY", "lift_ff.vortY_edge", ...
            "drag_ff.tot", "drag_ff.vortY", "drag_ff.vortZ"];
        force_labels = ["Lift (N)", "Lift, ω_x term (N)", "Lift, ω_y term (N)", "Lift, ω_y term, with edge terms (N)", "Lift, ω_x term, tapered (N)", "Lift, vel diff term (N)", ...
            "Lift (N)", ...
            "Drag (N)", "Drag, ω_y term (N)", "Drag, ω_z term (N)", "Drag, bernoulli term (N)", ...
            "Drag (N)", ...
            "Lift, ω_y term, frozen flow (N)", "Lift, ω_y term, with edge terms, frozen flow (N)", ...
            "Drag, frozen flow (N)", "Drag, ω_y term, frozen flow (N)", "Drag, ω_z term, frozen flow (N)"];

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
                      0, 0.1;...  % <Q> inst
                      -0.05, 0.05;... % u: extrap - meas
                      -0.05, 0.05;... % v: extrap - meas
                      -0.05, 0.05;... % w: extrap - meas
                      repmat([-0.5, 0.5], numel(obj.TRANSPORT_VARS), 1);... % ω_j du_i/dx_j c^2/U^2
                      repmat([-0.5, 0.5], 3, 1);... % net ω_i source c^2/U^2
                      repmat([-0.5, 0.5], 3, 1)]; % |ω_i| growth c^3/U^3

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
            "\boldmath$\langle Q \rangle \frac{c^2}{U_{\infty}^2}$",...
            "$(u_{extrap} - u_{meas}) \; / \; U$",...
            "$(v_{extrap} - v_{meas}) \; / \; U$",...
            "$(w_{extrap} - w_{meas}) \; / \; U$"];
        movie_3D_avg_labels = [movie_3D_avg_labels, obj.transport_labels(), obj.transport_sum_labels()];

        keys = cellstr(obj.movie_3D_avg_vars);
        values = movie_3D_avg_values;
        labels = movie_3D_avg_labels;
        obj.variable_name_dict = containers.Map(keys, values);
        obj.time_avg_var_name_dict = containers.Map(keys, time_avg_values);
        obj.label_dict = containers.Map(keys, labels);

        std_keys = cellstr(obj.movie_3D_std_vars);
        obj.std_var_name_dict = containers.Map(std_keys, movie_3D_std_values);
        % time average files (time_avg_STB): frame-to-frame SD over all
        % frames, named std_<field> (u_phase_std -> std_u, div_phase_std ->
        % std_div); others keep their names (not saved for time averages)
        time_std_values = regexprep(movie_3D_std_values, "^(\w+)_phase_std$", "std_$1");
        obj.time_std_var_name_dict = containers.Map(std_keys, time_std_values);
        obj.std_label_dict = containers.Map(std_keys, movie_3D_std_labels);

        hist_keys = cellstr(obj.hist_vars);
        obj.hist_var_name_dict = containers.Map(hist_keys, hist_vals);
        obj.hist_label_dict = containers.Map(hist_keys, hist_labels);

        freq_keys = cellstr(obj.freq_vars);
        obj.freq_var_name_dict = containers.Map(freq_keys, freq_vals);
        obj.freq_label_dict = containers.Map(freq_keys, freq_labels);

        % Frozen-flow check of the slab-normal derivatives (centre plane):
        % for du/dx, dv/dx, dw/dx and the vorticity components that contain
        % one (omega_y, omega_z), movies of the slab and frozen-flow
        % estimates, then pointwise rms ratio / correlation over the
        % wingbeat. All nondimensional like dwdx_phase_avg (* c/U). ∇·u is
        % the continuity check du/dx + dv/dy + dw/dz with the slab or the
        % frozen-flow du/dx (zero for incompressible flow).
        obj.frozen_quantities = ["du/dx", "dv/dx", "dw/dx", "ω_y", "ω_z", "∇·u"];
        obj.frozen_keys = ["dudx", "dvdx", "dwdx", "vortY", "vortZ", "div"];
        obj.frozen_kinds = [" (slab)", " (frozen)", ": rms ratio slab/frozen", ": correlation over phase"];
        tex_slab = ["\frac{\partial u}{\partial x}", "\frac{\partial v}{\partial x}", ...
            "\frac{\partial w}{\partial x}", "\omega_y", "\omega_z", "\nabla \cdot \mathbf{u}"];
        tex_ff = ["\frac{1}{U}\frac{\partial u}{\partial t}", "\frac{1}{U}\frac{\partial v}{\partial t}", ...
            "\frac{1}{U}\frac{\partial w}{\partial t}", "\omega_y^{\mathrm{ff}}", "\omega_z^{\mathrm{ff}}", ...
            "(\nabla \cdot \mathbf{u})^{\mathrm{ff}}"];
        lim = [0.2, 0.2, 0.2, 1, 1, 0.2];   % colour limits of the maps
        obj.frozen_vars = strings(1, 0);
        frozen_labels = strings(1, 0);
        obj.frozen_clims = zeros(0, 2);
        for q = 1:numel(obj.frozen_quantities)
            obj.frozen_vars = [obj.frozen_vars, obj.frozen_quantities(q) + obj.frozen_kinds];
            frozen_labels = [frozen_labels, ...
                "\boldmath$" + tex_slab(q) + "\frac{c}{U_{\infty}}$", ...
                "\boldmath$" + tex_ff(q) + "\frac{c}{U_{\infty}}$", ...
                "\boldmath$\mathrm{rms}(" + tex_slab(q) + ") / \mathrm{rms}(" + tex_ff(q) + ")$", ...
                "\boldmath$\rho$"]; %#ok<AGROW>
            obj.frozen_clims = [obj.frozen_clims; -lim(q) lim(q); -lim(q) lim(q); 0 1.5; -1 1]; %#ok<AGROW>
        end
        obj.section_vars = ["5 sections", "3 sections", "10 sections", "20 sections", "every column"];
        obj.section_count = obj.section_vars(1);
        b_sec = default_trim_bounds();
        obj.section_unc_bool = b_sec.unc_mask > 0;
        obj.section_unc_pct = 100 * b_sec.unc_mask;
        obj.section_unc_mode = "threshold";
        if isfield(b_sec, 'unc_mask_mode'), obj.section_unc_mode = string(b_sec.unc_mask_mode); end
        if obj.section_unc_pct <= 0, obj.section_unc_pct = 4; end
        obj.section_sub_bool = false;
        obj.section_sub_case = "freestream";
        obj.frozen_label_dict = containers.Map(cellstr(obj.frozen_vars), frozen_labels);
        obj.frozen_clim_dict = obj.build_clim_dict(obj.frozen_vars, obj.frozen_clims);

        force_keys = cellstr(obj.force_vars);
        obj.force_var_name_dict = containers.Map(force_keys, force_vals);
        % the omega_y lift terms are time integrals of a rate, not plane
        % integrals, so they can't be split across the plane
        obj.section_force_vars = obj.force_vars(~ismember(force_vals, ["lift.vortY", "lift.vortY_edge", "lift_ff.vortY", "lift_ff.vortY_edge"]));
        % flow variables: averaged over each section instead of summed
        % (names, fields and labels from the movie_3D_avg lists)
        % "|unc|": total uncertainty (uncTot), not masked by itself
        obj.section_flow_vars = ["u", "v", "w", "ω_x", "ω_y", "ω_z", "|unc|"];
        obj.section_plot_vars = [obj.section_force_vars, obj.section_flow_vars];
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
        sidebar_grid.RowHeight = {30, 30, 30, 30, 30, 30, 35, 30, 30, 30, 30, 30, 30, 0, 30, 30, 30};
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

        % RPCA, HR (harmonic regression) and HRPP (particle pool harmonic
        % regression) buttons share a row
        variant_grid = uigridlayout(sidebar_grid, [1, 3]);
        variant_grid.Layout.Row = 4;
        variant_grid.Layout.Column = 1;
        variant_grid.ColumnWidth = {'1x', '1x', '1x'};
        variant_grid.RowHeight = {'1x'};
        variant_grid.Padding = [0 0 0 0];
        variant_grid.ColumnSpacing = 8;

        rpca_button = uibutton(variant_grid, "state");
        rpca_button.Layout.Row = 1;
        rpca_button.Layout.Column = 1;
        rpca_button.Text = "RPCA";
        rpca_button.FontSize = 15;
        rpca_button.BackgroundColor = obj.get_button_color(obj.RPCA);
        rpca_button.ValueChangedFcn = @(src, event) RPCA_change(src, event, plot_area_panel);

        hr_button = uibutton(variant_grid, "state");
        hr_button.Layout.Row = 1;
        hr_button.Layout.Column = 2;
        hr_button.Text = "HR";
        hr_button.FontSize = 15;
        hr_button.Tooltip = "Harmonic regression files (_hr)";
        hr_button.BackgroundColor = obj.get_button_color(obj.HR);
        hr_button.ValueChangedFcn = @(src, event) HR_change(src, event, plot_area_panel);

        hrpp_button = uibutton(variant_grid, "state");
        hrpp_button.Layout.Row = 1;
        hrpp_button.Layout.Column = 3;
        hrpp_button.Text = "HRPP";
        hrpp_button.FontSize = 15;
        hrpp_button.Tooltip = "Particle pool harmonic regression files (_" + obj.HRPP_METHOD + ")";
        hrpp_button.BackgroundColor = obj.get_button_color(obj.HRPP);
        hrpp_button.ValueChangedFcn = @(src, event) HRPP_change(src, event, plot_area_panel);

        plot_type_dropdown = uidropdown(sidebar_grid);
        plot_type_dropdown.Layout.Row = 5;
        plot_type_dropdown.Layout.Column = 1;
        % Items are the shown labels, ItemsData the plot types (the labels
        % differ for time averaged cases, see get_plot_type_labels)
        initial_plot_types = obj.get_available_plot_types_for_current_case();
        set(plot_type_dropdown, 'Items', obj.get_plot_type_labels(initial_plot_types), ...
            'ItemsData', initial_plot_types);
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

        % Section avg plots (shares the colour-limit slider's row; only
        % one of them is shown, the row grows to fit these): number of y
        % sections, then the uncertainty mask of the section averages
        obj.section_grid = uigridlayout(sidebar_grid, [3, 3]);
        obj.section_grid.Layout.Row = 7;
        obj.section_grid.Layout.Column = 1;
        obj.section_grid.ColumnWidth = {'1x', 55, '1x'};
        obj.section_grid.RowHeight = {30, 30, 30};
        obj.section_grid.Padding = [0 0 0 0];
        obj.section_grid.RowSpacing = 4;
        obj.section_grid.ColumnSpacing = 4;
        obj.section_grid.Visible = "off";

        obj.section_dropdown = uidropdown(obj.section_grid);
        obj.section_dropdown.Layout.Row = 1;
        obj.section_dropdown.Layout.Column = [1 3];
        obj.section_dropdown.Items = obj.section_vars;
        obj.section_dropdown.Value = obj.section_count;
        obj.section_dropdown.ValueChangedFcn = @(src, event) section_count_change(src, event, plot_area_panel);

        sec_unc_button = uibutton(obj.section_grid, "state");
        sec_unc_button.Layout.Row = 2;
        sec_unc_button.Layout.Column = 1;
        sec_unc_button.Text = "Unc Mask";
        sec_unc_button.FontSize = 14;
        sec_unc_button.Value = obj.section_unc_bool;
        sec_unc_button.BackgroundColor = obj.get_button_color(obj.section_unc_bool);
        sec_unc_button.Tooltip = "Leave points with high uncertainty out of the section averages and " + ...
            "forces (the |unc| plot itself is never masked)";
        sec_unc_button.ValueChangedFcn = @(src, event) section_unc_change(src, event, plot_area_panel);

        sec_unc_field = uieditfield(obj.section_grid, "numeric");
        sec_unc_field.Layout.Row = 2;
        sec_unc_field.Layout.Column = 2;
        sec_unc_field.Limits = [0 Inf];
        sec_unc_field.Value = obj.section_unc_pct;
        sec_unc_field.HorizontalAlignment = 'center';
        sec_unc_field.Tooltip = "Uncertainty mask threshold, % of the freestream speed";
        sec_unc_field.ValueChangedFcn = @(src, event) section_unc_pct_change(src, event, plot_area_panel);

        sec_unc_mode = uidropdown(obj.section_grid);
        sec_unc_mode.Layout.Row = 2;
        sec_unc_mode.Layout.Column = 3;
        sec_unc_mode.Items = ["above threshold", "outside largest contour"];
        sec_unc_mode.ItemsData = ["threshold", "outer"];
        sec_unc_mode.Value = obj.section_unc_mode;
        sec_unc_mode.Tooltip = "above threshold: every point above it. outside largest contour: everything " + ...
            "outside the largest region enclosed by the threshold contour (holes inside it, e.g. vortex cores, kept)";
        sec_unc_mode.ValueChangedFcn = @(src, event) section_unc_mode_change(src, event, plot_area_panel);

        sec_sub_button = uibutton(obj.section_grid, "state");
        sec_sub_button.Layout.Row = 3;
        sec_sub_button.Layout.Column = [1 2];
        sec_sub_button.Text = "PIV Body Sub";
        sec_sub_button.FontSize = 14;
        sec_sub_button.Value = obj.section_sub_bool;
        sec_sub_button.BackgroundColor = obj.get_button_color(obj.section_sub_bool);
        sec_sub_button.Tooltip = "Subtract the steady case picked beside it (its time averaged field, " + ...
            "same trim and uncertainty mask) before the sections are formed, as in timeAvg_UI";
        sec_sub_button.ValueChangedFcn = @(src, event) section_sub_change(src, event, plot_area_panel);

        sec_sub_dropdown = uidropdown(obj.section_grid);
        sec_sub_dropdown.Layout.Row = 3;
        sec_sub_dropdown.Layout.Column = 3;
        sec_sub_dropdown.Items = ["ring", "body", "gliding", "freestream"];
        sec_sub_dropdown.Value = obj.section_sub_case;
        sec_sub_dropdown.Tooltip = "Steady case subtracted (e.g. for x3_wings_20deg_4Hz: ring = x3_ring, " + ...
            "body = x3_body_20deg_0Hz, gliding = x3_wings_20deg_0Hz, freestream = freestream, the empty test section)";
        sec_sub_dropdown.ValueChangedFcn = @(src, event) section_sub_case_change(src, event, plot_area_panel);

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

        % Extrapolate (velocity from the vorticity, on the field of view)
        % and Full Section (the same over the whole test section, only
        % available while Extrapolate is on) share a row
        extrap_grid = uigridlayout(sidebar_grid, [1, 2]);
        extrap_grid.Layout.Row = 11;
        extrap_grid.Layout.Column = 1;
        extrap_grid.ColumnWidth = {'1x', '1x'};
        extrap_grid.RowHeight = {'1x'};
        extrap_grid.Padding = [0 0 0 0];
        extrap_grid.ColumnSpacing = 8;

        extrapolate_button = uibutton(extrap_grid, "state");
        extrapolate_button.Layout.Row = 1;
        extrapolate_button.Layout.Column = 1;
        extrapolate_button.Text = "Extrapolate";
        extrapolate_button.FontSize = 14;
        extrapolate_button.BackgroundColor = obj.INACTIVE_COLOR;
        extrapolate_button.ValueChangedFcn = @(src, event) extrapolate_change(src, event, plot_area_panel);

        full_section_button = uibutton(extrap_grid, "state");
        full_section_button.Layout.Row = 1;
        full_section_button.Layout.Column = 2;
        full_section_button.Text = "Full Section";
        full_section_button.FontSize = 14;
        full_section_button.BackgroundColor = obj.INACTIVE_COLOR;
        full_section_button.Enable = "off"; % until Extrapolate is on
        full_section_button.ValueChangedFcn = @(src, event) full_section_change(src, event, plot_area_panel);
        % Extrapolate forces mirroring (helm_decomp mirrors the wake), so
        % the Mirror button is switched on and locked while it is active.
        % This remembers what Mirror was before, to restore it afterwards.
        mirror_before_extrapolate = obj.mirror_bool;

        % Noise Floor and its threshold share a row
        floor_grid = uigridlayout(sidebar_grid, [1, 2]);
        floor_grid.Layout.Row = 12;
        floor_grid.Layout.Column = 1;
        floor_grid.ColumnWidth = {'1x', 64};
        floor_grid.RowHeight = {'1x'};
        floor_grid.Padding = [0 0 0 0];
        floor_grid.ColumnSpacing = 8;

        floor_button = uibutton(floor_grid, "state");
        floor_button.Layout.Row = 1;
        floor_button.Layout.Column = 1;
        floor_button.Text = "Noise Floor";
        floor_button.FontSize = 14;
        floor_button.BackgroundColor = obj.INACTIVE_COLOR;
        floor_button.ValueChangedFcn = @(src, event) floor_change(src, event, plot_area_panel);

        floor_field = uieditfield(floor_grid, 'numeric');
        floor_field.Layout.Row = 1;
        floor_field.Layout.Column = 2;
        floor_field.HorizontalAlignment = 'center';
        floor_field.Value = obj.thresh;
        floor_field.ValueChangedFcn = @(src, event) thresh_change(src, event, plot_area_panel);

        % Q-mask and its threshold share a row
        q_mask_grid = uigridlayout(sidebar_grid, [1, 2]);
        q_mask_grid.Layout.Row = 13;
        q_mask_grid.Layout.Column = 1;
        q_mask_grid.ColumnWidth = {'1x', 64};
        q_mask_grid.RowHeight = {'1x'};
        q_mask_grid.Padding = [0 0 0 0];
        q_mask_grid.ColumnSpacing = 8;

        q_mask_button = uibutton(q_mask_grid, "state");
        q_mask_button.Layout.Row = 1;
        q_mask_button.Layout.Column = 1;
        q_mask_button.Text = "Q-mask";
        q_mask_button.FontSize = 14;
        q_mask_button.BackgroundColor = obj.INACTIVE_COLOR;
        q_mask_button.ValueChangedFcn = @(src, event) q_mask_change(src, event, plot_area_panel);

        q_mask_field = uieditfield(q_mask_grid, 'numeric');
        q_mask_field.Layout.Row = 1;
        q_mask_field.Layout.Column = 2;
        q_mask_field.HorizontalAlignment = 'center';
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

        % "seam comparison" only, in the frame slider's place (that plot is
        % averaged over the wingbeat): which seam, the statistic over the
        % wingbeat, and the convection speed U_c (same value as the U_c box
        % of "phase avg: 3D all planes")
        obj.seam_grid = uigridlayout(plot_grid, [1, 6]);
        obj.seam_grid.Layout.Row = 2;
        obj.seam_grid.Layout.Column = 1;
        obj.seam_grid.ColumnWidth = {44, '1x', 70, 64, 60, 36};
        obj.seam_grid.RowHeight = {'1x'};
        obj.seam_grid.Padding = [0 0 0 0];
        obj.seam_grid.ColumnSpacing = 8;
        obj.seam_grid.Visible = "off";

        seam_label = uilabel(obj.seam_grid);
        seam_label.Layout.Row = 1;
        seam_label.Layout.Column = 1;
        seam_label.Text = "Seam";
        seam_label.FontSize = 14;
        seam_label.HorizontalAlignment = 'right';

        obj.seam_slider = uislider(obj.seam_grid);
        obj.seam_slider.Layout.Row = 1;
        obj.seam_slider.Layout.Column = 2;
        obj.seam_slider.Limits = [1 2];
        obj.seam_slider.Value = obj.seam_ind;
        obj.seam_slider.MajorTicks = 1:2;
        obj.seam_slider.MinorTicks = [];
        obj.seam_slider.Tooltip = "Seam to compare: the measured field of the downstream plane " + ...
            "minus the frozen-flow reconstruction from the upstream plane where it reaches it";
        obj.seam_slider.ValueChangedFcn = @(src, event) seam_change(src, event, plot_area_panel);

        seam_stat_dropdown = uidropdown(obj.seam_grid);
        seam_stat_dropdown.Layout.Row = 1;
        seam_stat_dropdown.Layout.Column = 3;
        seam_stat_dropdown.Items = obj.SEAM_STATS;
        seam_stat_dropdown.Value = obj.seam_stat;
        seam_stat_dropdown.Tooltip = "Over the wingbeat: mean of the difference (signed; this equals the " + ...
            "difference of the two planes' time averages, so it doesn't depend on U_c), or its rms " + ...
            "(includes the phase mismatch, so it depends on U_c)";
        seam_stat_dropdown.ValueChangedFcn = @(src, event) seam_stat_change(src, event, plot_area_panel);

        seam_uc_label = uilabel(obj.seam_grid);
        seam_uc_label.Layout.Row = 1;
        seam_uc_label.Layout.Column = 4;
        seam_uc_label.Text = "U_c (m/s)";
        seam_uc_label.HorizontalAlignment = 'right';

        obj.seam_conv_field = uieditfield(obj.seam_grid, "numeric");
        obj.seam_conv_field.Layout.Row = 1;
        obj.seam_conv_field.Layout.Column = 5;
        obj.seam_conv_field.Limits = [0 Inf];
        obj.seam_conv_field.LowerLimitInclusive = "off";
        obj.seam_conv_field.ValueDisplayFormat = '%.3g';
        obj.seam_conv_field.HorizontalAlignment = 'center';
        obj.seam_conv_field.Tooltip = "Wake convection speed of the frozen-flow reconstruction (same as on " + ...
            "phase avg: 3D all planes)";
        obj.seam_conv_field.ValueChangedFcn = @(src, event) merged_conv_change(src, event, plot_area_panel);

        seam_uc_reset_button = uibutton(obj.seam_grid);
        seam_uc_reset_button.Layout.Row = 1;
        seam_uc_reset_button.Layout.Column = 6;
        seam_uc_reset_button.Text = "U∞";
        seam_uc_reset_button.Tooltip = "Back to each file's freestream speed U";
        seam_uc_reset_button.ButtonPushedFcn = @(src, event) merged_conv_reset(src, event, plot_area_panel);

        obj.play_button = uibutton(plot_grid, "state");
        obj.play_button.Layout.Row = 3;
        obj.play_button.Layout.Column = 1;
        obj.play_button.Text = "Play";
        obj.play_button.FontSize = 18;
        obj.play_button.BackgroundColor = obj.INACTIVE_COLOR;
        obj.play_button.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_area_panel);

        obj.param_panel = uipanel(sidebar_grid);
        obj.param_panel.Layout.Row = 14;
        obj.param_panel.Layout.Column = 1;
        obj.param_panel.Visible = "off";
        obj.param_panel.Title = "3D Plot Parameters";
        obj.param_panel.TitlePosition = 'centertop';

        param_grid = uigridlayout(obj.param_panel, [16, 1]);
        param_grid.ColumnWidth = {'1x'};
        % isovalue, iso variable, views, fixed y / z limits, x-axis /
        % shift / stroke labels, Remove Small, Unc Mask, number of
        % wingbeats, Card Style, Crop Box
        param_grid.RowHeight = {22, 55, 30, 50, 18, 24, 52, 30, 30, 30, 30, 30, 22, 55, 30, 52};
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
        l2.Layout.Row = 13;
        l2.Layout.Column = 1;
        l2.HorizontalAlignment = 'center';
        l2.Text = 'Number of Wingbeats';

        num_cycles_slider = uislider(param_grid);
        num_cycles_slider.Layout.Row = 14;
        num_cycles_slider.Layout.Column = 1;
        num_cycles_slider.Limits = [1 5];
        num_cycles_slider.Value = obj.num_cycles;
        num_cycles_slider.MajorTicks = 1:5;
        num_cycles_slider.MinorTicks = [];
        num_cycles_slider.ValueChangedFcn = @(src, event) num_cycles_change(src, event, plot_area_panel);

        % Fix Limits: hold the y and z axes at the limits typed beside it,
        % so different cases are drawn on the same axes. Turning it on the
        % first time fills the boxes with the current plot's limits.
        lims_grid = uigridlayout(param_grid, [2, 4]);
        lims_grid.Layout.Row = 7;
        lims_grid.Layout.Column = 1;
        lims_grid.ColumnWidth = {'1x', 14, 44, 44};
        lims_grid.RowHeight = {'1x', '1x'};
        lims_grid.Padding = [0 0 0 0];
        lims_grid.RowSpacing = 4;
        lims_grid.ColumnSpacing = 3;

        fix_lims_button = uibutton(lims_grid, "state");
        fix_lims_button.Layout.Row = [1 2];
        fix_lims_button.Layout.Column = 1;
        fix_lims_button.Text = "Fix Limits";
        fix_lims_button.FontSize = 14;
        fix_lims_button.Value = obj.fix_lims_bool;
        fix_lims_button.BackgroundColor = obj.get_button_color(obj.fix_lims_bool);
        fix_lims_button.Tooltip = "Hold the y/c and z/c axis limits at the values beside it (x is always 0 to 1 in t/T). Off: limits follow the data";
        fix_lims_button.ValueChangedFcn = @(src, event) fix_lims_change(src, event, plot_area_panel);

        lim_names = ["y", "z"];
        lim_sides = ["lower", "upper"];
        lim_fields = gobjects(2, 2);
        for lim_row = 1:2
            lim_label = uilabel(lims_grid);
            lim_label.Layout.Row = lim_row;
            lim_label.Layout.Column = 2;
            lim_label.Text = lim_names(lim_row);
            lim_label.HorizontalAlignment = 'right';
            for lim_col = 1:2
                lim_f = uieditfield(lims_grid, "numeric");
                lim_f.Layout.Row = lim_row;
                lim_f.Layout.Column = 2 + lim_col;
                lim_f.HorizontalAlignment = 'center';
                lim_f.ValueDisplayFormat = '%.3g';
                if lim_row == 1
                    lim_f.Value = obj.fix_ylim(lim_col);
                else
                    lim_f.Value = obj.fix_zlim(lim_col);
                end
                lim_f.Tooltip = lim_names(lim_row) + "/c " + lim_sides(lim_col) + " limit (Fix Limits)";
                lim_f.ValueChangedFcn = @(src, event) fix_lims_value_change(src, event, plot_area_panel);
                lim_fields(lim_row, lim_col) = lim_f;
            end
        end

        % x-axis as wingbeat time (t/T) or convective distance (x/c = U t / c)
        conv_units_button = uibutton(param_grid, "state");
        conv_units_button.Layout.Row = 8;
        conv_units_button.Layout.Column = 1;
        conv_units_button.Text = "x-axis: t/T";
        conv_units_button.FontSize = 16;
        conv_units_button.Value = obj.conv_units_bool;
        conv_units_button.BackgroundColor = obj.INACTIVE_COLOR;
        conv_units_button.Tooltip = "Toggle the 3D plot x-axis between wingbeat time t/T and convective units x/c = U t / c";
        conv_units_button.ValueChangedFcn = @(src, event) conv_units_change(src, event, plot_area_panel);

        % Phase shift by the convection time from the robot to the imaging
        % plane (same as phaseAvg_UI's Convection Shift button), and next
        % to it the stroke order (UDU, DUD, DU, UD), a further shift
        conv_shift_grid = uigridlayout(param_grid, [1, 2]);
        conv_shift_grid.Layout.Row = 9;
        conv_shift_grid.Layout.Column = 1;
        conv_shift_grid.ColumnWidth = {'1x', 62};
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

        stroke_order_dropdown = uidropdown(conv_shift_grid);
        stroke_order_dropdown.Layout.Row = 1;
        stroke_order_dropdown.Layout.Column = 2;
        stroke_order_dropdown.Items = ["UDU", "DUD", "DU", "UD"];
        stroke_order_dropdown.Value = obj.stroke_order;
        stroke_order_dropdown.FontSize = 12;
        stroke_order_dropdown.Enable = obj.conv_shift;
        stroke_order_dropdown.Tooltip = "Order of the strokes across the wingbeat (D = downstroke, U = upstroke). " + ...
            "UDU: downstroke centred. DUD: upstroke centred. DU: starts at the top of the stroke. " + ...
            "UD: starts at the bottom. From the stroke reversals in the wing position. Requires Convection Shift";
        stroke_order_dropdown.ValueChangedFcn = @(src, event) stroke_order_change(src, event, plot_area_panel);

        % "phase avg: 3D all planes" only, in place of Convection Shift:
        % wake convection speed U_c for the frozen-flow reconstruction,
        % and "U∞" to go back to each file's freestream speed
        uc_grid = uigridlayout(param_grid, [1, 3]);
        uc_grid.Layout.Row = 9;
        uc_grid.Layout.Column = 1;
        uc_grid.ColumnWidth = {'1x', 56, 36};
        uc_grid.RowHeight = {'1x'};
        uc_grid.Padding = [0 0 0 0];
        uc_grid.ColumnSpacing = 4;
        uc_grid.Visible = "off";

        uc_label = uilabel(uc_grid);
        uc_label.Layout.Row = 1;
        uc_label.Layout.Column = 1;
        uc_label.Text = "U_c (m/s)";
        uc_label.HorizontalAlignment = 'right';

        obj.merged_conv_field = uieditfield(uc_grid, "numeric");
        obj.merged_conv_field.Layout.Row = 1;
        obj.merged_conv_field.Layout.Column = 2;
        obj.merged_conv_field.Limits = [0 Inf];
        obj.merged_conv_field.LowerLimitInclusive = "off";
        obj.merged_conv_field.ValueDisplayFormat = '%.3g';
        obj.merged_conv_field.HorizontalAlignment = 'center';
        obj.merged_conv_field.Tooltip = "Wake convection speed used to turn time into streamwise distance " + ...
            "(frozen flow) on the all-planes plot. Tune it until the isosurfaces line up where one plane's " + ...
            "reconstruction meets the next";
        obj.merged_conv_field.ValueChangedFcn = @(src, event) merged_conv_change(src, event, plot_area_panel);

        uc_reset_button = uibutton(uc_grid);
        uc_reset_button.Layout.Row = 1;
        uc_reset_button.Layout.Column = 3;
        uc_reset_button.Text = "U∞";
        uc_reset_button.Tooltip = "Back to each file's freestream speed U";
        uc_reset_button.ButtonPushedFcn = @(src, event) merged_conv_reset(src, event, plot_area_panel);

        % Stroke reversal lines, downstroke shading and up/downstroke
        % labels; drawn only in the 2D views that show the x-axis
        % (+/-yz, +/-xz). Needs the convection shift, like phaseAvg_UI.
        label_stroke_button = uibutton(param_grid, "state");
        label_stroke_button.Layout.Row = 10;
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
        view_grid.Layout.Row = 4;
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
        iso_label.Layout.Row = 5;
        iso_label.Layout.Column = 1;
        iso_label.HorizontalAlignment = 'center';
        iso_label.Text = 'Iso views';

        iso_grid = uigridlayout(param_grid, [1, 4]);
        iso_grid.Layout.Row = 6;
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

        % Cosmetic "card" look: lighting, red-green diverging colormap
        % (best with ω_x as the colour variable), dark background, axes
        % hidden. Turning it off restores the plot exactly as it was.
        card_style_button = uibutton(param_grid, "state");
        card_style_button.Layout.Row = 15;
        card_style_button.Layout.Column = 1;
        card_style_button.Text = "Card Style";
        card_style_button.FontSize = 16;
        card_style_button.Value = obj.card_style;
        card_style_button.BackgroundColor = obj.get_button_color(obj.card_style);
        card_style_button.Tooltip = "Lit isosurface, red-green colormap symmetric about zero (choose ω_x as the variable), dark background and no axes. Off restores the original look";
        card_style_button.ValueChangedFcn = @(src, event) card_style_change(src, event, plot_area_panel);

        % Remove Small: hide small disconnected pieces of the isosurface
        % (speckle), threshold as % of the largest piece
        small_grid = uigridlayout(param_grid, [1, 3]);
        small_grid.Layout.Row = 11;
        small_grid.Layout.Column = 1;
        small_grid.ColumnWidth = {'1x', 46, 14};
        small_grid.RowHeight = {'1x'};
        small_grid.Padding = [0 0 0 0];
        small_grid.ColumnSpacing = 3;

        remove_small_button = uibutton(small_grid, "state");
        remove_small_button.Layout.Row = 1;
        remove_small_button.Layout.Column = 1;
        remove_small_button.Text = "Remove Small";
        remove_small_button.FontSize = 16;
        remove_small_button.Value = obj.remove_small_bool;
        remove_small_button.BackgroundColor = obj.get_button_color(obj.remove_small_bool);
        remove_small_button.Tooltip = "Hide small disconnected pieces of the isosurface. Only hides triangles; the data are unchanged";
        remove_small_button.ValueChangedFcn = @(src, event) remove_small_change(src, event, plot_area_panel);

        remove_small_field = uieditfield(small_grid, "numeric");
        remove_small_field.Layout.Row = 1;
        remove_small_field.Layout.Column = 2;
        remove_small_field.Limits = [0 100];
        remove_small_field.Value = obj.remove_small_pct;
        remove_small_field.HorizontalAlignment = 'center';
        remove_small_field.Tooltip = "Remove Small: hide isosurface pieces with fewer triangles than this % of the largest piece";
        remove_small_field.ValueChangedFcn = @(src, event) remove_small_pct_change(src, event, plot_area_panel);

        remove_small_label = uilabel(small_grid);
        remove_small_label.Layout.Row = 1;
        remove_small_label.Layout.Column = 3;
        remove_small_label.Text = '%';

        % Uncertainty mask: hide the isosurface where the wingbeat-averaged
        % total uncertainty is above the threshold (% of freestream)
        unc_grid = uigridlayout(param_grid, [1, 3]);
        unc_grid.Layout.Row = 12;
        unc_grid.Layout.Column = 1;
        unc_grid.ColumnWidth = {'1x', 46, 14};
        unc_grid.RowHeight = {'1x'};
        unc_grid.Padding = [0 0 0 0];
        unc_grid.ColumnSpacing = 3;

        unc_mask_button = uibutton(unc_grid, "state");
        unc_mask_button.Layout.Row = 1;
        unc_mask_button.Layout.Column = 1;
        unc_mask_button.Text = "Unc Mask";
        unc_mask_button.FontSize = 16;
        unc_mask_button.Value = obj.unc_mask_bool;
        unc_mask_button.BackgroundColor = obj.get_button_color(obj.unc_mask_bool);
        unc_mask_button.Tooltip = "Hide the isosurface where the total uncertainty, averaged over the wingbeat, is above this % of the freestream speed. Display only: the data and other calculations are unchanged";
        unc_mask_button.ValueChangedFcn = @(src, event) unc_mask_change(src, event, plot_area_panel);

        unc_mask_field = uieditfield(unc_grid, "numeric");
        unc_mask_field.Layout.Row = 1;
        unc_mask_field.Layout.Column = 2;
        unc_mask_field.Limits = [0 Inf];
        unc_mask_field.Value = obj.unc_mask_thresh;
        unc_mask_field.HorizontalAlignment = 'center';
        unc_mask_field.Tooltip = "Uncertainty mask threshold, % of the freestream speed";
        unc_mask_field.ValueChangedFcn = @(src, event) unc_mask_thresh_change(src, event, plot_area_panel);

        unc_mask_label = uilabel(unc_grid);
        unc_mask_label.Layout.Row = 1;
        unc_mask_label.Layout.Column = 3;
        unc_mask_label.Text = '%';

        % Crop Box: hide the isosurface inside a y-z box (e.g. the wire
        % wake), laid out like Fix Limits: y and z rows, lower / upper. A
        % second copy for the 2D plots (centroid) is made below; both set
        % the same box.
        crop_ctrls = struct('button', {}, 'fields', {});
        crop_ctrls(1) = make_crop_controls(param_grid, 16, 1, ...
            "Hide the isosurface inside the y-z box beside it (e.g. the wake of the robot's wires). " + ...
            "y from the mirror centreline, z as plotted, in chords. Also leaves the box out of the 2D centroid. " + ...
            "Display only: the data and other calculations are unchanged");

        save_button = uibutton(sidebar_grid, "state");
        save_button.Layout.Row = 15;
        save_button.Layout.Column = 1;
        save_button.Text = "Save Figure";
        save_button.FontSize = 18;
        save_button.BackgroundColor = obj.INACTIVE_COLOR;
        save_button.ValueChangedFcn = @(src, event) save_figure(src, event, plot_area_panel);

        % Saves "phase avg: movie" / "phase std: movie" as a .gif, one
        % frame per phase bin
        save_movie_button = uibutton(sidebar_grid, "push");
        save_movie_button.Layout.Row = 16;
        save_movie_button.Layout.Column = 1;
        save_movie_button.Text = "Save Movie";
        save_movie_button.FontSize = 18;
        save_movie_button.BackgroundColor = obj.INACTIVE_COLOR;
        save_movie_button.Tooltip = "Save the movie (every phase bin, from bin 1 to the last) as a .gif. " + ...
            "Only for phase avg: movie and phase std: movie";
        save_movie_button.ButtonPushedFcn = @(src, event) save_movie(src, event, plot_area_panel);

        % Uncertainty isolines on the 2D plots (types 1-4), like Unc Mask
        % for the 3D plot
        unc_cen_grid = uigridlayout(sidebar_grid, [3, 2]);
        unc_cen_grid.Layout.Row = 17;
        unc_cen_grid.Layout.Column = 1;
        unc_cen_grid.ColumnWidth = {'1x', '1x'};
        unc_cen_grid.RowHeight = {30, 30, 52};
        unc_cen_grid.Padding = [0 0 0 0];
        unc_cen_grid.ColumnSpacing = 4;
        unc_cen_grid.RowSpacing = 4;

        unc_contour_button = uibutton(unc_cen_grid, "state");
        unc_contour_button.Layout.Row = 1;
        unc_contour_button.Layout.Column = 1;
        unc_contour_button.Text = "Unc Contours";
        unc_contour_button.FontSize = 16;
        unc_contour_button.Value = obj.unc_contour_bool;
        unc_contour_button.BackgroundColor = obj.get_button_color(obj.unc_contour_bool);
        unc_contour_button.Tooltip = "Black isolines of the total uncertainty averaged over the wingbeat, at " + ...
            strjoin(string(obj.unc_contour_levels), ", ") + " % of the freestream speed";
        unc_contour_button.ValueChangedFcn = @(src, event) unc_contour_change(src, event, plot_area_panel);

        % Centroid of the plotted field (2D time avg and phase avg movie)
        centroid_button = uibutton(unc_cen_grid, "state");
        centroid_button.Layout.Row = 1;
        centroid_button.Layout.Column = 2;
        centroid_button.Text = "Centroid";
        centroid_button.FontSize = 16;
        centroid_button.Value = obj.centroid_bool;
        centroid_button.BackgroundColor = obj.get_button_color(obj.centroid_bool);
        centroid_button.Tooltip = "Black dot at the centroid of the plotted field, weighted by its departure " + ...
            "from the background value (0, or -1 / 1 for velocities) with the dominant sign only. " + ...
            "Points removed by the uncertainty mask (threshold below, mode from default_trim_bounds) carry no weight. " + ...
            "Computed live; follows the bins in the movie";
        centroid_button.ValueChangedFcn = @(src, event) centroid_change(src, event, plot_area_panel);

        % Centroid uncertainty mask threshold (% of freestream, 0 = off)
        cen_unc_grid = uigridlayout(unc_cen_grid, [1, 3]);
        cen_unc_grid.Layout.Row = 2;
        cen_unc_grid.Layout.Column = [1 2];
        cen_unc_grid.ColumnWidth = {'1x', 46, 14};
        cen_unc_grid.RowHeight = {'1x'};
        cen_unc_grid.Padding = [0 0 0 0];
        cen_unc_grid.ColumnSpacing = 3;

        cen_unc_label = uilabel(cen_unc_grid);
        cen_unc_label.Layout.Row = 1;
        cen_unc_label.Layout.Column = 1;
        cen_unc_label.Text = "Centroid unc mask";
        cen_unc_label.HorizontalAlignment = 'right';

        cen_unc_field = uieditfield(cen_unc_grid, "numeric");
        cen_unc_field.Layout.Row = 1;
        cen_unc_field.Layout.Column = 2;
        cen_unc_field.Limits = [0 Inf];
        cen_unc_field.Value = obj.centroid_unc_pct;
        cen_unc_field.HorizontalAlignment = 'center';
        cen_unc_field.Tooltip = "Uncertainty mask threshold for the centroid, % of the freestream speed " + ...
            "(0 = no mask). The mask boundary is drawn as a dashed line";
        cen_unc_field.ValueChangedFcn = @(src, event) centroid_unc_change(src, event, plot_area_panel);

        cen_unc_pct_label = uilabel(cen_unc_grid);
        cen_unc_pct_label.Layout.Row = 1;
        cen_unc_pct_label.Layout.Column = 3;
        cen_unc_pct_label.Text = '%';

        % Crop Box for the centroid (same box as the 3D plot's): points in
        % the box carry no weight, like the uncertainty mask
        crop_ctrls(2) = make_crop_controls(unc_cen_grid, 3, [1 2], ...
            "Leave the y-z box beside it out of the centroid (e.g. the wake of the robot's wires), " + ...
            "together with the uncertainty mask; the kept region is outlined. y from the mirror centreline, " + ...
            "z as plotted, in chords. Same box as the 3D plot's Crop Box");
        crop_grid_2D = crop_ctrls(2).button.Parent;

        % Set up plot titles and axes
        set_unc_contour_visibility();
        set_param_panel_visibility(obj.is_3D_plot_type());
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
            if obj.RPCA, set_HRPP(false); end

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
            if obj.HR, set_HRPP(false); end

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        % HRPP is a different method from the binned HR / RPCA variants,
        % so it can't be combined with them (as in timeAvg_UI)
        function HRPP_change(src, ~, plot_panel)
            previous_plot_type = obj.plot_type;
            set_HRPP(src.Value);
            if obj.HRPP
                obj.HR = false;
                hr_button.Value = false;
                hr_button.BackgroundColor = obj.get_button_color(false);
                obj.RPCA = false;
                rpca_button.Value = false;
                rpca_button.BackgroundColor = obj.get_button_color(false);
            end

            refresh_case_dropdown();
            refresh_plot_type_dropdown();
            refresh_variable_dropdown(previous_plot_type);

            obj.frame_ind = 1;
            obj.slider.Value = obj.frame_ind;

            obj.update_plot(plot_panel);
        end

        function set_HRPP(value)
            obj.HRPP = value;
            hrpp_button.Value = value;
            hrpp_button.BackgroundColor = obj.get_button_color(value);
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
            set(plot_type_dropdown, 'Items', obj.get_plot_type_labels(available_plot_types), ...
                'ItemsData', available_plot_types);
            if ~any(available_plot_types == obj.plot_type)
                obj.plot_type = available_plot_types(1);
            end
            plot_type_dropdown.Value = obj.plot_type;
        end

        function refresh_variable_dropdown(previous_plot_type)
            phase_avg_plots = obj.plot_types([1 2 5 9 12 14]);
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
                elseif ismember(obj.plot_type, obj.plot_types([10 13]))
                    obj.var_name_list = obj.section_plot_vars;
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

            set_param_panel_visibility(obj.is_3D_plot_type());
            set_unc_contour_visibility();
            obj.set_section_controls();
            set_merged_controls();
        end

        % "phase avg: 3D all planes" uses every downstream position, so the
        % position dropdown is hidden, and its x-axis is always the
        % streamwise distance from the robot (no t/T axis, convection
        % shift or stroke labels)
        function set_merged_controls()
            is_merged = obj.plot_type == obj.MERGED_3D_PLOT;
            conv_units_button.Enable = ~is_merged;
            conv_shift_button.Enable = ~is_merged;
            stroke_order_dropdown.Enable = obj.conv_shift && ~is_merged;
            % U_c takes Convection Shift's place on the all-planes plot
            conv_shift_grid.Visible = ~is_merged;
            uc_grid.Visible = is_merged;
            label_stroke_button.Enable = obj.conv_shift && ~is_merged;
            if is_merged
                num_cycles_slider.Tooltip = "Wingbeats of wake reconstructed downstream of the last plane";
            else
                num_cycles_slider.Tooltip = "";
            end
            % seam comparison: its seam controls replace the frame slider
            % and Play (plot_seam_comparison hides those)
            obj.seam_grid.Visible = obj.plot_type == obj.SEAM_PLOT;
            set_distance_dropdown_visibility();
        end

        function merged_conv_change(src, ~, plot_panel)
            obj.merged_conv_speed = src.Value;
            if obj.is_all_planes_plot_type()
                obj.update_plot(plot_panel); % same view, new surface
            end
        end

        function merged_conv_reset(~, ~, plot_panel)
            obj.merged_conv_speed = [];
            if obj.is_all_planes_plot_type()
                obj.update_plot(plot_panel);
            end
        end

        function seam_change(src, ~, plot_panel)
            src.Value = round(src.Value); % snap to a seam
            if src.Value == obj.seam_ind
                return
            end
            obj.seam_ind = src.Value;
            obj.update_plot(plot_panel);
        end

        function seam_stat_change(src, ~, plot_panel)
            obj.seam_stat = string(src.Value);
            obj.update_plot(plot_panel);
        end

        function section_count_change(src, ~, plot_panel)
            obj.section_count = string(src.Value);
            obj.update_plot(plot_panel);
        end

        function section_unc_change(src, ~, plot_panel)
            obj.section_unc_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.section_unc_bool);
            obj.update_plot(plot_panel);
        end

        function section_unc_pct_change(src, ~, plot_panel)
            obj.section_unc_pct = src.Value;
            if obj.section_unc_bool
                obj.update_plot(plot_panel);
            end
        end

        function section_sub_change(src, ~, plot_panel)
            obj.section_sub_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.section_sub_bool);
            obj.update_plot(plot_panel);
        end

        function section_sub_case_change(src, ~, plot_panel)
            obj.section_sub_case = string(src.Value);
            if obj.section_sub_bool
                obj.update_plot(plot_panel);
            end
        end

        function section_unc_mode_change(src, ~, plot_panel)
            obj.section_unc_mode = string(src.Value);
            if obj.section_unc_bool
                obj.update_plot(plot_panel);
            end
        end

        function set_distance_dropdown_visibility()
            is_visible = obj.is_flapper_source_mode(obj.source_mode) && ~isempty(obj.distance_labels) && ...
                ~obj.is_all_planes_plot_type();
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

        % Unc Contours: only for time avg of phase avg, phase avg: movie,
        % time avg of phase std and phase std: movie
        function set_unc_contour_visibility()
            row_heights = sidebar_grid.RowHeight;
            if ismember(obj.plot_type, obj.plot_types(1:4))
                unc_contour_button.Visible = "on";
                row_heights{17} = 30;
            else
                unc_contour_button.Visible = "off";
                row_heights{17} = 0;
            end
            % Save Movie: only the 2D movies (phase avg / phase std)
            if ismember(obj.plot_type, obj.plot_types([2 4 13]))
                save_movie_button.Enable = "on";
            else
                save_movie_button.Enable = "off";
            end
            if ismember(obj.plot_type, obj.plot_types(1:2))
                centroid_button.Visible = "on";
                cen_unc_grid.Visible = "on";
                crop_grid_2D.Visible = "on";
                unc_cen_grid.RowHeight = {30, 30, 52};
                row_heights{17} = 30 + 30 + 52 + 2 * unc_cen_grid.RowSpacing;
            else
                centroid_button.Visible = "off";
                cen_unc_grid.Visible = "off";
                crop_grid_2D.Visible = "off";
                unc_cen_grid.RowHeight = {'1x', 0, 0};
            end
            sidebar_grid.RowHeight = row_heights;
        end

        function centroid_unc_change(src, ~, plot_panel)
            obj.centroid_unc_pct = src.Value;
            if obj.centroid_bool
                obj.update_plot(plot_panel);
            end
        end

        function centroid_change(src, ~, plot_panel)
            obj.centroid_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.centroid_bool);
            obj.update_plot(plot_panel);
        end

        function unc_contour_change(src, ~, plot_panel)
            obj.unc_contour_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.unc_contour_bool);
            obj.update_plot(plot_panel);
        end

        function set_param_panel_visibility(is_visible)
            row_heights = sidebar_grid.RowHeight;
            if is_visible
                obj.param_panel.Visible = "on";
                row_heights{14} = 689;
            else
                obj.param_panel.Visible = "off";
                row_heights{14} = 0;
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

                full_section_button.Enable = "on";
            else
                obj.extrapolate_bool = false;
                src.BackgroundColor = obj.INACTIVE_COLOR;

                % Full Section only applies to extrapolated data
                obj.full_section_bool = false;
                full_section_button.Value = false;
                full_section_button.BackgroundColor = obj.INACTIVE_COLOR;
                full_section_button.Enable = "off";

                % Give Mirror back to the user in the state it was in
                obj.mirror_bool = mirror_before_extrapolate;
                mirror_button.Value = mirror_before_extrapolate;
                mirror_button.BackgroundColor = obj.get_button_color(mirror_before_extrapolate);
                mirror_button.Enable = "on";
            end

            obj.update_plot(plot_panel);
        end

        function full_section_change(src, ~, plot_panel)
            obj.full_section_bool = src.Value && obj.extrapolate_bool;
            src.Value = obj.full_section_bool;
            src.BackgroundColor = obj.get_button_color(obj.full_section_bool);
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
            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            obj.copy_plot_to_figure(plot_panel, fignew);
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

        % Steps the 2D movie through every phase bin (bin 1 to the last)
        % and appends each one to a .gif. The bins are drawn by the same
        % play loop as the Play button (update_plot), which calls
        % capture_frame after drawing each bin.
        function save_movie(~, ~, plot_panel)
            fig = ancestor(plot_panel, 'figure');
            if ~ismember(obj.plot_type, obj.plot_types([2 4 13]))
                uialert(fig, "Save Movie is only for phase avg: movie and phase std: movie.", "Save Movie");
                return
            end
            if obj.play
                uialert(fig, "Stop the movie before saving it.", "Save Movie");
                return
            end

            default_name = regexprep(obj.plot_type + "_" + obj.get_current_case_id() + ...
                "_" + obj.variable_name, "[^\w\-]+", "_") + ".gif";
            [file, folder] = uiputfile("*.gif", "Save Movie", default_name);
            figure(fig); % uiputfile can leave the app behind other windows
            if isequal(file, 0)
                return
            end
            filename = fullfile(folder, file);

            dlg = uiprogressdlg(fig, 'Title', "Saving Movie", ...
                'Message', "Preparing...", 'Cancelable', 'on');
            panel_units = plot_panel.Units;
            plot_panel.Units = 'pixels';
            panel_pos = plot_panel.Position;
            plot_panel.Units = panel_units;
            % off-screen copy of the plot panel, one frame per bin
            fignew = figure('Visible', 'off', 'Units', 'pixels', ...
                'Position', [100 100 panel_pos(3) panel_pos(4)]);

            start_frame = obj.frame_ind;
            num_saved = 0;
            save_error = [];
            % frames are kept until the end so all of them get the same
            % crop: the smallest box holding the content of every frame
            frames = {};
            bbox = [Inf -Inf Inf -Inf]; % [row_min row_max col_min col_max]
            try
                obj.frame_ind = 1;
                obj.slider.Value = 1;
                obj.movie_frame_fcn = @capture_frame;
                obj.play = true; % play loop runs bin 1 -> last bin, capture_frame stops it
                obj.update_plot(plot_panel);
            catch save_error
            end
            was_cancelled = dlg.CancelRequested;
            if isempty(save_error) && ~isempty(frames)
                dlg.Message = "Writing " + numel(frames) + " frames...";
                try
                    write_gif();
                catch save_error
                end
            end

            % back to the frame shown before saving
            obj.movie_frame_fcn = [];
            obj.play = false;
            obj.frame_ind = min(max(start_frame, 1), obj.num_bins);
            obj.slider.Value = obj.frame_ind;
            if isvalid(fignew)
                delete(fignew);
            end
            close(dlg);
            obj.update_plot(plot_panel);

            if ~isempty(save_error)
                uialert(fig, "Saving the movie failed: " + save_error.message, "Save Movie");
            elseif was_cancelled
                uialert(fig, "Cancelled: " + num_saved + " of " + obj.num_bins + ...
                    " bins saved to " + filename, "Save Movie", 'Icon', 'warning');
            else
                disp("Saved " + num_saved + " bins to " + filename)
            end

            function capture_frame()
                k = obj.frame_ind;
                delete(fignew.Children);
                obj.copy_plot_to_figure(plot_panel, fignew);
                img = print(fignew, '-RGBImage', '-r0');
                % content = pixels that differ from the background (corner
                % pixel colour); widen the box to cover this frame
                bg = img(1, 1, :);
                content = any(abs(int16(img) - int16(bg)) > 8, 3);
                rows = find(any(content, 2));
                cols = find(any(content, 1));
                if ~isempty(rows)
                    bbox = [min(bbox(1), rows(1)), max(bbox(2), rows(end)), ...
                            min(bbox(3), cols(1)), max(bbox(4), cols(end))];
                end
                frames{end+1} = img;
                num_saved = num_saved + 1;

                dlg.Value = k / obj.num_bins;
                dlg.Message = "Saving bin " + k + " of " + obj.num_bins;
                if k >= obj.num_bins || dlg.CancelRequested
                    obj.play = false; % ends the play loop in update_plot
                end
            end

            % crop every frame to the common box (plus MOVIE_CROP_PAD) and
            % write the .gif
            function write_gif()
                [h, w, ~] = size(frames{1});
                pad = obj.MOVIE_CROP_PAD;
                if all(isfinite(bbox))
                    r = max(1, bbox(1) - pad):min(h, bbox(2) + pad);
                    c = max(1, bbox(3) - pad):min(w, bbox(4) + pad);
                else
                    r = 1:h; c = 1:w; % nothing drawn: keep the full frame
                end
                for f = 1:numel(frames)
                    [A, cmap] = rgb2ind(frames{f}(r, c, :), 256);
                    if f == 1
                        imwrite(A, cmap, filename, "gif", "LoopCount", Inf, ...
                            "DelayTime", obj.MOVIE_FRAME_DELAY);
                    else
                        imwrite(A, cmap, filename, "gif", "WriteMode", "append", ...
                            "DelayTime", obj.MOVIE_FRAME_DELAY);
                    end
                end
            end
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

            % the stroke order only means something in the wing phase, so
            % it needs the convection shift too; reset when it goes off
            if ~obj.conv_shift
                obj.stroke_order = "UDU";
                stroke_order_dropdown.Value = obj.stroke_order;
            end
            stroke_order_dropdown.Enable = obj.conv_shift;

            if obj.plot_type == obj.plot_types(5)
                obj.update_plot(plot_panel);
            end
        end

        function stroke_order_change(src, ~, plot_panel)
            obj.stroke_order = string(src.Value);
            if ~obj.conv_shift
                obj.stroke_order = "UDU";
                src.Value = obj.stroke_order;
            end
            if obj.plot_type ~= obj.plot_types(5)
                return
            end
            % only the phase changes, so move the existing surface instead
            % of reloading and recomputing it; full redraw if that can't
            % be done (e.g. while playing)
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            if ~obj.shift_3D_surface(ax)
                obj.update_plot(plot_panel);
            else
                obj.apply_remove_small(ax); % filter the shifted surface
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

        function card_style_change(src, ~, plot_panel)
            obj.card_style = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.card_style);
            % restyle the current 3D plot in place, no reload or redraw
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            if obj.card_style
                if obj.is_3D_plot_type()
                    obj.apply_card_style(ax);
                end
            else
                obj.remove_card_style(ax);
                obj.restore_card_panel(plot_panel);
            end
        end

        function fix_lims_change(src, ~, plot_panel)
            obj.fix_lims_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.fix_lims_bool);
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            if obj.fix_lims_bool && ~obj.fix_lims_set && isscalar(ax) && obj.is_3D_plot_type()
                % first use: start from the current plot's limits
                obj.fix_ylim = round(ax.YLim, 2);
                obj.fix_zlim = round(ax.ZLim, 2);
                obj.fix_lims_set = true;
                set_lim_fields();
            end
            if obj.is_3D_plot_type()
                obj.apply_fixed_lims(ax);
            end
        end

        function fix_lims_value_change(~, ~, plot_panel)
            ylim_new = [lim_fields(1,1).Value, lim_fields(1,2).Value];
            zlim_new = [lim_fields(2,1).Value, lim_fields(2,2).Value];
            if ylim_new(1) >= ylim_new(2) || zlim_new(1) >= zlim_new(2)
                set_lim_fields(); % lower must be below upper: undo
                return
            end
            obj.fix_ylim = ylim_new;
            obj.fix_zlim = zlim_new;
            obj.fix_lims_set = true;
            if obj.fix_lims_bool && obj.is_3D_plot_type()
                ax = findobj(plot_panel.Children, 'Type', 'axes');
                obj.apply_fixed_lims(ax);
            end
        end

        function set_lim_fields()
            lim_fields(1,1).Value = obj.fix_ylim(1);
            lim_fields(1,2).Value = obj.fix_ylim(2);
            lim_fields(2,1).Value = obj.fix_zlim(1);
            lim_fields(2,2).Value = obj.fix_zlim(2);
        end

        function unc_mask_change(src, ~, plot_panel)
            obj.unc_mask_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.unc_mask_bool);
            if obj.is_3D_plot_type()
                obj.update_plot(plot_panel); % new isosurface, same view
            end
        end

        % Crop Box button and four limit fields (y lower / upper, z lower /
        % upper) in a 2 x 4 grid like Fix Limits
        function ctrl = make_crop_controls(parent, row, col, tip)
            g = uigridlayout(parent, [2, 4]);
            g.Layout.Row = row;
            g.Layout.Column = col;
            g.ColumnWidth = {'1x', 12, 38, 38};
            g.RowHeight = {'1x', '1x'};
            g.Padding = [0 0 0 0];
            g.RowSpacing = 4;
            g.ColumnSpacing = 3;

            btn = uibutton(g, "state");
            btn.Layout.Row = [1 2];
            btn.Layout.Column = 1;
            btn.Text = ["Crop"; "Box"];
            btn.FontSize = 14;
            btn.Value = obj.crop_box_bool;
            btn.BackgroundColor = obj.get_button_color(obj.crop_box_bool);
            btn.Tooltip = tip;
            btn.ValueChangedFcn = @(src, event) crop_box_change(src, event, plot_area_panel);

            flds = gobjects(2, 2);
            names = ["y", "z"];
            sides = ["lower", "upper"];
            for r = 1:2
                lab = uilabel(g);
                lab.Layout.Row = r;
                lab.Layout.Column = 2;
                lab.Text = names(r);
                lab.HorizontalAlignment = 'right';
                for c = 1:2
                    f = uieditfield(g, "numeric");
                    f.Layout.Row = r;
                    f.Layout.Column = 2 + c;
                    f.HorizontalAlignment = 'center';
                    f.ValueDisplayFormat = '%.3g';
                    f.Value = obj.crop_box(2*(r - 1) + c);
                    f.Tooltip = names(r) + "/c " + sides(c) + " edge of the Crop Box";
                    if r == 1
                        f.Tooltip = f.Tooltip + " (from the mirror centreline)";
                    end
                    f.ValueChangedFcn = @(src, event) crop_box_bounds_change(src, event, plot_area_panel);
                    flds(r, c) = f;
                end
            end
            ctrl = struct('button', btn, 'fields', flds);
        end

        % show the current crop state in both copies of the controls
        function sync_crop_controls()
            for k = 1:numel(crop_ctrls)
                crop_ctrls(k).button.Value = obj.crop_box_bool;
                crop_ctrls(k).button.BackgroundColor = obj.get_button_color(obj.crop_box_bool);
                for r = 1:2
                    for c = 1:2
                        crop_ctrls(k).fields(r, c).Value = obj.crop_box(2*(r - 1) + c);
                    end
                end
            end
        end

        % redraw if the current plot uses the box (3D isosurface, or the
        % 2D centroid)
        function crop_redraw(plot_panel)
            if obj.is_3D_plot_type() || ...
                    (obj.centroid_bool && ismember(obj.plot_type, obj.plot_types(1:2)))
                obj.update_plot(plot_panel); % 3D: new isosurface, same view
            end
        end

        function crop_box_change(src, ~, plot_panel)
            obj.crop_box_bool = src.Value;
            sync_crop_controls();
            crop_redraw(plot_panel);
        end

        function crop_box_bounds_change(src, ~, plot_panel)
            flds = [];
            for k = 1:numel(crop_ctrls)
                if any(crop_ctrls(k).fields(:) == src)
                    flds = crop_ctrls(k).fields;
                end
            end
            b = [flds(1,1).Value, flds(1,2).Value, flds(2,1).Value, flds(2,2).Value];
            if b(1) >= b(2) || b(3) >= b(4)
                sync_crop_controls(); % lower must be below upper: undo
                return
            end
            obj.crop_box = b;
            sync_crop_controls();
            if obj.crop_box_bool
                crop_redraw(plot_panel);
            end
        end

        function unc_mask_thresh_change(src, ~, plot_panel)
            obj.unc_mask_thresh = src.Value;
            if obj.unc_mask_bool && obj.is_3D_plot_type()
                obj.update_plot(plot_panel);
            end
        end

        function remove_small_change(src, ~, plot_panel)
            obj.remove_small_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.remove_small_bool);
            % filter (or restore) the current surface in place
            if obj.is_3D_plot_type()
                ax = findobj(plot_panel.Children, 'Type', 'axes');
                obj.apply_remove_small(ax);
            end
        end

        function remove_small_pct_change(src, ~, plot_panel)
            obj.remove_small_pct = src.Value;
            if obj.remove_small_bool && obj.is_3D_plot_type()
                ax = findobj(plot_panel.Children, 'Type', 'axes');
                obj.apply_remove_small(ax);
            end
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

    % 3D plot or "phase avg: 3D all planes" (share the 3D parameters)
    function tf = is_3D_plot_type(obj)
        tf = obj.plot_type == obj.plot_types(5) || obj.plot_type == obj.MERGED_3D_PLOT;
    end

    % Plots built from every downstream position of a case ("phase avg: 3D
    % all planes", "seam comparison"): no position dropdown, the case list
    % spans all positions
    function tf = is_all_planes_plot_type(obj)
        tf = obj.plot_type == obj.MERGED_3D_PLOT || obj.plot_type == obj.SEAM_PLOT;
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
    % version name, then _RPCA), or <case>_<HRPP_METHOD> for the particle
    % pool harmonic regression. These strip / add the suffixes.
    function stems = strip_variant_suffix(obj, stems)
        stems = regexprep(string(stems), "_" + obj.HRPP_METHOD + "$", "");
        stems = regexprep(stems, "_RPCA$", "");
        stems = regexprep(stems, "_hr$", "");
    end

    function case_id = with_variant_suffix(obj, case_id)
        case_id = obj.strip_variant_suffix(case_id);
        if strlength(case_id) == 0
            return
        end
        if obj.HRPP
            case_id = case_id + "_" + obj.HRPP_METHOD;
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

    % Indices of the measured (original) field of view on the extrapolated
    % grid (y_B, z_B). Newer files save that region's grid (y_B_fov,
    % z_B_fov). For older ones: extrapolation (helm_decomp) trims the
    % measured plane with default_trim_bounds (trim_vel_field), mirrors it
    % about the centreline and centres it, by index, in a larger zero-padded
    % grid; the same steps are repeated here. [] if it can't be found.
    function [iy, iz] = get_extrap_fov_indices(obj, d)
        iy = []; iz = [];
        if ~all(isfield(d, {'y_B', 'z_B'}))
            return
        end
        y_arr = d.y_B(:,1);
        z_arr = d.z_B(1,:);
        Ny = numel(y_arr);
        Nz = numel(z_arr);
        if Ny < 2 || Nz < 2
            return
        end

        if all(isfield(d, {'y_B_fov', 'z_B_fov'}))
            [~, y_first] = min(abs(y_arr - d.y_B_fov(1,1)));
            [~, z_first] = min(abs(z_arr - d.z_B_fov(1,1)));
            num_y = size(d.y_B_fov, 1);
            num_z = size(d.y_B_fov, 2);
        elseif all(isfield(d, {'y', 'z'}))
            % old flapper cases use their own trim bounds (old_flapper_compat)
            bounds = old_flapper_compat("trim_bounds_for", obj.get_current_case_id());
            y_meas = d.y(1,:,1);
            z_meas = squeeze(d.z(1,1,:));
            y_keep = y_meas(y_meas > bounds.ybounds(1) & y_meas < bounds.ybounds(2));
            num_y = 2*sum(y_keep >= bounds.y_cen) - 1; % mirrored, centreline once
            num_z = sum(z_meas > bounds.zbounds(1) & z_meas < bounds.zbounds(2));
            y_first = floor((Ny - num_y) / 2) + 1;      % index placement in helm_decomp
            z_first = floor((Nz - num_z) / 2) + 1;
        else
            return
        end
        if num_y < 1 || num_z < 1
            return
        end
        iy = max(y_first, 1) : min(y_first + num_y - 1, Ny);
        iz = max(z_first, 1) : min(z_first + num_z - 1, Nz);
    end

    % Outline the measured (original) field of view on a Full Section
    % extrapolated plot with a black dashed box, at the outer edges of the
    % measured cells
    function draw_original_fov_box(obj, ax, d)
        [iy, iz] = obj.get_extrap_fov_indices(d);
        if isempty(iy) || isempty(iz)
            return
        end
        y_arr = d.y_B(:,1);
        z_arr = d.z_B(1,:);
        dy = abs(y_arr(2) - y_arr(1));
        dz = abs(z_arr(2) - z_arr(1));
        y_lims = [min(y_arr(iy([1 end]))) - dy/2, max(y_arr(iy([1 end]))) + dy/2];
        z_lims = [min(z_arr(iz([1 end]))) - dz/2, max(z_arr(iz([1 end]))) + dz/2];

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
        % position-independent cases (freestream) belong to the new set
        mask = ismember(stems, position_independent_cases());
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

    % "Card Style" for the 3D plot: lights the isosurface, recolours it
    % with a red-green colormap symmetric about zero, darkens the
    % background and hides the axes and colorbar. Everything it changes is
    % saved first (axes appdata "card_style_orig", panel colour in
    % obj.card_panel_color) so remove_card_style puts it back exactly.
    % Safe to call repeatedly, e.g. after every redraw.
    function apply_card_style(obj, ax)
        if isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
            return
        end
        p = obj.find_isosurface_patch(ax);
        if isempty(p)
            return
        end
        panel = ax.Parent;
        cb = findall(panel, 'Type', 'colorbar');

        patch_props = {'FaceLighting', 'AmbientStrength', 'DiffuseStrength', ...
            'SpecularStrength', 'SpecularExponent', 'SpecularColorReflectance'};
        ax_props = {'Color', 'XColor', 'YColor', 'ZColor', 'Box', ...
            'XGrid', 'YGrid', 'ZGrid', 'CLimMode'};

        S = [];
        if isappdata(ax, 'card_style_orig')
            S = getappdata(ax, 'card_style_orig');
        end
        if isempty(S)
            % first time on this axes: save the original look
            S.patch = p;
            S.patch_props = patch_props;
            S.patch_vals = get(p, patch_props);
            S.ax_props = ax_props;
            S.ax_vals = get(ax, ax_props);
            S.title_visible = ax.Title.Visible;
            S.cmap = ax.Colormap;
            S.clim = ax.CLim;
            S.card_cmap = [];
            S.card_clim = [];
            S.cb = cb(:);
            S.cb_visible = visibility(cb);
            % lights are placed relative to the camera, so re-aim them
            % whenever the view changes (view buttons or mouse rotation);
            % added once per axes, they do nothing while the style is off
            if ~isappdata(ax, 'card_style_listeners')
                for prop = ["View", "CameraPosition"]
                    try
                        addlistener(ax, prop, 'PostSet', @(~, ~) obj.aim_card_lights(ax));
                    catch
                    end
                end
                setappdata(ax, 'card_style_listeners', true);
            end
        else
            % redraw on the same axes: setColorBar may have reset the
            % colormap / limits, so save those again unless they are still
            % the card style's own
            if ~isequal(ax.Colormap, S.card_cmap)
                S.cmap = ax.Colormap;
            end
            if ~isequal(ax.CLim, S.card_clim)
                S.clim = ax.CLim;
            end
            % colorbars already saved keep their original visibility;
            % only new ones are added
            keep = isvalid(S.cb);
            old_cb = S.cb(keep);
            old_vis = S.cb_visible(keep);
            is_new = arrayfun(@(h) ~any(h == old_cb), cb);
            new_cb = cb(is_new);
            S.cb = [old_cb(:); new_cb(:)];
            S.cb_visible = [old_vis(:); visibility(new_cb)];
        end

        % surface: soft satin highlights
        set(p, 'FaceLighting', 'gouraud', 'AmbientStrength', 0.35, ...
            'DiffuseStrength', 0.75, 'SpecularStrength', 0.55, ...
            'SpecularExponent', 18, 'SpecularColorReflectance', 0.6);

        % lights (replaced, never duplicated)
        delete(findall(ax, 'Type', 'light', 'Tag', obj.CARD_TAG));
        for k = 1:size(obj.CARD_LIGHT_POS, 1)
            lgt = light(ax, 'Color', obj.CARD_LIGHT_COLOR(k, :), 'Tag', obj.CARD_TAG, ...
                'HandleVisibility', 'off', 'UserData', k); % k: row of CARD_LIGHT_POS
            camlight(lgt, obj.CARD_LIGHT_POS(k, 1), obj.CARD_LIGHT_POS(k, 2));
        end

        % colours symmetric about zero so zero sits on the cream centre
        S.card_cmap = obj.card_colormap(256);
        ax.Colormap = S.card_cmap;
        c = max(abs(S.clim));
        if c > 0
            S.card_clim = [-c c];
            ax.CLim = S.card_clim;
        end

        % dark, quiet background with no axes, labels, title or colorbar
        set(ax, 'Color', obj.CARD_BG, 'XColor', 'none', 'YColor', 'none', ...
            'ZColor', 'none', 'Box', 'off', 'XGrid', 'off', 'YGrid', 'off', 'ZGrid', 'off');
        ax.Title.Visible = 'off';
        set(S.cb, 'Visible', 'off');
        if isempty(obj.card_panel_color)
            obj.card_panel_color = panel.BackgroundColor;
        end
        panel.BackgroundColor = obj.CARD_BG;

        setappdata(ax, 'card_style_orig', S);

        function vis = visibility(h)
            if isempty(h)
                vis = cell(0, 1);
            else
                vis = get(h(:), {'Visible'});
            end
        end
    end

    % Undo apply_card_style on this axes (no-op if it was never applied)
    function remove_card_style(obj, ax)
        if isempty(ax) || ~isscalar(ax) || ~isvalid(ax) || ~isappdata(ax, 'card_style_orig')
            return
        end
        S = getappdata(ax, 'card_style_orig');
        delete(findall(ax, 'Type', 'light', 'Tag', obj.CARD_TAG));
        keep = isvalid(S.patch);
        if any(keep)
            set(S.patch(keep), S.patch_props, S.patch_vals(keep, :));
        end
        set(ax, S.ax_props, S.ax_vals);
        ax.Title.Visible = S.title_visible;
        ax.Colormap = S.cmap;
        ax.CLim = S.clim;
        if strcmp(S.ax_vals{strcmp(S.ax_props, 'CLimMode')}, 'auto')
            ax.CLimMode = 'auto';
        end
        keep = isvalid(S.cb);
        if any(keep)
            set(S.cb(keep), {'Visible'}, S.cb_visible(keep));
        end
        rmappdata(ax, 'card_style_orig');
    end

    % Give the plot panel its original background back
    function restore_card_panel(obj, plot_panel)
        if ~isempty(obj.card_panel_color) && isvalid(plot_panel)
            plot_panel.BackgroundColor = obj.card_panel_color;
        end
        obj.card_panel_color = [];
    end

    % Keep the card style's lights at the same place relative to the camera
    function aim_card_lights(obj, ax)
        if ~isvalid(ax)
            return
        end
        lgts = findall(ax, 'Type', 'light', 'Tag', obj.CARD_TAG);
        for lgt = lgts(:)'
            k = lgt.UserData;
            camlight(lgt, obj.CARD_LIGHT_POS(k, 1), obj.CARD_LIGHT_POS(k, 2));
        end
    end

    % "Fix Limits" on the 3D plot: y and z axes held at fix_ylim / fix_zlim
    % (y/c, z/c), or back to automatic limits when off. The stroke labels
    % are drawn to the axis limits, so they are redrawn too.
    function apply_fixed_lims(obj, ax)
        if isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
            return
        end
        if obj.fix_lims_bool
            ylim(ax, obj.fix_ylim);
            zlim(ax, obj.fix_zlim);
        else
            % stroke labels span the old limits; remove them first so the
            % automatic limits follow the data only
            delete(findall(ax, 'Tag', obj.STROKE_TAG));
            ax.YLimMode = 'auto';
            ax.ZLimMode = 'auto';
        end
        obj.draw_stroke_labels_3D(ax);
    end

    % "Remove Small" on the 3D plot's isosurface: with remove_small_bool
    % on, hide pieces smaller than remove_small_pct % of the largest; off,
    % put them back. Only Faces changes (Vertices and colours stay, so the
    % x-axis units switch still works). The full faces are kept in the
    % patch's appdata; if the patch's faces aren't the filtered ones (new
    % surface, stroke order shift) they are the full surface. Safe to call
    % repeatedly, e.g. after every redraw.
    function apply_remove_small(obj, ax)
        if isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
            return
        end
        p = obj.find_isosurface_patch(ax);
        if ~isscalar(p)
            return
        end
        R = struct('faces_full', [], 'faces_kept', []);
        if isappdata(p, 'remove_small')
            R = getappdata(p, 'remove_small');
        end
        if isempty(R.faces_kept) || ~isequal(p.Faces, R.faces_kept)
            R.faces_full = p.Faces;   % current faces are the full surface
        end
        if obj.remove_small_bool
            R.faces_kept = obj.despeckle_faces(R.faces_full, obj.remove_small_pct);
            p.Faces = R.faces_kept;
            setappdata(p, 'remove_small', R);
        else
            p.Faces = R.faces_full;
            if isappdata(p, 'remove_small')
                rmappdata(p, 'remove_small');
            end
        end
    end

    % Faces of the triangle mesh without its small connected pieces: a
    % piece is kept if it has at least min_pct % as many triangles as the
    % largest piece. Pieces are found from shared vertices (isosurface
    % output shares vertices between neighbouring triangles).
    function faces = despeckle_faces(~, faces, min_pct)
        if isempty(faces) || min_pct <= 0
            return
        end
        n_verts = max(faces(:));
        G = graph([faces(:,1); faces(:,2); faces(:,3)], ...
                  [faces(:,2); faces(:,3); faces(:,1)], [], n_verts);
        piece = conncomp(G);                      % piece of each vertex
        face_piece = piece(faces(:,1));           % piece of each triangle
        n_faces = accumarray(face_piece(:), 1);   % triangles per piece
        keep_piece = n_faces >= min_pct / 100 * max(n_faces);
        faces = faces(keep_piece(face_piece), :);
    end

    % Diverging pine green -> cream -> cranberry colormap, n levels
    function cmap = card_colormap(obj, n)
        anchors = obj.CARD_CMAP_ANCHORS;
        cmap = interp1(linspace(0, 1, size(anchors, 1)), anchors, linspace(0, 1, n));
    end

    % Stroke reversals for the 3D plot from the phase-averaged wing
    % position (max = top of the stroke, upstroke -> downstroke; min =
    % bottom, downstroke -> upstroke), in flow bins. [] if not saved.
    function S = get_stroke_info_3D(obj, case_files, num_bins)
        S = [];
        wing_pos = [];
        if stb_exists(case_files)
            vars = stb_who(case_files);
            if ismember("phase_avg_wing_pos", vars)
                d = stb_load(case_files, "phase_avg_wing_pos");
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
        case_files = obj.get_current_case();
        parts = [stb_name(case_files), stb_file_stamp(case_files), string(obj.iso_var), ...
            sprintf("%.10g", obj.iso_val), string(obj.num_cycles), ...
            string(obj.conv_units_bool), string(obj.trim_bool), ...
            mat2str(obj.trim_y_bounds), mat2str(obj.trim_z_bounds), ...
            string(obj.mirror_bool), mat2str(obj.mirror_center_y), ...
            string(obj.filter_bool), string(use_extrapolated_data), ...
            string(obj.frame_ind), string(obj.conv_shift), obj.stroke_order, ...
            string(obj.unc_mask_bool), sprintf("%.10g", obj.unc_mask_thresh), ...
            string(obj.crop_box_bool), mat2str(obj.crop_box)];
        key = strjoin(parts, "|");
    end

    % Re-phase the current 3D plot for a new stroke order without
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
        if obj.conv_shift && obj.stroke_order ~= "UDU"
            flip_bins = obj.get_stroke_shift_bins(N, S3.base_shift - S3.conv_shift_bins);
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

    % Stroke order: bins to shift the 3D plot by, from the stroke
    % reversals in the wing position (downstroke: top -> bottom, upstroke:
    % bottom -> top; the strokes differ in length). frame_offset is the
    % stroke labels' shift without it (slider frame - 1), so bin k is
    % plotted at index mod(k - 1 + frame_offset + shift, N).
    %   UDU: 0 (as with the convection shift alone)
    %   DUD: the middle of the upstroke moves to where the middle of the
    %        downstroke is in UDU
    %   DU : the top of the stroke moves to the start of the wingbeat
    %   UD : the bottom of the stroke moves to the start
    % Without the wing position the strokes are taken as equal with the
    % downstroke centred.
    function flip_bins = get_stroke_shift_bins(obj, num_bins, frame_offset)
        S = obj.stroke_3D;
        if isempty(S)
            switch obj.stroke_order
                case "DUD", flip_bins = round(num_bins / 2);
                case "DU",  flip_bins = round(3 * num_bins / 4);
                case "UD",  flip_bins = round(num_bins / 4);
                otherwise,  flip_bins = 0;
            end
            disp("No wing position for " + obj.get_current_case_id() + ", stroke order " + ...
                obj.stroke_order + " assuming equal strokes")
            return
        end
        N = S.N;
        down_len = mod(S.bottom - S.top, N);
        up_len = N - down_len;
        switch obj.stroke_order
            case "DUD"
                down_mid = S.top + down_len / 2;
                up_mid = S.bottom + up_len / 2;
                flip_bins = round(mod(down_mid - up_mid, N));
            case "DU"
                flip_bins = round(mod(-(S.top - 1) - frame_offset, N));
            case "UD"
                flip_bins = round(mod(-(S.bottom - 1) - frame_offset, N));
            otherwise % UDU
                flip_bins = 0;
        end
        flip_bins = mod(flip_bins, N);
        disp(sprintf("Downstroke %.0f%% / upstroke %.0f%% of the wingbeat: %s with a %d / %d bin shift", ...
            100 * down_len / N, 100 * up_len / N, obj.stroke_order, flip_bins, N))
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
        % The plane sees the wake the wing shed one convection time earlier,
        % so the curve is moved EARLIER by that time (negative circshift) to put
        % it in the robot's wing phase. (A positive shift added the delay twice:
        % x2 and x4 then differed by 2*0.378 m / U instead of lining up.)
        shift_bins = -round(shift * num_bins);
        disp("Shifted " + obj.get_current_case_id() + " by: " + shift_bins + " / " + num_bins + ...
            " (" + dist + " m downstream)")
    end

    % Thin black isolines of the wingbeat-averaged total uncertainty
    % (nondimensional, fraction of U) at unc_contour_levels percent,
    % labelled in %. The colour limits of the plot are kept.
    function draw_unc_contours(obj, ax, y, z, unc_field)
        if isempty(unc_field) || ~isequal(size(unc_field), size(y))
            return
        end
        cl = ax.CLim;
        hold(ax, 'on');
        [C, hc] = contour(ax, y, z, 100 * unc_field, obj.unc_contour_levels, ...
            'LineColor', 'k', 'LineWidth', 0.6);
        hc.Tag = "unc_contours";
        if ~isempty(C)
            clabel(C, hc, 'FontSize', 9, 'Color', 'k', 'LabelSpacing', 400);
            try
                hc.LabelFormat = '%g%%'; % labels as 1%, 2%, ... (R2022b+)
            catch
            end
        end
        hold(ax, 'off');
        ax.CLim = cl;
    end

    % Centroid of a plotted 2D field F on the (y, z) grid. Weight: the
    % departure from the plot's background value (zero = 0, or -1 / 1 for
    % the velocities, as PIV_plot centres the colormap), keeping only the
    % dominant sign (the sign of its integral), so e.g. the stronger of two
    % counter-rotating vortices or the velocity deficit of the wake. NaN
    % points and points in mask (uncertainty mask, [] = none) have no
    % weight. Uniform grid, so plain sums.
    function [yc, zc] = field_centroid(~, y, z, F, zero, mask)
        yc = NaN; zc = NaN;
        w = F - zero;
        w(isnan(w)) = 0;
        if ~isempty(mask) && isequal(size(mask), size(w))
            w(mask) = 0;
        end
        s = sign(sum(w, "all"));
        if s == 0
            return
        end
        w = max(s * w, 0);
        W = sum(w, "all");
        if W > 0
            yc = sum(y .* w, "all") / W;
            zc = sum(z .* w, "all") / W;
        end
    end

    % Dashed black line around the region kept by the centroid's
    % uncertainty mask
    function draw_mask_outline(~, ax, y, z, mask)
        if isempty(mask) || ~isequal(size(mask), size(y)) || ~any(mask(:))
            return
        end
        cl = ax.CLim;
        hold(ax, 'on');
        [~, hc] = contour(ax, y, z, double(~mask), [0.5 0.5], ...
            'LineColor', 'k', 'LineStyle', '--', 'LineWidth', 1.2);
        hc.Tag = "centroid_mask";
        hold(ax, 'off');
        ax.CLim = cl;
    end

    function hm = draw_centroid(~, ax, yc, zc)
        cl = ax.CLim;
        hold(ax, 'on');
        hm = plot(ax, yc, zc, 'o', 'MarkerSize', 9, 'MarkerFaceColor', 'k', ...
            'MarkerEdgeColor', 'w', 'LineWidth', 1, 'Tag', "centroid");
        hold(ax, 'off');
        ax.CLim = cl;
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

        % new flapper first, so it is the default
        if ~isempty(obj.phase_new_flapper_case_name_list) || ~isempty(obj.time_new_flapper_case_name_list)
            source_modes(end + 1) = obj.NEW_FLAPPER_SOURCE_MODE;
        end

        if ~isempty(obj.phase_old_flapper_case_name_list) || ~isempty(obj.time_old_flapper_case_name_list)
            source_modes(end + 1) = obj.OLD_FLAPPER_SOURCE_MODE;
        end

        if ~isempty(obj.phase_turbine_case_name_list) || ~isempty(obj.time_turbine_case_name_list)
            source_modes(end + 1) = obj.TURBINE_SOURCE_MODE;
        end
    end

    % Cases for the dropdown: for the flappers, only those at the selected
    % downstream position
    function case_names = get_case_name_list_for_active_plot_type(obj)
        if obj.is_all_planes_plot_type()
            case_names = obj.get_merged_case_names();
            return
        end
        case_names = obj.get_case_name_list(obj.source_mode, obj.plot_type, obj.current_downstream_type);
    end

    % "phase avg: 3D all planes": downstream positions it joins, in order
    % from the robot (types and distances, m), for the current source
    function [types, dists] = get_merged_plane_types(obj)
        if obj.source_mode == obj.OLD_FLAPPER_SOURCE_MODE
            types = obj.OLD_FLAPPER_DOWNSTREAM_TYPES;
            dists = obj.OLD_FLAPPER_DOWNSTREAM_DISTS;
        elseif obj.source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            types = obj.NEW_FLAPPER_DOWNSTREAM_TYPES;
            dists = obj.NEW_FLAPPER_DOWNSTREAM_DISTS;
        else
            types = strings(0, 1);
            dists = zeros(0, 1);
            return
        end
        keep = ~ismember(types, obj.MERGED_3D_EXCLUDE_TYPES) & ~isnan(dists);
        types = types(keep);
        dists = dists(keep);
        [dists, order] = sort(dists(:));
        types = types(order);
    end

    % Phase averaged cases of the current source at any downstream
    % position (name without the position prefix), for "phase avg: 3D all
    % planes"; position-independent cases (freestream) are left out
    function case_names = get_merged_case_names(obj)
        case_names = strings(1, 0);
        if ~obj.is_flapper_source_mode(obj.source_mode)
            return
        end
        if obj.source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            stems = obj.phase_new_flapper_stems;
        else
            stems = obj.phase_old_flapper_stems;
        end
        [types, ~] = obj.get_merged_plane_types();
        [known_types, known_labels] = obj.get_known_downstream_options(obj.source_mode);
        for i = 1:numel(types)
            label = known_labels(known_types == types(i));
            case_names = [case_names, obj.get_flapper_case_names(stems, types(i), label, obj.source_mode)]; %#ok<AGROW>
        end
        case_names = unique(case_names, 'stable');
        case_names = case_names(~ismember(case_names, position_independent_cases()));
    end

    % Phase average case id of the current case at one downstream
    % position, "" if it wasn't measured there
    function case_id = get_merged_case_id(obj, downstream_type)
        name = string(obj.case_name);
        case_id = obj.with_variant_suffix(downstream_type + "_" + name);
        if any(obj.phase_avg_case_ids == case_id)
            return
        end
        % old flapper cases at the default position may have no prefix
        if obj.source_mode == obj.OLD_FLAPPER_SOURCE_MODE && ...
                downstream_type == obj.OLD_FLAPPER_DOWNSTREAM_TYPES(1) && ...
                obj.is_legacy_default_distance_stem(name)
            case_id = obj.with_variant_suffix(name);
            if any(obj.phase_avg_case_ids == case_id)
                return
            end
        end
        case_id = "";
    end

    % Files of a phase average case (stb_file_paths struct: .shared,
    % .fields, .integral)
    function case_files = get_phase_case(obj, case_id)
        key = char(string(case_id));
        if ~isKey(obj.phase_case_map, key)
            error("No phase-averaged files for %s (expected <case>[_<version>]_<method>_fields.mat in Processed Results\\phase_avg\\).", key)
        end
        case_files = obj.phase_case_map(key);
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

        % position-independent cases (freestream) at every new flapper
        % position
        if source_mode == obj.NEW_FLAPPER_SOURCE_MODE
            pi_names = position_independent_cases();
            phase_case_names = unique([phase_case_names, ...
                reshape(intersect(obj.phase_new_flapper_stems, pi_names, 'stable'), 1, [])], 'stable');
            time_case_names = unique([time_case_names, ...
                reshape(intersect(obj.time_new_flapper_stems, pi_names, 'stable'), 1, [])], 'stable');
        end

        % time averaged (0 Hz) cases have "time avg of phase avg" and the
        % section plot only
        if ismember(plot_type, obj.plot_types([1 3 10]))
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
            if ismember(case_name, position_independent_cases())
                base_case_id = case_name; % no position prefix (freestream)
            elseif ismember(obj.plot_type, obj.plot_types([1 3])) && obj.has_case_id(obj.time_avg_case_ids, case_name)
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

    % Files of the selected case: the phase average, or the time average
    % (stb_time_avg_case) when that is what's plotted. Either way a struct
    % for stb_load / stb_who.
    function case_files = get_current_case(obj)
        case_id = obj.get_current_case_id();
        if obj.is_time_avg_file_selected()
            case_files = obj.get_time_case(case_id);
        else
            case_files = obj.get_phase_case(case_id);
        end
    end

    function case_files = get_time_case(obj, case_id)
        case_files = stb_time_avg_case(obj.get_case_dir("time", case_id) + case_id + "_time_avg");
    end

    % Message in the plot area instead of a plot, when the selected case's
    % processed file doesn't hold the variable (reprocess the case to get it)
    function show_missing_variable(obj, plot_panel, var_name)
        delete(findobj(plot_panel.Children, 'Type', 'axes'));
        ax = axes(plot_panel);
        text(ax, 0.5, 0.5, string(var_name) + " is not in the processed file for " +...
            string(obj.get_current_case_id()) + newline + "(processed with an older version of the code: reprocess the case to get it)", ...
            'HorizontalAlignment', 'center', Interpreter='none', FontSize=14);
        axis(ax, 'off');
        obj.plot_hold_bool = false;
        fprintf("%s not in the processed file for %s - not plotted\n", var_name, obj.get_current_case_id());
    end

    % Record the folder of each case (first data root wins)
    function register_case_dirs(obj, kind, case_ids, folder)
        for k = 1:numel(case_ids)
            key = char(kind + "|" + case_ids(k));
            if ~isKey(obj.case_dir_map, key)
                obj.case_dir_map(key) = char(folder);
            end
        end
    end

    % Folder holding a time-averaged case's files (kind "time"). Falls back
    % to the primary root's folder for a case that wasn't found.
    function folder = get_case_dir(obj, kind, case_id)
        key = char(string(kind) + "|" + string(case_id));
        if ~isempty(obj.case_dir_map) && isKey(obj.case_dir_map, key)
            folder = string(obj.case_dir_map(key));
            return
        end
        switch string(kind)
            case "time", folder = obj.time_avg_file_path;
            otherwise,   folder = obj.phase_avg_file_path;
        end
    end

    function tf = current_case_has_phase_avg(obj)
        tf = any(obj.phase_avg_case_ids == obj.get_current_case_id());
    end

    function tf = current_case_has_time_avg(obj)
        tf = any(obj.time_avg_case_ids == obj.get_current_case_id());
    end

    % time avg of phase avg / time avg of phase std of a time averaged
    % (0 Hz) case: the time average file (mean / SD over all frames)
    function tf = is_time_avg_file_selected(obj)
        tf = ismember(obj.plot_type, obj.plot_types([1 3])) && obj.current_case_has_time_avg();
    end

    % Dropdown labels for plot types. A time averaged (gliding, 0 Hz) case
    % has no phase average, so its mean and SD plots are labelled
    % "time avg" and "time std".
    function labels = get_plot_type_labels(obj, plot_types)
        labels = string(plot_types);
        if obj.current_case_has_time_avg() && ~obj.current_case_has_phase_avg()
            labels(plot_types == obj.plot_types(1)) = "time avg";
            labels(plot_types == obj.plot_types(3)) = "time std";
        end
    end

    function plot_types = get_available_plot_types_for_current_case(obj)
        % the merged 3D plot doesn't depend on the selected position, so
        % while it is shown every plot type stays available (picking
        % another one goes back to the cases at the selected position)
        % (same for the seam comparison, built from the same planes)
        is_flapper = obj.is_flapper_source_mode(obj.source_mode);
        if obj.is_all_planes_plot_type() && is_flapper
            plot_types = obj.order_plot_types(obj.plot_types);
            return
        end
        plot_types = obj.get_position_plot_types();
        all_planes_types = [obj.MERGED_3D_PLOT, obj.SEAM_PLOT];
        if is_flapper && ~isempty(obj.get_merged_case_names())
            plot_types = [plot_types, all_planes_types(~ismember(all_planes_types, plot_types))];
        elseif ~is_flapper
            plot_types = plot_types(~ismember(plot_types, all_planes_types));
        end
        plot_types = obj.order_plot_types(plot_types);
    end

    % Dropdown order: "phase avg: section avg" (plot_types(13), added
    % last so the other indices stay) right after "time avg: section avg"
    function plot_types = order_plot_types(obj, plot_types)
        is_ph = plot_types == obj.plot_types(13);
        k = find(plot_types == obj.plot_types(10), 1);
        if any(is_ph) && ~isempty(k)
            rest = plot_types(~is_ph);
            k = find(rest == obj.plot_types(10), 1);
            plot_types = [rest(1:k), obj.plot_types(13), rest(k+1:end)];
        end
        % "seam comparison" right after "phase avg: 3D all planes"
        is_seam = plot_types == obj.SEAM_PLOT;
        if any(is_seam) && any(plot_types == obj.MERGED_3D_PLOT)
            rest = plot_types(~is_seam);
            k = find(rest == obj.MERGED_3D_PLOT, 1);
            plot_types = [rest(1:k), obj.SEAM_PLOT, rest(k+1:end)];
        end
    end

    function plot_types = get_position_plot_types(obj)
        if obj.is_time_avg_file_selected() || ~obj.current_case_has_phase_avg()
            plot_types = obj.plot_types(1);
            % SD over all frames (std_* fields of the time average file)
            if obj.current_case_has_time_avg()
                plot_types(end+1) = obj.plot_types(3);
            end
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
        if ~obj.is_3D_plot_type()
            % card style is only for the 3D plots; other plots get the
            % normal panel background back (their axes are new anyway)
            obj.restore_card_panel(plot_panel);
        end

        if obj.plot_type == obj.MERGED_3D_PLOT
            obj.plot_merged_3D(plot_panel);
            return
        end
        if obj.plot_type == obj.SEAM_PLOT
            obj.plot_seam_comparison(plot_panel);
            return
        end
        using_time_avg_file = obj.is_time_avg_file_selected();
        use_extrapolated_data = obj.extrapolate_bool && ~using_time_avg_file;
        % extrapolated - measured velocity: stored on the field of view grid
        % of the extrapolation, so it is loaded like the extrapolated data
        is_extrap_diff = any(obj.variable_name == obj.EXTRAP_DIFF_VARS) && ismember(plot_idx, [1, 2, 5, 9]);
        if is_extrap_diff
            if using_time_avg_file || ~ismember(plot_idx, [1, 2])
                delete(findobj(plot_panel.Children, 'Type', 'axes'));
                ax = axes(plot_panel);
                text(ax, 0.5, 0.5, "Extrapolated - measured is only available for phase averages " + ...
                    "(time avg of phase avg / phase avg: movie)", 'HorizontalAlignment', 'center', FontSize=14);
                axis(ax, 'off');
                obj.plot_hold_bool = false;
                return
            end
            use_extrapolated_data = true;
        end
        % transport terms need the gradients, which the extrapolated
        % (Helmholtz) field doesn't have: always the measured field
        is_transport = any(obj.variable_name == [obj.TRANSPORT_VARS, obj.TRANSPORT_SUM_VARS]);
        if is_transport
            use_extrapolated_data = false;
        end
        q_mask_enabled = obj.q_mask_bool && ismember(plot_idx, [1, 2]) && ~use_extrapolated_data;
        q_mask_var_name = "Q";

        cur_secondary_vars = {};

        if plot_idx == 10 || plot_idx == 13
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

            if is_extrap_diff
                % already the _integral field name (EXTRAP_DIFF_FIELDS)
                vars = {"L","U","num_bins","cycle_freq"};
                cur_secondary_vars = {"z_B_fov","y_B_fov"};
            elseif use_extrapolated_data
                var_name = obj.dict_B(var_name);
                % measured y/z are only needed to outline the original
                % field of view on the extrapolated grid (files processed
                % before y_B_fov / z_B_fov were saved)
                vars = {"L","U","num_bins","cycle_freq","y","z"};
                cur_secondary_vars = {"z_B","y_B"};
            end

            if strcmp(var_name, obj.LIFT_WX_FIELD)
                % derived field: load the stored fields it is built from
                vars = [vars, obj.get_lift_wx_inputs(using_time_avg_file)];
            elseif is_transport
                [transport_pairs, transport_own_vort] = obj.get_transport_inputs(var_name, using_time_avg_file);
                vars = [vars, cellstr(unique([transport_pairs(:); transport_own_vort]))'];
            elseif contains(obj.variable_name, obj.secondary_vars) || use_extrapolated_data
                cur_secondary_vars{end+1} = var_name;
            else
                vars{end+1} = var_name;
            end

            if q_mask_enabled && ~any(strcmp(string(cur_secondary_vars), q_mask_var_name))
                cur_secondary_vars{end+1} = q_mask_var_name;
            end
        elseif plot_idx == 3
            var_clims = obj.get_color_limits(obj.variable_name);
            if using_time_avg_file
                % SD over all frames of a time averaged (0 Hz) case
                var_name = obj.time_std_var_name_dict(obj.variable_name);
                vars = {"L","U","z","y",var_name};
            else
                var_name = obj.std_var_name_dict(obj.variable_name);
                vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
            end
        end
        
        % Unc Contours: wingbeat-averaged total uncertainty (not on the
        % extrapolated grid, which has no uncertainty)
        draw_unc_contours = obj.unc_contour_bool && ismember(plot_idx, 1:4) && ~use_extrapolated_data;
        % Centroid: plotted field's centroid, with the forces' uncertainty
        % mask (needs the uncertainty; none on the extrapolated grid)
        show_centroid = obj.centroid_bool && ismember(plot_idx, [1, 2]);
        need_unc = draw_unc_contours || (show_centroid && ~use_extrapolated_data);
        if need_unc
            if using_time_avg_file
                unc_var_name = "mean_uncTot";
            else
                unc_var_name = "uncTot_phase_avg";
            end
            if ~any(strcmp(string(vars), unc_var_name))
                vars{end+1} = unc_var_name;
            end
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
            if plot_idx == 5 && ~geom_hit && obj.unc_mask_bool && ~use_extrapolated_data
                vars{end+1} = "uncTot_phase_avg";
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

        case_files = obj.get_current_case();

        % field of view of the extrapolation (newer files), for the crop / box
        if use_extrapolated_data && ~is_extrap_diff && ismember(plot_idx, [1, 2])
            integral_vars = stb_who(case_files);
            if all(ismember({'y_B_fov', 'z_B_fov'}, integral_vars))
                cur_secondary_vars = [cur_secondary_vars, {"y_B_fov", "z_B_fov"}];
            end
        end
        if is_extrap_diff
            integral_vars = stb_who(case_files);
            if ~ismember(char(var_name), integral_vars)
                delete(findobj(plot_panel.Children, 'Type', 'axes'));
                ax = axes(plot_panel);
                text(ax, 0.5, 0.5, string(var_name) + " is not in this file: reprocess the case", ...
                    'HorizontalAlignment', 'center', Interpreter='none', FontSize=14);
                axis(ax, 'off');
                obj.plot_hold_bool = false;
                return
            end
        end

        if plot_idx == 8
            % wake forces: data is loaded by get_PIV_force below
        elseif ~isempty(cur_secondary_vars)
            d1 = stb_load(case_files, cur_secondary_vars{:});
            if ~isempty(vars)
            d2 = stb_load(case_files, vars{:});
    
            % Combine by converting to cell arrays of names/values and back to struct
            d = cell2struct([struct2cell(d1); struct2cell(d2)], [fieldnames(d1); fieldnames(d2)], 1);
            else
                d = d1;
            end
        else
            d = stb_load(case_files, vars{:});
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
        if ismember(plot_idx, [1, 2, 5, 9]) && is_transport && ...
                all(isfield(d, cellstr([transport_pairs(:); transport_own_vort])))
            % omega_j du_i/dx_j (c^2/U^2), or a row sum / growth of them;
            % left missing when the gradients aren't saved (older
            % processing) -> show_missing_variable
            d.(var_name) = obj.compute_transport_field(d, var_name, ...
                transport_pairs, transport_own_vort);
        end

        if plot_idx ~= 8
            if ~isfield(d, var_name)
                % e.g. older (old flapper) processing, or optional fields
                % (Q*_inst need bools.Q_inst = true, div_phase_std needs
                % bools.div_std = true)
                obj.show_missing_variable(plot_panel, var_name);
                return
            end
            val = d.(var_name);
            planeIdx = (size(val,1) + 1) / 2;
        end

        if q_mask_enabled
            q_mask_val = d.(q_mask_var_name);
        end

        if ismember(plot_idx, [1, 2, 3, 4, 5, 9])
            if is_extrap_diff
                y = d.y_B_fov;
                z = d.z_B_fov;
                val = permute(val, [2 3 1]); % time dimension moved
            elseif use_extrapolated_data
                y = d.y_B;
                z = d.z_B;
                val = permute(val, [2 3 1]); % time dimension moved
                if contains(var_name, "X")
                    val = val - 1; % add back freestream
                end
                % Extrapolate alone: only the original field of view
                % (velocity from the vorticity there); Full Section: all
                if ~obj.full_section_bool && ismember(plot_idx, [1, 2])
                    [iy_fov, iz_fov] = obj.get_extrap_fov_indices(d);
                    if ~isempty(iy_fov)
                        y = y(iy_fov, iz_fov);
                        z = z(iy_fov, iz_fov);
                        val = val(iy_fov, iz_fov, :);
                    end
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

            if strcmp(var_name, obj.LIFT_WX_FIELD) || is_transport
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

        % uncertainty for the isolines, trimmed / mirrored like the plotted
        % field and averaged over the wingbeat
        unc_field = [];
        if need_unc
            if isfield(d, unc_var_name)
                unc_field = d.(unc_var_name);
                unc_field = squeeze(unc_field(planeIdx,:,:,:));
                if ~ismatrix(unc_field)
                    unc_field = mean(unc_field, 3, "omitnan");
                end
                if obj.trim_bool
                    unc_field = unc_field(y_idx, z_idx);
                end
                if obj.mirror_bool
                    unc_field = unc_field(y_idx_m, :);
                    unc_field = [flip(unc_field(2:end,:), 1); unc_field];
                end
            else
                fprintf("Unc Contours / Centroid: %s not in this file\n", unc_var_name);
            end
        end
        unc_centroid = unc_field;
        if ~draw_unc_contours
            unc_field = []; % loaded for the centroid only
        end
        if show_centroid
            cen_mask = [];
            b = default_trim_bounds();
            if ~isempty(unc_centroid) && obj.centroid_unc_pct > 0
                cen_mode = "threshold";
                if isfield(b, 'unc_mask_mode'), cen_mode = b.unc_mask_mode; end
                cen_mask = unc_mask_region(unc_centroid, obj.centroid_unc_pct / 100, cen_mode);
            end
            % Crop Box: also left out of the centroid
            crop = obj.crop_box_mask(y, z, obj.mirror_bool && ~use_extrapolated_data);
            if ~isempty(crop)
                if isempty(cen_mask) || ~isequal(size(cen_mask), size(crop))
                    cen_mask = crop;
                else
                    cen_mask = cen_mask | crop;
                end
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

            % Uncertainty mask (3D plot only, display only). Masked points
            % get the median of the iso variable (its background value, ~0
            % for Q) rather than NaN, so no isosurface forms there and
            % surfaces crossing the mask edge are closed off cleanly.
            if plot_idx == 5 && obj.unc_mask_bool && ~use_extrapolated_data
                unc = squeeze(mean(d.uncTot_phase_avg(planeIdx,:,:,:), 4, "omitnan"));
                if obj.trim_bool
                    unc = unc(y_idx, z_idx);
                end
                if obj.mirror_bool
                    unc = unc(y_idx_m, :);
                    unc = [flip(unc(2:end,:), 1); unc];
                end
                mask = unc > obj.unc_mask_thresh / 100 | isnan(unc);
                mask3 = repmat(mask, 1, 1, size(Q, 3));
                Q(mask3) = median(Q(~mask3), "omitnan");
                fprintf("Uncertainty mask: %.1f%% of points hidden (unc > %g%% of U)\n", ...
                    100 * mean(mask(:)), obj.unc_mask_thresh);
            end
            % Crop Box (3D plot only, display only), same treatment
            if plot_idx == 5
                Q = obj.apply_crop_box(Q, y, z, obj.mirror_bool && ~use_extrapolated_data);
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
            if use_extrapolated_data && ~is_extrap_diff && obj.full_section_bool
                obj.draw_original_fov_box(ax, d);
            end
            obj.draw_unc_contours(ax, y, z, unc_field);
            if show_centroid
                [yc, zc] = obj.field_centroid(y, z, mean_val, params.zero, cen_mask);
                obj.draw_mask_outline(ax, y, z, cen_mask);
                obj.draw_centroid(ax, yc, zc);
                fprintf("Centroid of %s (unc mask %g%%): y/L = %.3f, z/L = %.3f\n", ...
                    obj.variable_name, obj.centroid_unc_pct, yc, zc);
            end
        elseif plot_idx == 3
            params.clims = var_clims;

            mean_val = mean(val,3);
            PIV_plot(y, z, mean_val, params, ax);
            obj.draw_unc_contours(ax, y, z, unc_field);
        elseif plot_idx == 2 || plot_idx == 4

        params.clims = var_clims;

        val_tr = val(:,:,obj.frame_ind);
        h = PIV_plot(y, z, val_tr, params, ax);
        if use_extrapolated_data && ~is_extrap_diff && obj.full_section_bool && plot_idx == 2
            % drawn once; playing only updates the contour's ZData
            obj.draw_original_fov_box(ax, d);
        end
        t = title(ax, ["Bin number: " + obj.frame_ind], FontSize=18);
        % time averaged, so the isolines stay put while the movie plays
        obj.draw_unc_contours(ax, y, z, unc_field);
        hm = gobjects(0);
        if show_centroid && plot_idx == 2
            % one centroid per bin, the marker follows the movie
            nb = size(val, 3);
            yc_bins = NaN(1, nb);
            zc_bins = NaN(1, nb);
            for kb = 1:nb
                [yc_bins(kb), zc_bins(kb)] = obj.field_centroid(y, z, val(:,:,kb), params.zero, cen_mask);
            end
            obj.draw_mask_outline(ax, y, z, cen_mask);
            hm = obj.draw_centroid(ax, yc_bins(obj.frame_ind), zc_bins(obj.frame_ind));
        end

        if ~isempty(obj.movie_frame_fcn) % Save Movie: first bin
            drawnow;
            obj.movie_frame_fcn();
        end

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
            if ~isempty(hm) && isvalid(hm)
                set(hm, 'XData', yc_bins(obj.frame_ind), 'YData', zc_bins(obj.frame_ind));
            end
    
            drawnow;

            if isempty(obj.movie_frame_fcn)
                pause(0.05);
            else
                obj.movie_frame_fcn(); % Save Movie: add this bin to the .gif
            end

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

            % Stroke reversals (Label Stroke and the stroke order). The wing position
            % is measured at the robot, so it only lines up with the flow
            % once the convection shift is applied.
            obj.stroke_3D = [];
            if obj.conv_shift
                obj.stroke_3D = obj.get_stroke_info_3D(case_files, d.num_bins);
            end

            % Stroke order (UDU / DUD / DU / UD). It moves the flow and
            % the wing phase together, so unlike the convection shift it
            % is part of the stroke labels' shift too.
            stroke_flip_bins = 0;
            if obj.conv_shift && obj.stroke_order ~= "UDU"
                stroke_flip_bins = obj.get_stroke_shift_bins(d.num_bins, obj.frame_ind - 1);
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

            % kept so the stroke order can shift this plot without a full redraw
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
            obj.apply_fixed_lims(ax);
            obj.set_stroke_frame_shift(params.shift - conv_shift_bins);
            obj.draw_stroke_labels_3D(ax);
            obj.apply_remove_small(ax);
            if obj.card_style
                % setColorBar above reset the colormap / colour limits, so
                % re-apply (also styles a freshly created axes)
                obj.apply_card_style(ax);
            end
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
            val = get_PIV_force(case_files, case_id, var_name, avg_type, norm_bool, default_trim_bounds());

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

    % "phase avg: 3D all planes": one case (e.g. wings_20deg_6Hz) at every
    % downstream position, joined into a single frozen-flow reconstruction
    % of the wake, with the x-axis the streamwise distance from the robot
    % (x/c, downstream positive).
    %
    % Plane i (at x_i) sees at time t the fluid that is at
    % x_i + U (t_ref - t) at the snapshot time t_ref, so its phase average
    % fills the wake downstream of it: the field at x comes from its bin
    % at wing phase phi_ref - f (x - x_i) / U (linearly interpolated
    % between bins, periodic). Each plane's reconstruction is cut off where
    % the next plane downstream starts; the last one runs on for "Number of
    % Wingbeats" wingbeats. The bins are binned on the robot's wing phase,
    % so all planes share the snapshot time: the slider / Play step the
    % wing phase at the robot (phi_ref = (bin - 1) / N), and the fluid at x
    % was shed at phi_ref - f x / U whichever plane measured it. Positions
    % where the case wasn't measured are skipped (the plane upstream then
    % fills the gap).
    function plot_merged_3D(obj, plot_panel)
        ax = findobj(plot_panel.Children, 'Type', 'axes');
        p = gobjects(0);
        if obj.plot_hold_bool
            p = obj.find_isosurface_patch(ax);
        end
        obj.slider.Visible = "on";
        obj.play_button.Visible = "on";

        if any(obj.variable_name == obj.EXTRAP_DIFF_VARS)
            show_message("Extrapolated - measured is only available for the 2D phase average plots");
            return
        end
        if obj.extrapolate_bool
            disp("phase avg: 3D all planes uses the measured fields (Extrapolate ignored)")
        end

        [M, msg] = obj.get_merged_planes();
        if isempty(M)
            show_message(msg);
            return
        end
        planes = M.planes;

        N = planes(1).N;   % slider bins: the first plane's
        if N ~= obj.num_bins
            obj.num_bins = N;
            obj.slider.Limits = [1 N];
            obj.slider.MajorTicks = 1:5:N;
            obj.slider.MinorTicks = 1:N;
        end
        obj.frame_ind = min(max(round(obj.frame_ind), 1), N);
        obj.slider.Value = obj.frame_ind;

        params = struct();
        params.clims = obj.get_color_limits(obj.variable_name);
        params.cb_lab = obj.label_dict(obj.variable_name);
        params.zero = M.zero;
        params.movie = false;
        params.conv_units = true; % plot_3D: equal aspect, all axes in chords

        % convection speed: the box, or each file's U until one is typed
        if isempty(obj.merged_conv_speed)
            obj.merged_conv_field.Value = planes(1).U;
        else
            obj.merged_conv_field.Value = obj.merged_conv_speed;
        end
        report_key = M.key + "|" + mat2str(obj.merged_conv_speed) + "|" + obj.num_cycles;
        if ~isfield(M, 'report_key') || ~strcmp(M.report_key, report_key)
            obj.print_merged_segments(planes);
            obj.merged_3D.report_key = report_key;
        end

        [surface_data, color_data, xlims] = obj.build_merged_surface(planes, (obj.frame_ind - 1) / N);

        if isscalar(p) && isscalar(ax)
            p.Vertices = surface_data.vertices;
            p.Faces = surface_data.faces;
            p.FaceVertexCData = color_data;
        else
            delete(ax);
            ax = axes(plot_panel);
            plot_3D(ax, surface_data, color_data, params);
            p = obj.find_isosurface_patch(ax);
            obj.plot_hold_bool = true;
        end
        setColorBar(ax, params)
        xlabel(ax, "x/c (downstream of the robot)", FontSize=16)
        % while playing the full reconstructed length (the surface moves),
        % otherwise cropped to where the isosurface ends
        if obj.play
            xlim(ax, xlims)
        else
            xlim(ax, obj.tight_merged_xlim(xlims, surface_data.vertices))
        end
        obj.draw_merged_planes(ax, planes);
        set_title();

        while obj.play && (obj.frame_ind < N)
            obj.frame_ind = obj.frame_ind + 1;
            obj.slider.Value = obj.frame_ind;
            [surface_data, color_data] = obj.build_merged_surface(planes, (obj.frame_ind - 1) / N);
            p.Vertices = surface_data.vertices;
            p.Faces = surface_data.faces;
            p.FaceVertexCData = color_data;
            set_title();
            obj.apply_remove_small(ax);
            pause(0.1);
            if obj.frame_ind == N
                obj.frame_ind = 0; % reset for next loop iteration
            end
        end

        obj.apply_fixed_lims(ax);
        obj.apply_remove_small(ax);
        xlim(ax, obj.tight_merged_xlim(xlims, p.Vertices(unique(p.Faces), :)));
        if obj.card_style
            obj.apply_card_style(ax);
        end

        function set_title()
            if isempty(obj.merged_conv_speed)
                uc_str = "U_c = U = " + sprintf("%.3g", planes(1).U) + " m/s";
            else
                uc_str = "U_c = " + sprintf("%.3g", obj.merged_conv_speed) + " m/s";
            end
            ax.Title.String = obj.case_name + "  (" + strjoin([planes.type], ", ") + ...
                "),  " + uc_str + ",  wing phase at robot: bin " + max(obj.frame_ind, 1) + " / " + N;
            ax.Title.Interpreter = 'none';
            ax.Title.FontSize = 14;
        end

        function show_message(text_str)
            delete(findobj(plot_panel.Children, 'Type', 'axes'));
            ax_msg = axes(plot_panel);
            text(ax_msg, 0.5, 0.5, text_str, 'HorizontalAlignment', 'center', ...
                Interpreter='none', FontSize=14);
            axis(ax_msg, 'off');
            obj.plot_hold_bool = false;
        end
    end

    % Fields of the current case at each downstream position for
    % plot_merged_3D: centre plane, trimmed / mirrored / filtered like the
    % 3D plot. Cached in obj.merged_3D; reloaded when the case, a file or a
    % setting they depend on changes. M = [] (and msg) if nothing to plot.
    function [M, msg] = get_merged_planes(obj)
        M = [];
        msg = "";
        if strlength(obj.case_name) == 0
            msg = "No case selected";
            return
        end
        [types, dists] = obj.get_merged_plane_types();
        case_ids = strings(size(types));
        for i = 1:numel(types)
            case_ids(i) = obj.get_merged_case_id(types(i));
        end
        found = strlength(case_ids) > 0;
        if ~any(found)
            msg = "No phase average of " + obj.case_name + " at any downstream position";
            return
        end
        types = types(found);
        dists = dists(found);
        case_ids = case_ids(found);
        plane_cases = cell(size(case_ids));
        names = strings(size(case_ids));
        stamps = strings(size(case_ids));
        for i = 1:numel(case_ids)
            plane_cases{i} = obj.get_phase_case(case_ids(i));
            names(i) = stb_name(plane_cases{i});
            stamps(i) = stb_file_stamp(plane_cases{i});
        end

        var_name = obj.variable_name_dict(obj.variable_name);
        iso_var_name = obj.variable_name_dict(obj.iso_var);
        is_transport = any(obj.variable_name == [obj.TRANSPORT_VARS, obj.TRANSPORT_SUM_VARS]);

        % background value of the colour variable (as in update_plot); the
        % colour limits only matter through it (noise floor), so the cache
        % below survives moving the colour limit slider
        var_clims = obj.get_color_limits(obj.variable_name);
        if strcmp(var_name, obj.LIFT_WX_FIELD) || is_transport
            zero = 0;
        elseif min(var_clims) < -1
            zero = -1;
        elseif min(var_clims) < 0.5
            zero = 0;
        else
            zero = 1;
        end

        key = strjoin([names(:)', stamps(:)', string(obj.variable_name), string(obj.iso_var), ...
            string(obj.trim_bool), mat2str(obj.trim_y_bounds), mat2str(obj.trim_z_bounds), ...
            string(obj.mirror_bool), mat2str(obj.mirror_center_y), string(obj.filter_bool), ...
            string(obj.floor_bool), sprintf("%.10g", obj.thresh), ...
            string(obj.unc_mask_bool), sprintf("%.10g", obj.unc_mask_thresh), ...
            string(obj.crop_box_bool), mat2str(obj.crop_box), string(zero)], "|");
        if ~isempty(obj.merged_3D) && obj.merged_3D.key == key
            M = obj.merged_3D;
            return
        end

        transport_pairs = strings(0, 2);
        transport_own_vort = strings(0, 1);
        if is_transport
            [transport_pairs, transport_own_vort] = obj.get_transport_inputs(var_name, false);
        end
        % sign flipped on the mirrored half (as in update_plot)
        flip_sign = any(contains(["v","ω_z","ω_x"], obj.variable_name));

        plane_list = {};
        missing = strings(0);
        for i = 1:numel(types)
            fprintf("Loading %s (%s, %.3f m downstream)\n", case_ids(i), types(i), dists(i));
            [P, miss] = obj.load_merged_plane(plane_cases{i}, var_name, iso_var_name, ...
                is_transport, transport_pairs, transport_own_vort, zero, flip_sign);
            if isempty(P)
                missing(end+1) = case_ids(i) + ": " + miss; %#ok<AGROW>
                continue
            end
            P.type = types(i);
            P.case_id = case_ids(i);
            P.x = dists(i);
            plane_list{end+1} = P; %#ok<AGROW>
        end
        planes = [plane_list{:}]; % same fields, same order
        if ~isempty(missing)
            fprintf("Skipped (not in the processed file - reprocess the case):\n");
            fprintf("  %s\n", missing);
        end
        if isempty(planes)
            msg = "None of the planes of " + obj.case_name + " could be loaded:" + newline + strjoin(missing, newline);
            return
        end

        % check that the planes agree on frequency / speed
        f_all = [planes.f];
        if max(f_all) - min(f_all) > 0.02 * mean(f_all)
            fprintf("Note: wingbeat frequency differs between planes (%s Hz)\n", mat2str(f_all, 3));
        end
        U_all = [planes.U];
        if max(U_all) - min(U_all) > 0.02 * mean(U_all)
            fprintf("Note: freestream U differs between planes (%s m/s)\n", mat2str(U_all, 3));
        end

        M = struct('key', key, 'planes', planes, 'zero', zero);
        obj.merged_3D = M;
    end

    % One plane for plot_merged_3D: colour variable (val) and iso variable
    % (Q) on the centre plane, y x z x bins, with the 3D plot's trim,
    % mirror, filter, noise floor and uncertainty mask. P = [] and miss =
    % the missing field if the file doesn't have what's needed.
    function [P, miss] = load_merged_plane(obj, case_files, var_name, iso_var_name, ...
            is_transport, transport_pairs, transport_own_vort, zero, flip_sign)
        P = [];
        miss = "";
        vars = ["L","U","num_bins","cycle_freq","z","y"];
        sec_vars = strings(1, 0);
        if strcmp(var_name, obj.LIFT_WX_FIELD)
            vars = [vars, string(obj.get_lift_wx_inputs(false))];
        elseif is_transport
            vars = [vars, unique([transport_pairs(:); transport_own_vort(:)])'];
        elseif contains(obj.variable_name, obj.secondary_vars)
            sec_vars(end+1) = var_name;
        else
            vars(end+1) = var_name;
        end
        if contains(obj.iso_var, obj.secondary_vars)
            sec_vars(end+1) = iso_var_name;
        else
            vars(end+1) = iso_var_name;
        end
        if obj.unc_mask_bool
            vars(end+1) = "uncTot_phase_avg";
        end

        % only ask for fields that are there (no load warnings)
        file_vars = string(stb_who(case_files));
        vars = unique([vars, sec_vars], 'stable');
        vars = vars(ismember(vars, file_vars));
        d = stb_load(case_files, vars{:});

        for need = ["L","U","num_bins","cycle_freq","z","y"]
            if ~isfield(d, need)
                miss = need;
                return
            end
        end
        if strcmp(var_name, obj.LIFT_WX_FIELD) && all(isfield(d, cellstr(string(obj.get_lift_wx_inputs(false)))))
            d.(var_name) = obj.compute_lift_wx_field(d, false);
        elseif is_transport && all(isfield(d, cellstr([transport_pairs(:); transport_own_vort(:)])))
            d.(var_name) = obj.compute_transport_field(d, var_name, transport_pairs, transport_own_vort);
        end
        if ~isfield(d, var_name)
            miss = var_name;
            return
        end
        if ~isfield(d, iso_var_name)
            miss = iso_var_name;
            return
        end

        plane_idx = (size(d.y, 1) + 1) / 2;
        y = squeeze(d.y(plane_idx,:,:));
        z = squeeze(d.z(plane_idx,:,:));
        val = d.(var_name);
        val = squeeze(val(plane_idx,:,:,:));
        Q = d.(iso_var_name);
        Q = squeeze(Q(plane_idx,:,:,:));
        unc = [];
        if obj.unc_mask_bool
            if isfield(d, "uncTot_phase_avg")
                unc = squeeze(mean(d.uncTot_phase_avg(plane_idx,:,:,:), 4, "omitnan"));
            else
                fprintf("Unc Mask: uncTot_phase_avg not in %s, not masked\n", stb_name(case_files));
            end
        end

        if obj.trim_bool
            y_idx = find(y(:,1) > obj.trim_y_bounds(1) & y(:,1) < obj.trim_y_bounds(2));
            z_idx = find(z(1,:) > obj.trim_z_bounds(1) & z(1,:) < obj.trim_z_bounds(2));
            y = y(y_idx, z_idx);
            z = z(y_idx, z_idx);
            val = val(y_idx, z_idx, :);
            Q = Q(y_idx, z_idx, :);
            if ~isempty(unc)
                unc = unc(y_idx, z_idx);
            end
        end
        if obj.mirror_bool
            % mirror across the centreline to reconstruct the other side
            % of the wake, the centreline row only once
            y_idx_m = find(y(:,1) > obj.mirror_center_y);
            y = y(y_idx_m, :);
            z = z(y_idx_m, :);
            val = val(y_idx_m, :, :);
            Q = Q(y_idx_m, :, :);
            y = y - min(y, [], "all");
            y = [flip(-y(2:end,:), 1); y];
            z = [flip(z(2:end,:), 1); z];
            val_add = flip(val(2:end,:,:), 1);
            if flip_sign
                val_add = -val_add;
            end
            val = [val_add; val];
            Q = [flip(Q(2:end,:,:), 1); Q];
            if ~isempty(unc)
                unc = unc(y_idx_m, :);
                unc = [flip(unc(2:end,:), 1); unc];
            end
        end
        if obj.filter_bool
            val = obj.nan_safe_medfilt(val);
            Q = obj.nan_safe_medfilt(Q);
        end
        if obj.floor_bool
            val(val < (zero + obj.thresh) & val > (zero - obj.thresh)) = zero;
        end
        if ~isempty(unc)
            % masked points get the iso variable's background (median), so
            % no isosurface forms there (as in the 3D plot)
            mask3 = repmat(unc > obj.unc_mask_thresh / 100 | isnan(unc), 1, 1, size(Q, 3));
            Q(mask3) = median(Q(~mask3), "omitnan");
        end
        Q = obj.apply_crop_box(Q, y, z, obj.mirror_bool);

        P = struct();
        P.U = d.U;
        P.L = d.L;
        P.f = d.cycle_freq;
        P.N = d.num_bins;
        P.yv = y(:,1);
        P.zv = z(1,:)';
        P.val = val;
        P.Q = Q;
    end

    % Isosurface of plot_merged_3D at wing phase phi_ref (cycles): one
    % frozen-flow segment per plane, from the plane to the next one
    % downstream (the last: obj.num_cycles wingbeats), joined into a single
    % patch. xlims: x/c covered.
    function [s, cdata, xlims] = build_merged_surface(obj, planes, phi_ref)
        verts = zeros(0, 3);
        faces = zeros(0, 3);
        cdata = zeros(0, 1);
        n = numel(planes);
        x_end = 0;
        for i = 1:n
            P = planes(i);
            lambda = obj.merged_speed(P) / P.f; % wake wavelength, m per wingbeat
            a = P.x;
            if i < n
                b = planes(i+1).x;            % cut off where the next plane starts
            else
                b = a + obj.num_cycles * lambda;
            end
            x_end = b;
            dx = lambda / P.N;                % one bin of convection
            nx = max(2, ceil((b - a) / dx - 1e-9) + 1);
            xs = linspace(a, b, nx);
            % fluid at xs crossed the plane (b - a)/U earlier: earlier bins
            phase = phi_ref - (xs - a) / lambda;
            Qs = obj.phase_interp(P.Q, phase);
            Cs = obj.phase_interp(P.val, phase);

            % y x (streamwise) x z for meshgrid(x, y, z) volumes
            [Xg, Yg, Zg] = meshgrid(xs / P.L, P.yv, P.zv);
            Qs = permute(Qs, [1 3 2]);
            Cs = permute(Cs, [1 3 2]);
            si = isosurface(Xg, Yg, Zg, Qs, obj.iso_val);
            if isempty(si.vertices)
                continue
            end
            ci = interp3(Xg, Yg, Zg, Cs, si.vertices(:,1), si.vertices(:,2), si.vertices(:,3));
            faces = [faces; si.faces + size(verts, 1)]; %#ok<AGROW>
            verts = [verts; si.vertices]; %#ok<AGROW>
            cdata = [cdata; ci(:)]; %#ok<AGROW>
        end
        s = struct('vertices', verts, 'faces', faces);
        xlims = [planes(1).x, x_end] / planes(1).L;
    end

    % Convection speed (m/s) for one plane of plot_merged_3D: the U_c box,
    % or the file's freestream U if none was typed
    function Uc = merged_speed(obj, P)
        if isempty(obj.merged_conv_speed)
            Uc = P.U;
        else
            Uc = obj.merged_conv_speed;
        end
    end

    % What each plane's segment covers (Command Window), in wingbeats of
    % wake at the convection speed
    function print_merged_segments(obj, planes)
        for i = 1:numel(planes)
            Uc = obj.merged_speed(planes(i));
            lambda = Uc / planes(i).f; % m per wingbeat
            if i < numel(planes)
                seg = planes(i+1).x - planes(i).x;
                fprintf("%s: %.3f to %.3f m (%.2f wingbeats at U_c = %.3g m/s, f = %.3g Hz)\n", ...
                    planes(i).type, planes(i).x, planes(i+1).x, seg / lambda, Uc, planes(i).f);
                if seg > lambda
                    fprintf("  longer than a wingbeat: the periodic phase average repeats along it\n");
                end
            else
                fprintf("%s: %.3f to %.3f m (%d wingbeat(s), %.3f m each at U_c = %.3g m/s, f = %.3g Hz)\n", ...
                    planes(i).type, planes(i).x, planes(i).x + obj.num_cycles * lambda, ...
                    obj.num_cycles, lambda, Uc, planes(i).f);
            end
        end
    end

    % x-limits of plot_merged_3D cropped to the isosurface: from the first
    % plane to just past the last vertex, never beyond the reconstructed
    % length (xlims_full); the full length if the surface is empty
    function xl = tight_merged_xlim(~, xlims_full, verts)
        xl = xlims_full;
        if isempty(verts)
            return
        end
        pad = 0.02 * diff(xlims_full);
        xl(2) = min(xlims_full(2), max(verts(:,1)) + pad);
        if xl(2) <= xl(1)
            xl = xlims_full;
        end
    end

    % Phase average A (y x z x N bins, bin k at phase (k-1)/N, periodic)
    % at the given phases (cycles), linear between neighbouring bins
    function V = phase_interp(~, A, phase)
        N = size(A, 3);
        kf = mod(phase(:)' * N, N);
        k0 = floor(kf);
        w = kf - k0;
        k0 = mod(k0, N);                 % kf can round up to N
        k1 = mod(k0 + 1, N);
        V0 = A(:,:,k0 + 1);
        V1 = A(:,:,k1 + 1);
        V = V0 .* reshape(1 - w, 1, 1, []) + V1 .* reshape(w, 1, 1, []);
        on_bin = w == 0;                 % keep NaNs of the other bin out
        V(:,:,on_bin) = V0(:,:,on_bin);
    end

    % Dashed outline of each measurement plane (its y-z extent) and its
    % label, on plot_merged_3D
    function draw_merged_planes(obj, ax, planes)
        delete(findall(ax, 'Tag', obj.MERGED_3D_MARKER_TAG));
        hold(ax, 'on')
        for i = 1:numel(planes)
            P = planes(i);
            x = P.x / P.L;
            yl = [min(P.yv) max(P.yv)];
            zl = [min(P.zv) max(P.zv)];
            h = plot3(ax, x * ones(1, 5), yl([1 2 2 1 1]), zl([1 1 2 2 1]), '--', ...
                'Color', [0.45 0.45 0.45], 'LineWidth', 1);
            style(h)
            h = text(ax, x, mean(yl), zl(2), P.type, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', 'FontSize', 12, 'Color', [0.3 0.3 0.3], ...
                'Interpreter', 'none');
            style(h)
        end
        hold(ax, 'off')

        function style(h)
            h.Tag = obj.MERGED_3D_MARKER_TAG;
            h.HandleVisibility = 'off';
            h.PickableParts = 'none';
        end
    end

    % "seam comparison": at the seam where the frozen-flow reconstruction
    % behind plane A (as on "phase avg: 3D all planes") reaches plane B,
    % the next one downstream,
    %   D(y, z, phi) = val_B(y, z, phi) - val_A(y, z, phi - (x_B - x_A) / lambda_A)
    % with lambda_A = U_c / f_A, shown as its mean or rms over the
    % wingbeat (seam_stat). D is evaluated on plane B's grid (plane A
    % interpolated onto it), with the planes as loaded for the all-planes
    % plot (trim / mirror / filter / noise floor). The colour range spans
    % the same width as the variable's own colour limits, centred on zero.
    function plot_seam_comparison(obj, plot_panel)
        delete(findobj(plot_panel.Children, 'Type', 'axes'));
        obj.plot_hold_bool = false;
        obj.slider.Visible = "off";
        obj.play_button.Visible = "off";
        obj.seam_grid.Visible = "on";

        if any(obj.variable_name == obj.EXTRAP_DIFF_VARS)
            show_message("Extrapolated - measured is only available for the 2D phase average plots");
            return
        end
        if obj.extrapolate_bool
            disp("seam comparison uses the measured fields (Extrapolate ignored)")
        end

        [M, msg] = obj.get_merged_planes();
        if isempty(M)
            show_message(msg);
            return
        end
        planes = M.planes;
        n_seams = numel(planes) - 1;
        if isempty(obj.merged_conv_speed)
            obj.seam_conv_field.Value = planes(1).U;
        else
            obj.seam_conv_field.Value = obj.merged_conv_speed;
        end
        if n_seams < 1
            obj.seam_slider.Enable = "off";
            show_message("Only one plane (" + planes(1).type + ") of " + obj.case_name + ...
                " could be loaded: no seam to compare");
            return
        end

        % slider: one tick per seam, labelled by the two planes
        seam_labels = strings(1, n_seams);
        for j = 1:n_seams
            seam_labels(j) = planes(j).type + "-" + planes(j+1).type;
        end
        obj.seam_ind = min(max(round(obj.seam_ind), 1), n_seams);
        obj.seam_slider.Enable = n_seams > 1;
        obj.seam_slider.Limits = [1 max(n_seams, 2)]; % Limits must be increasing
        obj.seam_slider.MajorTicks = 1:n_seams;
        obj.seam_slider.MajorTickLabels = seam_labels;
        obj.seam_slider.Value = obj.seam_ind;

        A = planes(obj.seam_ind);     % upstream: reconstructed
        B = planes(obj.seam_ind + 1); % downstream: measured
        [D, shift] = obj.seam_difference(A, B);
        nb = size(D, 3);
        % points with too few valid bins (e.g. outside one plane's field
        % of view in some bins) are left out
        valid = sum(~isnan(D), 3) >= nb / 2;
        if obj.seam_stat == "rms"
            S = sqrt(mean(D.^2, 3, "omitnan"));
        else
            S = mean(D, 3, "omitnan");
        end
        S(~valid) = NaN;
        if all(isnan(S), "all")
            show_message("Planes " + A.type + " and " + B.type + " don't overlap in y-z");
            return
        end

        % scalar summary over the overlap: rms of the plotted map, and the
        % rms of the measured field's departure from its background (for
        % scale)
        S_rms = sqrt(mean(S(valid).^2, "omitnan"));
        ref = B.val - M.zero;
        ref_rms = sqrt(mean(ref(repmat(valid, 1, 1, size(ref, 3))).^2, "omitnan"));
        fprintf("Seam %s (%s): %s over the wingbeat of measured - reconstructed %s; " + ...
            "rms over the overlap = %.4g (%.1f%% of the rms of %s - %g at %s), " + ...
            "reconstruction lag = %.3f wingbeats, U_c = %.3g m/s\n", ...
            seam_labels(obj.seam_ind), obj.case_name, obj.seam_stat, obj.variable_name, ...
            S_rms, 100 * S_rms / ref_rms, obj.variable_name, M.zero, B.type, shift, obj.merged_speed(A));

        var_clims = obj.get_color_limits(obj.variable_name);
        params = struct();
        params.zero = 0;
        if obj.seam_stat == "rms"
            params.clims = [0, diff(var_clims) / 2]; % jet, from 0
            params.cb_lab = "rms \boldmath$\Delta\,$" + obj.label_dict(obj.variable_name);
        else
            params.clims = [-1 1] * diff(var_clims) / 2;
            params.cb_lab = "\boldmath$\Delta\,$" + obj.label_dict(obj.variable_name);
        end
        [Zq, Yq] = meshgrid(B.zv, B.yv); % y x z, as the other 2D plots
        ax = axes(plot_panel);
        PIV_plot(Yq, Zq, S, params, ax);

        if isempty(obj.merged_conv_speed)
            uc_str = "U_c = U = " + sprintf("%.3g", obj.merged_speed(A));
        else
            uc_str = "U_c = " + sprintf("%.3g", obj.merged_conv_speed);
        end
        title(ax, [obj.case_name + ",  seam " + seam_labels(obj.seam_ind) + ...
            ":  " + obj.seam_stat + " over the wingbeat of " + B.type + " (measured) - " + ...
            A.type + " (frozen flow)", ...
            uc_str + " m/s,  lag " + sprintf("%.2f", shift) + " wingbeats,  rms over overlap = " + ...
            sprintf("%.3g", S_rms) + " (" + sprintf("%.0f", 100 * S_rms / ref_rms) + "% of " + ...
            B.type + " rms)"], 'Interpreter', 'none', 'FontSize', 14);

        function show_message(text_str)
            delete(findobj(plot_panel.Children, 'Type', 'axes'));
            ax_msg = axes(plot_panel);
            text(ax_msg, 0.5, 0.5, text_str, 'HorizontalAlignment', 'center', ...
                Interpreter='none', FontSize=14);
            axis(ax_msg, 'off');
        end
    end

    % Seam difference for plot_seam_comparison: plane B measured minus the
    % frozen-flow reconstruction from plane A where it reaches x_B, per
    % bin of B (y x z x N_B, on B's grid, NaN where A doesn't cover it).
    % shift: lag of the reconstruction, (x_B - x_A) / lambda_A wingbeats.
    function [D, shift] = seam_difference(obj, A, B)
        lambda = obj.merged_speed(A) / A.f; % m per wingbeat
        shift = (B.x - A.x) / lambda;
        % same convention as build_merged_surface: at x_B, segment A shows
        % the phase phi - shift of plane A, where segment B starts at phi
        phase = (0:B.N-1) / B.N - shift;
        R = obj.phase_interp(A.val, phase); % A's grid, y x z x N_B
        same_grid = isequal(size(A.yv), size(B.yv)) && isequal(size(A.zv), size(B.zv)) && ...
            max(abs(A.yv - B.yv)) < 1e-9 && max(abs(A.zv - B.zv)) < 1e-9;
        if ~same_grid
            [Zq, Yq] = meshgrid(B.zv, B.yv);
            [Za, Ya] = meshgrid(A.zv, A.yv);
            R_B = NaN(numel(B.yv), numel(B.zv), B.N);
            for k = 1:B.N
                R_B(:,:,k) = interp2(Za, Ya, R(:,:,k), Zq, Yq, "linear", NaN);
            end
            R = R_B;
        end
        D = B.val - R;
    end

    % Show the section-count dropdown instead of the colour-limit slider
    % for the "time avg: section avg" plot
    function set_section_controls(obj)
        is_section = ismember(obj.plot_type, obj.plot_types([10 13]));
        sidebar = obj.section_grid.Parent;
        row_heights = sidebar.RowHeight;
        if is_section
            obj.section_grid.Visible = "on";
            obj.clim_slider.Visible = "off";
            row_heights{7} = 98;   % section count, uncertainty mask, PIV Body Sub rows
        else
            obj.section_grid.Visible = "off";
            obj.clim_slider.Visible = "on";
            row_heights{7} = 35;
        end
        sidebar.RowHeight = row_heights;
    end

    % Trim bounds of the section plots: default_trim_bounds with their
    % uncertainty mask settings (off: no mask)
    function bounds = get_section_bounds(obj)
        bounds = default_trim_bounds();
        if obj.section_unc_bool
            bounds.unc_mask = obj.section_unc_pct / 100;
        else
            bounds.unc_mask = 0;
        end
        bounds.unc_mask_mode = obj.section_unc_mode;
    end

    % Steady case the section plots subtract (PIV Body Sub), as timeAvg_UI
    % picks it (get_PIV_sub_file_paths) for the current case
    % <type>_<amp>deg_<freq>Hz: ring -> <pos>_ring, body ->
    % <pos>_body_<amp>deg_0Hz (or <pos>_body), gliding -> <type>_<amp>deg_0Hz
    % (a steady case without an amplitude, e.g. x3_NACA, is its own),
    % freestream -> freestream. sub_name = "" if there is none.
    function [sub_files, sub_name] = get_section_sub_case(obj)
        sub_files = [];
        sub_name = "";
        base = obj.strip_variant_suffix(obj.get_current_case_id());
        tok = regexp(char(base), '^(.*)_(\d+(\.\d+)?)deg_\d+(\.\d+)?Hz', 'tokens', 'once');
        if isempty(tok)
            type = base;   % steady case without amplitude / frequency
            amp = "";
        else
            type = string(tok{1});
            amp = string(tok{2});
        end
        prefix = get_downstream_prefix(type, true);
        switch obj.section_sub_case
            case "ring"
                names = prefix + "ring";
            case "body"
                names = [prefix + "body_" + amp + "deg_0Hz", prefix + "body"];
            case "gliding"
                if strlength(amp) == 0
                    names = type;
                else
                    names = type + "_" + amp + "deg_0Hz";
                end
            case "freestream"
                names = position_independent_cases();
            otherwise
                names = strings(0);
        end
        for k = 1:numel(names)
            if any(obj.time_avg_case_ids == names(k))
                sub_name = names(k);
                sub_files = obj.get_time_case(sub_name);
                return
            end
        end
        fprintf("PIV Body Sub: no %s case found for %s (looked for %s) - not subtracted\n", ...
            obj.section_sub_case, base, strjoin(names, ", "));
    end

    % Section plots' PIV Body Sub: the subtracted case's time averaged
    % field (force integrand from get_PIV_force, or a flow variable)
    % interpolated onto the current case's trimmed grid (y, z in chords
    % from the centreline, before mirroring). [] if there is no case or no
    % such variable. kind: "force" (force_var) or "flow" (variable name in
    % the time averaged file); bounds: the section bounds.
    function [F_sub, sub_name] = get_section_sub_field(obj, kind, var, bounds, y_q, z_q)
        F_sub = [];
        [sub_files, sub_name] = obj.get_section_sub_case();
        if isempty(sub_files)
            return
        end
        key = kind + "|" + sub_name + "|" + var + "|" + sprintf("%.10g", bounds.unc_mask) + "|" + bounds.unc_mask_mode;
        if obj.section_sub_cache.key == key
            S = obj.section_sub_cache.data;
        else
            S = struct('y', [], 'z', [], 'field', []);
            if kind == "force"
                [~, ~, I] = get_PIV_force(sub_files, sub_name, var, 0, false, bounds);
                if ~isempty(I.field)
                    S = struct('y', I.y(:), 'z', I.z(:), 'field', mean(I.field, 3, "omitnan"));
                end
            else
                file_vars = string(stb_who(sub_files));
                if ismember(var, file_vars)
                    load_vars = {'y', 'z', char(var)};
                    has_unc = ismember("mean_uncTot", file_vars) && var ~= "mean_uncTot";
                    if has_unc, load_vars{end+1} = 'mean_uncTot'; end
                    d = stb_load(sub_files, load_vars{:});
                    b = old_flapper_compat("trim_bounds_for", stb_name(sub_files), bounds);
                    [y_tr, z_tr, val] = trim_vel_field(d.y, d.z, d.(var), b);
                    val = mean(val, 3, "omitnan");
                    if has_unc && b.unc_mask > 0
                        [~, ~, unc] = trim_vel_field(d.y, d.z, d.mean_uncTot, b);
                        mask = unc_mask_region(unc, b.unc_mask, b.unc_mask_mode);
                        if ~isempty(mask), val(mask) = NaN; end
                    end
                    S = struct('y', y_tr(:, 1), 'z', z_tr(1, :).', 'field', val);
                else
                    fprintf("PIV Body Sub: %s not in %s - not subtracted\n", var, sub_name);
                end
            end
            obj.section_sub_cache = struct('key', key, 'data', S);
        end
        if isempty(S.field) || numel(S.y) < 2 || numel(S.z) < 2
            return
        end
        % same grid (same position and processing): no interpolation
        if isequal(size(S.field), [numel(y_q), numel(z_q)]) && ...
                max(abs(S.y - y_q(:))) < 1e-9 && max(abs(S.z - z_q(:))) < 1e-9
            F_sub = S.field;
        else
            [Zq, Yq] = meshgrid(z_q(:), y_q(:));
            F_sub = interp2(S.z(:).', S.y(:), S.field, Zq, Yq, "linear");   % NaN outside its plane
        end
        fprintf("PIV Body Sub: %s data used with %s data subtracted\n", ...
            obj.get_current_case_id(), sub_name);
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
    %
    % Flow variables (u, v, w, ω_x, ω_y, ω_z) go to plot_section_flow,
    % which averages over each section instead of summing.
    %
    % "phase avg: section avg" (plot_types(13)) does the same for every
    % phase bin of the phase averaged field instead of the cycle average,
    % shown as a movie (frame slider, Play / Stop, Save Movie) with the
    % axes fixed over the wingbeat.
    function plot_section_force(obj, plot_panel)
        is_phase = obj.plot_type == obj.plot_types(13);
        obj.slider.Visible = "off";
        obj.play_button.Visible = "off";
        if strlength(obj.case_name) == 0
            return
        end
        if ismember(obj.variable_name, obj.section_flow_vars)
            obj.plot_section_flow(plot_panel);
            return
        end
        if ~ismember(obj.variable_name, obj.section_force_vars)
            return
        end
        % phase averaged file if there is one, else the time averaged file
        % (0 Hz cases): mean_* fields, freestream U and rho = 1.225, as in
        % timeAvg_UI. For a time average the nonlinear terms (lift_vel,
        % vel diff, bernoulli, drag_vel) use the mean velocity, not the
        % mean of the per-frame products.
        case_id = obj.get_current_case_id();
        if obj.current_case_has_phase_avg()
            case_files = obj.get_phase_case(case_id);
            avg_type = 1;
            avg_label = "Time averaged";
        elseif obj.current_case_has_time_avg() && ~is_phase
            case_files = obj.get_time_case(case_id);
            avg_type = 0;
            avg_label = "Time averaged (0 Hz file)";
        else
            return
        end

        ax = axes(plot_panel);
        force_var = obj.force_var_name_dict(char(obj.variable_name));
        sec_bounds = obj.get_section_bounds();
        cache_key = "force|" + strjoin(string(stb_name(case_files)), ",") + "|" + force_var + "|" + avg_type + ...
            "|" + sprintf("%.10g", sec_bounds.unc_mask) + "|" + sec_bounds.unc_mask_mode;
        if obj.section_cache.key == cache_key
            I = obj.section_cache.data;
        else
            [~, ~, I] = get_PIV_force(case_files, case_id, force_var, avg_type, false, sec_bounds);
            obj.section_cache = struct('key', cache_key, 'data', I);
        end
        if isempty(I.field)
            text(ax, 0.5, 0.5, string(obj.variable_name) + " is not a plane integral", ...
                'HorizontalAlignment', 'center', FontSize=16);
            axis(ax, 'off');
            return
        end

        if is_phase
            field = I.field;                        % N/m^2, [ny nz nb], one bin each
            avg_label = "Phase averaged";
        else
            % cycle average (bins weighted equally, like the wake forces mean)
            field = mean(I.field, 3, "omitnan");   % N/m^2, [ny nz]
        end
        nb = size(field, 3);
        y_nd = I.y(:);                          % y/c from the centreline
        % PIV Body Sub: the steady case's integrand, from every bin
        sub_note = "";
        if obj.section_sub_bool
            [F_sub, sub_name] = obj.get_section_sub_field("force", force_var, sec_bounds, y_nd, I.z(:));
            if isempty(F_sub)
                sub_note = " (no " + obj.section_sub_case + " case to subtract)";
            else
                field = field - F_sub;
                sub_note = " minus " + sub_name;
            end
        end
        % Mirror: both wings, the integrands being even in y
        if obj.mirror_bool
            [y_nd, field] = obj.mirror_section_field(y_nd, field, false);
        end
        y = y_nd * I.L;                         % m
        z = I.z(:) * I.L;

        % force per unit span of each column, N/m, [ny nb]
        dL_dy = reshape(trapz(z, field, 2), numel(y), nb);
        nan_cols = sum(isnan(dL_dy), 1);

        % trapz weights along y, so the slices add up to trapz over y
        dy = diff(y);
        w = ([dy; 0] + [0; dy]) / 2;
        col_lift = w .* dL_dy;                  % N, each column's share
        total = sum(col_lift, 1, "omitnan");    % = cycle mean (or bin value) in "wake forces"

        % slices: equal widths in y ("every column": one per column)
        [edges, sec_idx] = obj.get_section_edges(y_nd);
        n = numel(edges) - 1;
        sec_lift = zeros(n, nb);
        for b = 1:nb
            sec_lift(:, b) = accumarray(sec_idx, col_lift(:, b), [n 1], @(v) sum(v, "omitnan"), 0);
        end

        % axes limits over every bin, so the movie doesn't rescale
        lim_l = obj.zero_based_limits(sec_lift);
        lim_r = obj.zero_based_limits(dL_dy);
        [lim_l, lim_r] = obj.align_zero_limits(lim_l, lim_r);

        k = 1;
        if is_phase
            k = obj.setup_section_frames(nb);
        end

        % bars as patches so each spans its slice exactly
        yyaxis(ax, 'left')
        hold(ax, 'on')
        c = ax.ColorOrder(1, :);
        h_bar = gobjects(n, 1);
        for j = 1:n
            h_bar(j) = patch(ax, [edges(j) edges(j+1) edges(j+1) edges(j)], [0 0 sec_lift(j,k) sec_lift(j,k)], c, ...
                'FaceAlpha', 0.5, 'EdgeColor', c);
        end
        % percentages of the total: cycle average only (a bin's total can
        % be near zero)
        if ~is_phase && n <= 20 && abs(total) > 0
            for j = 1:n
                if sec_lift(j) >= 0, va = 'bottom'; else, va = 'top'; end
                text(ax, (edges(j) + edges(j+1))/2, sec_lift(j), sprintf("%.0f%%", 100*sec_lift(j)/total), ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', va, FontSize=12);
            end
        end
        yline(ax, 0, '-k', 'HandleVisibility', 'off');
        force_label = obj.force_label_dict(char(obj.variable_name));   % e.g. "Lift, ω_x term (N)"
        ylabel(ax, erase(force_label, " (N)") + " from section (N)", FontSize=16)

        yyaxis(ax, 'right')
        h_line = plot(ax, y_nd, dL_dy(:, k), '-', 'LineWidth', 1.5);
        ylabel(ax, "per unit span (N/m)", FontSize=16)

        % same zero height on both axes
        yyaxis(ax, 'left');  ylim(ax, lim_l);
        yyaxis(ax, 'right'); ylim(ax, lim_r);
        yyaxis(ax, 'left');

        xlim(ax, [edges(1), edges(end)])
        xlabel(ax, "y/c (from centreline)", FontSize=16)
        h_title = title(ax, title_text(k), FontSize=16, Interpreter="none"); % names contain "_"

        if is_phase
            obj.play_section_frames(nb, @draw_bin);
        end

        function draw_bin(kk)
            for jj = 1:n
                h_bar(jj).YData = [0 0 sec_lift(jj,kk) sec_lift(jj,kk)];
            end
            h_line.YData = dL_dy(:, kk);
            h_title.String = title_text(kk);
        end

        function str = title_text(kk)
            str = string(sprintf("%s %s: %.4f N total, %d sections", ...
                avg_label, string(obj.variable_name), total(kk), n));
            str = str + sub_note;
            if obj.mirror_bool
                str = str + " (mirrored, both sides)";
            end
            if obj.section_unc_bool
                str = str + sprintf(" (unc mask %g%%, %s)", obj.section_unc_pct, obj.section_unc_mode);
            end
            if is_phase
                str = "Bin " + kk + " of " + nb + ", " + str;
            end
            if nan_cols(kk) > 0
                str = str + sprintf(" (%d NaN columns left out)", nan_cols(kk));
            end
        end
    end

    % "phase avg: section avg": show the frame slider and Play / Stop for
    % nb bins; returns the bin to draw first
    function k = setup_section_frames(obj, nb)
        obj.slider.Visible = "on";
        obj.play_button.Visible = "on";
        if nb ~= obj.num_bins
            obj.num_bins = nb;
            obj.slider.Limits = [1 max(nb, 2)];
            obj.slider.MajorTicks = 1:5:nb;
            obj.slider.MinorTicks = 1:nb;
        end
        obj.frame_ind = min(max(obj.frame_ind, 1), obj.num_bins);
        obj.slider.Value = obj.frame_ind;
        k = obj.frame_ind;
    end

    % Play loop of "phase avg: section avg": draw_bin(k) updates the plot
    % to bin k. Same behaviour as the 2D movie loop (loops until Stop) and
    % the same Save Movie hook (movie_frame_fcn, after each bin is drawn).
    function play_section_frames(obj, nb, draw_bin)
        if ~isempty(obj.movie_frame_fcn) % Save Movie: first bin
            drawnow;
            obj.movie_frame_fcn();
        end
        while obj.play && (obj.frame_ind < nb)
            obj.frame_ind = obj.frame_ind + 1;
            obj.slider.Value = obj.frame_ind;
            draw_bin(obj.frame_ind);
            drawnow;
            if isempty(obj.movie_frame_fcn)
                pause(0.05);
            else
                obj.movie_frame_fcn(); % Save Movie: add this bin
            end
            if obj.frame_ind == nb
                obj.frame_ind = 0; % reset for next loop iteration
            end
        end
    end

    % Section edges along y (y/c) for the selected section count: equal
    % widths between the first and last column, or one section per column
    % ("every column"). sec_idx is each column's section.
    % Section plots with Mirror on: reflect the trimmed half plane (y/c
    % from the centreline, dimension 1 of field) to the other side, so the
    % sections cover both wings. odd: the variable changes sign across the
    % centreline (v, omega_x, omega_z). A centreline row (y = 0) is kept
    % once; a plane that already spans both sides is left as it is.
    function [y_nd, field] = mirror_section_field(~, y_nd, field, odd)
        y_nd = y_nd(:);
        tol = 1e-6 * max(abs(y_nd));
        if isempty(y_nd) || min(y_nd) < -tol
            return
        end
        if abs(y_nd(1)) <= tol
            k0 = 2; % centreline sample: not repeated
        else
            k0 = 1;
        end
        sz = size(field);
        part = field(k0:end, :);
        part = reshape(flip(reshape(part, [numel(y_nd) - k0 + 1, sz(2:end)]), 1), size(part));
        if odd
            part = -part;
        end
        field = reshape([part; reshape(field, sz(1), [])], [sz(1) + size(part, 1), sz(2:end)]);
        y_nd = [-flip(y_nd(k0:end)); y_nd];
    end

    function [edges, sec_idx] = get_section_edges(obj, y_nd)
        y_nd = y_nd(:);
        n_sec = sscanf(char(obj.section_count), '%d');
        if isempty(n_sec)
            edges = [y_nd(1) - (y_nd(2) - y_nd(1))/2; ...
                     (y_nd(1:end-1) + y_nd(2:end))/2; ...
                     y_nd(end) + (y_nd(end) - y_nd(end-1))/2];
            sec_idx = (1:numel(y_nd))';
        else
            edges = linspace(y_nd(1), y_nd(end), n_sec + 1)';
            sec_idx = discretize(y_nd, edges);
        end
    end

    % "time avg: section avg" for a flow variable (u, v, w, ω_x, ω_y,
    % ω_z): the cycle-averaged field on the same trimmed plane as the
    % force version (trim_vel_field with default_trim_bounds, or the old
    % flapper bounds), so the sections line up with the force plot. Each
    % bar is the area-weighted mean of the variable over its section
    % (trapz weights in y and z), the line is the z-average of each column
    % and the dashed line the mean over the whole plane. Same
    % nondimensional units as the 2D plots (u/U, ω c/U).
    %
    % Points with high uncertainty (bounds.unc_mask, as in the forces)
    % and missing points are left out of the averages rather than filled.
    %
    % "phase avg: section avg": the same for every phase bin (movie), with
    % the axis fixed over the wingbeat; the uncertainty mask is the
    % time-averaged one (unc_mask_region), as for the forces.
    function plot_section_flow(obj, plot_panel)
        is_phase = obj.plot_type == obj.plot_types(13);
        case_id = obj.get_current_case_id();
        if obj.current_case_has_phase_avg()
            case_files = obj.get_phase_case(case_id);
            var_name = obj.variable_name_dict(char(obj.variable_name));
            unc_name = "uncTot_phase_avg";
            avg_label = "Time averaged";
        elseif obj.current_case_has_time_avg() && ~is_phase
            case_files = obj.get_time_case(case_id);
            var_name = obj.time_avg_var_name_dict(char(obj.variable_name));
            unc_name = "mean_uncTot";
            avg_label = "Time averaged (0 Hz file)";
        else
            return
        end
        if is_phase
            avg_label = "Phase averaged";
        end

        file_vars = string(stb_who(case_files));
        if ~ismember(var_name, file_vars)
            obj.show_missing_variable(plot_panel, var_name);
            return
        end
        load_vars = {'y', 'z', char(var_name)};
        % the uncertainty plot itself isn't masked by the uncertainty
        % (that would only leave its low values)
        is_unc_var = string(var_name) == unc_name;
        has_unc = ismember(unc_name, file_vars) && ~is_unc_var;
        if has_unc
            load_vars{end+1} = char(unc_name);
        end
        cache_key = "flow|" + strjoin(string(stb_name(case_files)), ",") + "|" + strjoin(string(load_vars), ",");
        if obj.section_cache.key == cache_key
            d = obj.section_cache.data;
        else
            d = stb_load(case_files, load_vars{:});
            obj.section_cache = struct('key', cache_key, 'data', d);
        end

        % same trim as get_PIV_force
        file_stem = stb_name(case_files);
        bounds = old_flapper_compat("trim_bounds_for", file_stem, obj.get_section_bounds());
        [y_tr, z_tr, val] = trim_vel_field(d.y, d.z, d.(var_name), bounds);
        if is_phase
            field = val;                        % one bin each, [ny nz nb]
        else
            field = mean(val, 3, "omitnan");   % cycle average, bins weighted equally, [ny nz]
        end
        nb = size(field, 3);

        n_masked = 0;
        if has_unc && isfield(bounds, 'unc_mask') && ~isempty(bounds.unc_mask) && bounds.unc_mask > 0
            [~, ~, unc] = trim_vel_field(d.y, d.z, d.(unc_name), bounds);
            unc_mode = "threshold";
            if isfield(bounds, 'unc_mask_mode'), unc_mode = bounds.unc_mask_mode; end
            mask = unc_mask_region(unc, bounds.unc_mask, unc_mode);   % [ny nz]
            mask3 = repmat(mask, 1, 1, nb);
            n_masked = nnz(mask & ~all(isnan(field), 3));
            field(mask3) = NaN;
        end

        ax = axes(plot_panel);
        y_nd = y_tr(:, 1);   % y/c from the centreline
        z_nd = z_tr(1, :).';
        % PIV Body Sub: the steady case's field (time averaged file, same
        % trim and mask), from every bin
        sub_note = "";
        if obj.section_sub_bool
            sub_var = obj.time_avg_var_name_dict(char(obj.variable_name));
            [F_sub, sub_name] = obj.get_section_sub_field("flow", sub_var, bounds, y_nd, z_nd);
            if isempty(F_sub)
                sub_note = "no " + obj.section_sub_case + " case subtracted";
            else
                field = field - F_sub;
                sub_note = "minus " + sub_name;
            end
        end
        % Mirror: both sides of the wake; v, omega_x and omega_z change
        % sign across the centreline (as in the 2D plots)
        if obj.mirror_bool && numel(y_nd) >= 2
            is_odd = ismember(obj.variable_name, ["v", "ω_x", "ω_z"]);
            [y_nd, field] = obj.mirror_section_field(y_nd, field, is_odd);
        end
        if numel(y_nd) < 2 || numel(z_nd) < 2 || all(isnan(field), "all")
            text(ax, 0.5, 0.5, "No data in the trimmed plane", 'HorizontalAlignment', 'center', FontSize=16);
            axis(ax, 'off');
            return
        end

        % trapz weights, so a mean is (trapz over y and z) / area
        trap_w = @(x) ([diff(x); 0] + [0; diff(x)]) / 2;
        A0 = trap_w(y_nd) * trap_w(z_nd).';   % area of each point, (y/c)(z/c)
        [edges, sec_idx] = obj.get_section_edges(y_nd);
        n = numel(edges) - 1;
        col_mean = NaN(numel(y_nd), nb);
        sec_mean = NaN(n, nb);
        plane_mean = NaN(1, nb);
        for b = 1:nb
            fb = field(:, :, b);
            good = ~isnan(fb);
            A = A0;
            A(~good) = 0;
            fb(~good) = 0;
            col_sum = sum(A .* fb, 2);
            col_area = sum(A, 2);
            col_mean(:, b) = col_sum ./ col_area;       % z-average of each column (NaN if empty)
            plane_mean(b) = sum(col_sum) / sum(col_area);
            sec_mean(:, b) = accumarray(sec_idx, col_sum, [n 1]) ./ accumarray(sec_idx, col_area, [n 1]);
        end

        % axis from zero, unless the values sit far from it (e.g. u ~ -1);
        % over every bin, so the movie doesn't rescale
        vals = [sec_mean(:); col_mean(:)];
        lo = min(vals, [], "omitnan");
        hi = max(vals, [], "omitnan");
        if lo > 0 && lo > (hi - lo) || hi < 0 && -hi > (hi - lo)
            span = max(hi - lo, 1e-3 * max(abs([lo hi])));
            lim = [lo - 0.15*span, hi + 0.15*span];
            if hi < 0, base = lim(2); else, base = lim(1); end
        else
            lim = obj.zero_based_limits(vals);
            base = 0;
        end

        k = 1;
        if is_phase
            k = obj.setup_section_frames(nb);
        end

        hold(ax, 'on')
        c = ax.ColorOrder(1, :);
        h_bar = gobjects(n, 1);
        h_txt = gobjects(n, 1);
        show_txt = n <= 20;
        for j = 1:n
            h_bar(j) = patch(ax, [edges(j) edges(j+1) edges(j+1) edges(j)], bar_y(j, k), c, ...
                'FaceAlpha', 0.5, 'EdgeColor', c);
            if j > 1, h_bar(j).HandleVisibility = 'off'; end
            if show_txt
                h_txt(j) = text(ax, (edges(j) + edges(j+1))/2, base, "", ...
                    'HorizontalAlignment', 'center', FontSize=12);
            end
        end
        h_col = plot(ax, y_nd, col_mean(:, k), '-', 'Color', ax.ColorOrder(2, :), 'LineWidth', 1.5);
        h_mean = yline(ax, plane_mean(k), '--k', 'LineWidth', 1);
        if base == 0
            yline(ax, 0, '-k', 'HandleVisibility', 'off');
        end
        legend(ax, [h_bar(1), h_col, h_mean], ["section mean", "column mean (over z)", "plane mean"], ...
            'Location', 'best', FontSize=12);
        ylim(ax, lim)
        xlim(ax, [edges(1), edges(end)])
        box(ax, 'on')
        xlabel(ax, "y/c (from centreline)", FontSize=16)
        ylabel(ax, obj.label_dict(char(obj.variable_name)), FontSize=16, Interpreter="latex")
        h_title = title(ax, "", FontSize=16, Interpreter="none");
        draw_bin(k);

        if is_phase
            obj.play_section_frames(nb, @draw_bin);
        end

        % bar outline from the base to the section mean (flat at the base
        % for an empty section)
        function yy = bar_y(jj, kk)
            v = sec_mean(jj, kk);
            if isnan(v), v = base; end
            yy = [base base v v];
        end

        function draw_bin(kk)
            for jj = 1:n
                h_bar(jj).YData = bar_y(jj, kk);
                if show_txt
                    v = sec_mean(jj, kk);
                    if isnan(v)
                        h_txt(jj).String = "";
                    else
                        h_txt(jj).Position(2) = v;
                        h_txt(jj).String = sprintf("%.3g", v);
                        if v >= base
                            h_txt(jj).VerticalAlignment = 'bottom';
                        else
                            h_txt(jj).VerticalAlignment = 'top';
                        end
                    end
                end
            end
            h_col.YData = col_mean(:, kk);
            h_mean.Value = plane_mean(kk);
            str = string(sprintf("%s %s: plane mean %.4g, %d sections", ...
                avg_label, string(obj.variable_name), plane_mean(kk), n));
            if is_phase
                str = "Bin " + kk + " of " + nb + ", " + str;
            end
            notes = strings(0);
            if n_masked > 0
                notes(end+1) = sprintf("%d points masked: unc %g%%, %s", n_masked, ...
                    obj.section_unc_pct, obj.section_unc_mode);
            end
            if base ~= 0
                notes(end+1) = "axis not from zero";
            end
            if strlength(sub_note) > 0
                notes(end+1) = sub_note;
            end
            if obj.mirror_bool
                notes(end+1) = "mirrored";
            end
            if ~isempty(notes)
                str = str + " (" + strjoin(notes, ", ") + ")";
            end
            h_title.String = str;
        end
    end

    % Copy an axes with left and right y axes (yyaxis) into fig, which
    % copyobj doesn't support: copies each side's plotted objects, limits
    % and labels into a new yyaxis axes at the same position
    % Copies the axes and colorbars of the plot panel into fig (Save
    % Figure / Save Movie)
    function copy_plot_to_figure(obj, plot_panel, fig)
        ax = findobj(plot_panel.Children, 'Type', 'axes');
        cb = findobj(plot_panel.Children, 'Type', 'colorbar');
        % copyobj can't copy axes with two y axes (yyaxis, e.g. the
        % section avg plot), so those are rebuilt side by side
        is_yy = arrayfun(@(a) numel(a.YAxis) > 1, ax);
        if any(~is_yy) || ~isempty(cb)
            copyobj([ax(~is_yy); cb(:)], fig);
        end
        for a = ax(is_yy)'
            obj.copy_yyaxis_axes(a, fig);
        end
        if ~isempty(obj.card_panel_color)
            fig.Color = obj.CARD_BG; % card style: dark around the axes too
        end
    end

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

    % "frozen flow" plot type: compares the slab-normal derivatives du/dx,
    % dv/dx, dw/dx on the centre plane, and omega_y, omega_z built from
    % them, with the frozen-flow estimates from the phase series (x points
    % upstream, so d/dx = (1/U) d/dt; get_frozen_flow_fields ->
    % frozen_flow_gradients). All nondimensional, (c/U) * derivative, like
    % dwdx_phase_avg. Same check as helper functions/slab_derivative_map.m.
    function plot_frozen_flow(obj, plot_panel)
        if strlength(obj.case_name) == 0 || ~obj.current_case_has_phase_avg()
            return
        end
        file = obj.get_phase_case(obj.get_current_case_id());

        ax = axes(plot_panel);
        try
            R = get_frozen_flow_fields(file, obj.get_current_case_id(), []);   % untrimmed centre plane
        catch err
            text(ax, 0.5, 0.5, err.message, 'HorizontalAlignment', 'center', ...
                Interpreter='none', FontSize=14);
            axis(ax, 'off');
            obj.slider.Visible = "off"; obj.play_button.Visible = "off";
            return
        end

        % which quantity, and which of slab / frozen / rms ratio / correlation
        k = find(obj.frozen_vars == string(obj.variable_name), 1);
        if isempty(k), k = 1; end
        nk = numel(obj.frozen_kinds);
        key = obj.frozen_keys(ceil(k / nk));
        kind = mod(k - 1, nk) + 1;
        if ~isfield(R.slab, key)
            text(ax, 0.5, 0.5, "dvdy\_phase\_avg / dwdz\_phase\_avg not in this file (older processing)", ...
                'HorizontalAlignment', 'center', FontSize=14);
            axis(ax, 'off');
            obj.slider.Visible = "off"; obj.play_button.Visible = "off";
            return
        end
        slab = R.slab.(key);
        ff = R.ff.(key);
        y = R.y;  z = R.z;
        nb = size(slab, 3);

        if obj.trim_bool
            y_idx = find(y(:,1) > obj.trim_y_bounds(1) & y(:,1) < obj.trim_y_bounds(2));
            z_idx = find(z(1,:) > obj.trim_z_bounds(1) & z(1,:) < obj.trim_z_bounds(2));
            y = y(y_idx, z_idx);  z = z(y_idx, z_idx);
            slab = slab(y_idx, z_idx, :);  ff = ff(y_idx, z_idx, :);
        end

        params.U = R.U;
        params.zero = 0;
        params.clims = obj.get_color_limits(obj.variable_name);
        params.cb_lab = obj.frozen_label_dict(char(obj.variable_name));

        if kind <= 2
            obj.slider.Visible = "on";
            obj.play_button.Visible = "on";
            if nb ~= obj.num_bins
                obj.num_bins = nb;
                obj.slider.Limits = [1 nb];
                obj.slider.MajorTicks = 1:5:nb;
                obj.slider.MinorTicks = 1:nb;
            end
            obj.frame_ind = min(max(obj.frame_ind, 1), obj.num_bins);
            if kind == 1
                val = slab;
            else
                val = ff;
            end

            h = PIV_plot(y, z, val(:,:,obj.frame_ind), params, ax);
            % d/dt: exact (harmonic regression) or finite difference
            suffix = "";
            if kind == 2, suffix = "  (d/dt: " + R.ddt_method + ")"; end
            t = title(ax, "Bin number: " + obj.frame_ind + suffix, FontSize=18);
            while obj.play && (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;
                tmp = val(:,:,obj.frame_ind);
                tmp(tmp < params.clims(1)) = params.clims(1);
                tmp(tmp > params.clims(2)) = params.clims(2);
                set(h, 'ZData', tmp);
                set(t, 'String', "Bin number: " + obj.frame_ind + suffix);
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
        a = slab - mean(slab, 3, 'omitnan');
        b = ff   - mean(ff, 3, 'omitnan');
        if kind == 3
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

    function [pairs, own_vort] = get_transport_inputs(~, var_name, using_time_avg_file)
        % Stored fields for a transport variable: pairs is an n x 2 string
        % array of {vorticity field, gradient field} whose products are
        % summed (n = 1 for a single term of transport_term_list, n = 3
        % for a row sum, *_total / *_growth); own_vort is omega_i for
        % *_growth (empty string array otherwise)
        terms = transport_term_list();
        names = string(terms(:, 1));
        name = erase(string(var_name), "transport_");
        own_vort = strings(0, 1);
        if endsWith(name, ["_total", "_growth"])
            comp = extractBefore(name, "_");          % "wx"
            k = find(startsWith(names, comp + "_"));  % the 3 terms of that row
            if endsWith(name, "_growth")
                own_vort = "vort" + upper(extractAfter(comp, 1)); % "vortX"
            end
        else
            k = find(names == name, 1);
        end
        if isempty(k)
            error("Unknown vorticity transport term " + string(var_name))
        end
        pairs = [string(terms(k, 2)), string(terms(k, 3))];
        if using_time_avg_file
            pairs = "mean_" + pairs;
            own_vort = "mean_" + own_vort;
        else
            pairs = pairs + "_phase_avg";
            own_vort = own_vort + "_phase_avg";
        end
    end

    function val = compute_transport_field(~, d, var_name, pairs, own_vort)
        % Sum of omega_j du_i/dx_j over the rows of pairs (product of the
        % stored nondimensional fields, c^2/U^2), times omega_i for
        % *_growth (c^3/U^3)
        val = 0;
        for r = 1:size(pairs, 1)
            val = val + d.(char(pairs(r, 1))) .* d.(char(pairs(r, 2)));
        end
        if endsWith(string(var_name), "_growth")
            val = d.(char(own_vort)) .* val;
        end
    end

    function labels = transport_sum_labels(obj)
        % net omega_i source and |omega_i| growth, TRANSPORT_SUM_VARS order
        labels = strings(1, numel(obj.TRANSPORT_SUM_VARS));
        uvw = ["u" "v" "w"];
        xyz = ["x" "y" "z"];
        for k = 1:3
            row = "\omega_j \frac{\partial " + uvw(k) + "}{\partial x_j}";
            labels(k) = "\boldmath$" + row + " \frac{c^2}{U_{\infty}^2} \;\; " + ...
                "(\mathrm{net}\ \omega_" + xyz(k) + "\ \mathrm{source})$";
            labels(k + 3) = "\boldmath$\omega_" + xyz(k) + " " + row + ...
                " \frac{c^3}{U_{\infty}^3} \;\; (|\omega_" + xyz(k) + "|\ \mathrm{growth})$";
        end
    end

    function labels = transport_labels(obj)
        % omega_j du_i/dx_j c^2/U^2 for each TRANSPORT_VARS entry, plus
        % its plain name, e.g. "... (omega_y -> omega_x tilt)"
        labels = strings(1, numel(obj.TRANSPORT_VARS));
        for k = 1:numel(obj.TRANSPORT_VARS)
            parts = split(obj.TRANSPORT_VARS(k), " ");   % "ω_x", "du/dx", ...
            w = extractAfter(parts(1), "_");             % omega_j
            uvw = extractBetween(parts(2), "d", "/");    % u_i
            dx = extractAfter(parts(2), "/d");           % x_j
            wi = replace(uvw, ["u" "v" "w"], ["x" "y" "z"]); % omega_i
            if w == wi
                name = "\omega_" + wi + "\ \mathrm{stretch}";
            else
                name = "\omega_" + w + " \!\rightarrow\! \omega_" + wi + "\ \mathrm{tilt}";
            end
            labels(k) = "\boldmath$\omega_" + w + " \frac{\partial " + uvw + ...
                "}{\partial " + dx + "} \frac{c^2}{U_{\infty}^2} \;\; (" + name + ")$";
        end
    end

    % Crop Box: points of the 3D plot's iso variable Q ([ny nz nb] on the
    % plotted y, z grid) inside obj.crop_box get Q's background value (its
    % median), like the uncertainty mask, so no isosurface forms there and
    % surfaces crossing the box edge are closed off. y is measured from
    % the mirror centreline (the plotted y when mirrored).
    function Q = apply_crop_box(obj, Q, y, z, mirrored)
        if ~isequal(size(y), [size(Q, 1), size(Q, 2)])
            return
        end
        mask = obj.crop_box_mask(y, z, mirrored);
        if isempty(mask)
            return
        end
        b = obj.crop_box;
        mask3 = repmat(mask, 1, 1, size(Q, 3));
        Q(mask3) = median(Q(~mask3), "omitnan");
        fprintf("Crop Box: %.1f%% of points hidden (y %g to %g, z %g to %g)\n", ...
            100 * mean(mask(:)), b);
    end

    % Points of the plotted y, z grid inside the Crop Box ([] if it's off
    % or holds no points). y is measured from the mirror centreline (the
    % plotted y when mirrored).
    function mask = crop_box_mask(obj, y, z, mirrored)
        mask = [];
        if ~obj.crop_box_bool || isempty(y)
            return
        end
        b = obj.crop_box;
        y_rel = y;
        if ~mirrored
            y_rel = y - obj.mirror_center_y;
        end
        m = y_rel > b(1) & y_rel < b(2) & z > b(3) & z < b(4);
        if any(m(:))
            mask = m;
        end
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