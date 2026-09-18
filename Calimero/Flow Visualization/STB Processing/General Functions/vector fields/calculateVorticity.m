% Compute vorticity -------------------------------------------------------
function [omega_x, omega_y, omega_z] = calculateVorticity(xRaw,yRaw,zRaw,uRaw,vRaw,wRaw)

% A: ALGORITHM TAKEN FROM RAFFEL'S PIV HANDBOOK
% 6.4 Estimation of Differential Quantities, page 195
[dx, dy, dz] = validateVorticityGrid(xRaw, yRaw, zRaw, uRaw);
validateVorticitySignConvention(dx, dy, dz);

tmp = uRaw;
tmp(tmp == 0) = median(uRaw,"all");
u = tmp;

tmp = vRaw;
tmp(tmp == 0) = median(vRaw,"all");
v = tmp;

tmp = wRaw;
tmp(tmp == 0) = median(wRaw,"all");
w = tmp;

% tmp = uRaw;
% tmp(tmp == 0) = NaN;
% u = tmp;
% 
% tmp = vRaw;
% tmp(tmp == 0) = NaN;
% v = tmp;
% 
% tmp = wRaw;
% tmp(tmp == 0) = NaN;
% w = tmp;
% 
% u = fill3D(u);
% v = fill3D(v);
% w = fill3D(w);

%     C = 1 / (8 * dx * dy);
% 
%     i = 2:size(xRaw,1)-1; 
%     j = 2:size(xRaw,2)-1;
%     k = 1:size(xRaw,3);
% 
%     omega_z(i,j,k) = C * (...
%     -dx * (vRaw(i-1,j-1,k) + 2*vRaw(i,j-1,k) + vRaw(i+1,j-1,k)) ...
%     -dy * (uRaw(i+1,j-1,k) + 2*uRaw(i+1,j,k) + uRaw(i+1,j+1,k)) ...
%     +dx * (vRaw(i+1,j+1,k) + 2*vRaw(i,j+1,k) + vRaw(i-1,j+1,k)) ...
%     +dy * (uRaw(i-1,j+1,k) + 2*uRaw(i-1,j,k) + uRaw(i-1,j-1,k)) ...
% );

[omega_x, omega_y, omega_z] = computeVorticityWithSignedSpacing(u, v, w, dx, dy, dz);

end

function [omega_x, omega_y, omega_z] = computeVorticityWithSignedSpacing(u, v, w, dx, dy, dz)
% 1. Define the kernels. Signed spacing is intentional: STB grids may be
% stored decreasing along a matrix dimension, and curl signs depend on that
% orientation.
Ku = [ -1,   0,  1;
       -2,  0, 2;
       -1,   0,  1 ] * dx;

Kv = [ 1, 2, 1;
        0,    0,    0;
        -1,  -2,  -1 ] * dy;

% kernels flipped since convn flips them again before applying them

% 2. Apply Convolution
% 'same' keeps the output the same size as input.
% convn handles the 3rd dimension (k) automatically by applying 
% the 2D kernel to every slice.
C = 1 / (8 * dx * dy);
omega_z = C * (convn(u, Ku, 'same') + convn(v, Kv, 'same'));

