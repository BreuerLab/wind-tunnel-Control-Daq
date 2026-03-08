function [s,cData] = stack_vortices_3D(x, y, C_phase_avg, Q_phase_avg, wing_freq, params)
%% trim data (if trimmed before calculating Q, Q-isosurfaces always exist at
% boundaries)

xbounds = [-2.4 2.4]; % roughly -0.15 to 0.15 meters
ybounds = [-2.1 2.3]; % roughly -0.2 to 0.2 meters

x_idx = find(x(:,1) > xbounds(1) & x(:,1) < xbounds(2));  % columns
y_idx = find(y(1,:) > ybounds(1) & y(1,:) < ybounds(2));  % rows

x = x(x_idx, y_idx);
y = y(x_idx, y_idx);
C_phase_avg = C_phase_avg(x_idx,y_idx,:);
Q_phase_avg = Q_phase_avg(x_idx,y_idx,:);

%%
if params.mirror
% Mirror in x-direction across y-axis at centerpoint of robot/ellipse

% First trim data about center point
x_cen = -0.142 / params.L;

x_idx = find(x(:,1) > x_cen);  % columns

x = x(x_idx, :);
y = y(x_idx, :);
C_phase_avg = C_phase_avg(x_idx,:,:);
Q_phase_avg = Q_phase_avg(x_idx,:,:);

% shift axis so that min point is now considered as origin
x = x - min(x, [], "all");

% Now reflect data
% x goes from positive to negative from left to right
x_add = flip(-x,1);
y_add = flip(y,1);
C_add = flip(-C_phase_avg,1);
Q_add = flip(Q_phase_avg,1);

% trimming 2:end to exclude double counting of zero
x = [x_add(1:end-1, :); x];
y = [y_add(1:end-1,:); y];
C_phase_avg = [C_add(1:end-1,:,:); C_phase_avg];
Q_phase_avg = [Q_add(1:end-1,:,:); Q_phase_avg];
end
% ------------------------------------------------------------------

% ------------------------------------------------------------------
% Use frozen flow assumption, i.e. convection of vortices, to get z-axis
wind_speed = 4;
dt = 1 / (wing_freq * params.num_bins);
z = zeros(1, params.num_bins);
for k = 1:params.num_bins
    z(k) =  wind_speed * dt * (k - 1);
end
z = z / params.L; % non-dimensionalize z by characterisitic length

% normalize by wingbeat period
z = z / max(z);

[Ny, Nx] = size(x);
Nz = length(z);

% ------------------------------------------------------------------

% Replicate along z
X = repmat(x, [1 1 Nz]);       % Ny x Nx x Nz
Y = repmat(y, [1 1 Nz]);       % Ny x Nx x Nz
Z = repmat(reshape(z, [1 1 Nz]), [Ny Nx 1]); % Ny x Nx x Nz

Q_phase_avg_s = circshift(squeeze(Q_phase_avg), [0 0 params.shift]);  % shift along the 3rd dimension (Z)
C_phase_avg_s = circshift(squeeze(C_phase_avg), [0 0 params.shift]);  % shift along the 3rd dimension (Z)

% Shuffle axes so that 3D plot is easier to rotate
Q2 = permute(Q_phase_avg_s, [1 3 2]);
C2 = permute(C_phase_avg_s, [1 3 2]);

% I want Z-axis to become x-axis on new plot, and Y to replace Z

% X2 = permute(X, [3 1 2]);
% Y2 = permute(Y, [3 1 2]);
% Z2 = permute(Z, [3 1 2]); 

xv = squeeze(X(:,1,1));    % Nx
yv = squeeze(Y(1,:,1));    % Ny
zv = squeeze(Z(1,1,:));    % Nz
[Z2, X2, Y2] = meshgrid(zv, xv, yv);

% X_fin = X; Y_fin = Y; Z_fin = Z; Q_fin = Q_phase_avg_s; C_fin = C_phase_avg_s;
X_fin = X2; Y_fin = Y2; Z_fin = Z2; Q_fin = Q2; C_fin = C2;

if params.num_cycles > 1   
%% Stack 3 wingbeats together

z_step = max(Z_fin(1,:,1)) + (Z_fin(1,2,1) - Z_fin(1,1,1));
rep_n = params.num_cycles;

% Repeat data along 3rd dimension
X_big = repmat(X_fin, [1, rep_n, 1]);
Y_big = repmat(Y_fin, [1, rep_n, 1]);
Z_big = repmat(Z_fin, [1, rep_n, 1]);
Q_big = repmat(Q_fin, [1, rep_n, 1]);
C_big = repmat(C_fin, [1, rep_n, 1]);

offsets = repelem((0:rep_n-1) * z_step, 1, size(Z_fin,2));

% Apply the offsets using implicit expansion
% Z_big is [100 x (75*N) x 20], offsets is [1 x (75*N)]
Z_big = Z_big + offsets;

% Q_big = circshift(Q_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
% C_big = circshift(C_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)

X_fin = X_big; Y_fin = Y_big; Z_fin = Z_big; Q_fin = Q_big; C_fin = C_big;
end

%% Interpolate onto finer scale
if params.movie
% choose upsampling factor
factor = 5;  % try 2 or 3

% original sizes
[Ny, Nx] = size(x);
Nz = length(z);

% Create finer grids
xq = linspace(min(x(:)), max(x(:)), Nx*factor);
yq = linspace(min(y(:)), max(y(:)), Ny*factor);
zq = linspace(min(z(:)), max(z(:)), Nz*factor);
dz = zq(2) - zq(1);
zq = zq + dz; % trim off leading 0 so that diff is constant of zq_big

[Xq, Yq, Zq] = meshgrid(xq, yq, zq);

% Interpolate Q and vorticity onto fine grid
Q_fine = interp3(X, Y, Z, Q_phase_avg, Xq, Yq, Zq, 'linear');
C_fine = interp3(X, Y, Z, C_phase_avg, Xq, Yq, Zq, 'linear');

%% Stack 3 wingbeats together

% Repeat Z coordinates
zq_big = [zq, zq + max(zq), zq + 2*max(zq)];

% Repeat data along 3rd dimension
Q_big    = cat(3, Q_fine,    Q_fine,    Q_fine);
C_big = cat(3, C_fine, C_fine, C_fine);

Q_big = circshift(Q_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
C_big = circshift(C_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)

% Make a bigger grid using ndgrid
[X_big, Y_big, Z_big] = meshgrid(xq, yq, zq_big);

X_fin = X_big; Y_fin = Y_big; Z_fin = Z_big; Q_fin = Q_big; C_fin = C_big;
end

% Extract isosurface from larger volume
if params.movie
    s = isosurface(X_fin, Y_fin, Z_fin, Q_fin, params.isoValue);
    cData = interp3(X_fin, Y_fin, Z_fin, C_fin, ...
                s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
else
    s = isosurface(Z_fin, X_fin, Y_fin, Q_fin, params.isoValue);
    cData = interp3(Z_fin, X_fin, Y_fin, C_fin, ...
                 s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
    % s = isosurface(X_fin, Y_fin, Z_fin, Q_fin, params.isoValue);
    % cData = interp3(X_fin, Y_fin, Z_fin, C_fin, ...
    %              s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
    % s = isosurface(Y_fin, X_fin, Z_fin, Q_fin, params.isoValue);
    % cData = interp3(Y_fin, X_fin, Z_fin, C_fin, ...
    %              s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
end
end