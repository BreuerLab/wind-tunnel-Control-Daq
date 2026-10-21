function S = time_avg_STB(file_path, U, L, save_filepath_local, PIV_case_name, num_images, bools, bounds)
    tic;
    save_path = fullfile(save_filepath_local, PIV_case_name + "_time_avg.mat");

    if bools.proc_vel
    % wind tunnel properties were not measured for gliding data
    speed = U;
    density = 1.225;

    % variable preallocation
    lift_vals = zeros(1,num_images);
    drag_vals = zeros(1,num_images);
    % per-frame lift/drag for the frame (bin) averages, as in
    % phase_avg_STB but with the whole run as a single bin
    lift_frames = struct();
    drag_frames = struct();
    lift_vel_frames = NaN(1,num_images); % velocity-only lift (u*w)
    Qx_sum = 0; Qy_sum = 0; Qz_sum = 0; Q_sum = 0; Q_n = 0; % for Q of each frame, averaged
    drag_vel_frames = NaN(1,num_images); % velocity-only drag
    print_dim_bool = true;

    fields = get_STB_processing_fields();

    for i = 1:num_images
        % Import data (using a temporary struct or list)
        [x, y, z, data{1:length(fields)}] = import_STB_data(file_path, bools.nondim, U, L, i, bools.RPCA);
        
        if i == 1
            % Initialize structure with zeros based on first file size
            for f = 1:length(fields)
                S.(['mean_' fields{f}]) = zeros(size(x));
                n_valid.(['mean_' fields{f}]) = zeros(size(x)); % frames with data, per bin
            end

            % turn printing boolean off for printing of trimmed dimensions
            print_dim_bool = false;
            disp("Trimming for force calculation only")
        end
        
        % Accumulate sums dynamically
        for f = 1:length(fields)
            fn = ['mean_' fields{f}];
            current_data = data{f};
            valid = ~isnan(current_data);
            current_data(~valid) = 0;
            S.(fn) = S.(fn) + current_data;
            n_valid.(fn) = n_valid.(fn) + valid;
        end

        % Q on this instantaneous field (accumulated, averaged below)
        [Qx_frame, Qy_frame, Qz_frame, Q_frame] = inst_Q_avg(data{1}, data{2}, data{3}, x, y, z);
        Q_ok = isfinite(Q_frame);
        Qx_frame(~Q_ok) = 0; Qy_frame(~Q_ok) = 0; Qz_frame(~Q_ok) = 0; Q_frame(~Q_ok) = 0;
        Qx_sum = Qx_sum + Qx_frame;
        Qy_sum = Qy_sum + Qy_frame;
        Qz_sum = Qz_sum + Qz_frame;
        Q_sum = Q_sum + Q_frame;
        Q_n = Q_n + Q_ok;

        F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, 0, bounds); % trimming

        [lift, drag] = get_wake_lift(speed, L, F, true, density);
        lift_vals(i) = lift.vortX;
        drag_vals(i) = drag.tot;

        % keep every lift / drag term for this frame
        if i == 1
            lift_fields = fieldnames(lift);
            drag_fields = fieldnames(drag);
            for f = 1:length(lift_fields)
                lift_frames.(lift_fields{f}) = NaN(1,num_images);
            end
            for f = 1:length(drag_fields)
                drag_frames.(drag_fields{f}) = NaN(1,num_images);
            end
        end
        for f = 1:length(lift_fields)
            lift_frames.(lift_fields{f})(i) = mean(lift.(lift_fields{f}), "all", "omitnan");
        end
        for f = 1:length(drag_fields)
            drag_frames.(drag_fields{f})(i) = mean(drag.(drag_fields{f}), "all", "omitnan");
        end

        % velocity-only estimates (vort_bool false)
        [lift_vel, drag_vel] = get_wake_lift(speed, L, F, false, density);
        lift_vel_frames(i) = mean(lift_vel, "all", "omitnan");
        drag_vel_frames(i) = mean(drag_vel, "all", "omitnan");
        
        if mod(i, 100) == 0
            fprintf('Processed %d/%d\n', i, num_images);
        end
    end

    % Divide each bin's sum by the number of frames that actually had data
    % in that bin (NaN-omitting mean). Dividing by num_images would pull
    % bins with intermittent holes toward zero. Bins with no data in any
    % frame come out NaN and are filled downstream (nanRegionFill).
    avg_fields = fieldnames(S);
    for f = 1:length(avg_fields)
        S.(avg_fields{f}) = S.(avg_fields{f}) ./ n_valid.(avg_fields{f});
    end

    % Vorticity of the time-averaged velocity (in addition to the average
    % of the per-frame vorticity, mean_vort*)
    [S.mean_vortX_uavg, S.mean_vortY_uavg, S.mean_vortZ_uavg] = vorticity_of_mean_velocity(x, y, z,...
        S.mean_u, S.mean_v, S.mean_w, S.mean_uncU, S.mean_uncV, S.mean_uncW);

    % Add metadata to the struct
    S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.rho = density;
    S.PIV_case_name = PIV_case_name;
    S.mean_lift = mean(lift_vals); S.mean_drag = mean(drag_vals);

    % Q of each frame averaged over all frames (vs Q of the mean field,
    % computed in calc_secondary_vals_time)
    S.Qx_inst_avg = Qx_sum ./ Q_n;
    S.Qy_inst_avg = Qy_sum ./ Q_n;
    S.Qz_inst_avg = Qz_sum ./ Q_n;
    S.Q_inst_avg = Q_sum ./ Q_n;

    % Before-averaging (BA) lift and drag: lift / drag computed for each
    % frame, then averaged over all frames. Same names as phase_avg_STB
    % (*_before_avg), with one value instead of one per bin.
    lift_before_avg = struct();
    for f = 1:length(lift_fields)
        lift_before_avg.(lift_fields{f}) = mean(lift_frames.(lift_fields{f}), "omitnan");
    end
    drag_before_avg = struct();
    for f = 1:length(drag_fields)
        drag_before_avg.(drag_fields{f}) = mean(drag_frames.(drag_fields{f}), "omitnan");
    end
    S.lift_before_avg = lift_before_avg; S.drag_before_avg = drag_before_avg;
    S.lift_vel_before_avg = mean(lift_vel_frames, "omitnan");
    S.drag_vel_before_avg = mean(drag_vel_frames, "omitnan");

    % Save the entire structure
    save(save_path, '-struct', 'S');
    
    fprintf('Processing and saving took %.4f seconds.\n', toc);

    calc_secondary_vals_time(S, save_filepath_local, bounds)
    else
    % load in processed velocity field struct from an earlier run
    S = load(save_path);
    
    % Calculate secondary values (Q, power, integral values) and save in
    % separate file
    calc_secondary_vals_time(S, save_filepath_local, bounds)
    end
end