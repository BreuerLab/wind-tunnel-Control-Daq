function [u_query, v_query, w_query] = sample_velocity_trilinear(x_query, y_query, z_query, ...
    x_axis, y_axis, z_axis, u_field, v_field, w_field)

query_size = size(x_query);
x_query = x_query(:);
y_query = y_query(:);
z_query = z_query(:);

u_query = NaN(size(x_query));
v_query = NaN(size(x_query));
w_query = NaN(size(x_query));

x_axis = x_axis(:);
y_axis = y_axis(:);
z_axis = z_axis(:);

in_bounds = isfinite(x_query) & isfinite(y_query) & isfinite(z_query) & ...
    x_query >= x_axis(1) & x_query <= x_axis(end) & ...
    y_query >= y_axis(1) & y_query <= y_axis(end) & ...
    z_query >= z_axis(1) & z_query <= z_axis(end);

if ~any(in_bounds)
    u_query = reshape(u_query, query_size);
    v_query = reshape(v_query, query_size);
    w_query = reshape(w_query, query_size);
    return
end

valid_idx = find(in_bounds);
[x_idx, x_weight] = get_axis_cell(x_axis, x_query(valid_idx));
[y_idx, y_weight] = get_axis_cell(y_axis, y_query(valid_idx));
[z_idx, z_weight] = get_axis_cell(z_axis, z_query(valid_idx));

u_query(valid_idx) = interpolate_component(u_field, y_idx, z_idx, x_idx, ...
    y_weight, z_weight, x_weight);
v_query(valid_idx) = interpolate_component(v_field, y_idx, z_idx, x_idx, ...
    y_weight, z_weight, x_weight);
w_query(valid_idx) = interpolate_component(w_field, y_idx, z_idx, x_idx, ...
    y_weight, z_weight, x_weight);

u_query = reshape(u_query, query_size);
v_query = reshape(v_query, query_size);
w_query = reshape(w_query, query_size);
end

function [idx, weight] = get_axis_cell(axis_values, query_values)
idx = interp1(axis_values, 1:numel(axis_values), query_values, 'previous', NaN);
idx = max(1, min(numel(axis_values) - 1, idx));
next_idx = idx + 1;
weight = (query_values - axis_values(idx)) ./ (axis_values(next_idx) - axis_values(idx));
end

function values = interpolate_component(field, y_idx, z_idx, x_idx, y_weight, z_weight, x_weight)
field_size = size(field);

c000 = field(sub2ind(field_size, y_idx,     z_idx,     x_idx));
c100 = field(sub2ind(field_size, y_idx + 1, z_idx,     x_idx));
c010 = field(sub2ind(field_size, y_idx,     z_idx + 1, x_idx));
c110 = field(sub2ind(field_size, y_idx + 1, z_idx + 1, x_idx));
c001 = field(sub2ind(field_size, y_idx,     z_idx,     x_idx + 1));
c101 = field(sub2ind(field_size, y_idx + 1, z_idx,     x_idx + 1));
c011 = field(sub2ind(field_size, y_idx,     z_idx + 1, x_idx + 1));
c111 = field(sub2ind(field_size, y_idx + 1, z_idx + 1, x_idx + 1));

c00 = c000 .* (1 - y_weight) + c100 .* y_weight;
c10 = c010 .* (1 - y_weight) + c110 .* y_weight;
c01 = c001 .* (1 - y_weight) + c101 .* y_weight;
c11 = c011 .* (1 - y_weight) + c111 .* y_weight;

c0 = c00 .* (1 - z_weight) + c10 .* z_weight;
c1 = c01 .* (1 - z_weight) + c11 .* z_weight;

values = c0 .* (1 - x_weight) + c1 .* x_weight;
end
