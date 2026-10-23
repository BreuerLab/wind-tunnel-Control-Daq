function [y, z, u] = trim_vel_field(y, z, u, bounds)
    % bounds: struct with the trim limits and center point, all
    % nondimensional (divided by L):
    %   bounds.ybounds = [ymin ymax], bounds.zbounds = [zmin zmax]
    %   bounds.y_cen, bounds.z_cen (data is shifted so these become 0)
    % Defined at the entry points (process_case and the STB UIs).

    ybounds = bounds.ybounds;
    zbounds = bounds.zbounds;
    y_cen = bounds.y_cen;
    z_cen = bounds.z_cen;
    
    x_ind = 3;
    y_idx = find(y(1,:,1) > ybounds(1) & y(1,:,1) < ybounds(2));  % columns
    z_idx = find(z(1,1,:) > zbounds(1) & z(1,1,:) < zbounds(2));  % rows
    
    y = y(x_ind, y_idx, z_idx);
    z = z(x_ind, y_idx, z_idx);

    u = squeeze(u(x_ind, y_idx, z_idx,:));

    % First trim data about center point
    y_idx = find(y(1,:,1) >= y_cen);  % columns

    y = y - y_cen;
    z = z - z_cen;

    y = squeeze(y(:, y_idx, :));
    z = squeeze(z(:, y_idx, :));

    u = u(y_idx, :, :);
end