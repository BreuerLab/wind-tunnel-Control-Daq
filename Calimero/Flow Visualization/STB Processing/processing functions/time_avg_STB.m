function S = time_avg_STB(file_path, nondim_bool, U, L, num_files, save_filepath_local, PIV_case_name, RPCA_bool)
    tic;

    % wind tunnel properties were not measured for gliding data
    speed = U;
    density = 1.225;

    % variable preallocation
    lift_vals = zeros(1,num_files);
    drag_vals = zeros(1,num_files);
    print_dim_bool = true;

    fields = get_STB_processing_fields();
    
    for i = 1:num_files
        % Import data (using a temporary struct or list)
        [x, y, z, data{1:length(fields)}] = import_STB_data(file_path, nondim_bool, U, L, i, RPCA_bool);
        
        if i == 1
            % Initialize structure with zeros based on first file size
            for f = 1:length(fields)
                S.(['mean_' fields{f}]) = zeros(size(x));
            end

            % turn printing boolean off for printing of trimmed dimensions
            print_dim_bool = false;
            disp("Trimming for force calculation only")
        end
        
        % Accumulate sums dynamically
        for f = 1:length(fields)
            fn = ['mean_' fields{f}];
            current_data = data{f};
            current_data(isnan(current_data)) = 0;
            S.(fn) = S.(fn) + current_data;
        end

        F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, 0); % trimming

        [lift, drag] = get_wake_lift(speed, L, F, true, density);
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
    save_path = fullfile(save_filepath_local, PIV_case_name + "_time_avg.mat");
    save(save_path, '-struct', 'S');
    
    fprintf('Processing and saving took %.4f seconds.\n', toc);

    calc_secondary_vals_time(S, save_filepath_local)
end