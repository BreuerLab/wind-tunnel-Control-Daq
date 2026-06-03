% Trim STB fields and build get_wake_lift input.
function [F, y_tr, z_tr, T] = prepare_STB_wake_field(L, y, z, print_dim_bool, source, x_conv, fill_velocity_nans)

if nargin < 7
    fill_velocity_nans = false;
end

T = trim_STB_source_fields(L, y, z, source, print_dim_bool);

if fill_velocity_nans
    T.u = nanToMedian(T.u);
    T.v = nanToMedian(T.v);
    T.w = nanToMedian(T.w);
end

y_tr = T.y;
z_tr = T.z;

F.x = x_conv; F.y = y_tr; F.z = z_tr;
F.u = T.u; F.v = T.v; F.w = T.w;
F.vortX = T.vortX; F.vortY = T.vortY; F.vortZ = T.vortZ;
end
