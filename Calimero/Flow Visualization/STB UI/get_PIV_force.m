function [var, err] = get_PIV_force(file_name, case_name, force_var_name, vort_bool, avg_type)

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

        if avg_type == 0
            speed = d.U;
            density = 1.225;
        else
            % Find matching DAQ file
            [daq_data_filename, daq_data_path] = get_daq_paths(case_name);
    
            WT_d = get_wind_tunnel_data(daq_data_filename);
            speed = WT_d.Speed_m_s_;
            density = WT_d.Density_kg_m3_;
            % density = 1.225;
        end

        % Compute Lift force
        y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L
        z_cen = -0.03 / d.L;
        % rho = ; % 1.225 kg/m^3

        % Capture all outputs into a cell array
        [outputs{1:2}] = get_wake_lift(speed, d.L, d.y, d.z, d, avg_type, vort_bool, y_cen, z_cen, density);
        
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