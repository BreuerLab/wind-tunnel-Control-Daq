function [var, err] = get_PIV_force(file_name, force_var_name, vort_bool, avg_type)

        switch avg_type
            case 0
            vars = {"L","U","y","z","mean_u","mean_w"};
            if vort_bool
                vars = [vars, "mean_vortX","mean_vortY","mean_vortZ"];
            end
            case 1
            vars = {"L","U","y","z","u_phase_avg","w_phase_avg"};
            if vort_bool
                vars = [vars, "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"];
            end
        end

        d = load(file_name, vars{:});

        % Compute Lift force
        y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L
        z_cen = -0.03 / d.L;

        % Capture all outputs into a cell array
        [outputs{1:2}] = get_wake_lift(d.U, d.L, d.y, d.z, d, avg_type, vort_bool, y_cen, z_cen);
        
        % Define your field names
        fields = {'lift', 'drag'};
        
        % Convert to a struct
        F = cell2struct(outputs, fields, 2);

        if contains(force_var_name, "vel")
            force_var_name = extractBefore(force_var_name, "_vel");
        end
        var = F.(force_var_name);
        err = 0;
end