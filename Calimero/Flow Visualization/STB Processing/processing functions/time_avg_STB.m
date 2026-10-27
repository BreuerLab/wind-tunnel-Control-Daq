function S = time_avg_STB(file_path, U, L, save_filepath_local, PIV_case_name, num_images, bools, bounds)
    tic;
    save_path = fullfile(save_filepath_local, PIV_case_name + "_time_avg.mat");

    if bools.proc_vel
    % wind tunnel properties were not measured for gliding data
    speed = U;
    density = 1.225;

    fields = get_STB_processing_fields();

    % Optional outputs (default on if the caller didn't set them)
    calc_Q_inst = ~isfield(bools, 'Q_inst') || bools.Q_inst;
    calc_vort_uavg = ~isfield(bools, 'vort_uavg') || bools.vort_uavg;

    opts.calc_Q_inst = calc_Q_inst;
    opts.nondim = bools.nondim;
    opts.RPCA = bools.RPCA;

    % Frames are loaded and processed in chunks (one import_STB_data call
    % and one get_wake_lift call per chunk instead of per frame), and the
    % chunks are spread over the parallel workers like the phase bins in
    % phase_avg_STB. Each worker keeps running sums, so memory doesn't grow
    % with the number of frames; each worker holds one chunk's frames at a
    % time, so lower frames_per_chunk (or num_workers) if memory runs out.
    frames_per_chunk = 20;
    if isfield(bools, 'frames_per_chunk') && ~isempty(bools.frames_per_chunk)
        frames_per_chunk = max(1, round(bools.frames_per_chunk));
    end
    if bools.RPCA && frames_per_chunk > 1
        % RPCA runs on the frames of each import_STB_data call, so a chunk
        % would change its result; one frame per call as before
        warning("time_avg_STB:RPCAChunk",...
            "RPCA is on: processing one frame at a time so its result is unchanged")
        frames_per_chunk = 1;
    end
    chunk_starts = 1:frames_per_chunk:num_images;
    num_chunks = numel(chunk_starts);
    chunks = cell(1, num_chunks);
    for c = 1:num_chunks
        chunks{c} = chunk_starts(c):min(chunk_starts(c) + frames_per_chunk - 1, num_images);
    end

    num_workers = 0;
    if isfield(bools, 'num_workers')
        num_workers = bools.num_workers;
    end
    num_workers = start_pool(num_workers);

    % chunks split between the workers (round robin, so the first chunk,
    % which prints the trimmed dimensions, is on worker 1)
    num_groups = max(num_workers, 1);
    chunk_groups = cell(1, num_groups);
    for g = 1:num_groups
        chunk_groups{g} = g:num_groups:num_chunks;
    end

    fprintf("Time average: %d frames in %d chunks of up to %d, %d worker(s)\n",...
        num_images, num_chunks, frames_per_chunk, num_workers);
    disp("Trimming for force calculation only")

    accs = cell(1, num_groups);
    t_loop = tic;
    parfor (g = 1:num_groups, num_workers)
        acc = [];
        for c = chunk_groups{g}
            acc = process_chunk(file_path, U, L, chunks{c}, fields, bounds,...
                speed, density, opts, c == 1, acc);
            fprintf('processed frames %d-%d of %d\n', chunks{c}(1), chunks{c}(end), num_images);
        end
        accs{g} = acc;
    end
    t_loop = toc(t_loop);

    % ----- Combine the workers' running sums -----
    accs = accs(~cellfun(@isempty, accs)); % workers left without a chunk
    x = accs{1}.x; y = accs{1}.y; z = accs{1}.z;
    sums = accs{1}.sum; counts = accs{1}.n;
    if calc_Q_inst
        Q_sums = accs{1}.Q_sum; Q_n = accs{1}.Q_n;
    end
    t_stage = accs{1}.t;
    for g = 2:numel(accs)
        for f = 1:length(fields)
            sums{f} = sums{f} + accs{g}.sum{f};
            counts{f} = counts{f} + accs{g}.n{f};
        end
        if calc_Q_inst
            for k = 1:4
                Q_sums{k} = Q_sums{k} + accs{g}.Q_sum{k};
            end
            Q_n = Q_n + accs{g}.Q_n;
        end
        t_stage = add_times(t_stage, accs{g}.t);
    end

    % Divide each bin's sum by the number of frames that actually had data
    % in that bin (NaN-omitting mean). Dividing by num_images would pull
    % bins with intermittent holes toward zero. Bins with no data in any
    % frame come out NaN and are filled downstream (nanRegionFill).
    for f = 1:length(fields)
        S.(['mean_' fields{f}]) = sums{f} ./ counts{f};
    end
    clear sums counts

    % per-frame lift / drag terms, put back in frame order
    lift_fields = fieldnames(accs{1}.lift);
    drag_fields = fieldnames(accs{1}.drag);
    lift_frames = struct();
    drag_frames = struct();
    for f = 1:length(lift_fields)
        lift_frames.(lift_fields{f}) = NaN(1, num_images);
    end
    for f = 1:length(drag_fields)
        drag_frames.(drag_fields{f}) = NaN(1, num_images);
    end
    lift_vel_frames = NaN(1, num_images); % velocity-only lift (u*w)
    drag_vel_frames = NaN(1, num_images); % velocity-only drag
    for g = 1:numel(accs)
        idx = accs{g}.frames;
        for f = 1:length(lift_fields)
            lift_frames.(lift_fields{f})(idx) = accs{g}.lift.(lift_fields{f});
        end
        for f = 1:length(drag_fields)
            drag_frames.(drag_fields{f})(idx) = accs{g}.drag.(drag_fields{f});
        end
        lift_vel_frames(idx) = accs{g}.lift_vel;
        drag_vel_frames(idx) = accs{g}.drag_vel;
    end
    clear accs

    % Vorticity of the time-averaged velocity (in addition to the average
    % of the per-frame vorticity, mean_vort*)
    if calc_vort_uavg
    t0 = tic;
    [S.mean_vortX_uavg, S.mean_vortY_uavg, S.mean_vortZ_uavg] = vorticity_of_mean_velocity(x, y, z,...
        S.mean_u, S.mean_v, S.mean_w, S.mean_uncU, S.mean_uncV, S.mean_uncW);
    t_stage.vort_uavg = toc(t0);
    end

    % Add metadata to the struct
    S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.rho = density;
    S.PIV_case_name = PIV_case_name;
    S.mean_lift = mean(lift_frames.vortX); S.mean_drag = mean(drag_frames.tot);

    % Q of each frame averaged over all frames (vs Q of the mean field,
    % computed in calc_secondary_vals_time)
    if calc_Q_inst
    S.Qx_inst_avg = Q_sums{1} ./ Q_n;
    S.Qy_inst_avg = Q_sums{2} ./ Q_n;
    S.Qz_inst_avg = Q_sums{3} ./ Q_n;
    S.Q_inst_avg = Q_sums{4} ./ Q_n;
    end

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
    t0 = tic;
    save_STB_struct(save_path, S, bools);
    t_stage.save = toc(t0);

    fprintf('Processing and saving took %.4f seconds.\n', toc);
    if num_workers > 0
        fprintf('  frame loop (%d workers, wall clock): %.1f s; stage times below are summed over workers\n',...
            num_workers, t_loop);
    end
    fprintf(['  load (import_STB_data): %.1f s\n  per-frame forces: %.1f s\n' ...
        '  time avg sums: %.1f s\n  Q_inst_avg: %.1f s\n' ...
        '  vorticity of mean velocity: %.1f s\n  save: %.1f s\n'], ...
        t_stage.import, t_stage.forces, t_stage.stats, t_stage.Q_inst, ...
        t_stage.vort_uavg, t_stage.save);

    calc_secondary_vals_time(S, save_filepath_local, bounds)
    else
    % load in processed velocity field struct from an earlier run
    S = load(save_path);

    % Calculate secondary values (Q, power, integral values) and save in
    % separate file
    calc_secondary_vals_time(S, save_filepath_local, bounds)
    end
end

% Process one chunk of frames and add it to a worker's running totals acc
% ([] on the worker's first chunk): NaN-omitting sums and frame counts of
% every field, per-frame lift / drag (with their frame numbers), and the
% sums of per-frame Q. Runs on a parallel worker.
function acc = process_chunk(file_path, U, L, frames, fields, bounds,...
    speed, density, opts, print_dim_bool, acc)
n = numel(frames);

data = cell(1, length(fields));
t0 = tic;
[x, y, z, data{:}] = import_STB_data(file_path, opts.nondim, U, L, frames, opts.RPCA);
t_import = toc(t0);

if isempty(acc)
    acc.x = x; acc.y = y; acc.z = z;
    grid_size = [size(x,1), size(x,2), size(x,3)];
    acc.sum = repmat({zeros(grid_size)}, 1, length(fields));
    acc.n = repmat({zeros(grid_size)}, 1, length(fields));
    acc.frames = [];
    acc.lift = struct(); acc.drag = struct();
    acc.lift_vel = []; acc.drag_vel = [];
    if opts.calc_Q_inst
        acc.Q_sum = repmat({zeros(grid_size)}, 1, 4);
        acc.Q_n = zeros(grid_size);
    end
    acc.t = struct('import', 0, 'forces', 0, 'stats', 0, 'Q_inst', 0, 'vort_uavg', 0, 'save', 0);
end
acc.t.import = acc.t.import + t_import;

% Forces on each frame (frames along the last dimension)
t0 = tic;
F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, 0, bounds); % trimming
[lift, drag] = get_wake_lift(speed, L, F, true, density);
[lift_vel, drag_vel] = get_wake_lift(speed, L, F, false, density); % velocity only
clear F
acc.frames = [acc.frames, frames(:)'];
acc.lift = append_per_frame(acc.lift, lift, n);
acc.drag = append_per_frame(acc.drag, drag, n);
acc.lift_vel = [acc.lift_vel, per_frame(lift_vel, n)];
acc.drag_vel = [acc.drag_vel, per_frame(drag_vel, n)];
acc.t.forces = acc.t.forces + toc(t0);

% Sums over the frames that have data, per point
t0 = tic;
for f = 1:length(fields)
    valid = ~isnan(data{f});
    acc.sum{f} = acc.sum{f} + sum(data{f}, 4, "omitnan");
    acc.n{f} = acc.n{f} + sum(valid, 4);
end
acc.t.stats = acc.t.stats + toc(t0);

% Q on each instantaneous field; the chunk average times its frame count
% gives the sum, so chunks combine exactly
if opts.calc_Q_inst
    t0 = tic;
    Q_avg = cell(1, 4);
    [Q_avg{:}, ~, ~, ~, ~, Q_n] = inst_Q_avg(data{1}, data{2}, data{3}, x, y, z);
    for k = 1:4
        Q_chunk_sum = Q_avg{k} .* Q_n;
        Q_chunk_sum(Q_n == 0) = 0; % NaN average where no frame had data
        acc.Q_sum{k} = acc.Q_sum{k} + Q_chunk_sum;
    end
    acc.Q_n = acc.Q_n + Q_n;
    acc.t.Q_inst = acc.t.Q_inst + toc(t0);
end
end

% One value per frame from a get_wake_lift output (frames along the last
% dimension; any other dimensions are averaged, as the frame-by-frame
% loop did with mean(..., "all", "omitnan")). Row vector of length n.
function v = per_frame(vals, n)
v = mean(reshape(vals, [], n), 1, "omitnan");
end

% Append one chunk's per-frame values of every lift (or drag) term
function out = append_per_frame(out, terms, n)
names = fieldnames(terms);
for k = 1:numel(names)
    v = per_frame(terms.(names{k}), n);
    if isfield(out, names{k})
        out.(names{k}) = [out.(names{k}), v];
    else
        out.(names{k}) = v;
    end
end
end

function t = add_times(t, t2)
names = fieldnames(t);
for k = 1:numel(names)
    t.(names{k}) = t.(names{k}) + t2.(names{k});
end
end
