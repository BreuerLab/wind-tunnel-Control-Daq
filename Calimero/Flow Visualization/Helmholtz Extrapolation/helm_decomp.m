function [y_big, z_big, velX, velY, velZ, iy_fov, iz_fov] = helm_decomp(x, y, z, L, D)
% Velocity field induced by the measured phase-averaged vorticity,
% extrapolated beyond the field of view (Helmholtz / Biot-Savart).
%
% The wingbeat is turned into a volume with the frozen-flow assumption
% (bin k sits at x = U t_k). The half-plane data are mirrored about the
% centreline, placed in a zero-padded tunnel-sized cross-section, and the
% velocity is solved on a box that is periodic in all directions: one
% wingbeat repeating up- and downstream (exact for a periodic wake) and
% periodic copies of the wake one tunnel width apart in y and z (an
% approximation of the walls).
%
% x    : frozen-flow position of each bin (m), x = U t, uniformly spaced
%        over one wingbeat (nominal bin times)
% y, z : measured half-plane coordinates (chords, divided by L), y(1) on
%        the centreline (as returned by trim_vel_field)
% L    : chord (m)
% D    : struct with vortX, vortY, vortZ, [ny nz nbins] (omega L / U)
%
% y_big, z_big     : [Ny Nz] grid (chords); the measured points keep their
%                    measured coordinates
% velX, velY, velZ : [nbins Ny Nz] velocity induced by the vorticity, / U.
%                    The freestream is not included (velX is (u + U)/U)
% iy_fov, iz_fov   : indices of the (mirrored) field of view in y_big, z_big

TUNNEL_SIZE = 1.2; % m, test section width and height

% -----------------------------------------
% ----- Reorder to [x y z] ----------------
% -----------------------------------------
vortX = permute(D.vortX, [3 1 2]);
vortY = permute(D.vortY, [3 1 2]);
vortZ = permute(D.vortZ, [3 1 2]);

% -----------------------------------------
% ------------- Mirroring Wake ------------
% -----------------------------------------
% Reflect and skip the first row to avoid double-counting the centerline.
% y -> -y: omega_x and omega_z change sign, omega_y doesn't.
vortX = cat(2, flip(-vortX(:,2:end,:),2), vortX);
vortY = cat(2, flip(vortY(:,2:end,:),2), vortY);
vortZ = cat(2, flip(-vortZ(:,2:end,:),2), vortZ);
[nx, ny, nz] = size(vortX);

% -----------------------------------------
% ---- Grid, all lengths in chords --------
% -----------------------------------------
x = x(:) / L;
dx = x(2) - x(1); % one wingbeat = nx * dx
dy = y(2) - y(1);
dz = z(2) - z(1);

% tunnel-sized cross-section, with the field of view in the middle
Ny = max(round((TUNNEL_SIZE / L) / dy), ny);
Nz = max(round((TUNNEL_SIZE / L) / dz), nz);
iy_fov = floor((Ny - ny) / 2) + (1:ny);
iz_fov = floor((Nz - nz) / 2) + (1:nz);

% coordinates continued from the measured ones: the centreline row (y(1))
% is the middle row of the mirrored data
iy_centre = iy_fov((ny + 1) / 2);
y_arr = y(1) + ((1:Ny)' - iy_centre) * dy;
z_arr = z(1) + ((1:Nz) - iz_fov(1)) * dz;
y_big = repmat(y_arr, [1, Nz]);
z_big = repmat(z_arr, [Ny, 1]);

% -----------------------------------------
% ---- Enlarge fields with emptiness ------
% -----------------------------------------
n_bad = nnz(~isfinite(vortX)) + nnz(~isfinite(vortY)) + nnz(~isfinite(vortZ));
if n_bad > 0
    warning("helm_decomp:nanVorticity", ...
        "%d non-finite vorticity values set to 0 before extrapolating", n_bad)
end
vortX_big = zeros(nx, Ny, Nz);
vortY_big = zeros(nx, Ny, Nz);
vortZ_big = zeros(nx, Ny, Nz);
vortX_big(:, iy_fov, iz_fov) = fillmissing_zero(vortX);
vortY_big(:, iy_fov, iz_fov) = fillmissing_zero(vortY);
vortZ_big(:, iy_fov, iz_fov) = fillmissing_zero(vortZ);
clear vortX vortY vortZ

% -----------------------------------------
% -------- Extrapolate Flowfield ----------
% -----------------------------------------
[velX, velY, velZ] = get_vel_from_vort(dx, dy, dz, vortX_big, vortY_big, vortZ_big);
end

function a = fillmissing_zero(a)
a(~isfinite(a)) = 0;
end
