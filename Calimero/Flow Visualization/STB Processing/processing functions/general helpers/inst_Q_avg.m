function [Qx_avg, Qy_avg, Qz_avg, Q_avg] = inst_Q_avg(u, v, w, x, y, z)
% Q (and its parts Qx, Qy, Qz, as returned by calQlate3D) computed on each
% instantaneous (binned) velocity field, then averaged over the frames.
%
% Compare with Q of the averaged field (calc_secondary_vals_common):
% Q is quadratic in the velocity gradients, so
%   <Q> = Q(mean u) + 1/2 (<|Omega'|^2> - <|S'|^2>)
% i.e. <Q> also contains the frame-to-frame variability (phase jitter,
% cycle-to-cycle variation) and measurement noise.
%
% u, v, w : [nx ny nz nFrames] (or [nx ny nz] for one frame), same
%           (non-)dimensionalisation as the averaged fields
% x, y, z : grids [nx ny nz]
% outputs : [nx ny nz]

dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));

n_frames = size(u, 4);
grid_size = [size(u, 1), size(u, 2), size(u, 3)];
Qx_sum = zeros(grid_size); Qy_sum = Qx_sum; Qz_sum = Qx_sum; Q_sum = Qx_sum;
n_valid = zeros(grid_size);

for k = 1:n_frames
    % fill holes first: the derivative kernel in calQlate3D would
    % otherwise spread every NaN over its neighbourhood
    uk = fill3D(u(:,:,:,k));
    vk = fill3D(v(:,:,:,k));
    wk = fill3D(w(:,:,:,k));

    [Qxk, Qyk, Qzk, Qk] = calQlate3D(uk, vk, wk, dx, dy, dz);

    valid = isfinite(Qk);
    Qxk(~valid) = 0; Qyk(~valid) = 0; Qzk(~valid) = 0; Qk(~valid) = 0;
    Qx_sum = Qx_sum + Qxk;
    Qy_sum = Qy_sum + Qyk;
    Qz_sum = Qz_sum + Qzk;
    Q_sum = Q_sum + Qk;
    n_valid = n_valid + valid;
end

% NaN where no frame had data
Qx_avg = Qx_sum ./ n_valid;
Qy_avg = Qy_sum ./ n_valid;
Qz_avg = Qz_sum ./ n_valid;
Q_avg = Q_sum ./ n_valid;
end
