% Compute vorticity -------------------------------------------------------
function [omega_x, omega_y, omega_z] = calculateVorticity(xRaw,yRaw,zRaw,uRaw,vRaw,wRaw)

% A: ALGORITHM TAKEN FROM RAFFEL'S PIV HANDBOOK
% 6.4 Estimation of Differential Quantities, page 195
omega_x = nan(size(uRaw));
omega_y = nan(size(uRaw));
omega_z = nan(size(uRaw));

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

dx = abs(xRaw(2,1,1) - xRaw(1,1,1));
dy = abs(yRaw(1,2,1) - yRaw(1,1,1));
dz = abs(zRaw(1,1,2) - zRaw(1,1,1));

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

% 1. Define the Kernels
% Note: In MATLAB convolution, the kernel is effectively "flipped" 
% during the operation, but for symmetric stencils like this, 
% we just map the coefficients directly.

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