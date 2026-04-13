function S = time_avg_STB(file_path, nondim_bool, U, L, num_files, save_filepath_local, PIV_case_name, RPCA_bool)
    tic;
    % Define the field names we want to average (must be same order as
    % import_STB)
    fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot'};
    
    for i = 1:num_files
        % Import data (using a temporary struct or list)
        [x, y, z, data{1:12}] = import_STB_data(file_path, nondim_bool, U, L, i, RPCA_bool);
        
        if i == 1
            % Initialize structure with zeros based on first file size
            for f = 1:length(fields)
                S.(['mean_' fields{f}]) = zeros(size(x));
            end
        end
        
        % Accumulate sums dynamically
        for f = 1:length(fields)
            fn = ['mean_' fields{f}];
            S.(fn) = S.(fn) + data{f};
        end
        
        if mod(i, 100) == 0
            fprintf('Processed %d/%d\n', i, num_files);
        end
    end

    % Divide all accumulated fields by num_files to compute average
    avg_fields = fieldnames(S);
    for f = 1:length(avg_fields)
        S.(avg_fields{f}) = S.(avg_fields{f}) / num_files;
    end

    % Compute Lift force
    avg_type = 0;
    y_cen = -0.142 / L;
    z_cen = -0.03 / L;
    [lift_vel, drag_vel] = get_wake_lift(U, L, y, z, S, avg_type, false, y_cen, z_cen);
    [lift, drag] = get_wake_lift(U, L, y, z, S, avg_type, true, y_cen, z_cen);

    % Add metadata to the struct
    S.x = x; S.y = y; S.z = z; S.L = L; S.U = U;
    S.PIV_case_name = PIV_case_name;
    S.lift = lift; S.drag = drag; S.lift_vel = lift_vel; S.drag_vel = drag_vel;

    % Save the entire structure
    save_path = fullfile(save_filepath_local, [PIV_case_name, '_time_avg.mat']);
    save(save_path, '-struct', 'S');
    
    fprintf('Processing and saving took %.4f seconds.\n', toc);
end