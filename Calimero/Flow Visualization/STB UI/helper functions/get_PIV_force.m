function [var, err] = get_PIV_force(file_name, case_name, force_var_name, avg_type, norm_bool, bounds)
        % bounds: trim limits and center point for trim_vel_field
        % (defaults in default_trim_bounds.m)

        % *_tavg (e.g. lift_tavg.vortX, lift_vel_tavg): average the phase
        % averaged fields over the cycle (each bin weighted equally) into a
        % single time-averaged field, then compute the force from that field
        % (no convection axis, so terms like lift.vortY aren't defined).
        % Ignored for time-averaged (avg_type 0) files, which already are.
        tavg_bool = false;
        if contains(force_var_name, "_tavg")
            force_var_name = erase(force_var_name, "_tavg");
            tavg_bool = (avg_type == 1);
        end

        vort_bool = true;
        % velocity-only estimates (lift_vel, drag_vel) use vort_bool false;
        % lift.vel_diff is a term of the vorticity-based lift
        if endsWith(force_var_name, "_vel")
            force_var_name = extractBefore(force_var_name, "_vel");
            vort_bool = false;
        end

        % lift_uavg / drag_uavg: use the vorticity of the averaged velocity
        % (vort*_uavg) instead of the averaged per-frame vorticity
        vort_suffix = "";
        if contains(force_var_name, "_uavg")
            force_var_name = erase(force_var_name, "_uavg");
            vort_suffix = "_uavg";
        end

        switch avg_type
            case 0
            vars = {"L","U","rho","y","z","mean_u","mean_v","mean_w"};
            if vort_bool
                vars = [vars, {"mean_vortX" + vort_suffix, "mean_vortY" + vort_suffix, "mean_vortZ" + vort_suffix}];
            end
            vars = [vars, "mean_uncTot"];
            case 1
            vars = {"L","U","U_act","rho_act","cycle_freq","y","z","u_phase_avg","v_phase_avg","w_phase_avg"};
            if vort_bool
                if vort_suffix == ""
                    vars = [vars, "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"]; % "dudy_phase_avg", "dudz_phase_avg"
                else
                    vars = [vars, "vortX_uavg","vortY_uavg","vortZ_uavg"];
                end
            end
            vars = [vars, "uncTot_phase_avg"];
        end

        d = load(file_name, vars{:});
        switch avg_type
            case 0
                speed = d.U;
                density = 1.225;
            case 1
                speed = d.U_act * d.U;
                density = d.rho_act;
        end
        

        % Use frozen flow assumption, i.e. convection of vortices, to get z-axis
        if avg_type ~= 0 && ~tavg_bool
            [~, ~, freq] = parse_name(case_name);
            if freq <= 0 && isfield(d, 'cycle_freq')
                freq = d.cycle_freq;
            end
            if freq <= 0
                error("Unable to determine cycle frequency for " + string(case_name))
            end
            num_bins = size(d.u_phase_avg,4);
            period = 1 / freq;
            % actual time of each bin: the mean phase of its frames
            % (bin_placement), not the bin centre; nominal if not saved
            placement = [];
            if ismember('bin_placement', who('-file', file_name))
                p = load(file_name, 'bin_placement');
                placement = p.bin_placement;
            end
            t_bins = bin_times(num_bins, period, placement);
            x_conv = speed * t_bins(:)';
        else
            x_conv = 0;
            period = NaN;
        end
        
    % ------------------------------------------------------------
    % Trim velocity field before calculating integral quantities
    % -------------------------------------------------------------
    y = d.y;
    z = d.z;
    
    switch avg_type
    case 0
        u_tr = d.mean_u;
        v_tr = d.mean_v;
        w_tr = d.mean_w;
        
        if vort_bool
        vortX_tr = d.("mean_vortX" + vort_suffix);
        vortY_tr = d.("mean_vortY" + vort_suffix);
        vortZ_tr = d.("mean_vortZ" + vort_suffix);
        end
        
        unc_tr = d.mean_uncTot;
    case 1
        u_tr = d.u_phase_avg;
        v_tr = d.v_phase_avg;
        w_tr = d.w_phase_avg;
        
        if vort_bool
        if vort_suffix == ""
            vortX_tr = d.vortX_phase_avg;
            vortY_tr = d.vortY_phase_avg;
            vortZ_tr = d.vortZ_phase_avg;
        else
            vortX_tr = d.vortX_uavg;
            vortY_tr = d.vortY_uavg;
            vortZ_tr = d.vortZ_uavg;
        end
        end
    
        unc_tr = d.uncTot_phase_avg;

        if tavg_bool
            % cycle average of the phase averaged fields (bins on dim 4);
            % omitnan so a hole in one bin is filled by the other bins
            u_tr = mean(u_tr, 4, "omitnan");
            v_tr = mean(v_tr, 4, "omitnan");
            w_tr = mean(w_tr, 4, "omitnan");
            if vort_bool
            vortX_tr = mean(vortX_tr, 4, "omitnan");
            vortY_tr = mean(vortY_tr, 4, "omitnan");
            vortZ_tr = mean(vortZ_tr, 4, "omitnan");
            end
            unc_tr = mean(unc_tr, 4, "omitnan");
        end
    end
    
    [y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr, bounds);
    [~, ~, v_tr] = trim_vel_field(y, z, v_tr, bounds);
    [~, ~, w_tr] = trim_vel_field(y, z, w_tr, bounds);
    if vort_bool
    [~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr, bounds);
    [~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr, bounds);
    [~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr, bounds);
    end
    [~, ~, unc_tr] = trim_vel_field(y, z, unc_tr, bounds);
    
    % Fill holes in the (averaged) velocity field by Laplace interpolation
    % from surrounding data, plane by plane. A global median fill puts
    % ~freestream values into holes inside the downwash region, which
    % biases the integral of w (and hence the lift estimate).
    u_tr = nanRegionFill(u_tr);
    v_tr = nanRegionFill(v_tr);
    w_tr = nanRegionFill(w_tr);
    
    D.x = x_conv; D.y = y_tr; D.z = z_tr;
    D.period = period; % wingbeat period, for the periodic time integrals
    D.u = u_tr; D.v = v_tr; D.w = w_tr;
    if vort_bool
    D.vortX = vortX_tr; D.vortY = vortY_tr; D.vortZ = vortZ_tr;
    end
    D.unc = unc_tr;
    
    % Capture all outputs into a cell array
    % [outputs{1:2}] = get_wake_lift(speed, d.L, x, d.y, d.z, d, avg_type, vort_bool, y_cen, z_cen, density);
    [outputs{1:2}] = get_wake_lift(speed, d.L, D, vort_bool, density);
    
    % Define your field names
    fields = {'lift', 'drag'};
    
    % Convert to a struct
    F = cell2struct(outputs, fields, 2);
    
    % Pull out the requested (possibly nested) force. Terms that
    % aren't defined for a case, e.g. lift.vortY for a time average
    % (no convection axis), are replaced with zero.
    parts = split(string(force_var_name), ".");
    var = F;
    for k = 1:numel(parts)
        if isstruct(var) && isfield(var, parts(k))
            var = var.(parts(k));
        else
            [~, file_label] = fileparts(file_name);
            fprintf("%s not defined for %s, using 0\n", force_var_name, file_label);
            var = 0;
            break
        end
    end
    err = 0;
    
    if norm_bool
        var = var / (0.5 * density * d.L^2 * d.U_act^2);
        % should be chord * span, not chord^2
    end
end