clear variables
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
integration_step_times = [total_step_time, -total_step_time];
integration_labels = {'Forward', 'Backward'};
ftle_results = struct([]);

for direction_idx = 1:numel(integration_step_times)
    integration_step_time = integration_step_times(direction_idx);
    step_dt = sign(integration_step_time) * particle_dt;
    direction_label = integration_labels{direction_idx};

    fprintf("%s FTLE integration, T = %.4g s\n", direction_label, integration_step_time)
    [particle_path_x, particle_path_y, particle_path_z, ...
        particle_final_x, particle_final_y, particle_final_z] = trace_particles_rk4( ...
        particle_x0, particle_y0, particle_z0, num_particle_timesteps, step_dt, ...
        is_inside_volume, wrap_x_periodic, x_axis, y_axis, z_axis, ...
        u_phase_avg, v_phase_avg, w_phase_avg);

    [ftle_scalar, ftle_max_eigenvalue] = compute_ftle_from_flow_map( ...
        particle_x0, particle_y0, particle_z0, ...
        particle_final_x, particle_final_y, particle_final_z, abs(integration_step_time));

    ftle_results(direction_idx).label = direction_label;
    ftle_results(direction_idx).total_step_time = integration_step_time;
    ftle_results(direction_idx).particle_path_x = particle_path_x;
    ftle_results(direction_idx).particle_path_y = particle_path_y;
    ftle_results(direction_idx).particle_path_z = particle_path_z;
    ftle_results(direction_idx).particle_final_x = particle_final_x;
    ftle_results(direction_idx).particle_final_y = particle_final_y;
    ftle_results(direction_idx).particle_final_z = particle_final_z;
    ftle_results(direction_idx).ftle_scalar = ftle_scalar;
    ftle_results(direction_idx).ftle_max_eigenvalue = ftle_max_eigenvalue;

    if plot_particle_tracks
        plot_particle_tracks_3d(particle_path_x, particle_path_y, particle_path_z, ...
            grid_size, plot_seed_stride, x_axis, y_axis, z_axis, ...
            sprintf("%s RK4 particle tracks, T = %.4g s", direction_label, integration_step_time))
    end

    if plot_ftle_isosurfaces
        plot_ftle_volume_isosurfaces(particle_x0, particle_y0, particle_z0, ...
            ftle_scalar, ftle_iso_percentiles, ftle_face_alpha, ...
            sprintf("%s FTLE isosurfaces, T = %.4g s", direction_label, integration_step_time))
    end
end

if plot_ftle_isosurfaces
    particle_y_axis = squeeze(particle_y0(:,1,1));
    particle_z_axis = squeeze(particle_z0(1,:,1));
    particle_x_axis = squeeze(particle_x0(1,1,:));

    % meshgrid ordering is (y, x, z), while the FTLE fields are stored as (y, z, x).
    [X_ftle, Y_ftle, Z_ftle] = meshgrid(particle_x_axis, particle_y_axis, particle_z_axis);

    figure
    ax = gca;
    hold(ax, "on")
    grid(ax, "on")
    axis(ax, "equal")
    view(ax, 3)
    xlabel(ax, "x")
    ylabel(ax, "y")
    zlabel(ax, "z")
    title(ax, "Forward and Backward FTLE isosurface comparison")

    comparison_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980]; % blue, orange
    num_plotted_surfaces = 0;
    for direction_idx = 1:numel(ftle_results)
        ftle_plot = permute(ftle_results(direction_idx).ftle_scalar, [1 3 2]);
        valid_ftle = ftle_plot(isfinite(ftle_plot));

        if isempty(valid_ftle)
            warning("%s FTLE has no valid values for comparison isosurface plotting.", ...
                ftle_results(direction_idx).label)
            continue
        end

        iso_values = percentile_values(valid_ftle, ftle_iso_percentiles);
        iso_values = unique(iso_values(isfinite(iso_values)));
        iso_values = iso_values(iso_values > min(valid_ftle) & iso_values < max(valid_ftle));

        if isempty(iso_values)
            warning("%s FTLE comparison isosurface levels were outside the valid scalar-field range.", ...
                ftle_results(direction_idx).label)
            continue
        end

        surface_color = comparison_colors(direction_idx,:);
        for iso_idx = 1:numel(iso_values)
            iso_value = iso_values(iso_idx);
            surface_data = isosurface(X_ftle, Y_ftle, Z_ftle, ftle_plot, iso_value);
            if isempty(surface_data.vertices) || isempty(surface_data.faces)
                continue
            end

            surface_patch = patch(ax, "Faces", surface_data.faces, ...
                "Vertices", surface_data.vertices);
            set(surface_patch, "FaceColor", surface_color, ...
                "EdgeColor", "none", ...
                "FaceAlpha", ftle_face_alpha, ...
                "DisplayName", sprintf("%s FTLE = %.4g", ftle_results(direction_idx).label, iso_value));
            isonormals(X_ftle, Y_ftle, Z_ftle, ftle_plot, surface_patch)
            num_plotted_surfaces = num_plotted_surfaces + 1;
        end
    end

    if num_plotted_surfaces > 0
        legend(ax, "show")
    end
    camlight(ax, "headlight")
    lighting(ax, "gouraud")
    xlim(ax, [min(particle_x_axis) max(particle_x_axis)])
    ylim(ax, [min(particle_y_axis) max(particle_y_axis)])
    zlim(ax, [min(particle_z_axis) max(particle_z_axis)])
end

forward_ftle_scalar = ftle_results(1).ftle_scalar;
forward_ftle_max_eigenvalue = ftle_results(1).ftle_max_eigenvalue;
backward_ftle_scalar = ftle_results(2).ftle_scalar;
backward_ftle_max_eigenvalue = ftle_results(2).ftle_max_eigenvalue;
