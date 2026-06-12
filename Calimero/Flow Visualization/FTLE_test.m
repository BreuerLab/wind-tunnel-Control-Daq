clear
close all

filepath = "Y:\Processed Results\phase_avg\flexible_20deg_6Hz_phase_avg.mat";

TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
SOURCE_X_INDEX = 3;

particle_dt = (1 / 6) / 125;
num_particle_timesteps = 125;
plot_seed_stride = [4 4 8]; % [y z x] stride used only for plotting
plot_particle_tracks = true;
if strcmp(getenv("FTLE_DISABLE_PARTICLE_PLOT"), "1")
    plot_particle_tracks = false;
end

vars = {"u_phase_avg", "v_phase_avg", "w_phase_avg", "y", "z",...
        "num_bins", "U", "U_act"};

load(filepath, vars{:})

y = squeeze(y(SOURCE_X_INDEX,:,:));
z = squeeze(z(SOURCE_X_INDEX,:,:));

y_idx = find(y(:,1) > TRIM_Y_BOUNDS(1) & y(:,1) < TRIM_Y_BOUNDS(2));
z_idx = find(z(1,:) > TRIM_Z_BOUNDS(1) & z(1,:) < TRIM_Z_BOUNDS(2));

u_phase_avg = squeeze(u_phase_avg(SOURCE_X_INDEX,y_idx,z_idx,:));
v_phase_avg = squeeze(v_phase_avg(SOURCE_X_INDEX,y_idx,z_idx,:));
w_phase_avg = squeeze(w_phase_avg(SOURCE_X_INDEX,y_idx,z_idx,:));
y = y(y_idx,z_idx);
z = z(y_idx,z_idx);

speed = U_act * U;
% [~, ~, freq] = parse_name(D.PIV_case_name);
freq = 6;
phase_dt = 1 / (freq * num_bins);
x = zeros(1, num_bins);
for k = 1:num_bins
    x(k) =  speed * phase_dt * (k - 1);
end

x_axis = x(:);
y_axis = y(:,1);
z_axis = z(1,:).';

[y_axis, y_sort_idx] = sort(y_axis);
[z_axis, z_sort_idx] = sort(z_axis);
[x_axis, x_sort_idx] = sort(x_axis);

u_phase_avg = u_phase_avg(y_sort_idx,z_sort_idx,x_sort_idx);
v_phase_avg = v_phase_avg(y_sort_idx,z_sort_idx,x_sort_idx);
w_phase_avg = w_phase_avg(y_sort_idx,z_sort_idx,x_sort_idx);

is_inside_volume = @(x_query, y_query, z_query) isfinite(x_query) & ...
    isfinite(y_query) & isfinite(z_query) & ...
    x_query >= min(x_axis) & x_query <= max(x_axis) & ...
    y_query >= min(y_axis) & y_query <= max(y_axis) & ...
    z_query >= min(z_axis) & z_query <= max(z_axis);

[particle_y0, particle_z0, particle_x0] = ndgrid(y_axis, z_axis, x_axis);
grid_size = size(particle_x0);
num_particles = numel(particle_x0);
num_track_steps = num_particle_timesteps + 1;

particle_path_x = NaN(num_particles, num_track_steps);
particle_path_y = NaN(num_particles, num_track_steps);
particle_path_z = NaN(num_particles, num_track_steps);

particle_path_x(:,1) = particle_x0(:);
particle_path_y(:,1) = particle_y0(:);
particle_path_z(:,1) = particle_z0(:);

cur_x = particle_path_x(:,1);
cur_y = particle_path_y(:,1);
cur_z = particle_path_z(:,1);

for step_idx = 1:num_particle_timesteps
    valid_particles = is_inside_volume(cur_x, cur_y, cur_z);

    [k1_x, k1_y, k1_z] = sample_velocity_trilinear(cur_x, cur_y, cur_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    [k2_x, k2_y, k2_z] = sample_velocity_trilinear(cur_x + 0.5 * particle_dt * k1_x, ...
        cur_y + 0.5 * particle_dt * k1_y, cur_z + 0.5 * particle_dt * k1_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    [k3_x, k3_y, k3_z] = sample_velocity_trilinear(cur_x + 0.5 * particle_dt * k2_x, ...
        cur_y + 0.5 * particle_dt * k2_y, cur_z + 0.5 * particle_dt * k2_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    [k4_x, k4_y, k4_z] = sample_velocity_trilinear(cur_x + particle_dt * k3_x, ...
        cur_y + particle_dt * k3_y, cur_z + particle_dt * k3_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    next_x = cur_x + (particle_dt / 6) * (k1_x + 2 * k2_x + 2 * k3_x + k4_x);
    next_y = cur_y + (particle_dt / 6) * (k1_y + 2 * k2_y + 2 * k3_y + k4_y);
    next_z = cur_z + (particle_dt / 6) * (k1_z + 2 * k2_z + 2 * k3_z + k4_z);

    valid_particles = valid_particles & isfinite(next_x) & isfinite(next_y) & isfinite(next_z) & ...
        is_inside_volume(next_x, next_y, next_z);

    cur_x(:) = NaN;
    cur_y(:) = NaN;
    cur_z(:) = NaN;
    cur_x(valid_particles) = next_x(valid_particles);
    cur_y(valid_particles) = next_y(valid_particles);
    cur_z(valid_particles) = next_z(valid_particles);

    particle_path_x(:,step_idx + 1) = cur_x;
    particle_path_y(:,step_idx + 1) = cur_y;
    particle_path_z(:,step_idx + 1) = cur_z;
end

if plot_particle_tracks
    plot_y_idx = 1:max(1, plot_seed_stride(1)):grid_size(1);
    plot_z_idx = 1:max(1, plot_seed_stride(2)):grid_size(2);
    plot_x_idx = 1:max(1, plot_seed_stride(3)):grid_size(3);
    [plot_y_grid, plot_z_grid, plot_x_grid] = ndgrid(plot_y_idx, plot_z_idx, plot_x_idx);
    plot_particle_idx = sub2ind(grid_size, plot_y_grid(:), plot_z_grid(:), plot_x_grid(:));

    figure
    hold on
    grid on
    axis equal
    view(3)
    xlabel("x")
    ylabel("y")
    zlabel("z")
    title("RK4 particle tracks through phase-averaged velocity field")

    for i = 1:numel(plot_particle_idx)
        particle_idx = plot_particle_idx(i);
        valid_track = isfinite(particle_path_x(particle_idx,:)) & ...
            isfinite(particle_path_y(particle_idx,:)) & ...
            isfinite(particle_path_z(particle_idx,:));
        if nnz(valid_track) > 1
            plot3(particle_path_x(particle_idx,valid_track), ...
                particle_path_y(particle_idx,valid_track), ...
                particle_path_z(particle_idx,valid_track), 'LineWidth', 0.75)
        end
    end

    xlim([min(x_axis) max(x_axis)])
    ylim([min(y_axis) max(y_axis)])
    zlim([min(z_axis) max(z_axis)])
end