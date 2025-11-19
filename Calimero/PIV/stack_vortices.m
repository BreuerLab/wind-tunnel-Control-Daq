function stack_vortices(x, y, vort_phase_avg, Q_phase_avg, wing_freq, num_bins)
wind_speed = 4;
dt = wing_freq / num_bins;
z = zeros(1, num_bins);
for k = 1:num_bins
    z(k) =  wind_speed * dt * k;
end

% Trimming everything but tip vortex
x_idx = find(x(1,:) > 0.025 & x(1,:) < 0.15);  % columns
y_idx = find(y(:,1) > -0.2 & y(:,1) < 0.2);  % rows

x_tr = x(y_idx, x_idx);
y_tr = y(y_idx, x_idx);
vort_phase_avg_tr = vort_phase_avg(y_idx, x_idx,:);
Q_phase_avg_tr = Q_phase_avg(y_idx, x_idx,:);

% manually shift z array so that red and blue portions align
% z = circshift(z,5);

[Ny, Nx] = size(x_tr);
Nz = length(z);

% Replicate along z
X = repmat(x_tr, [1 1 Nz]);       % Ny x Nx x Nz
Y = repmat(y_tr, [1 1 Nz]);       % Ny x Nx x Nz
Z = repmat(reshape(z, [1 1 Nz]), [Ny Nx 1]); % Ny x Nx x Nz

shift = -7;
Q_phase_avg_tr_s = circshift(Q_phase_avg_tr, [0 0 shift]);  % shift along the 3rd dimension (Z)
vort_phase_avg_tr_s = circshift(vort_phase_avg_tr, [0 0 shift]);  % shift along the 3rd dimension (Z)

isoValue = 100;
figure
s = isosurface(X, Y, Z, Q_phase_avg_tr_s, isoValue);
cData = interp3(X, Y, Z, vort_phase_avg_tr_s, s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
p = patch('Vertices', s.vertices, 'Faces', s.faces, ...
          'FaceVertexCData', cData, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none');

view(3);
params.cmin = -50;
params.cmax = 50;
colorbarpzn(params.cmin, params.cmax); % , 'level', 21
xlabel("y [m]")
ylabel("z [m]")
zlabel("x [m]")
end