% C = 1 / (8 * dx * dy);
% 
% i = 2:size(xRaw,1)-1; 
% j = 2:size(xRaw,2)-1;
% k = 1:size(xRaw,3);
% 
% omega_z(i,j,k) = C * (...
%             dx*(uRaw(i-1,j-1,k) + 2*uRaw(i,j-1,k) + uRaw(i+1,j-1,k)) ...
%             + dy*(vRaw(i+1,j-1,k) + 2*vRaw(i+1,j,k) + vRaw(i+1,j+1,k)) ...
%             - dx*(uRaw(i+1,j+1,k) + 2*uRaw(i,j+1,k) + uRaw(i-1,j+1,k)) ...
%             - dy*(vRaw(i-1,j+1,k) + 2*vRaw(i-1,j,k) + vRaw(i-1,j-1,k)) ...
% );
% Dont compute the edge vorticity
% C = 1 / (8 * dx * dy);
% for k = 1:size(xRaw,3)
%     for i = 2:size(xRaw,1)-1
%         for j = 2:size(xRaw,2)-1
%             omega_z(i,j,k) = ...
%                 C * ( ...
%                 + dx*(uRaw(i-1,j-1,k) + 2*uRaw(i,j-1,k) + uRaw(i+1,j-1,k)) ...
%                 + dy*(vRaw(i+1,j-1,k) + 2*vRaw(i+1,j,k) + vRaw(i+1,j+1,k)) ...
%                 - dx*(uRaw(i+1,j+1,k) + 2*uRaw(i,j+1,k) + uRaw(i-1,j+1,k)) ...
%                 - dy*(vRaw(i-1,j+1,k) + 2*vRaw(i-1,j,k) + vRaw(i-1,j-1,k)) ...
%                 );
% 
%             % - (1/2)*dx*(vRaw(i-1,j-1,k) + 2*vRaw(i,j-1,k) + vRaw(i+1,j-1,k)) ...
%             %     - (1/2)*dy*(uRaw(i+1,j-1,k) + 2*uRaw(i+1,j,k) + uRaw(i+1,j+1,k)) ...
%             %     + (1/2)*dx*(vRaw(i+1,j+1,k) + 2*vRaw(i,j+1,k) + vRaw(i-1,j+1,k)) ...
%             %     + (1/2)*dy*(uRaw(i-1,j+1,k) + 2*uRaw(i-1,j,k) + uRaw(i-1,j-1,k)) ...
% 
%             % omega_z(i,j) = ((1/2) / (4*dx*dy))*...
%             %     ( ...
%             %     dx*(uRaw(i-1,j-1) + 2*uRaw(i,j-1) + uRaw(i+1,j-1)) ...
%             %     + dy*(vRaw(i+1,j-1) + 2*vRaw(i+1,j) + vRaw(i+1,j+1)) ...
%             %     - dx*(uRaw(i+1,j+1) + 2*uRaw(i,j+1) + uRaw(i-1,j+1)) ...
%             %     - dy*(vRaw(i-1,j+1) + 2*vRaw(i-1,j) + vRaw(i-1,j-1)) ...
%             %     );
%         end
%     end
% end

% We define this as a 3D array: [Rows x Cols x Slices]
% Since k (Cols) doesn't change, the second dimension size is 1.
Kw = zeros(3, 1, 3);
Kw(1, 1, :) = [ -1,  -2,  -1]; % i-1 terms
Kw(2, 1, :) = [0,  0,  0]; % i terms
Kw(3, 1, :) = [ 1,  2, 1]; % i+1 terms
Kw = Kw * dz;

% Kernel for uRaw: Operations on Dim 1 (j) and Dim 3 (i)
Ku = zeros(3, 1, 3);
Ku(:, 1, 3) = [-1, -2,  -1]; % j-1 terms
Ku(:, 1, 2) = [0, 0, 0]; % j terms (middle)
Ku(:, 1, 1) = [1, 2,  1]; % j+1 terms
Ku = Ku * dx;

C = 1 / (8 * dx * dz);
omega_y = C * (convn(w, Kw, 'same') + convn(u, Ku, 'same'));

% C = 1 / (8 * dx * dz);
% 
% i = 2:size(xRaw,3)-1; 
% j = 2:size(xRaw,1)-1;
% k = 1:size(xRaw,2);
% 
% omega_y(j,k,i) = C * (...
%             dz*(wRaw(j-1,k,i-1) + 2*wRaw(j-1,k,i) + wRaw(j-1,k,i+1)) ...
%             + dx*(uRaw(j-1,k,i+1) + 2*uRaw(j,k,i+1) + uRaw(j+1,k,i+1)) ...
%             - dz*(wRaw(j+1,k,i+1) + 2*wRaw(j+1,k,i) + wRaw(j+1,k,i-1)) ...
%             - dx*(uRaw(j+1,k,i-1) + 2*uRaw(j,k,i-1) + uRaw(j-1,k,i-1)) ...
% );

