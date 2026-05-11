function S = time_avg_STB(file_path, nondim_bool, U, L, num_files, save_filepath_local, PIV_case_name, RPCA_bool)
    tic;

    avg_type = 0;

    speed = U;
    density = 1.225;

    y_cen = -2.26;
    z_cen = -0.03 / L;
    x_conv = 0;

    lift_vals = zeros(1,num_files);
    drag_vals = zeros(1,num_files);

    % Define the field names we want to average (must be same order as
    % import_STB)
    fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot', 'hel', 'numP',...
        'dudx', 'dudy', 'dudz', 'dvdx', 'dvdy', 'dvdz', 'dwdx', 'dwdy', 'dwdz', 'Utot_diff'};
    
    for i = 1:num_files
        % Import data (using a temporary struct or list)
        [x, y, z, data{1:length(fields)}] = import_STB_data(file_path, nondim_bool, U, L, i, RPCA_bool);
        
        if i == 1
            % Initialize structure with zeros based on first file size
            for f = 1:length(fields)
                S.(['mean_' fields{f}]) = zeros(size(x));
            end
        end
        
        % Accumulate sums dynamically
        for f = 1:length(fields)
            fn = ['mean_' fields{f}];
            current_data = data{f};
            current_data(isnan(current_data)) = 0;
            S.(fn) = S.(fn) + current_data;
        end

        avg_type = 2;

        x_conv = 0;

        u_tr = data{1}; v_tr = data{2}; w_tr = data{3};
        vortX_tr = data{5}; vortY_tr = data{6}; vortZ_tr = data{7};
        unc_tr = data{12};
    
        [y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr);
        [~, ~, v_tr] = trim_vel_field(y, z, v_tr);
        [~, ~, w_tr] = trim_vel_field(y, z, w_tr);
        [~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr);
        [~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr);
        [~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr);
        [~, ~, unc_tr] = trim_vel_field(y, z, unc_tr);
    
        F.x = x_conv; F.y = y_tr; F.z = z_tr;
        F.u = u_tr; F.v = v_tr; F.w = w_tr;
        F.vortX = vortX_tr; F.vortY = vortY_tr; F.vortZ = vortZ_tr;
        F.unc = unc_tr;

        [lift, drag] = get_wake_lift(speed, L, F, avg_type, true, density);
        lift_vals(i) = lift.vortX;
        drag_vals(i) = drag.tot;
        
        if mod(i, 100) == 0
            fprintf('Processed %d/%d\n', i, num_files);
        end
    end

    % Divide all accumulated fields by num_files to compute average
    avg_fields = fieldnames(S);
    for f = 1:length(avg_fields)
        S.(avg_fields{f}) = S.(avg_fields{f}) / num_files;
    end

    % Add metadata to the struct
    S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.rho = density;
    S.PIV_case_name = PIV_case_name;
    S.mean_lift = mean(lift_vals); S.mean_drag = mean(drag_vals);

    % Save the entire structure
    save_path = fullfile(save_filepath_local, [PIV_case_name, '_time_avg.mat']);
    save(save_path, '-struct', 'S');
    
    fprintf('Processing and saving took %.4f seconds.\n', toc);

    calc_secondary_vals_time(S, save_filepath_local)
end