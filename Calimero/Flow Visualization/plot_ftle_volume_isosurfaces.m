function plot_ftle_volume_isosurfaces(particle_x0, particle_y0, particle_z0, ...
    ftle_scalar, ftle_iso_percentiles, ftle_face_alpha, plot_title)
%PLOT_FTLE_VOLUME_ISOSURFACES Plot 3D FTLE isosurfaces for one scalar field.

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
title(ax, plot_title)

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
