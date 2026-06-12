function plot_particle_tracks_3d(particle_path_x, particle_path_y, particle_path_z, ...
    grid_size, plot_seed_stride, x_axis, y_axis, z_axis, plot_title)
%PLOT_PARTICLE_TRACKS_3D Plot a strided subset of integrated particle paths.

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
title(plot_title)

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
