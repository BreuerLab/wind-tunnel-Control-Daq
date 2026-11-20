% Trim STB fields and build get_wake_lift input.
function [F, y_tr, z_tr, T] = prepare_STB_wake_field(L, y, z, print_dim_bool, source, x_conv, bounds, fill_velocity_nans)
% bounds: trim limits and center point passed on to trim_vel_field

if nargin < 8
    fill_velocity_nans = false;
end

T = trim_STB_source_fields(L, y, z, source, print_dim_bool, bounds);

if fill_velocity_nans
    % Laplace interpolation of holes, plane by plane (was a global median)
    T.u = nanRegionFill(T.u);
    T.v = nanRegionFill(T.v);
    T.w = nanRegionFill(T.w);
end

y_tr = T.y;
z_tr = T.z;

F.x = x_conv; F.y = y_tr; F.z = z_tr;
F.u = T.u; F.v = T.v; F.w = T.w;
F.vortX = T.vortX; F.vortY = T.vortY; F.vortZ = T.vortZ;
F.unc = T.uncTot;
end
