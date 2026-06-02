function [y, z, u] = trim_vel_field(y, z, u)

    ybounds = [-2.7 2]; % roughly -0.15 to 0.15 meters
    zbounds = [-2.36 2.55]; % roughly -0.2 to 0.2 meters

    y_cen = -2.26;
    z_cen = 0.043;
    
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