function [ftle_scalar, max_eigenvalue] = compute_ftle_from_flow_map( ...
    initial_x, initial_y, initial_z, final_x, final_y, final_z, total_step_time)
%COMPUTE_FTLE_FROM_FLOW_MAP Calculate FTLE from an initial/final flow map.
% Initial and final coordinates are stored on a regular particle lattice with
% dimensions (y, z, x). The returned fields use the same ordering.

if total_step_time <= 0 || ~isfinite(total_step_time)
    error("total_step_time must be a positive finite scalar.")
end

grid_size = array_size_3d(initial_x);
if ~isequal(grid_size, array_size_3d(initial_y), array_size_3d(initial_z), ...
        array_size_3d(final_x), array_size_3d(final_y), array_size_3d(final_z))
    error("Initial and final particle-coordinate arrays must have matching sizes.")
end

ftle_scalar = NaN(grid_size);
max_eigenvalue = NaN(grid_size);

if any(grid_size < 3)
    return
end

interior_y = 2:(grid_size(1) - 1);
interior_z = 2:(grid_size(2) - 1);
interior_x = 2:(grid_size(3) - 1);

dx0 = initial_x(interior_y,interior_z,interior_x + 1) - ...
    initial_x(interior_y,interior_z,interior_x - 1);
dy0 = initial_y(interior_y + 1,interior_z,interior_x) - ...
    initial_y(interior_y - 1,interior_z,interior_x);
dz0 = initial_z(interior_y,interior_z + 1,interior_x) - ...
    initial_z(interior_y,interior_z - 1,interior_x);

dxdx0 = central_difference(final_x, interior_y, interior_z, interior_x, 3, dx0);
dxdy0 = central_difference(final_x, interior_y, interior_z, interior_x, 1, dy0);
dxdz0 = central_difference(final_x, interior_y, interior_z, interior_x, 2, dz0);

dydx0 = central_difference(final_y, interior_y, interior_z, interior_x, 3, dx0);
dydy0 = central_difference(final_y, interior_y, interior_z, interior_x, 1, dy0);
dydz0 = central_difference(final_y, interior_y, interior_z, interior_x, 2, dz0);

dzdx0 = central_difference(final_z, interior_y, interior_z, interior_x, 3, dx0);
dzdy0 = central_difference(final_z, interior_y, interior_z, interior_x, 1, dy0);
dzdz0 = central_difference(final_z, interior_y, interior_z, interior_x, 2, dz0);

valid_gradient = isfinite(dxdx0) & isfinite(dxdy0) & isfinite(dxdz0) & ...
    isfinite(dydx0) & isfinite(dydy0) & isfinite(dydz0) & ...
    isfinite(dzdx0) & isfinite(dzdy0) & isfinite(dzdz0);

valid_idx = find(valid_gradient);
for idx = valid_idx(:).'
    jacobian = [dxdx0(idx), dxdy0(idx), dxdz0(idx); ...
                dydx0(idx), dydy0(idx), dydz0(idx); ...
                dzdx0(idx), dzdy0(idx), dzdz0(idx)];
    cauchy_green = jacobian.' * jacobian;
    lambda_max = max(real(eig(cauchy_green)));

    if lambda_max > 0 && isfinite(lambda_max)
        [local_y, local_z, local_x] = ind2sub(size(valid_gradient), idx);
        field_y = local_y + 1;
        field_z = local_z + 1;
        field_x = local_x + 1;

        max_eigenvalue(field_y,field_z,field_x) = lambda_max;
        ftle_scalar(field_y,field_z,field_x) = log(lambda_max) / (2 * total_step_time);
    end
end
end

function derivative = central_difference(field, interior_y, interior_z, interior_x, dimension, denominator)
switch dimension
    case 1
        numerator = field(interior_y + 1,interior_z,interior_x) - ...
            field(interior_y - 1,interior_z,interior_x);
    case 2
        numerator = field(interior_y,interior_z + 1,interior_x) - ...
            field(interior_y,interior_z - 1,interior_x);
    case 3
        numerator = field(interior_y,interior_z,interior_x + 1) - ...
            field(interior_y,interior_z,interior_x - 1);
    otherwise
        error("dimension must be 1, 2, or 3.")
end

derivative = numerator ./ denominator;
derivative(~isfinite(derivative)) = NaN;
end

function grid_size = array_size_3d(array)
grid_size = size(array);
if numel(grid_size) < 3
    grid_size(3) = 1;
end
end
