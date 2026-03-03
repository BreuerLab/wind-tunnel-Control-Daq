function stack_vortices_3D(x, y, z, C_phase_avg, Q_phase_avg, wing_freq, params)
% ------------------------------------------------------------------
mirror_bool = true;
if mirror_bool
% Mirror in x-direction across y-axis at centerpoint of robot/ellipse

% First trim data about center point
x_cen = -0.142 / params.L;

x_idx = find(x(1,:) > x_cen);  % columns

x = x(:, x_idx);
y = y(:, x_idx);
C_phase_avg = C_phase_avg(:, x_idx,:);
Q_phase_avg = Q_phase_avg(:, x_idx,:);

% shift axis so that min point is now considered as origin
x = x - min(x, [], "all");

% Now reflect data
% x goes from positive to negative from left to right
x_add = flip(-x,2);
y_add = flip(y,2);
C_add = flip(-C_phase_avg,2);
Q_add = flip(Q_phase_avg,2);

% trimming 2:end to exclude double counting of zero
x = [x x_add(:,2:end)];
y = [y y_add(:,2:end)];
C_phase_avg = [C_phase_avg C_add(:,2:end,:)];
Q_phase_avg = [Q_phase_avg Q_add(:,2:end,:)];
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

Q_phase_avg_s = circshift(Q_phase_avg, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
C_phase_avg_s = circshift(C_phase_avg, [0 0 params.shift]);  % shift along the 3rd dimension (Z)

% Shuffle axes so that 3D plot is easier to rotate
Q2 = permute(Q_phase_avg_s, [2 3 1]);
C2 = permute(C_phase_avg_s, [2 3 1]);

xv = squeeze(X(1,:,1));    % Nx
yv = squeeze(Y(:,1,1));    % Ny
zv = squeeze(Z(1,1,:));    % Nz
[Z2, X2, Y2] = meshgrid(zv, xv, yv);

% X_fin = X; Y_fin = Y; Z_fin = Z; Q_fin = Q_phase_avg_s; C_fin = w_phase_avg_s;
X_fin = X2; Y_fin = Y2; Z_fin = Z2; Q_fin = Q2; C_fin = C2;

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
end

p = patch('vertices', s.vertices, 'faces', s.faces, ...
          'FaceVertexCData', cData, 'FaceColor', 'interp', 'EdgeColor', 'none');

view(3);
if params.zero ~= 0
    cb = colorbarpzn(params.clims(1), params.clims(2), 'full', 1, 'dft', 'pwg');
else
    cb = colorbarpzn(params.clims(1), params.clims(2)); % , 'level', 21
end
if ~params.movie
    ylabel(cb,'\boldmath$\frac{\omega c}{U_{\infty}}$','Interpreter','Latex','FontSize',18,'Rotation',0)
    % xlabel("x/c", FontSize=16)
    xlabel("t/T", FontSize=16)
    ylabel("y/c", FontSize=16)
    zlabel("z/c", FontSize=16)
else
    cb.Visible = 'off';
    ax = gca;
    ax.XTick = [];
    ax.YTick = [];
    ax.ZTick = [];
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.ZTickLabel = [];
    ax.Box = 'off';
    ax.XColor = 'none'; % hides axis line
    ax.YColor = 'none';
    ax.ZColor = 'none';
end

% Zoom out
% ax = gca;
% ax.XLim = ax.XLim * 2;   % doubles the range in x
% ax.YLim = ax.YLim * 2;   % doubles the range in y
% ax.ZLim = ax.ZLim * 2;   % doubles the range in z

% xlabel("y [m]")
% ylabel("z [m]")
% zlabel("x [m]")
end