% for k = 1:size(xRaw,2)
%     for i = 2:size(xRaw,1)-1
%         for j = 2:size(xRaw,3)-1
%             omega_z(i,k,j) = ...
%                 ( ...
%                 - (1/2)*dz*(uRaw(i-1,k,j-1) + 2*uRaw(i-1,k,j) + uRaw(i-1,k,j+1)) ...
%                 - (1/2)*dx*(wRaw(i-1,k,j+1) + 2*wRaw(i,k,j+1) + wRaw(i+1,k,j+1)) ...
%                 + (1/2)*dz*(uRaw(i+1,k,j+1) + 2*uRaw(i+1,k,j) + uRaw(i+1,k,j-1)) ...
%                 + (1/2)*dx*(wRaw(i+1,k,j-1) + 2*wRaw(i,k,j-1) + wRaw(i-1,k,j-1)) ...
%                 ) ...
%                 / (4*dx*dy);
%             % - (1/2)*dz*(uRaw(i-1,k,j-1) + 2*uRaw(i,k,j-1) + uRaw(i+1,k,j-1)) ...
%             %     - (1/2)*dx*(wRaw(i+1,k,j-1) + 2*wRaw(i+1,k,j) + wRaw(i+1,k,j+1)) ...
%             %     + (1/2)*dz*(uRaw(i+1,k,j+1) + 2*uRaw(i,k,j+1) + uRaw(i-1,k,j+1)) ...
%             %     + (1/2)*dx*(wRaw(i-1,k,j+1) + 2*wRaw(i-1,k,j) + wRaw(i-1,k,j-1)) ...
%         end
%     end
% end
% elseif (dim == 1)
Kv = zeros(1, 3, 3);
Kv(1, :, 1) = [ -1,  -2,  -1]; % i-1 terms
Kv(1, :, 2) = [0,  0,  0]; % i terms
Kv(1, :, 3) = [ 1,  2, 1]; % i+1 terms
Kv = Kv * dy;

% Kernel for uRaw: Operations on Dim 1 (j) and Dim 3 (i)
Kw = zeros(1, 3, 3);
Kw(1, 3, :) = [-1, -2,  -1]; % j-1 terms
Kw(1, 2, :) = [0, 0, 0]; % j terms (middle)
Kw(1, 1, :) = [1, 2,  1]; % j+1 terms
Kw = Kw * dz;

C = 1 / (8 * dy * dz);
omega_x = C * (convn(v, Kv, 'same') + convn(w, Kw, 'same'));

% C = 1 / (8 * dy * dz);
% 
% i = 2:size(xRaw,2)-1; 
% j = 2:size(xRaw,3)-1;
% k = 1:size(xRaw,1);
% 
% omega_x(k,i,j) = C * (...
%             dy*(vRaw(k,i-1,j-1) + 2*vRaw(k,i,j-1) + vRaw(k,i+1,j-1)) ...
%             + dz*(wRaw(k,i+1,j-1) + 2*wRaw(k,i+1,j) + wRaw(k,i+1,j+1)) ...
%             - dy*(vRaw(k,i+1,j+1) + 2*vRaw(k,i,j+1) + vRaw(k,i-1,j+1)) ...
%             - dz*(wRaw(k,i-1,j+1) + 2*wRaw(k,i-1,j) + wRaw(k,i-1,j-1)) ...
% );

% for k = 1:size(xRaw,1)
%     for i = 2:size(xRaw,2)-1
%         for j = 2:size(xRaw,3)-1
%             omega_z(k,i,j) = ...
%                 ( ...
%                 - (1/2)*dy*(wRaw(k,i-1,j-1) + 2*wRaw(k,i,j-1) + wRaw(k,i+1,j-1)) ...
%                 - (1/2)*dz*(vRaw(k,i+1,j-1) + 2*vRaw(k,i+1,j) + vRaw(k,i+1,j+1)) ...
%                 + (1/2)*dy*(wRaw(k,i+1,j+1) + 2*wRaw(k,i,j+1) + wRaw(k,i-1,j+1)) ...
%                 + (1/2)*dz*(vRaw(k,i-1,j+1) + 2*vRaw(k,i-1,j) + vRaw(k,i-1,j-1)) ...
%                 ) ...
%                 / (4*dy*dz);
%         end
%     end
% end

