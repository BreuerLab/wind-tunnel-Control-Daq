function [var, err] = get_PIV_force(file_name, case_name, force_var_name, avg_type, norm_bool, y_cen)

        vort_bool = true;
        if contains(force_var_name, "vel")
            force_var_name = extractBefore(force_var_name, "_vel");
            vort_bool = false;
        end

        switch avg_type
            case 0
            vars = {"L","U","rho","y","z","mean_u","mean_v","mean_w"};
            if vort_bool
                vars = [vars, "mean_vortX","mean_vortY","mean_vortZ"];
            end
            vars = [vars, "mean_uncTot"];
            case 1
            vars = {"L","U","U_act","rho_act","cycle_freq","y","z","u_phase_avg","v_phase_avg","w_phase_avg"};
            if vort_bool
                vars = [vars, "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg",...
                    ]; % "dudy_phase_avg", "dudz_phase_avg"
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
        if avg_type ~= 0
            [~, ~, freq] = parse_name(case_name);
            if freq <= 0 && isfield(d, 'cycle_freq')
                freq = d.cycle_freq;
            end
            if freq <= 0
                error("Unable to determine cycle frequency for " + string(case_name))
            end
            num_bins = size(d.u_phase_avg,4);
            dt = 1 / (freq * num_bins);
            x_conv = zeros(1, num_bins);
            for k = 1:num_bins
                x_conv(k) =  speed * dt * (k - 1);
            end
        else
            x_conv = 0;
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
vortX_tr = d.mean_vortX;
vortY_tr = d.mean_vortY;
vortZ_tr = d.mean_vortZ;
end

unc_tr = d.mean_uncTot;
case 1
u_tr = d.u_phase_avg;
v_tr = d.v_phase_avg;
w_tr = d.w_phase_avg;

if vort_bool
vortX_tr = d.vortX_phase_avg;
vortY_tr = d.vortY_phase_avg;
vortZ_tr = d.vortZ_phase_avg;
end

unc_tr = d.uncTot_phase_avg;
end

[y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr);
[~, ~, v_tr] = trim_vel_field(y, z, v_tr);
[~, ~, w_tr] = trim_vel_field(y, z, w_tr);
if vort_bool
[~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr);
[~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr);
[~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr);
end
[~, ~, unc_tr] = trim_vel_field(y, z, unc_tr);

% Replace nans in velocity field with median values so integral
% calculations aren't skewed
u_tr = nanToMedian(u_tr);
v_tr = nanToMedian(v_tr);
w_tr = nanToMedian(w_tr);

D.x = x_conv; D.y = y_tr; D.z = z_tr;
D.u = u_tr; D.v = v_tr; D.w = w_tr;
if vort_bool
D.vortX = vortX_tr; D.vortY = vortY_tr; D.vortZ = vortZ_tr;
end
D.unc = unc_tr;

        % Capture all outputs into a cell array
        % [outputs{1:2}] = get_wake_lift(speed, d.L, x, d.y, d.z, d, avg_type, vort_bool, y_cen, z_cen, density);
        [outputs{1:2}] = get_wake_lift(speed, d.L, D, avg_type, vort_bool, density);
        
        % Define your field names
        fields = {'lift', 'drag'};
        
        % Convert to a struct
        F = cell2struct(outputs, fields, 2);

        var = eval("F." + force_var_name);
        err = 0;

        if norm_bool
            var = var / (0.5 * density * d.L^2 * d.U_act^2);
            % should be chord * span, not chord^2
        end
end