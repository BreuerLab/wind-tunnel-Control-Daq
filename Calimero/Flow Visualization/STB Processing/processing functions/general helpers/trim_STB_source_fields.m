function T = trim_STB_source_fields(L, y, z, source, print_dim_bool)
if iscell(source)
    source = import_data_to_struct(source);
end

names = fieldnames(source);
[T.y, T.z, T.(names{1})] = trim_vel_field(y, z, source.(names{1}));

for i = 2:numel(names)
    [~, ~, T.(names{i})] = trim_vel_field(y, z, source.(names{i}));
end

if print_dim_bool
% initial dimensions
init_W = round((max(y,[],"all") - min(y,[],"all"))* L * 100);
init_L = round((max(z,[],"all") - min(z,[],"all"))* L * 100);

% final dimensions
fin_W = round((max(T.y,[],"all") - min(T.y,[],"all")) * L * 100);
fin_L = round((max(T.z,[],"all") - min(T.z,[],"all")) * L * 100);

% element-size of matrices
init_size = size(y);
fin_size = size(T.y);

fprintf("Data trimmed from: (%d, %d) to (%d, %d)\n", ...
             init_size(2), init_size(3), fin_size(1), fin_size(2));
fprintf("Data trimmed from: (%d x %d cm) to (%d x %d cm)\n", ...
             init_W, init_L, fin_W, fin_L);
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