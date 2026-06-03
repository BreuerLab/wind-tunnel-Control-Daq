function [y_big, z_big, velX, velY, velZ] = helm_decomp(x, y, z, L, D)
% -----------------------------------------
% ----- Reorder and resize matrices -------
% -----------------------------------------
vortX = permute(D.vortX, [3 1 2]);
vortY = permute(D.vortY, [3 1 2]);
vortZ = permute(D.vortZ, [3 1 2]);
u = permute(D.u, [3 1 2]);

x = repmat(x', [1, size(vortX,2), size(vortX,3)]);
y = repmat(y', [size(vortX,1), 1, size(vortX,3)]);
z = repmat(reshape(z, [1 1 length(z)]), [size(vortX,1), size(vortX,2), 1]);

% -----------------------------------------
% ------------- Mirroring Wake ------------
% -----------------------------------------

% Reflect and skip the first row to avoid double-counting the centerline.
x_add = flip(x(:,2:end,:),2);
y_add = flip(-y(:,2:end,:),2); % INVERSION
z_add = flip(z(:,2:end,:),2);

vortX_add = flip(-vortX(:,2:end,:),2);
vortY_add = flip(vortY(:,2:end,:),2); % NO INVERSION
vortZ_add = flip(-vortZ(:,2:end,:),2);

u_add = flip(u(:,2:end,:),2);

x = cat(2, x_add, x);
y = cat(2, y_add, y);
z = cat(2, z_add, z);
vortX = cat(2, vortX_add, vortX);
vortY = cat(2, vortY_add, vortY); 
vortZ = cat(2, vortZ_add, vortZ);
u = cat(2, u_add, u);

% -----------------------------------------
% ---- Enlarge fields with emptiness ------
% -----------------------------------------
dy = y(1,2,1) - y(1,1,1);
dz = z(1,1,2) - z(1,1,1);
Ny = round((1.2 / L) / dy);
Nz = round((1.2 / L) / dz);
start_y = floor((Ny - size(x,2)) / 2) + 1;
start_z = floor((Nz - size(x,3)) / 2) + 1;

vortX_extra = zeros(size(x,1), Ny, Nz);
vortY_extra = zeros(size(x,1), Ny, Nz);
vortZ_extra = zeros(size(x,1), Ny, Nz);

vortX_extra(:, start_y:start_y + size(x,2) - 1, start_z:start_z + size(x,3) - 1) = vortX;
vortY_extra(:, start_y:start_y + size(x,2) - 1, start_z:start_z + size(x,3) - 1) = vortY;
vortZ_extra(:, start_y:start_y + size(x,2) - 1, start_z:start_z + size(x,3) - 1) = vortZ;

x_arr = squeeze(x(:,1,1));
y_arr = -(Ny/2)*dy:dy:(Ny/2 - 1)*dy;
z_arr = -(Nz/2)*dz:dz:(Nz/2 - 1)*dz;

y_big = repmat(y_arr', [1, length(z_arr)]);
z_big = repmat(z_arr, [length(y_arr), 1]);

% -----------------------------------------
% -------- Extrapolate Flowfield ----------
% -----------------------------------------
[velX, velY, velZ] = get_vel_from_vort(x_arr, y_arr, z_arr, vortX_extra, vortY_extra, vortZ_extra);

% Compare with measured flowfield
% velX_tr = velX(:,y_arr >= min(y,[],"all") & y_arr <= max(y,[],"all"), z_arr >= min(z,[],"all") & z_arr <= max(z,[],"all"));
% velY_tr = velY(:,y_arr >= min(y,[],"all") & y_arr <= max(y,[],"all"), z_arr >= min(z,[],"all") & z_arr <= max(z,[],"all"));
% velZ_tr = velZ(:,y_arr >= min(y,[],"all") & y_arr <= max(y,[],"all"), z_arr >= min(z,[],"all") & z_arr <= max(z,[],"all"));
% 
% params.clims = [-0.1 0.1];
% params.zero = 0;
% params.cb_lab = "u/U";
% 
% p_y = squeeze(y(1,:,2:end));
% p_z = squeeze(z(1,:,2:end));
% p_u = squeeze(u(1,:,2:end));
% p_u = p_u + 1;
% 
% figure
% ax = gca;
% PIV_plot(y_big, z_big, squeeze(velX(1,:,:)), params, ax);
% 
% figure
% ax = gca;
% PIV_plot(p_y, p_z, squeeze(velX_tr(1,:,:)), params, ax);
% 
% figure
% ax = gca;
% PIV_plot(p_y, p_z, p_u, params, ax);
end