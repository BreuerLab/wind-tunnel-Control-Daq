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
        % old flapper (Feb 2026) / new flapper (Aug-Sep 2026) data sets, as
        % in phaseAvg_UI: new flapper case types start with these prefixes
        OLD_FLAPPER_SOURCE_MODE = "old flapper";
        % particle-track method the HRPP button selects (particle pool fit
        % with harmonic regression across bins): <case>_particle_pool_hr20
        HRPP_METHOD = "particle_pool_hr20";
        NEW_FLAPPER_SOURCE_MODE = "new flapper";
        new_flapper_downstream_types = ["x1";"x2";"x3";"x4";"x5";"MPS"];
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
        % All data roots (e.g. ["F:\", "C:\...\STB Round 1\"]) and, for
        % each wing type, the root its STB cases came from (its load cell
        % data is read from that root's Force Measurements)
        data_roots;
        type_root_map;
        phase_case_map;   % selection label -> case files (stb_file_paths struct)
        source_modes; % data sets present, new flapper first
        source_mode;  % data set the case dropdowns list

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
        % which steady case to subtract: "ring", "body", "gliding" or "freestream"
        PIV_sub_case;
        force_sub;
        % boolean, with wingbeat frequency on the x-axis plot every load
        % cell frequency in range, not just those with flow field data
        all_lc_freqs_bool;
        % boolean, also plot every earlier repeat of each load cell case
        % (hollow markers); the series itself uses the latest repeat
        all_lc_repeats_bool;
        RPCA;
        % harmonic regression files (_hr, from bools.harmonic_reg)
        HR;
        % particle pool + harmonic regression files (HRPP_METHOD, from
        % bools.particle); replaces HR / RPCA, which are binned variants
        HRPP;
        % Difference: plot variable 1 minus variables 2 (and 3)
        diff_bool;
        % Sub First: subtract each curve's first point (lowest x, e.g. the
        % 0 Hz value) from all of its points, separately for every case
        sub_first_bool;
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
        % get_PIV_force). trim_bounds.unc_mask_mode picks "threshold" (mask
        % every such point) or "outer" (only outside the largest region
        % enclosed by the threshold contour, keeping vortex cores)
        unc_mask_bool;
        unc_mask_pct;
        % Live Calculate Crop Box: points inside [ymin ymax zmin zmax]
        % (y/L from the mirror centreline y_cen, z/L unshifted, as in
        % flowField_UI's Crop Box) are left out of the force integrals
        % together with the uncertainty mask (trim_bounds.crop_box, see
        % crop_box_region)
        crop_box_bool;
        crop_box;

        % ------- Available parameters user can select from -------
        available_selections;

        selection; % list of selected cases
        % wingbeat frequencies in the data and the [low high] range plotted
        % when the x-axis is wingbeat frequency
        available_freqs;
        freq_range;
        % same for the other x-axes: amplitudes (deg) plotted, and the
        % downstream positions plotted as [first last] indices into
        % dist_positions (positions of the current data set, in order of
        % distance; slider ticks are their names)
        amp_range;
        dist_range;
        dist_positions;
        sel_type;
        sel_freq;
        sel_amp;
        % downstream distance x-axis: the model, i.e. the case type without
        % its position prefix ("wings", "body", "NACA", "ring", ...), or "all"
        sel_model;
        % position prefix without "_" ("x3", "MPS", "UP_one"; "" = none,
        % e.g. the old flapper "flexible" plane), or "all"
        sel_position;

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
            % data_path: one data root, or several as a string array (e.g.
            % the new flapper data and the old flapper STB Round 1 folder)
            obj.data_roots = string(data_path(:))';
            obj.root_path = obj.data_roots(1);
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
                "Qx centroid y", "Qx centroid z",...
                "BA: lift vortX", "BA: lift vel diff", "BA: lift vel", "BA: drag vort", "BA: drag vel",...
                "lift vortY (edge)", "lift vortX (taper)",...
                "TA: lift vortX", "TA: lift vel diff", "TA: lift vel", "TA: drag vort", "TA: drag vel",...
                "lift vel (extrap)", "drag vel (extrap)", "lift vel (extrap fill)", "drag vel (extrap fill)",...
                "divergence",...
                "lift vortY (frozen flow)", "lift vortY (edge, frozen flow)"];
            obj.var_names = [obj.var_names, "lift_uavg.vortX", "drag_uavg.tot",...
                "wx_y", "wx_z", "Qx_y", "Qx_z",...
                "Qxcomp_y", "Qxcomp_z",... % Q_x (not Q) centroid
                "lift_before_avg.vortX", "lift_before_avg.vel_diff", "lift_vel_before_avg",...
                "drag_before_avg.tot", "drag_vel_before_avg",...
                "lift.vortY_edge", "lift.vortX_taper",...
                "lift_tavg.vortX", "lift_tavg.vel_diff", "lift_vel_tavg", "drag_tavg.tot", "drag_vel_tavg",...
                "lift_vel_B", "drag_vel_B", "lift_vel_B_fill", "drag_vel_B_fill",...
                "div_avg",... % planar average of du/dx + dv/dy + dw/dz
                "lift_ff.vortY", "lift_ff.vortY_edge"]; % omega_y from the frozen-flow d/dx
            obj.y_labels = [obj.y_labels, "Lift (N)", "Drag (N)",...
                "$\omega_x$ centroid $y/L$", "$\omega_x$ centroid $z/L$",...
                "Q centroid $y/L$", "Q centroid $z/L$",...
                "$Q_x$ centroid $y/L$", "$Q_x$ centroid $z/L$",...
                "Lift (N)", "Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)",...
                "Lift (N)", "Lift (N)",...
                "Lift (N)", "Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)",...
                "Lift (N)", "Drag (N)", "Lift (N)", "Drag (N)",...
                "$\overline{\nabla \cdot \mathbf{u}} \; c / U_{\infty}$",...
                "Lift (N)", "Lift (N)"];

            % Category of each variable, matching the Variable Type dropdown
            % (same groups as phaseAvg_UI)
            obj.var_categories = strings(size(obj.var_names));
            obj.var_categories(ismember(obj.var_names, ["lift_uavg.vortX", "drag_uavg.tot",...
                "lift.vortY_edge", "lift.vortX_taper"])) = "force";
            % omega_y lift with omega_y rebuilt from the frozen-flow
            % streamwise gradients, d/dx = (1/U) d/dt (lift_ff, saved by
            % calc_secondary_vals_common; get_PIV_force with _ff)
            obj.var_categories(ismember(obj.var_names, ["lift_ff.vortY", "lift_ff.vortY_edge"])) = "force";
            obj.var_categories(ismember(obj.var_names, ["lift.vortX", "lift.vortY", "lift.vel_diff",...
                "lift_vel", "drag.tot", "drag_vel"])) = "force";
            % velocity-only forces on the Helmholtz-extrapolated field
            % (_B: extrapolated velocity only, _B_fill: measured inside the
            % FOV). Stored in the _integral file, so always loaded, never
            % calculated live; 0 Hz cases read as 0 unless their time avg
            % was processed after the extrapolation was added for it.
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
            obj.all_lc_freqs_bool = false;
            obj.all_lc_repeats_bool = false;
            obj.RPCA = false;
            obj.HR = false;
            obj.HRPP = false;
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
            obj.sub_first_bool = false;
            obj.calc_bool = false;
            obj.conv_shift = false;
            obj.unwrap_shift = false;
            obj.trim_bounds = default_trim_bounds();
            if ~isfield(obj.trim_bounds, 'unc_mask_mode')
                obj.trim_bounds.unc_mask_mode = "threshold";
            end
            % uncertainty mask starts as the saved forces use it
            % (default_trim_bounds), so live and stored forces agree
            obj.unc_mask_bool = isfield(obj.trim_bounds, 'unc_mask') && obj.trim_bounds.unc_mask > 0;
            obj.unc_mask_pct = 4;
            if obj.unc_mask_bool
                obj.unc_mask_pct = 100 * obj.trim_bounds.unc_mask;
            end
            obj.set_unc_mask_bound();
            obj.crop_box_bool = false;
            obj.crop_box = [-1.4 1.4 -3.5 -1.2];
            obj.set_crop_box_bound();

            % Search through files in path to get types and speeds.
            % Phase averaged cases live in phase_avg\, the 0 Hz (gliding)
            % cases are time averaged and live in time_avg\.
            % (from every data root; each wing type remembers its root)
            obj.available_selections = cell(0, 3);
            obj.plain_steady_types = strings(0, 1);
            obj.type_root_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
            obj.phase_case_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for r = 1:numel(obj.data_roots)
                phase_dir = obj.data_roots(r) + "Processed Results\phase_avg\";
                time_dir = obj.data_roots(r) + "Processed Results\time_avg\";
                % phase averages: one case per <stem>_<method>_fields.mat
                % (+ _shared, _integral), found by its label
                cases = stb_list_phase_avg(phase_dir);
                for k = 1:numel(cases)
                    if ~isKey(obj.phase_case_map, char(cases(k).label))
                        obj.phase_case_map(char(cases(k).label)) = cases(k).files;
                    end
                end
                files = struct('name', cellstr(string({cases.label})'));
                contents_t = [];
                if isfolder(time_dir)
                    contents_t = dir(time_dir);
                    contents_t = contents_t(~[contents_t.isdir]);
                    % 0 Hz cases named like the flapping ones (plain-named
                    % steady cases are added below)
                    is_zero_hz = ~cellfun(@isempty, regexp({contents_t.name}, '_0Hz_time_avg\.mat$', 'once'));
                    zero_hz = contents_t(is_zero_hz);
                    files = [files; struct('name', {zero_hz.name}')]; %#ok<AGROW>
                end

                % Get amps, freqs, types from file names
                root_selections = cell(0, 3);
                if ~isempty(files)
                    root_selections = get_sel_from_file(files);
                end

                % Steady cases named without amplitude/frequency (e.g.
                % x3_NACA_time_avg.mat) are added as their own type with
                % amp = 0 and freq = 0
                if ~isempty(contents_t)
                    steady_names = string({contents_t.name});
                    steady_names = steady_names(endsWith(steady_names, "_time_avg.mat") &...
                                                ~contains(steady_names, "Hz"));
                    steady_types = unique(erase(steady_names, "_time_avg.mat")', 'stable');
                    obj.plain_steady_types = unique([obj.plain_steady_types; steady_types(:)], 'stable');
                    for k = 1:length(steady_types)
                        root_selections(end+1, :) = {steady_types(k), 0, 0}; %#ok<AGROW>
                    end
                end

                for k = 1:size(root_selections, 1)
                    key = char(string(root_selections{k, 1}));
                    if ~isKey(obj.type_root_map, key)
                        obj.type_root_map(key) = char(obj.data_roots(r));
                    end
                end
                obj.available_selections = [obj.available_selections; root_selections];
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
                error("No STB files found in Processed Results of %s. Expected *_<method>_fields.mat or *_time_avg.mat files.", strjoin(obj.data_roots, ", "))
            end

            % full frequency range to start (0 to 8 Hz for the current data)
            obj.available_freqs = unique(cell2mat(obj.available_selections(:, 3)))';
            obj.freq_range = [min(obj.available_freqs), max(obj.available_freqs)];

            obj.plot_curves = [];
            obj.selection = strings(0);

            obj.source_modes = obj.get_available_source_modes();
            obj.source_mode = obj.source_modes(1); % new flapper when present

            % label -> type for every type (both data sets)
            all_types = obj.get_ordered_type_options(unique(string(obj.available_selections(:, 1)), 'stable'));
            all_types = all_types(strlength(all_types) > 0);
            all_labels = strings(length(all_types), 1);
            for i = 1:length(all_types)
                all_labels(i) = obj.get_type_label(all_types(i));
            end
            [~, first_label] = unique(all_labels, 'stable');
            obj.distance_type_dict = containers.Map(cellstr(all_labels(first_label)), cellstr(all_types(first_label)));

            [selection_types, obj.distance_labels] = obj.get_available_type_options();
            obj.sel_type = selection_types(1);
            obj.sel_amp = obj.get_first_amp(obj.sel_type);
            obj.sel_freq = obj.get_first_freq(obj.sel_type, obj.sel_amp);
            obj.sel_model = "all";
            obj.sel_position = "all";
            obj.amp_range = [];
            obj.dist_range = [];
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

            sidebar_grid = uigridlayout(option_panel, [27, 1]);
            sidebar_grid.ColumnWidth = {'1x'};
            sidebar_grid.RowHeight = {30, 60, 30, 30, 30, 30, 30, 110, 30, 30, 30, 30, 30, 30, 30,...
                                      30, 25, 30, 30, 30, 30, 30, 30, 30, 30, 277, 30};
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

            % range of whichever variable is on the x-axis (frequency,
            % amplitude or downstream position), see setup_range_slider
            freq_slider = uislider(freq_grid, "range");
            freq_slider.Layout.Row = 2;
            freq_slider.Layout.Column = 1;
            freq_slider.MinorTicks = [];
            freq_slider.ValueChangedFcn = @(src, event) freq_range_change(src, event, freq_label, plot_panel);
            obj.setup_range_slider(freq_slider, freq_label);

            % Old/new flapper data set the case dropdowns below list
            source_dropdown = uidropdown(sidebar_grid);
            source_dropdown.Layout.Row = 3;
            source_dropdown.Layout.Column = 1;
            source_dropdown.Items = obj.source_modes;
            source_dropdown.Value = obj.source_mode;
            source_dropdown.Tooltip = "Data set the case dropdowns list (entries already added are kept)";

            % Dropdown boxes for the three variables held fixed while the
            % x-axis varies (get_fixed_variable_names): the model on its
            % own row, the other two side by side below it
            fixed_dropdown_1 = uidropdown(sidebar_grid);
            fixed_dropdown_1.Layout.Row = 4;
            fixed_dropdown_1.Layout.Column = 1;

            fixed_grid = uigridlayout(sidebar_grid, [1, 2]);
            fixed_grid.Layout.Row = 5;
            fixed_grid.Layout.Column = 1;
            fixed_grid.ColumnWidth = {'1x', '1x'};
            fixed_grid.RowHeight = {'1x'};
            fixed_grid.Padding = [0 0 0 0];
            fixed_grid.ColumnSpacing = 6;

            fixed_dropdown_2 = uidropdown(fixed_grid);
            fixed_dropdown_2.Layout.Row = 1;
            fixed_dropdown_2.Layout.Column = 1;

            fixed_dropdown_3 = uidropdown(fixed_grid);
            fixed_dropdown_3.Layout.Row = 1;
            fixed_dropdown_3.Layout.Column = 2;

            fixed_dropdowns = [fixed_dropdown_1, fixed_dropdown_2, fixed_dropdown_3];
            obj.reset_fixed_variable_defaults();
            obj.update_fixed_dropdowns(fixed_dropdowns);

            % RPCA, HR (harmonic regression) and HRPP (particle pool
            % harmonic regression) buttons share a row
            variant_grid = uigridlayout(sidebar_grid, [1, 3]);
            variant_grid.Layout.Row = 6;
            variant_grid.Layout.Column = 1;
            variant_grid.ColumnWidth = {'1x', '1x', '1x'};
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

            hrpp_button = uibutton(variant_grid, "state");
            hrpp_button.Layout.Row = 1;
            hrpp_button.Layout.Column = 3;
            hrpp_button.Text = "HRPP";
            hrpp_button.FontSize = 18;
            hrpp_button.Tooltip = "Particle pool harmonic regression files (_" + obj.HRPP_METHOD + ") for the flapping cases";
            hrpp_button.BackgroundColor = obj.get_button_color(obj.HRPP);
            hrpp_button.ValueChangedFcn = @(src, event) HRPP_change(src, event);

            % Button to add entry
            entry_button_grid = uigridlayout(sidebar_grid, [1, 2]);
            entry_button_grid.Layout.Row = 7;
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
            lbox.Layout.Row = 8;
            lbox.Layout.Column = 1;
            lbox.Items = strings(0);

            x_axis_dropdown.ValueChangedFcn = @(src, event) x_axis_change(src, event, fixed_dropdowns, plot_panel, lbox, freq_slider, freq_label);
            source_dropdown.ValueChangedFcn = @(src, event) source_change(src, event, fixed_dropdowns, freq_slider, freq_label);
            for k_fixed = 1:numel(fixed_dropdowns)
                fixed_dropdowns(k_fixed).ValueChangedFcn = @(src, event) fixed_change(src, event, k_fixed, fixed_dropdowns);
            end
            add_button.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
            delete_button.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

            clear_button = uibutton(sidebar_grid);
            clear_button.Layout.Row = 9;
            clear_button.Layout.Column = 1;
            clear_button.Text = "Clear Entries";
            clear_button.FontSize = 18;
            clear_button.BackgroundColor = [1 1 1];
            clear_button.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

            % Variable type filters the two variable dropdowns below
            var_type_dropdown = uidropdown(sidebar_grid);
            var_type_dropdown.Layout.Row = 10;
            var_type_dropdown.Layout.Column = 1;
            var_type_dropdown.Items = ["kinematics", "flow", "force", "BA: force", "TA: force", "load cell"];
            var_type_dropdown.Value = obj.var_type;

            % Dropdown boxes for variable selection
            force_var_dropdown_1 = uidropdown(sidebar_grid);
            force_var_dropdown_1.Layout.Row = 11;
            force_var_dropdown_1.Layout.Column = 1;
            force_var_dropdown_1.Items = obj.get_var_dropdown_items(obj.get_force_var_label(obj.force_var));
            force_var_dropdown_1.Value = obj.get_force_var_label(obj.force_var);

            force_var_dropdown_2 = uidropdown(sidebar_grid);
            force_var_dropdown_2.Layout.Row = 12;
            force_var_dropdown_2.Layout.Column = 1;
            force_var_dropdown_2.Items = obj.get_var_dropdown_items("none");
            force_var_dropdown_2.Value = "none";

            force_var_dropdown_3 = uidropdown(sidebar_grid);
            force_var_dropdown_3.Layout.Row = 13;
            force_var_dropdown_3.Layout.Column = 1;
            force_var_dropdown_3.Items = obj.get_var_dropdown_items("none");
            force_var_dropdown_3.Value = "none";
            var_dropdowns = [force_var_dropdown_1, force_var_dropdown_2, force_var_dropdown_3];
            var_type_dropdown.ValueChangedFcn = @(src, event) var_type_change(src, event, var_dropdowns);
            for var_dropdown = var_dropdowns
                var_dropdown.ValueChangedFcn = @(src, event) force_var_change(src, event, plot_panel, var_dropdowns);
            end

            operation_dropdown = uidropdown(sidebar_grid);
            operation_dropdown.Layout.Row = 14;
            operation_dropdown.Layout.Column = 1;
            operation_dropdown.Items = obj.operations;
            operation_dropdown.Tooltip = "shift: phase shift of variables 2 and 3 behind variable 1 for each case (cross-correlation of the phase-averaged signals); needs two or more variables";

            % Convection shift for the shift operation (as in phaseAvg_UI
            % and flowField_UI): STB signals are shifted by the convection
            % time from the robot to the imaging plane, kinematics are not
            shift_grid = uigridlayout(sidebar_grid, [1, 2]);
            shift_grid.Layout.Row = 15;
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
            piv_sub_button.Layout.Row = 16;
            piv_sub_button.Layout.Column = 1;
            piv_sub_button.Text = "PIV Body Sub";
            piv_sub_button.FontSize = 18;
            piv_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            piv_sub_button.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

            % Steady case used for the subtraction, matched to each
            % selection's downstream position (and amplitude for body/gliding)
            piv_sub_dropdown = uidropdown(sidebar_grid);
            piv_sub_dropdown.Layout.Row = 17;
            piv_sub_dropdown.Layout.Column = 1;
            piv_sub_dropdown.Items = ["ring", "body", "gliding", "freestream"];
            piv_sub_dropdown.Value = obj.PIV_sub_case;
            piv_sub_dropdown.Tooltip = "Steady case subtracted (e.g. for x3_wings_20deg_4Hz: ring = x3_ring, body = x3_body_20deg_0Hz, gliding = x3_wings_20deg_0Hz, freestream = freestream, the empty test section)";
            piv_sub_dropdown.ValueChangedFcn = @(src, event) PIV_sub_case_change(src, event, plot_panel);

            force_sub_button = uibutton(sidebar_grid, "state");
            force_sub_button.Layout.Row = 18;
            force_sub_button.Layout.Column = 1;
            force_sub_button.Text = "Force Body Sub";
            force_sub_button.FontSize = 18;
            force_sub_button.BackgroundColor = obj.COLOR_INACTIVE;
            force_sub_button.Tooltip = "Subtract the body load cell signal from the load cell forces / moment (load cell variables)";
            force_sub_button.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

            % Which load cell cases are plotted: frequencies without flow
            % field data (e.g. 0.1 Hz), and every repeat of each case
            lc_grid = uigridlayout(sidebar_grid, [1, 2]);
            lc_grid.Layout.Row = 19;
            lc_grid.Layout.Column = 1;
            lc_grid.Padding = [0 0 0 0];
            lc_grid.ColumnSpacing = 6;

            all_lc_button = uibutton(lc_grid, "state");
            all_lc_button.Layout.Row = 1;
            all_lc_button.Layout.Column = 1;
            all_lc_button.Text = "All LC Freqs";
            all_lc_button.FontSize = 16;
            all_lc_button.BackgroundColor = obj.COLOR_INACTIVE;
            all_lc_button.Tooltip = "Wingbeat frequency x-axis: plot load cell variables at every frequency in range with load cell data (latest repeat), including frequencies with no flow field case";
            all_lc_button.ValueChangedFcn = @(src, event) all_lc_freqs_change(src, event, plot_panel);

            all_repeats_button = uibutton(lc_grid, "state");
            all_repeats_button.Layout.Row = 1;
            all_repeats_button.Layout.Column = 2;
            all_repeats_button.Text = "All LC Repeats";
            all_repeats_button.FontSize = 16;
            all_repeats_button.BackgroundColor = obj.COLOR_INACTIVE;
            all_repeats_button.Tooltip = "Also plot every earlier repeat of each load cell case (same case measured at different times) as hollow markers; the series uses the latest repeat";
            all_repeats_button.ValueChangedFcn = @(src, event) all_lc_repeats_change(src, event, plot_panel);

            % Which processed load cell data the load cell variables read
            % (forces, voltage, current)
            load_cell_data_dropdown = uidropdown(sidebar_grid);
            load_cell_data_dropdown.Layout.Row = 20;
            load_cell_data_dropdown.Layout.Column = 1;
            load_cell_data_dropdown.Items = obj.load_cell_data_labels;
            load_cell_data_dropdown.Value = obj.load_cell_data_labels(obj.load_cell_data_vars == obj.load_cell_data_var);
            load_cell_data_dropdown.Tooltip = "Load cell data used for the load cell variables (phase-averaged version of the chosen filter for the shift operation)";
            load_cell_data_dropdown.Enable = "off";
            load_cell_data_dropdown.ValueChangedFcn = @(src, event) load_cell_data_change(src, event, plot_panel);

            x_norm_button = uibutton(sidebar_grid, "state");
            x_norm_button.Layout.Row = 21;
            x_norm_button.Layout.Column = 1;
            x_norm_button.Text = "Normalize X-axis";
            x_norm_button.FontSize = 18;
            x_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            x_norm_button.ValueChangedFcn = @(src, event) x_norm_change(src, event, plot_panel);

            y_norm_button = uibutton(sidebar_grid, "state");
            y_norm_button.Layout.Row = 22;
            y_norm_button.Layout.Column = 1;
            y_norm_button.Text = "Normalize Y-axis";
            y_norm_button.FontSize = 18;
            y_norm_button.BackgroundColor = obj.COLOR_INACTIVE;
            y_norm_button.ValueChangedFcn = @(src, event) y_norm_change(src, event, plot_panel);

            % Put the two selected variables on separate left/right y-axes
            separate_y_button = uibutton(sidebar_grid, "state");
            separate_y_button.Layout.Row = 23;
            separate_y_button.Layout.Column = 1;
            separate_y_button.Text = "Separate Y-Axis";
            separate_y_button.FontSize = 18;
            separate_y_button.BackgroundColor = obj.COLOR_INACTIVE;
            separate_y_button.ValueChangedFcn = @(src, event) separate_y_axis_change(src, event, plot_panel);

            % Difference and, next to it, Sub First
            diff_grid = uigridlayout(sidebar_grid, [1, 2]);
            diff_grid.Layout.Row = 24;
            diff_grid.Layout.Column = 1;
            diff_grid.ColumnWidth = {'1x', '1x'};
            diff_grid.RowHeight = {'1x'};
            diff_grid.Padding = [0 0 0 0];
            diff_grid.ColumnSpacing = 8;

            diff_button = uibutton(diff_grid, "state");
            diff_button.Layout.Row = 1;
            diff_button.Layout.Column = 1;
            diff_button.Text = "Difference";
            diff_button.FontSize = 18;
            diff_button.BackgroundColor = obj.COLOR_INACTIVE;
            diff_button.Tooltip = "Plot variable 1 minus variable 2 (and minus variable 3), e.g. lift vortX - lift (LC). Mean / range / rmse operations";
            diff_button.ValueChangedFcn = @(src, event) diff_change(src, event, plot_panel);

            sub_first_button = uibutton(diff_grid, "state");
            sub_first_button.Layout.Row = 1;
            sub_first_button.Layout.Column = 2;
            sub_first_button.Text = "Sub First";
            sub_first_button.FontSize = 18;
            sub_first_button.Value = obj.sub_first_bool;
            sub_first_button.BackgroundColor = obj.get_button_color(obj.sub_first_bool);
            sub_first_button.Tooltip = "Subtract each curve's first point (lowest x-axis value, e.g. 0 Hz) from all of its points, separately for every case and variable";
            sub_first_button.ValueChangedFcn = @(src, event) sub_first_change(src, event, plot_panel);

            calc_button = uibutton(sidebar_grid, "state");
            calc_button.Layout.Row = 25;
            calc_button.Layout.Column = 1;
            calc_button.Text = "Live Calculate";
            calc_button.FontSize = 18;
            calc_button.BackgroundColor = obj.COLOR_INACTIVE;

            % Trim limits and center point for Live Calculate,
            % nondimensional (divided by L)
            bounds_panel = uipanel(sidebar_grid);
            bounds_panel.Layout.Row = 26;
            bounds_panel.Layout.Column = 1;
            bounds_panel.Title = "Live Calc Bounds (y/L, z/L)";
            bounds_panel.TitlePosition = 'centertop';

            bounds_grid = uigridlayout(bounds_panel, [8, 3]);
            bounds_grid.ColumnWidth = {45, '1x', '1x'};
            bounds_grid.RowHeight = {25, 25, 25, 25, 25, 25, 25, 25};
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

            % How the threshold is applied (unc_mask_region)
            unc_mode_label = uilabel(bounds_grid);
            unc_mode_label.Layout.Row = 5;
            unc_mode_label.Layout.Column = 1;
            unc_mode_label.Text = "mode";

            unc_mode_dropdown = uidropdown(bounds_grid);
            unc_mode_dropdown.Layout.Row = 5;
            unc_mode_dropdown.Layout.Column = [2 3];
            unc_mode_dropdown.Items = ["All above threshold", "Outside largest contour"];
            unc_mode_dropdown.ItemsData = ["threshold", "outer"];
            unc_mode_dropdown.Value = obj.trim_bounds.unc_mask_mode;
            unc_mode_dropdown.Tooltip = "All above threshold: mask every point above the uncertainty threshold. " + ...
                "Outside largest contour: mask only what lies outside the largest region enclosed by the threshold contour, " + ...
                "so high-uncertainty vortex cores inside the plane stay in the integrals (static cases)";
            unc_mode_dropdown.ValueChangedFcn = @(src, event) unc_mask_mode_change(src, event, plot_panel);
            bounds_fields(end+1) = unc_mode_dropdown;

            % Crop Box: y and z limits of a region left out of the live
            % forces, merged with the uncertainty mask
            crop_rows = {"crop y", "y/L from the mirror centreline (y_cen)";
                         "crop z", "z/L, unshifted (as plotted in flowField_UI)"};
            crop_sides = ["lower", "upper"];
            crop_fields = gobjects(2, 2);
            for r = 1:2
                crop_label = uilabel(bounds_grid);
                crop_label.Layout.Row = 5 + r;
                crop_label.Layout.Column = 1;
                crop_label.Text = crop_rows{r, 1};
                for c = 1:2
                    crop_f = uieditfield(bounds_grid, 'numeric');
                    crop_f.Layout.Row = 5 + r;
                    crop_f.Layout.Column = c + 1;
                    crop_f.Value = obj.crop_box(2*(r - 1) + c);
                    crop_f.Tooltip = "Crop Box " + crop_sides(c) + " edge, " + crop_rows{r, 2};
                    crop_f.ValueChangedFcn = @(src, event) crop_box_value_change(src, event, plot_panel);
                    crop_fields(r, c) = crop_f;
                    bounds_fields(end+1) = crop_f; %#ok<AGROW>
                end
            end

            crop_button = uibutton(bounds_grid, "state");
            crop_button.Layout.Row = 8;
            crop_button.Layout.Column = [1 3];
            crop_button.Text = "Crop Box";
            crop_button.Value = obj.crop_box_bool;
            crop_button.BackgroundColor = obj.get_button_color(obj.crop_box_bool);
            crop_button.Tooltip = "Leave the y-z box above out of the live force integrals (treated as undisturbed freestream), " + ...
                "together with the uncertainty mask. Same box convention as flowField_UI's Crop Box";
            crop_button.ValueChangedFcn = @(src, event) crop_box_change(src, event, plot_panel);
            bounds_fields(end+1) = crop_button;

            set(bounds_fields, 'Enable', 'off'); % only used with Live Calculate
            calc_button.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel, bounds_fields);

            save_fig_button = uibutton(sidebar_grid);
            save_fig_button.Layout.Row = 27;
            save_fig_button.Layout.Column = 1;
            save_fig_button.Text = "Save Fig";
            save_fig_button.FontSize = 18;
            save_fig_button.BackgroundColor = [1 1 1];
            save_fig_button.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

            % Set up plot titles and axes
            obj.update_plot(plot_panel);

            % ===== Nested Callback Functions =====
            
            function x_axis_change(src, ~, fixed_dropdowns, plot_panel, lbox, freq_slider, freq_label)
                obj.x_axis_type = obj.get_x_axis_type(src.Value);
                obj.setup_range_slider(freq_slider, freq_label);
                obj.reset_fixed_variable_defaults();
                obj.update_fixed_dropdowns(fixed_dropdowns);
                obj.selection = strings(0);
                lbox.Items = strings(0);
                obj.update_plot(plot_panel);
            end

            % new data set: refill the case dropdowns from it. Entries
            % already in the list keep their own data set.
            function source_change(src, ~, fixed_dropdowns, freq_slider, freq_label)
                obj.source_mode = string(src.Value);
                [~, obj.distance_labels] = obj.get_available_type_options();
                % amplitudes / positions differ between the data sets
                obj.amp_range = [];
                obj.dist_range = [];
                obj.setup_range_slider(freq_slider, freq_label);
                obj.reset_fixed_variable_defaults();
                obj.update_fixed_dropdowns(fixed_dropdowns);
            end

            function freq_range_change(src, ~, freq_label, plot_panel)
                % snap both ends to the slider's values (measured
                % frequencies / amplitudes, or positions)
                vals = obj.get_range_slider_values();
                new_range = src.Value;
                for k = 1:2
                    [~, idx] = min(abs(vals - src.Value(k)));
                    new_range(k) = vals(idx);
                end
                new_range = sort(new_range);
                src.Value = new_range;
                obj.set_x_range(new_range);
                obj.update_range_label(freq_label);
                obj.update_plot(plot_panel);
            end

            % k-th fixed dropdown changed: refill the ones after it. Their
            % values are kept if the new choice has data at them;
            % update_fixed_dropdown falls back to the first available
            % option otherwise (ensure_selected_value)
            function fixed_change(src, ~, k, fixed_dropdowns)
                fixed_vars = obj.get_fixed_variable_names();
                obj.set_selected_value_from_item(fixed_vars(k), src.Value);
                for m = k + 1:numel(fixed_dropdowns)
                    obj.update_fixed_dropdown(fixed_dropdowns(m), fixed_vars(m));
                end
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

            % HRPP is a different method from the binned HR / RPCA
            % variants, so it can't be combined with them
            function RPCA_change(src, ~)
                obj.RPCA = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.RPCA);
                if obj.RPCA, set_HRPP(false); end
            end

            function HR_change(src, ~)
                obj.HR = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.HR);
                if obj.HR, set_HRPP(false); end
            end

            function HRPP_change(src, ~)
                set_HRPP(src.Value);
                if obj.HRPP
                    obj.HR = false;
                    hr_button.Value = false;
                    hr_button.BackgroundColor = obj.get_button_color(false);
                    obj.RPCA = false;
                    rpca_button.Value = false;
                    rpca_button.BackgroundColor = obj.get_button_color(false);
                end
            end

            function set_HRPP(value)
                obj.HRPP = value;
                hrpp_button.Value = value;
                hrpp_button.BackgroundColor = obj.get_button_color(value);
            end

            function force_sub_change(src, ~, plot_panel)
                obj.force_sub = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.force_sub);
                obj.update_plot(plot_panel);
            end

            function all_lc_freqs_change(src, ~, plot_panel)
                obj.all_lc_freqs_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.all_lc_freqs_bool);
                if any(obj.is_load_cell_var(obj.get_active_force_vars()))
                    obj.update_plot(plot_panel);
                end
            end

            function all_lc_repeats_change(src, ~, plot_panel)
                obj.all_lc_repeats_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.all_lc_repeats_bool);
                if any(obj.is_load_cell_var(obj.get_active_force_vars()))
                    obj.update_plot(plot_panel);
                end
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

            function sub_first_change(src, ~, plot_panel)
                obj.sub_first_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.sub_first_bool);
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
                    if obj.HRPP
                        selection_key = selection_key + "|HRPP=true";
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

            function crop_box_change(src, ~, plot_panel)
                obj.crop_box_bool = src.Value;
                src.BackgroundColor = obj.get_button_color(obj.crop_box_bool);
                obj.set_crop_box_bound();
                if obj.calc_bool
                    obj.update_plot(plot_panel);
                end
            end

            function crop_box_value_change(~, ~, plot_panel)
                b = [crop_fields(1,1).Value, crop_fields(1,2).Value, ...
                     crop_fields(2,1).Value, crop_fields(2,2).Value];
                if b(1) >= b(2) || b(3) >= b(4)
                    % lower must be below upper: undo
                    for r = 1:2
                        for c = 1:2
                            crop_fields(r, c).Value = obj.crop_box(2*(r - 1) + c);
                        end
                    end
                    return
                end
                obj.crop_box = b;
                obj.set_crop_box_bound();
                if obj.calc_bool && obj.crop_box_bool
                    obj.update_plot(plot_panel);
                end
            end

            function unc_mask_mode_change(src, ~, plot_panel)
                obj.trim_bounds.unc_mask_mode = string(src.Value);
                if obj.calc_bool && obj.unc_mask_bool
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
            available_types = available_types(obj.get_source_mask(available_types, obj.source_mode));
            selection_types = obj.get_ordered_type_options(available_types);
            selection_labels = strings(length(selection_types), 1);

            for i = 1:length(selection_types)
                selection_labels(i) = obj.get_type_label(selection_types(i));
            end
        end

        function amps = get_amp_options(obj, selected_type)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            amps = unique(selection_amps(selection_types == string(selected_type) &...
                obj.get_source_mask(selection_types, obj.source_mode)));
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
                % the model (case type without its position: wings, body,
                % NACA, ...) first, so e.g. NACA isn't mixed with the other
                % 0 deg, 0 Hz cases; then the two variables not on the x-axis
                case "wingbeat frequency"
                    fixed_vars = ["model", "position", "amp"];
                case "wingbeat amplitude"
                    fixed_vars = ["model", "position", "freq"];
                case "downstream distance"
                    fixed_vars = ["model", "amp", "freq"];
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
                case "model"
                    obj.sel_model = string(options(1));
                case "position"
                    obj.sel_position = string(options(1));
                case "case"
                    obj.sel_amp = options(1, 1);
                    obj.sel_freq = options(1, 2);
            end
        end

        function update_fixed_dropdowns(obj, dropdowns)
            fixed_vars = obj.get_fixed_variable_names();
            for k = 1:numel(dropdowns)
                obj.update_fixed_dropdown(dropdowns(k), fixed_vars(k));
            end
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
                case "model"
                    obj.ensure_selected_value(variable_name, options);
                    dropdown.Items = [strrep(string(options(:)), "_", " "); "all"];
                    if obj.sel_model == "all"
                        dropdown.Value = "all";
                    else
                        dropdown.Value = strrep(obj.sel_model, "_", " ");
                    end
                case "position"
                    obj.ensure_selected_value(variable_name, options);
                    dropdown.Items = [obj.position_label(options(:)); "all"];
                    if obj.sel_position == "all"
                        dropdown.Value = "all";
                    else
                        dropdown.Value = obj.position_label(obj.sel_position);
                    end
                case "case"
                    obj.ensure_selected_value(variable_name, options);
                    dropdown.Items = [obj.case_label(options(:, 1), options(:, 2)); "all"];
                    if obj.sel_amp == -1
                        dropdown.Value = "all";
                    else
                        dropdown.Value = obj.case_label(obj.sel_amp, obj.sel_freq);
                    end
            end
        end

        % "20 deg, 4 Hz" for each amplitude / frequency pair (column)
        function labels = case_label(~, amps, freqs)
            labels = string(amps(:)) + " deg, " + string(freqs(:)) + " Hz";
        end

        function ensure_selected_value(obj, variable_name, options)
            selected_value = obj.get_selected_value(variable_name);
            if obj.is_all_value(variable_name, selected_value)
                return
            end

            if variable_name == "case"
                is_option = ~isempty(selected_value) && ismember(selected_value, options, 'rows');
            else
                is_option = ~isempty(selected_value) && ismember(selected_value, options);
            end
            if ~is_option
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
                case "model"
                    selected_value = obj.sel_model;
                case "position"
                    selected_value = obj.sel_position;
                case "case"
                    selected_value = [obj.sel_amp, obj.sel_freq];
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
                case "model"
                    if string(item) == "all"
                        obj.sel_model = "all";
                    else
                        % dropdown shows "_" as spaces
                        models = obj.get_fixed_variable_options("model");
                        k = find(strrep(models, "_", " ") == string(item), 1);
                        obj.sel_model = models(k);
                    end
                case "position"
                    if string(item) == "all"
                        obj.sel_position = "all";
                    else
                        positions = obj.get_fixed_variable_options("position");
                        k = find(obj.position_label(positions) == string(item), 1);
                        obj.sel_position = positions(k);
                    end
                case "case"
                    if string(item) == "all"
                        obj.sel_amp = -1;
                        obj.sel_freq = -1;
                    else
                        tok = regexp(char(item), '^(\S+) deg, (\S+) Hz$', 'tokens', 'once');
                        obj.sel_amp = str2double(tok{1});
                        obj.sel_freq = str2double(tok{2});
                    end
            end
        end

        function options = get_fixed_variable_options(obj, variable_name)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));
            mask = obj.get_source_mask(selection_types, obj.source_mode);

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
                case "model"
                    % downstream distance: only models measured at a known
                    % distance (not freestream)
                    if obj.x_axis_type == "downstream distance"
                        mask = mask & arrayfun(@(t) isfinite(obj.get_downstream_distance(t)), selection_types);
                    end
                    options = unique(obj.get_model(selection_types(mask)), 'stable');
                case "position"
                    % in order of distance (no known distance last)
                    options = unique(obj.get_position(selection_types(mask)), 'stable');
                    dists = arrayfun(@(p) obj.position_distance(p), options);
                    dists(~isfinite(dists)) = Inf;
                    [~, order] = sort(dists);
                    options = options(order);
                case "case"
                    options = unique([selection_amps(mask), selection_freqs(mask)], 'rows');
            end
        end

        % Measurement position of a case type, the prefix without "_":
        % "x3_NACA" -> "x3", "UP_one_flexible" -> "UP_one", "flexible" or
        % "freestream" -> "" (none)
        function positions = get_position(~, types)
            types = string(types);
            positions = strings(size(types));
            for i = 1:numel(types)
                positions(i) = erase(get_downstream_prefix(types(i), true), "_");
            end
        end

        % Case type from its position and model (inverse of get_position /
        % get_model)
        function type = build_type(~, position, model)
            if strlength(position) == 0
                type = string(model);
            else
                type = string(position) + "_" + model;
            end
        end

        % Dropdown / slider name of a position: new flapper as is ("x3");
        % old flapper as its distance label (flexible, UP_one, UP_two ->
        % "x = 0.9m", ...); "none" for no position in the new data set
        function labels = position_label(obj, positions)
            positions = string(positions);
            labels = positions;
            old_positions = ["", "UP_one", "UP_two"];
            for i = 1:numel(positions)
                k = find(old_positions == positions(i), 1);
                if obj.source_mode == obj.OLD_FLAPPER_SOURCE_MODE && ~isempty(k)
                    labels(i) = obj.downstream_distance_labels(k);
                elseif strlength(positions(i)) == 0
                    labels(i) = "none";
                end
            end
        end

        % Distance (m) of a position in the current data set, as
        % get_downstream_distance; NaN if none (e.g. freestream)
        function dist = position_distance(obj, position)
            position = string(position);
            dist = NaN;
            old_positions = ["", "UP_one", "UP_two"];
            k = find(old_positions == position, 1);
            if obj.source_mode == obj.OLD_FLAPPER_SOURCE_MODE && ~isempty(k)
                dist = obj.downstream_distances(k);
            elseif strlength(position) > 0 && position ~= "UP_one" && position ~= "UP_two"
                dist = obj.get_robot_to_plane_dist(position + "_x");
            end
        end

        % Case type without its measurement position prefix: "x3_NACA" ->
        % "NACA", "UP_one_flexible" -> "flexible", "flexible" -> "flexible"
        function models = get_model(~, types)
            types = string(types);
            models = types;
            for i = 1:numel(types)
                prefix = get_downstream_prefix(types(i), true);
                if strlength(prefix) > 0
                    models(i) = extractAfter(types(i), strlength(prefix));
                end
            end
        end

        function mask = get_variable_mask(obj, selection_types, selection_amps, selection_freqs, variable_name, value)
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
                case "model"
                    if string(value) == "all"
                        mask = true(size(selection_types));
                    else
                        mask = obj.get_model(selection_types) == string(value);
                    end
                case "position"
                    if string(value) == "all"
                        mask = true(size(selection_types));
                    else
                        mask = obj.get_position(selection_types) == string(value);
                    end
                case "case"
                    if value(1) == -1
                        mask = true(size(selection_amps));
                    else
                        mask = selection_amps == value(1) & selection_freqs == value(2);
                    end
            end
        end

        function all_value = is_all_value(~, variable_name, value)
            switch variable_name
                case "type"
                    all_value = string(value) == "all";
                case {"amp", "freq"}
                    all_value = value == -1;
                case {"model", "position"}
                    all_value = string(value) == "all";
                case "case"
                    all_value = value(1) == -1;
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
            mask = obj.get_source_mask(selection_types, obj.source_mode);

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
                            part = "type=" + selection_types(cur_idx);
                        case "amp"
                            part = "amp=" + string(selection_amps(cur_idx));
                        case "freq"
                            part = "freq=" + string(selection_freqs(cur_idx));
                        case "model"
                            part = "model=" + obj.get_model(selection_types(cur_idx));
                        case "position"
                            part = "position=" + obj.get_position(selection_types(cur_idx));
                        case "case"
                            part = "amp=" + string(selection_amps(cur_idx)) + ...
                                "|freq=" + string(selection_freqs(cur_idx));
                    end

                    selection_key = selection_key + "|" + part;
                end
                selection_key = selection_key + "|source=" + obj.source_mode;

                if sum(strcmp(selection_keys, selection_key)) == 0
                    selection_keys(end + 1) = selection_key;
                end
            end
        end

        function info = decode_selection(obj, selection_key)
            parts = split(string(selection_key), "|");
            info = struct("x_axis_type", parts(1), "type", "", "model", "", "position", "", "amp", NaN, "freq", NaN, "RPCA", false, "HR", false, "HRPP", false, "source", "");
            has_position = false;

            for i = 2:length(parts)
                variable_name = extractBefore(parts(i), "=");
                value = extractAfter(parts(i), "=");
                switch variable_name
                    case "type"
                        info.type = value;
                    case "model"
                        info.model = value;
                    case "position"
                        info.position = value;
                        has_position = true;
                    case "amp"
                        info.amp = str2double(value);
                    case "freq"
                        info.freq = str2double(value);
                    case "RPCA"
                        info.RPCA = string(value) == "true";
                    case "HR"
                        info.HR = string(value) == "true";
                    case "HRPP"
                        info.HRPP = string(value) == "true";
                    case "source"
                        info.source = string(value);
                end
            end
            % model + position entries (frequency / amplitude x-axis): the
            % case type the rest of the code uses
            if strlength(info.model) > 0 && has_position
                info.type = obj.build_type(info.position, info.model);
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
                    label = "Distance | " + obj.model_label(info) + info.amp + " deg | " + info.freq + " Hz";
            end

            if info.source == obj.OLD_FLAPPER_SOURCE_MODE
                label = label + " | old flapper";
            end

            if info.HR
                label = label + " | HR";
            end
            if info.RPCA
                label = label + " | RPCA";
            end
            if info.HRPP
                label = label + " | HRPP";
            end
        end

        function points = get_selection_points(obj, info)
            selection_types = string(obj.available_selections(:, 1));
            selection_amps = cell2mat(obj.available_selections(:, 2));
            selection_freqs = cell2mat(obj.available_selections(:, 3));
            % only cases from the entry's data set
            if strlength(info.source) > 0
                keep = obj.get_source_mask(selection_types, info.source);
                selection_types = selection_types(keep);
                selection_amps = selection_amps(keep);
                selection_freqs = selection_freqs(keep);
            end

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
                    % amplitudes inside the slider range
                    r = obj.get_x_range("wingbeat amplitude");
                    if ~isempty(r)
                        amps = amps(amps >= r(1) - 1e-9 & amps <= r(2) + 1e-9);
                    end
                    points.types = repmat(info.type, 1, length(amps));
                    points.amps = amps(:)';
                    points.freqs = repmat(info.freq, 1, length(amps));
                    points.x_values = points.amps;
                case "downstream distance"
                    mask = selection_amps == info.amp & selection_freqs == info.freq;
                    if strlength(info.model) > 0 % entries from before the model filter: every model
                        mask = mask & obj.get_model(selection_types) == info.model;
                    end
                    types = obj.get_ordered_type_options(selection_types(mask));
                    x_values = NaN(size(types));
                    for i = 1:length(types)
                        x_values(i) = obj.get_downstream_distance(types(i));
                    end
                    % positions inside the slider range
                    r = obj.get_x_range("downstream distance");
                    if ~isempty(r)
                        pos_idx = arrayfun(@(t) obj.position_index(t), types);
                        x_values(~(pos_idx >= r(1) & pos_idx <= r(2))) = NaN;
                    end
                    valid_indices = find(isfinite(x_values));
                    % in order of distance, so the curve runs downstream
                    [~, order] = sort(x_values(valid_indices));
                    valid_indices = valid_indices(order);
                    points.types = reshape(types(valid_indices), 1, []);
                    points.amps = repmat(info.amp, 1, numel(valid_indices));
                    points.freqs = repmat(info.freq, 1, numel(valid_indices));
                    points.x_values = reshape(x_values(valid_indices), 1, []);
            end
        end

        % Data sets present among the cases, new flapper first (default)
        function source_modes = get_available_source_modes(obj)
            types = string(obj.available_selections(:, 1));
            types = types(strlength(types) > 0);
            source_modes = strings(0, 1);
            if any(obj.is_new_flapper_type(types))
                source_modes(end + 1, 1) = obj.NEW_FLAPPER_SOURCE_MODE;
            end
            if any(~obj.is_new_flapper_type(types))
                source_modes(end + 1, 1) = obj.OLD_FLAPPER_SOURCE_MODE;
            end
        end

        function mask = is_new_flapper_type(obj, types)
            types = string(types);
            % position-independent cases (freestream) belong to the new set
            mask = ismember(types, position_independent_cases());
            for i = 1:length(obj.new_flapper_downstream_types)
                prefix = obj.new_flapper_downstream_types(i);
                mask = mask | types == prefix | startsWith(types, prefix + "_");
            end
        end

        function mask = get_source_mask(obj, types, source_mode)
            if string(source_mode) == obj.NEW_FLAPPER_SOURCE_MODE
                mask = obj.is_new_flapper_type(types);
            else
                mask = ~obj.is_new_flapper_type(types);
            end
        end

        % "NACA, " (model, "_" as spaces) for labels, "" if no model
        function label = model_label(~, info)
            label = "";
            if strlength(info.model) > 0
                label = strrep(info.model, "_", " ") + ", ";
            end
        end

        % Downstream distance (m) of a case's imaging plane: the old
        % flapper positions (no prefix, UP_one, UP_two) as before, the new flapper ones
        % (x1-x5, MPS) from plane_downstream_dists (robot to plane). NaN
        % for anything else (e.g. freestream, which has no position).
        function distance = get_downstream_distance(obj, type)
            type = string(type);
            distance = NaN;
            if contains(type, "turbine")
                return
            end
            position = obj.get_position(type);
            if obj.is_new_flapper_type(type)
                if strlength(position) > 0
                    distance = obj.get_robot_to_plane_dist(type);
                end
            else
                % old flapper: no prefix, UP_one, UP_two
                k = find(["", "UP_one", "UP_two"] == position, 1);
                if ~isempty(k)
                    distance = obj.downstream_distances(k);
                end
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
                    label = obj.model_label(info) + info.amp + " deg, " + info.freq + " Hz";
            end

            if info.HR
                label = label + " - HR";
            end
            if info.RPCA
                label = label + " - RPCA";
            end
            if info.HRPP
                label = label + " - HRPP";
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

        % "All LC Repeats": the reduced value (mean / range / ...) of every
        % repeat of a load cell case except the latest, which the series
        % itself uses. Force Body Sub uses the latest body case for all.
        function vals = get_load_cell_repeat_values(obj, force_var, type, amp, freq)
            stamps = get_force_timestamps(obj.get_force_path(type), type, amp, freq);
            stamps = stamps(1:end-1); % drop the latest
            vals = NaN(1, length(stamps));
            for k = 1:length(stamps)
                var = obj.get_load_cell_signal(force_var, type, amp, freq, false, stamps(k));
                vals(k) = obj.reduce_signal(var);
            end
            vals = vals(isfinite(vals));
        end

        % "All LC Freqs": add the frequencies in range that have processed
        % load cell data for the selection's type and amplitude but no flow
        % field case. They are flagged in points.lc_only.
        function points = add_load_cell_only_points(obj, points, info)
            lc_freqs = get_force_freqs(obj.get_force_path(info.type), info.type, info.amp);
            in_range = lc_freqs >= obj.freq_range(1) - 1e-9 & lc_freqs <= obj.freq_range(2) + 1e-9;
            lc_freqs = lc_freqs(in_range);
            % compare with a tolerance (e.g. 0.1 stored as 0.1000000001)
            is_new = arrayfun(@(f) ~any(abs(points.freqs - f) < 1e-6), lc_freqs);
            new_freqs = lc_freqs(is_new);
            if isempty(new_freqs)
                return
            end
            disp("Load cell only frequencies for " + info.type + ", " + info.amp + " deg: " +...
                strjoin(string(new_freqs), ", ") + " Hz")
            n = length(new_freqs);
            points.types = [points.types, repmat(info.type, 1, n)];
            points.amps = [points.amps, repmat(info.amp, 1, n)];
            points.freqs = [points.freqs, new_freqs];
            points.x_values = [points.x_values, new_freqs];
            points.lc_only = [points.lc_only, true(1, n)];
        end

        function U = get_nominal_speed(~, case_files)
            % nominal freestream speed the STB "pitot U" (U_act) is
            % normalised by; 4 m/s unless the case's files say otherwise
            U = 4;
            if stb_has_var(case_files, "U")
                d = stb_load(case_files, "U");
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
            % one hue per case, shades of it for the variables (see
            % get_series_color)
            curve_colors = obj.get_series_colors(num_sel, num_vars);

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
            % "All LC Repeats": earlier repeats of each load cell point
            rep_values = cell(num_vars, num_sel);
            rep_x_vals = cell(num_vars, num_sel);

            for var_idx = 1:num_vars % Loop through each selected variable
                force_var = selected_force_vars(var_idx);
                % The load cell is measured at one position, so selections
                % that differ only in downstream position (or RPCA / HR / HRPP) share
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
                points.lc_only = false(1, length(points.freqs));
                % "All LC Freqs": add load cell frequencies with no flow
                % field case (difference mode needs matching points)
                if obj.is_load_cell_var(force_var) && obj.all_lc_freqs_bool &&...
                        ~diff_plot && info.x_axis_type == "wingbeat frequency"
                    points = obj.add_load_cell_only_points(points, info);
                end
                num_points = length(points.freqs);

                if num_points == 0
                    continue
                end

                vals = NaN(1, num_points);
                errs = zeros(1, num_points);
                % earlier repeats: point index and value of each
                show_repeats = obj.is_load_cell_var(force_var) && obj.all_lc_repeats_bool && ~diff_plot;
                rep_j = zeros(1, 0);
                rep_v = zeros(1, 0);
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

                    if points.lc_only(j)
                        % no flow field case: nominal frequency, and the
                        % tunnel speed saved with the load cell data
                        measured_freqs(j) = freq;
                        if obj.x_norm && freq > 0
                            wind_speed_acts(j) = obj.get_load_cell_signal("LC_U", type, amp, freq, false) *...
                                obj.get_nominal_speed("");
                        end
                        var = obj.get_load_cell_signal(force_var, type, amp, freq, false);
                        vals(j) = obj.reduce_signal(var);
                        if show_repeats
                            v = obj.get_load_cell_repeat_values(force_var, type, amp, freq);
                            rep_j = [rep_j, repmat(j, 1, length(v))];
                            rep_v = [rep_v, v];
                        end
                        disp(j + " of " + num_points + " complete (load cell only)")
                        continue
                    end

                    name = obj.get_case_name(type, amp, freq);
                    % RPCA, HR and HRPP only apply to phase averaged cases
                    if freq ~= 0
                        name = obj.add_variant_suffix(name, info);
                    end
                    if freq == 0
                        suffix = "_time_avg";
                    else
                        suffix = "_phase_avg";
                    end
                    case_files = obj.get_case(name, suffix);

                    if freq == 0
                        avg_type = 0;
                        measured_freqs(j) = 0;
                        errs(j) = 0;
                    else
                        avg_type = 1;
                        d = stb_load(case_files, "U", "L", "U_act", "rho_act", "freq_avg");
                        F = d;
                        measured_freqs(j) = mean(F.freq_avg);
                        wind_speed = d.U;
                        density = d.rho_act;
                        area = d.L * d.L * 3 * 2;
                        wind_speed_acts(j) = d.U_act * d.U;
                    end
                    is_live = false;

                    if obj.is_load_cell_var(force_var)
                        var = obj.get_load_cell_signal(force_var, type, amp, freq, false);
                    elseif obj.is_live_Q_centroid(force_var, case_files)
                        % Q / Q_x centroid with the Live Calc bounds and
                        % uncertainty mask (get_Q_centroid)
                        var = get_Q_centroid(case_files, case_files, force_var, obj.get_Q_centroid_bounds());
                        if obj.PIV_sub
                            bod_case = obj.get_PIV_sub_case(type, amp);
                            var = var - get_Q_centroid(bod_case, bod_case, force_var, obj.get_Q_centroid_bounds());
                        end
                    elseif (obj.calc_bool && obj.is_piv_force_variable(force_var)) || obj.is_tavg_force_var(force_var) ||...
                            obj.needs_live_ff(force_var, case_files)
                        [var, err] = get_PIV_force(case_files, name, force_var, avg_type, obj.y_norm, obj.trim_bounds);
                        is_live = true;

                        if obj.PIV_sub
                            bod_case = obj.get_PIV_sub_case(type, amp);
                            [bod_var, ~] = get_PIV_force(bod_case, "", force_var, 0, obj.y_norm, obj.trim_bounds);
                            var = var - bod_var;
                        end
                    else
                        % variables not defined for a case (e.g.
                        % lift.vortY for a 0 Hz mean flow field) are
                        % replaced with zero
                        % look in the expected file first, then the other
                        var_files = obj.get_stored_var_files(force_var, case_files);
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
                            bod_case = obj.get_PIV_sub_case(type, amp);
                            bod_var = obj.load_stored_var(stb_case_files(bod_case, "integral"), force_var);
                            var = var - bod_var;
                        end
                    end

                    % Calculate mean force and store in array for plotting
                    vals(j) = obj.reduce_signal(var);

                    % Error bar: standard error of the plotted mean (random
                    % uncertainty only; see get_mean_se)
                    if ~obj.is_load_cell_var(force_var)
                        se = obj.get_mean_se(force_var, case_files, freq, name);
                        if is_live && obj.y_norm
                            se = se / obj.get_force_norm_factor(case_files, freq);
                        end
                        if obj.PIV_sub && se > 0
                            % difference of two independent means: their
                            % variances add
                            bod_case = obj.get_PIV_sub_case(type, amp);
                            bod_se = obj.get_mean_se(force_var, bod_case, 0, "PIV sub case");
                            if is_live && obj.y_norm
                                bod_se = bod_se / obj.get_force_norm_factor(bod_case, 0);
                            end
                            se = hypot(se, bod_se);
                        end
                        errs(j) = se;
                    end
                    if show_repeats
                        v = obj.get_load_cell_repeat_values(force_var, type, amp, freq);
                        rep_j = [rep_j, repmat(j, 1, length(v))];
                        rep_v = [rep_v, v];
                    end
                    disp(j + " of " + num_points + " complete")
                end

                if obj.is_load_cell_var(force_var)
                    errs(:) = 0; % no load cell error bars yet
                end

                if info.x_axis_type == "wingbeat frequency" && obj.x_norm
                    missing_wind_indices = find(~isfinite(wind_speed_acts) & points.freqs > 0 & ~points.lc_only);
                    for k = missing_wind_indices
                        type = points.types(k);
                        amp = points.amps(k);
                        freq = points.freqs(k);
                        name = obj.get_case_name(type, amp, freq);
                        d = stb_load(obj.get_case(name, "_phase_avg"), "U", "U_act");
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
                if show_repeats && ~isempty(rep_j)
                    % same x as their point (rep_j indexes the points
                    % before x_var was reduced to the kept ones; repeats
                    % only exist for kept points)
                    kept_pos = cumsum(keep);
                    rep_x_vals{var_idx, target} = [rep_x_vals{var_idx, target}, x_var(kept_pos(rep_j))];
                    rep_values{var_idx, target} = [rep_values{var_idx, target}, rep_v];
                end
                x_all = [x_vals{var_idx, target}, x_var(:)'];
                v_all = [values{var_idx, target}, vals(:)'];
                e_all = [errors{var_idx, target}, errs(:)'];
                [x_vals{var_idx, target}, order] = sort(x_all);
                values{var_idx, target} = v_all(order);
                errors{var_idx, target} = e_all(order);
            end
            end

            % Sub First: each series (variable and case) minus its first
            % point, the one at the lowest x (e.g. 0 Hz). Its error bar
            % adds to the others' (difference of independent means) and
            % the reference point itself becomes 0 +/- 0. The earlier load
            % cell repeats are shifted by the same value.
            if obj.sub_first_bool
                for var_idx = 1:num_vars
                    for i = 1:num_sel
                        v = values{var_idx, i};
                        k0 = find(isfinite(v), 1);
                        if isempty(k0)
                            continue
                        end
                        v0 = v(k0);
                        e = errors{var_idx, i};
                        e0 = e(k0);
                        values{var_idx, i} = v - v0;
                        if isfinite(e0) && e0 > 0
                            e = hypot(e, e0);
                        end
                        e(k0) = 0;
                        errors{var_idx, i} = e;
                        if ~isempty(rep_values{var_idx, i})
                            rep_values{var_idx, i} = rep_values{var_idx, i} - v0;
                        end
                        fprintf("Sub First: %s, %s minus %.4g (point at x = %g)\n", ...
                            obj.get_selection_label(obj.selection(i)), selected_force_vars(var_idx), ...
                            v0, x_vals{var_idx, i}(k0));
                    end
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
                        color = curve_colors{i, k};
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
                    original_color = curve_colors{i, var_idx};
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

                    % "All LC Repeats": earlier repeats as hollow markers
                    if ~isempty(rep_values{var_idx, i})
                        s2 = plot(ax, rep_x_vals{var_idx, i}, rep_values{var_idx, i}, char(variable_marker),...
                            LineStyle="none", MarkerSize=8, Color=original_color, MarkerFaceColor="none");
                        s2.DisplayName = s1.DisplayName + " (earlier repeats)";
                    end
                end
            end
            end

            % Sub First: say so on the y-axis label(s)
            if obj.sub_first_bool && num_vars > 0
                for k = 1:numel(ax.YAxis)
                    if strlength(string(ax.YAxis(k).Label.String)) > 0
                        ax.YAxis(k).Label.String = string(ax.YAxis(k).Label.String) + " (minus first point)";
                    end
                end
            end

            if (obj.saveFig)
                obj.save_hidden_figure(fignew);
            end
        end

        % Colour of each series, {case, variable}. Several cases: each case
        % gets a ColorBrewer sequential palette (Blues, Oranges, Greens,
        % Purples, Reds, Greys; colorbrewer2.org, 9 classes; repeating
        % after six cases) and its variables take well separated levels of
        % it, darkest for variable 1, so the cases are told apart by hue
        % and the variables of a case by lightness (and marker). One case:
        % a distinct colour per variable.
        function colors = get_series_colors(~, num_sel, num_vars)
            num_sel = max(1, num_sel);
            num_vars = max(1, num_vars);
            colors = cell(num_sel, num_vars);
            if num_sel == 1
                c = lines(num_vars);
                for k = 1:num_vars
                    colors{1, k} = c(k, :);
                end
                return
            end
            palettes = { ...
                ["#f7fbff" "#deebf7" "#c6dbef" "#9ecae1" "#6baed6" "#4292c6" "#2171b5" "#08519c" "#08306b"], ... % Blues
                ["#fff5eb" "#fee6ce" "#fdd0a2" "#fdae6b" "#fd8d3c" "#f16913" "#d94801" "#a63603" "#7f2704"], ... % Oranges
                ["#f7fcf5" "#e5f5e0" "#c7e9c0" "#a1d99b" "#74c476" "#41ab5d" "#238b45" "#006d2c" "#00441b"], ... % Greens
                ["#fcfbfd" "#efedf5" "#dadaeb" "#bcbddc" "#9e9ac8" "#807dba" "#6a51a3" "#54278f" "#3f007d"], ... % Purples
                ["#fff5f0" "#fee0d2" "#fcbba1" "#fc9272" "#fb6a4a" "#ef3b2c" "#cb181d" "#a50f15" "#67000d"], ... % Reds
                ["#ffffff" "#f0f0f0" "#d9d9d9" "#bdbdbd" "#969696" "#737373" "#525252" "#252525" "#000000"]};   % Greys
            % levels used, darkest first: one variable -> level 7; more ->
            % spread from 8 to 4 (levels 1-3 are too light on white)
            if num_vars == 1
                levels = 7;
            else
                levels = round(linspace(8, 4, num_vars));
            end
            hex2rgb = @(h) double(sscanf(char(extractAfter(h, 1)), '%2x', [1 3])) / 255;
            for i = 1:num_sel
                pal = palettes{mod(i - 1, numel(palettes)) + 1};
                for k = 1:num_vars
                    colors{i, k} = hex2rgb(pal(levels(k)));
                end
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
                            obj.get_phase_avg_signal(force_vars(k), type, amp, freq, info);
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
        % (info: the selection, for its HR / RPCA / HRPP variant)
        function [var, measured_freq, wind_speed_act] = get_phase_avg_signal(obj, force_var, type, amp, freq, info)
            name = obj.get_case_name(type, amp, freq);
            name = obj.add_variant_suffix(name, info);
            suffix = "_phase_avg";
            case_files = obj.get_case(name, suffix);

            d = stb_load(case_files, "U", "U_act", "freq_avg");
            F = d;
            measured_freq = mean(F.freq_avg);
            wind_speed_act = d.U_act * d.U;

            if obj.is_load_cell_var(force_var)
                % phase-averaged load cell signal, measured at the robot
                var = obj.get_load_cell_signal(force_var, type, amp, freq, true);
                var = double(var(:)');
                return
            elseif obj.is_live_Q_centroid(force_var, case_files)
                var = get_Q_centroid(case_files, case_files, force_var, obj.get_Q_centroid_bounds());
            elseif (obj.calc_bool && obj.is_piv_force_variable(force_var)) || obj.is_tavg_force_var(force_var) ||...
                    obj.needs_live_ff(force_var, case_files)
                var = get_PIV_force(case_files, name, force_var, 1, obj.y_norm, obj.trim_bounds);
            else
                var_files = obj.get_stored_var_files(force_var, case_files);
                var = obj.load_stored_var(var_files, force_var);
                if ismember(force_var, ["wx_y", "wx_z"])
                    vortX_avg = obj.load_stored_var(var_files, "vortX_avg");
                    var = mask_vortex_centroid(var, vortX_avg, name);
                end
            end
            var = double(var(:)');

            % old flapper cases without automated homing that started at a
            % different phase: same correction as phaseAvg_UI applies to its
            % STB curves, not the load cell (table in old_flapper_compat)
            phase_offset = old_flapper_compat("phase_offset", type, amp, freq);
            if phase_offset ~= 0
                var = circshift(var, round(phase_offset*length(var)));
            end
        end

        function tf = is_load_cell_var(~, force_var)
            tf = startsWith(string(force_var), "LC_");
        end

        % Selection without what the load cell doesn't depend on: the
        % downstream position prefix (x1_, MPS_, ...; get_force strips it
        % too), RPCA, HR and HRPP
        function info = strip_load_cell_position(~, info)
            prefix = get_downstream_prefix(info.type);
            if strlength(prefix) > 0
                info.type = extractAfter(info.type, strlength(prefix));
            end
            info.RPCA = false;
            info.HR = false;
            info.HRPP = false;
        end

        % Selection label of a case's processing variant, as
        % stb_list_phase_avg names them: <case>_hr_RPCA (binned: harmonic
        % regression, then RPCA) or <case>_particle_pool_hr20 (HRPP:
        % particle pool fit with harmonic regression; no binned variants)
        function name = add_variant_suffix(obj, name, info)
            if isfield(info, 'HRPP') && info.HRPP
                name = name + "_" + obj.HRPP_METHOD;
                return
            end
            if info.HR
                name = name + "_hr";
            end
            if info.RPCA
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
        function signal = get_load_cell_signal(obj, force_var, type, amp, freq, phase_avg, time_stamp)
            % time_stamp (optional): which repeat of the case to load;
            % default the latest
            if nargin < 7
                time_stamp = "";
            end
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
                signal = get_force(obj.get_force_path(type), type, amp, freq, idx, var_name_F, time_stamp);
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
                signal = signal / obj.get_nominal_speed(obj.get_case(name, suffix));
            end

            if obj.force_sub && ismember(quantity, ["drag", "lift", "pitch"])
                if obj.is_plain_steady_type(type)
                    disp("Force Body Sub skipped for steady case " + type)
                else
                    % same-amplitude body case (get_body_force falls back
                    % to 20 deg only when there is no body data at this
                    % amplitude)
                    try
                        body_signal = get_body_force(obj.get_force_path(type), type, amp, freq, idx, var_name_F);
                    catch ME
                        if ~startsWith(ME.identifier, "get_force:")
                            rethrow(ME)
                        end
                        disp(ME.message + " - no body case, point not plotted")
                        signal = NaN;
                        return
                    end
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
            conv_speed = plane_downstream_dists("conv_speed"); % m/s
            % The plane sees the wake the wing shed one convection time earlier,
            % so the curve is moved EARLIER by that time (negative circshift) to put
            % it in the robot's wing phase. (A positive shift added the delay twice:
            % x2 and x4 then differed by 2*0.378 m / U instead of lining up.)
            shift_samples = -round(dist / conv_speed * freq_cor * length(signal));
            signal = circshift(signal, shift_samples);
            disp("Shifted " + obj.get_force_var_label(force_var) + " by: " + shift_samples + ...
                " / " + length(signal) + " (" + dist + " m downstream)")
        end

        % Streamwise distance (m) from the robot to the imaging plane for a
        % case type, from plane_downstream_dists (shared with phaseAvg_UI
        % and flowField_UI): xN = x3 + (N - 3) * sep, MPS; old flapper at
        % x3, UP_one / UP_two one / two spacings further
        function dist = get_robot_to_plane_dist(~, type)
            d = plane_downstream_dists();
            prefix = regexprep(get_downstream_prefix(type, true), "_$", ""); % e.g. "x3", "UP_one"
            x_pos = regexp(char(prefix), '^x(\d+)$', 'tokens', 'once');
            if ~isempty(x_pos)
                dist = d.x3 + (str2double(x_pos{1}) - 3) * d.sep;
            elseif prefix == "MPS"
                dist = d.MPS;
            elseif prefix == "UP_one"
                dist = d.old(2);
            elseif prefix == "UP_two"
                dist = d.old(3);
            elseif contains(type, "turbine")
                dist = NaN;
            else
                dist = d.old(1); % old flapper
            end
        end

        % forces from the time-averaged field (TA: force), not stored in
        % the files, so always calculated by get_PIV_force
        % Q centroid (Qx_y, Qx_z) and Q_x centroid (Qxcomp_y, Qxcomp_z):
        % with Live Calculate on, recomputed from the saved Q / Q_x with the
        % Live Calc bounds and uncertainty mask. Also computed (default
        % bounds) when the _integral file predates the variable.
        function tf = is_live_Q_centroid(obj, force_var, case_files)
            force_var = string(force_var);
            tf = false;
            if ~ismember(force_var, ["Qx_y", "Qx_z", "Qxcomp_y", "Qxcomp_z"])
                return
            end
            tf = obj.calc_bool || ~stb_has_var(case_files, force_var);
        end

        function bounds = get_Q_centroid_bounds(obj)
            if obj.calc_bool
                bounds = obj.trim_bounds;
            else
                bounds = default_trim_bounds();
            end
        end

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
                 ismember(force_var, ["lift.vortY_edge", "lift.vortX_taper",...
                 "lift_ff.vortY", "lift_ff.vortY_edge"]));
        end

        % Frozen-flow forces (lift_ff.*) of a file processed before they
        % were saved: calculated live by get_PIV_force instead
        function tf = needs_live_ff(~, force_var, case_files)
            tf = startsWith(string(force_var), ["lift_ff.", "drag_ff."]) && ...
                ~stb_has_var(case_files, "lift_ff");
        end

        % Files of a case (struct for stb_load / stb_who): a phase average
        % (suffix "_phase_avg", found by its selection label among the
        % <stem>_<method>_fields.mat files) or a time average ("_time_avg",
        % <case>_time_avg.mat + _integral.mat)
        function case_files = get_case(obj, name, suffix)
            name = string(name);
            if string(suffix) == "_phase_avg"
                if ~isKey(obj.phase_case_map, char(name))
                    error("timeAvg_UI:caseNotFound", "No phase-averaged files for %s (expected <case>[_<version>]_<method>_fields.mat in Processed Results\\phase_avg\\).", name)
                end
                case_files = obj.phase_case_map(char(name));
                return
            end
            % time averages: time_avg\ (or, older, next to the phase
            % averages), first data root holding the case
            case_dir = obj.data_roots(1) + "Processed Results\time_avg\";
            for r = 1:numel(obj.data_roots)
                found = false;
                for d = [obj.data_roots(r) + "Processed Results\time_avg\",...
                         obj.data_roots(r) + "Processed Results\phase_avg\"]
                    if isfile(d + name + suffix + ".mat") || isfile(d + name + suffix + "_integral.mat")
                        case_dir = d;
                        found = true;
                        break
                    end
                end
                if found, break; end
            end
            case_files = stb_time_avg_case(case_dir + name + suffix);
        end

        % Files of the PIV subtraction case (time average, see
        % get_PIV_sub_file_paths) as a case struct
        function case_files = get_PIV_sub_case(obj, type, amp)
            [file_path, ~] = obj.get_PIV_sub_file_paths(type, amp);
            case_files = stb_time_avg_case(extractBefore(file_path, strlength(file_path) - strlength(".mat") + 1));
        end

        % Load cell folder for a wing type: Force Measurements of the data
        % root its STB cases came from (the primary root if unknown)
        function force_path = get_force_path(obj, type)
            key = char(string(type));
            force_path = obj.force_path;
            if ~isempty(obj.type_root_map) && isKey(obj.type_root_map, key)
                force_path = string(obj.type_root_map(key)) + "Force Measurements\";
            end
        end

        function var = compute_div_avg(obj, files)
            % Planar average of du/dx + dv/dy + dw/dz on the trimmed centre
            % plane, as calc_secondary_vals_common saves it (div_avg), from
            % the gradient fields of a time average (mean_d*d*) or phase
            % average (d*d*_phase_avg) main file. One value per bin for a
            % phase average. [] if no file has the three gradients.
            var = [];
            grads = ["dudx", "dvdy", "dwdz"];
            for f = 1:numel(files)
                vars_in_file = string(stb_who(files(f)));
                for names = {"mean_" + grads, grads + "_phase_avg"}
                    fields = names{1};
                    if ~all(ismember(fields, vars_in_file)) || ...
                            ~all(ismember(["y", "z"], vars_in_file))
                        continue
                    end
                    d = stb_load(files(f), "y", "z", fields{:});
                    div = d.(fields(1)) + d.(fields(2)) + d.(fields(3));
                    [~, ~, T] = trim_vel_field(d.y, d.z, div, obj.trim_bounds);
                    var = squeeze(mean(T, [1, 2]));
                    return
                end
            end
        end

        function files = get_stored_var_files(~, force_var, case_files)
            % a case's files in the order to look for a stored variable: a
            % few (not nested) are kept with the flow fields / shared data,
            % the rest in the integral file
            if ~contains(force_var, ".") && ...
                    ismember(force_var, ["U_act", "rho_act", "num_bins","num_clusters","phase_spread_ratio"])
                files = stb_case_files(case_files);
            else
                files = stb_case_files(case_files, "integral");
            end
        end

        function var = load_stored_var(obj, files, var_name)
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
                if ~ismember(char(parts(1)), stb_who(files(f)))
                    continue
                end
                d = stb_load(files(f), parts(1));
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

            % divergence planar average not in the _integral file (older
            % processing): computed from the gradients in the main file
            if string(var_name) == "div_avg"
                var = obj.compute_div_avg(files);
                if ~isempty(var)
                    return
                end
            end

            [~, file_name] = fileparts(files(1));
            % an old flapper file without the variable at all was processed
            % before it existed: leave the point out rather than plot 0
            in_any = false;
            for f = 1:numel(files)
                in_any = in_any || ismember(char(parts(1)), stb_who(files(f)));
            end
            if ~in_any && old_flapper_compat("is_old", file_name)
                fprintf("%s not saved for %s (older processing), not plotted\n", var_name, file_name);
                var = NaN;
                return
            end
            fprintf("%s not defined for %s, using 0\n", var_name, file_name);
            var = 0;
        end

        % Uncertainty mask threshold passed to get_PIV_force with the trim
        % bounds (fraction of the freestream; 0 = off)
        % Crop Box passed to get_PIV_force with the trim bounds ([] = off)
        function set_crop_box_bound(obj)
            if obj.crop_box_bool
                obj.trim_bounds.crop_box = obj.crop_box;
            else
                obj.trim_bounds.crop_box = [];
            end
        end

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

        % Values the range slider snaps to and their tick labels, for an
        % x-axis (default: the current one): the measured frequencies (Hz)
        % or amplitudes (deg) of the current data set, or the downstream
        % positions as indices 1..n into dist_positions (ordered by
        % distance, labelled with their names; no MPS)
        function [vals, labels] = get_range_slider_values(obj, x_axis_type)
            if nargin < 2
                x_axis_type = obj.x_axis_type;
            end
            types = string(obj.available_selections(:, 1));
            in_source = obj.get_source_mask(types, obj.source_mode);
            switch x_axis_type
                case "wingbeat frequency"
                    vals = obj.available_freqs(:)';
                    labels = string(vals);
                case "wingbeat amplitude"
                    amps = cell2mat(obj.available_selections(:, 2));
                    vals = unique(amps(in_source))';
                    labels = string(vals);
                case "downstream distance"
                    pos = unique(obj.get_position(types(in_source)));
                    % MPS is left off the distance axis (its cases are
                    % still listed for the frequency / amplitude axes)
                    pos = pos(pos ~= "MPS");
                    dists = arrayfun(@(p) obj.position_distance(p), pos);
                    keep = isfinite(dists);
                    [~, order] = sort(dists(keep));
                    pos = pos(keep);
                    obj.dist_positions = reshape(pos(order), 1, []);
                    vals = 1:numel(obj.dist_positions);
                    labels = obj.position_label(obj.dist_positions);
            end
        end

        % Index of a case type's position in dist_positions (NaN if none)
        function idx = position_index(obj, type)
            idx = find(obj.dist_positions == obj.get_position(type), 1);
            if isempty(idx)
                idx = NaN;
            end
        end

        % [low high] slider range of an x-axis (default: the current one);
        % the full range if unset or no longer valid, [] if no values
        function r = get_x_range(obj, x_axis_type)
            if nargin < 2
                x_axis_type = obj.x_axis_type;
            end
            vals = obj.get_range_slider_values(x_axis_type);
            if isempty(vals)
                r = [];
                return
            end
            switch x_axis_type
                case "wingbeat frequency", r = obj.freq_range;
                case "wingbeat amplitude", r = obj.amp_range;
                case "downstream distance", r = obj.dist_range;
            end
            if numel(r) ~= 2 || ~all(ismember(r, vals))
                r = [min(vals), max(vals)];
                obj.set_x_range(r, x_axis_type);
            end
        end

        function set_x_range(obj, r, x_axis_type)
            if nargin < 3
                x_axis_type = obj.x_axis_type;
            end
            switch x_axis_type
                case "wingbeat frequency", obj.freq_range = r;
                case "wingbeat amplitude", obj.amp_range = r;
                case "downstream distance", obj.dist_range = r;
            end
        end

        % Range slider and its label for the current x-axis
        function setup_range_slider(obj, slider, label)
            [vals, tick_labels] = obj.get_range_slider_values();
            if isempty(vals)
                slider.Enable = "off";
                label.Enable = "off";
                label.Text = "No cases";
                return
            end
            r = obj.get_x_range();
            lims = [min(vals), max(vals)];
            if lims(1) == lims(2)
                lims(2) = lims(1) + 1; % slider needs a span
            end
            slider.Limits = lims;
            slider.Value = r;
            slider.MajorTicks = vals;
            slider.MajorTickLabels = cellstr(tick_labels);
            slider.Enable = "on";
            label.Enable = "on";
            obj.update_range_label(label);
        end

        function update_range_label(obj, label)
            r = obj.get_x_range();
            if isempty(r)
                return
            end
            switch obj.x_axis_type
                case "wingbeat frequency"
                    label.Text = sprintf("Frequencies: %g - %g Hz", r(1), r(2));
                case "wingbeat amplitude"
                    label.Text = sprintf("Amplitudes: %g - %g deg", r(1), r(2));
                case "downstream distance"
                    names = obj.position_label(obj.dist_positions(r));
                    label.Text = "Positions: " + names(1) + " - " + names(2);
            end
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
            %   freestream -> freestream (empty test section, one case for
            %                 all positions, see position_independent_cases)
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
                case "freestream"
                    case_names = position_independent_cases();
                otherwise
                    error("Unknown PIV subtraction case: %s", obj.PIV_sub_case);
            end

            % steady cases may sit in a time_avg subfolder (old ring
            % location), next to the phase averaged files, or in
            % Processed Results\time_avg
            % (in every data root)
            search_dirs = strings(1, 0);
            for r = 1:numel(obj.data_roots)
                root_phase = obj.data_roots(r) + "Processed Results\phase_avg\";
                search_dirs = [search_dirs, root_phase + "time_avg\", root_phase,...
                               obj.data_roots(r) + "Processed Results\time_avg\"]; %#ok<AGROW>
            end

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
        % Standard error (random uncertainty) of the plotted mean of a
        % force or flow variable, for its error bar. 0 if there is none.
        %
        % Phase averaged cases: the plotted value is the mean of the N_b
        % bin values, so SE = sqrt(sum(SE_b.^2)) / N_b with SE_b the
        % standard error of bin b (bins hold separate frames, so treated
        % as independent):
        %   forces: SE_b = (frame-to-frame SD of the BA force in bin b,
        %           *_before_std) / sqrt(bin_count(b))
        %   u/v/w avg: SE_b = u_avg_se(b), the plane average of the
        %           per-point SE (calc_secondary_vals_common)
        % 0 Hz cases: the saved SE of the time average (*_before_se,
        % u_avg_se). Frames are assumed independent (STB frame interval
        % long compared with the flow's correlation time).
        %
        % Forces from the averaged field (plain and TA forces) use the SE
        % of their BA version: to first order (delta method) the force of
        % the mean field and the mean of the per-frame forces have the same
        % random error. Forces with no BA version ((u avg), vortY, edge /
        % taper, extrapolated) and other flow variables get no bar. Only
        % for the "mean" operation (range / rmse: no bar yet).
        function se = get_mean_se(obj, var_name, case_files, freq, case_name)
            se = 0;
            if obj.operation ~= "mean"
                return
            end
            var_name = string(var_name);
            if ismember(var_name, ["u_avg", "v_avg", "w_avg"])
                se_name = var_name + "_se";
                files = stb_case_files(case_files, "integral");
                combine_bins = freq ~= 0;
            else
                ba_name = obj.get_ba_force_name(var_name);
                if ba_name == ""
                    return
                end
                if freq == 0
                    se_name = replace(ba_name, "_before_avg", "_before_se");
                    combine_bins = false;
                else
                    se_name = replace(ba_name, "_before_avg", "_before_std");
                    combine_bins = true;
                end
                files = stb_case_files(case_files);
            end
            se_vals = [];
            for f = 1:numel(files)
                parts = split(se_name, ".");
                if ~ismember(char(parts(1)), stb_who(files(f)))
                    continue
                end
                d = stb_load(files(f), parts(1));
                se_vals = d.(parts(1));
                for k = 2:numel(parts)
                    if isstruct(se_vals) && isfield(se_vals, parts(k))
                        se_vals = se_vals.(parts(k));
                    else
                        se_vals = [];
                        break
                    end
                end
                if ~isempty(se_vals)
                    break
                end
            end
            if isempty(se_vals) || isstruct(se_vals)
                disp("No " + se_name + " saved for " + case_name + " (older processing) - no error bar")
                return
            end
            se_vals = double(se_vals(:));

            % BA force SD per bin -> SE per bin
            if combine_bins && endsWith(extractBefore(se_name + ".", "."), "_before_std")
                c = stb_load(case_files, "bin_count");
                n = double(c.bin_count(:));
                if numel(n) ~= numel(se_vals)
                    disp("bin_count does not match " + se_name + " for " + case_name + " - no error bar")
                    return
                end
                se_vals = se_vals ./ sqrt(n);
            end

            if combine_bins
                se = sqrt(sum(se_vals.^2, "omitnan")) / numel(se_vals);
            else
                se = se_vals(1);
            end
            if ~isfinite(se)
                se = 0;
            end
        end

        % BA counterpart of a force variable ("" if it has none):
        % lift.vortX / lift_tavg.vortX -> lift_before_avg.vortX,
        % lift_vel / lift_vel_tavg -> lift_vel_before_avg
        function ba_name = get_ba_force_name(obj, var_name)
            ba_name = "";
            var_name = string(var_name);
            category = obj.get_var_category(var_name);
            if category == "BA: force"
                ba_name = var_name;
            elseif ismember(category, ["force", "TA: force"])
                base = replace(var_name, "_tavg", "");
                if ismember(base, ["lift_vel", "drag_vel"])
                    ba_name = base + "_before_avg";
                elseif startsWith(base, ["lift.", "drag."]) && ...
                        ~ismember(base, ["lift.vortY", "lift.vortY_edge", "lift.vortX_taper"])
                    ba_name = replace(base, ".", "_before_avg.");
                end
            end
        end

        % Factor get_PIV_force divides by when normalizing (y_norm)
        function factor = get_force_norm_factor(~, case_files, freq)
            if freq == 0
                d = stb_load(case_files, "L");
                density = 1.225;
                U_act = 1;
                if stb_has_var(case_files, "U_act")
                    u = stb_load(case_files, "U_act"); U_act = u.U_act;
                end
            else
                d = stb_load(case_files, "L", "U_act", "rho_act");
                density = d.rho_act;
                U_act = d.U_act;
            end
            factor = 0.5 * density * d.L^2 * U_act^2;
        end

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