function stack_vortices(x, y, vort_phase_avg, Q_phase_avg, w_phase_avg, wing_freq, params)
wind_speed = 4;
dt = 1 / (wing_freq * params.num_bins);
z = zeros(1, params.num_bins);
for k = 1:params.num_bins
    z(k) =  wind_speed * dt * (k - 1);
end
z = z / params.L; % non-dimensionalize z by characterisitic length

[Ny, Nx] = size(x);
Nz = length(z);

% Replicate along z
X = repmat(x, [1 1 Nz]);       % Ny x Nx x Nz
Y = repmat(y, [1 1 Nz]);       % Ny x Nx x Nz
Z = repmat(reshape(z, [1 1 Nz]), [Ny Nx 1]); % Ny x Nx x Nz

Q_phase_avg_s = circshift(Q_phase_avg, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
vort_phase_avg_s = circshift(vort_phase_avg, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
w_phase_avg_s = circshift(w_phase_avg, [0 0 params.shift]);

% Shuffle axes

% [X_new, Y_new, Z_new] = meshgrid(y(:,1), z, x(1,:));  
% 
% Q_new = permute(Q_phase_avg_s, [1 3 2]);  % Ny x Nz x Nx → new Y x new Z x new X
% vort_new = permute(vort_phase_avg_s, [1 3 2]);

% X2 = permute(X, [3 2 1]);     % becomes Z–X–Y
% Y2 = permute(Y, [3 2 1]);
% Z2 = permute(Z, [3 2 1]);
Q2 = permute(Q_phase_avg_s, [2 3 1]);
C2 = permute(w_phase_avg_s, [2 3 1]);

xv = squeeze(X(1,:,1));    % Nx
yv = squeeze(Y(:,1,1));    % Ny
zv = squeeze(Z(1,1,:));    % Nz
[Z2, X2, Y2] = meshgrid(zv, xv, yv);

isoValue = 0.05;

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
vort_fine = interp3(X, Y, Z, vort_phase_avg, Xq, Yq, Zq, 'linear');

%% Stack 3 wingbeats together

% Repeat Z coordinates
zq_big = [zq, zq + max(zq), zq + 2*max(zq)];

% Repeat data along 3rd dimension
Q_big    = cat(3, Q_fine,    Q_fine,    Q_fine);
vort_big = cat(3, vort_fine, vort_fine, vort_fine);

Q_big = circshift(Q_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)
vort_big = circshift(vort_big, [0 0 params.shift]);  % shift along the 3rd dimension (Z)

% Make a bigger grid using ndgrid
[X_big, Y_big, Z_big] = meshgrid(xq, yq, zq_big);

X_fin = X_big; Y_fin = Y_big; Z_fin = Z_big; Q_fin = Q_big; C_fin = vort_big;
end

% Extract isosurface from larger volume
% s = isosurface(X_fin, Y_fin, Z_fin, Q_fin, isoValue);
s = isosurface(Z_fin, X_fin, Y_fin, Q_fin, isoValue);

% Colors
% cData = interp3(X_fin, Y_fin, Z_fin, C_fin, ...
%                 s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
cData = interp3(Z_fin, X_fin, Y_fin, C_fin, ...
                s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));

p = patch('vertices', s.vertices, 'faces', s.faces, ...
          'FaceVertexCData', cData, 'FaceColor', 'interp', 'EdgeColor', 'none');

view(3);
if params.zero ~= 0
    cb = colorbarpzn(params.clims(1), params.clims(2), 'full', 1);
else
    cb = colorbarpzn(params.clims(1), params.clims(2)); % , 'level', 21
end
ylabel(cb,'\boldmath$\frac{\omega c}{U_{\infty}}$','Interpreter','Latex','FontSize',16,'Rotation',0)
xlabel("y/c")
ylabel("z/c")
zlabel("x/c")

% xlabel("y [m]")
% ylabel("z [m]")
% zlabel("x [m]")
end