clear
close all

filepath = "Y:\Processed Results\phase_avg\flexible_20deg_6Hz_phase_avg.mat";

TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m
SOURCE_X_INDEX = 3;

particle_dt = (1 / 6) / 125;
num_particle_timesteps = 50;
total_step_time = num_particle_timesteps * particle_dt;
particle_seed_stride = [2 2 2]; % [y z x] spacing for FTLE finite differences
plot_seed_stride = [4 4 8]; % [y z x] stride used only for plotting
plot_particle_tracks = true;
plot_ftle_isosurfaces = true;
ftle_iso_percentiles = [90]; % [75 90]
ftle_face_alpha = 0.45;

vars = {"u_phase_avg", "v_phase_avg", "w_phase_avg", "y", "z",...
        "num_bins", "U", "U_act", "L"};

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

u_phase_avg = u_phase_avg * U;
v_phase_avg = v_phase_avg * U;
w_phase_avg = w_phase_avg * U;
y = y * L;
z = z * L;

speed = -U_act * U;
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

x_bounds = [min(x_axis), max(x_axis)];
wrap_x_periodic = @(x_query) wrap_periodic_coordinate(x_query, x_bounds(1), x_bounds(2));

is_inside_volume = @(x_query, y_query, z_query) isfinite(x_query) & ...
    isfinite(y_query) & isfinite(z_query) & ...
    y_query >= min(y_axis) & y_query <= max(y_axis) & ...
    z_query >= min(z_axis) & z_query <= max(z_axis);