% NOTE: ADD COMPUTATION OF EDGES (USE MATLAB'S IMPLEMENTATION IN "curl")

% B: Using Matlab's curl function:
% [omega_z, ~] = curl(xRaw, yRaw, uRaw, vRaw);

end

function [dx, dy, dz] = validateVorticityGrid(xRaw, yRaw, zRaw, uRaw)
    if ~isequal(size(xRaw), size(yRaw), size(zRaw), size(uRaw))
        error("Vorticity grid and velocity arrays must have matching sizes.")
    end

    dx = getSignedUniformSpacing(squeeze(xRaw(:,1,1)), "xRaw", "dimension 1");
    dy = getSignedUniformSpacing(squeeze(yRaw(1,:,1)), "yRaw", "dimension 2");
    dz = getSignedUniformSpacing(squeeze(zRaw(1,1,:)), "zRaw", "dimension 3");

    assertNoCrossVariation(xRaw, [2 3], "xRaw");
    assertNoCrossVariation(yRaw, [1 3], "yRaw");
    assertNoCrossVariation(zRaw, [1 2], "zRaw");
end

function spacing = getSignedUniformSpacing(coord, coord_name, dim_name)
    coord = coord(:);
    if numel(coord) < 3
        error(coord_name + " must have at least three points along " + dim_name + " for vorticity calculation.")
    end

    spacing_values = diff(coord);
    spacing = spacing_values(1);
    tolerance = 1e-9 * max(1, max(abs(coord)));

    if abs(spacing) <= tolerance
        error(coord_name + " has zero spacing along " + dim_name + ".")
    end

    if any(sign(spacing_values) ~= sign(spacing))
        error(coord_name + " must be monotonic along " + dim_name + ".")
    end

    if max(abs(spacing_values - spacing)) > tolerance
        error(coord_name + " spacing must be uniform along " + dim_name + ".")
    end
end

function assertNoCrossVariation(coord, invariant_dims, coord_name)
    tolerance = 1e-9 * max(1, max(abs(coord), [], "all"));

    for dim = invariant_dims
        if size(coord, dim) > 1 && max(abs(diff(coord, 1, dim)), [], "all") > tolerance
            error(coord_name + " should vary only along its corresponding matrix dimension.")
        end
    end
end

function validateVorticitySignConvention(dx, dy, dz)
    % Use a linear velocity field with known curl:
    % u = 2y + 3z, v = 5x + 7z, w = 11x + 13y
    % curl(u,v,w) = [13 - 7, 3 - 11, 5 - 2] = [6, -8, 3].
    persistent checked_signatures

    if isempty(checked_signatures)
        checked_signatures = strings(0,1);
    end

    signature = string(sign(dx)) + "_" + string(sign(dy)) + "_" + string(sign(dz));
    if any(checked_signatures == signature)
        return
    end

    grid_size = 5;
    [x, y, z] = ndgrid((0:grid_size-1) * dx, ...
                       (0:grid_size-1) * dy, ...
                       (0:grid_size-1) * dz);

    u = 10 + 2*y + 3*z;
    v = 20 + 5*x + 7*z;
    w = 30 + 11*x + 13*y;

    [omega_x, omega_y, omega_z] = computeVorticityWithSignedSpacing(u, v, w, dx, dy, dz);
    interior = 2:grid_size-1;
    tolerance = 1e-10;

    max_error = max([...
        max(abs(omega_x(interior,interior,interior) - 6), [], "all"), ...
        max(abs(omega_y(interior,interior,interior) + 8), [], "all"), ...
        max(abs(omega_z(interior,interior,interior) - 3), [], "all")]);

    if max_error > tolerance
        error("Vorticity sign convention self-check failed. Check coordinate orientation and kernel signs.")
    end

    checked_signatures(end+1) = signature;
end