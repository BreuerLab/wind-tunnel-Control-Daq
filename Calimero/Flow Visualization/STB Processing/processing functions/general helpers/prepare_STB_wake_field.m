function [F, y_tr, z_tr, T] = prepare_STB_wake_field(y, z, source, x_conv, fill_velocity_nans)
%PREPARE_STB_WAKE_FIELD Trim STB fields and build get_wake_lift input.

if nargin < 4
    x_conv = 0;
end

if nargin < 5
    fill_velocity_nans = false;
end

T = trim_STB_source_fields(y, z, source);

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

if isfield(T, 'unc')
    F.unc = T.unc;
else
    F.unc = T.uncTot;
end
end

function T = trim_STB_source_fields(y, z, source)
if iscell(source)
    source = import_data_to_struct(source);
end

names = fieldnames(source);
[T.y, T.z, T.(names{1})] = trim_vel_field(y, z, source.(names{1}));

for i = 2:numel(names)
    [~, ~, T.(names{i})] = trim_vel_field(y, z, source.(names{i}));
end
end

function S = import_data_to_struct(data)
S.u = data{1};
S.v = data{2};
S.w = data{3};
S.vortX = data{5};
S.vortY = data{6};
S.vortZ = data{7};
S.uncTot = data{12};
end