% sample particles on a regular lattice so neighboring tracks define the
% central finite differences used for the FTLE flow-map Jacobian
[particle_y0, particle_z0, particle_x0] = ndgrid( ...
    y_axis(1:particle_seed_stride(1):end), ...
    z_axis(1:particle_seed_stride(2):end), ...
    x_axis(1:particle_seed_stride(3):end));
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

    [k1_x, k1_y, k1_z] = sample_velocity_trilinear(wrap_x_periodic(cur_x), cur_y, cur_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k2_sample_x = wrap_x_periodic(cur_x + 0.5 * particle_dt * k1_x);
    [k2_x, k2_y, k2_z] = sample_velocity_trilinear(k2_sample_x, ...
        cur_y + 0.5 * particle_dt * k1_y, cur_z + 0.5 * particle_dt * k1_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k3_sample_x = wrap_x_periodic(cur_x + 0.5 * particle_dt * k2_x);
    [k3_x, k3_y, k3_z] = sample_velocity_trilinear(k3_sample_x, ...
        cur_y + 0.5 * particle_dt * k2_y, cur_z + 0.5 * particle_dt * k2_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k4_sample_x = wrap_x_periodic(cur_x + particle_dt * k3_x);
    [k4_x, k4_y, k4_z] = sample_velocity_trilinear(k4_sample_x, ...
        cur_y + particle_dt * k3_y, cur_z + particle_dt * k3_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    next_x = wrap_x_periodic(cur_x + (particle_dt / 6) * ...
        (k1_x + 2 * k2_x + 2 * k3_x + k4_x));
    next_y = cur_y + (particle_dt / 6) * (k1_y + 2 * k2_y + 2 * k3_y + k4_y);
    next_z = cur_z + (particle_dt / 6) * (k1_z + 2 * k2_z + 2 * k3_z + k4_z);

    valid_particles = valid_particles & is_inside_volume(next_x, next_y, next_z);

    cur_x(:) = NaN;
    cur_y(:) = NaN;
    cur_z(:) = NaN;
    cur_x(valid_particles) = next_x(valid_particles);
    cur_y(valid_particles) = next_y(valid_particles);
    cur_z(valid_particles) = next_z(valid_particles);

    particle_path_x(:,step_idx + 1) = cur_x;
    particle_path_y(:,step_idx + 1) = cur_y;
    particle_path_z(:,step_idx + 1) = cur_z;

    if mod(step_idx, 5) == 0
        disp(step_idx)
    end
end

particle_final_x = reshape(particle_path_x(:,end), grid_size);
particle_final_y = reshape(particle_path_y(:,end), grid_size);
particle_final_z = reshape(particle_path_z(:,end), grid_size);

[ftle_scalar, ftle_max_eigenvalue] = compute_ftle_from_flow_map( ...
    particle_x0, particle_y0, particle_z0, ...
    particle_final_x, particle_final_y, particle_final_z, total_step_time);

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

if plot_ftle_isosurfaces
    plot_ftle_volume_isosurfaces(particle_x0, particle_y0, particle_z0, ...
        ftle_scalar, ftle_iso_percentiles, ftle_face_alpha, total_step_time)
end

function plot_ftle_volume_isosurfaces(particle_x0, particle_y0, particle_z0, ...
    ftle_scalar, ftle_iso_percentiles, ftle_face_alpha, total_step_time)

particle_y_axis = squeeze(particle_y0(:,1,1));
particle_z_axis = squeeze(particle_z0(1,:,1));
particle_x_axis = squeeze(particle_x0(1,1,:));

% meshgrid ordering is (y, x, z), while the FTLE field is stored as (y, z, x).
[X_ftle, Y_ftle, Z_ftle] = meshgrid(particle_x_axis, particle_y_axis, particle_z_axis);
ftle_plot = permute(ftle_scalar, [1 3 2]);
valid_ftle = ftle_plot(isfinite(ftle_plot));

if isempty(valid_ftle)
    warning("No valid FTLE values were available for isosurface plotting.")
    return
end

iso_values = percentile_values(valid_ftle, ftle_iso_percentiles);
iso_values = unique(iso_values(isfinite(iso_values)));
iso_values = iso_values(iso_values > min(valid_ftle) & iso_values < max(valid_ftle));

if isempty(iso_values)
    warning("FTLE isosurface levels were outside the valid scalar-field range.")
    return
end

figure
ax = gca;
hold(ax, "on")
grid(ax, "on")
axis(ax, "equal")
view(ax, 3)
xlabel(ax, "x")
ylabel(ax, "y")
zlabel(ax, "z")
title(ax, sprintf("FTLE isosurfaces, T = %.4g s", total_step_time))

colors = lines(numel(iso_values));
for iso_idx = 1:numel(iso_values)
    iso_value = iso_values(iso_idx);
    surface_data = isosurface(X_ftle, Y_ftle, Z_ftle, ftle_plot, iso_value);
    if isempty(surface_data.vertices) || isempty(surface_data.faces)
        continue
    end

    surface_patch = patch(ax, "Faces", surface_data.faces, ...
        "Vertices", surface_data.vertices);
    surface_patch.FaceColor = colors(iso_idx,:);
    surface_patch.EdgeColor = "none";
    surface_patch.FaceAlpha = ftle_face_alpha;
    surface_patch.DisplayName = sprintf("FTLE = %.4g", iso_value);
    isonormals(X_ftle, Y_ftle, Z_ftle, ftle_plot, surface_patch)
end

legend(ax, "show", "Location", "best")
camlight(ax, "headlight")
lighting(ax, "gouraud")
xlim(ax, [min(particle_x_axis) max(particle_x_axis)])
ylim(ax, [min(particle_y_axis) max(particle_y_axis)])
zlim(ax, [min(particle_z_axis) max(particle_z_axis)])
end

function values = percentile_values(data, percentiles)
data = sort(data(:));
percentiles = min(100, max(0, percentiles(:)));

if isempty(data)
    values = NaN(size(percentiles));
    return
end

rank = 1 + (percentiles / 100) * (numel(data) - 1);
lower_idx = floor(rank);
upper_idx = ceil(rank);
weight = rank - lower_idx;

values = data(lower_idx) .* (1 - weight) + data(upper_idx) .* weight;
values = reshape(values, size(percentiles));
end

function wrapped = wrap_periodic_coordinate(query, lower_bound, upper_bound)
wrapped = query;
period = upper_bound - lower_bound;

if period <= 0 || ~isfinite(period)
    return
end

outside = isfinite(query) & (query < lower_bound | query > upper_bound);
wrapped(outside) = lower_bound + mod(query(outside) - lower_bound, period);
end
