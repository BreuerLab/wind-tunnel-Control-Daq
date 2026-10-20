function [Q_avg, Q_pos_avg] = inst_Q_avg(u, v, w, x, y, z)
% Q computed on each instantaneous (binned) velocity field, then averaged
% over the frames: <Q> and <Q+> = <max(Q, 0)>.
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
% Q_avg, Q_pos_avg : [nx ny nz]

dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));

n_frames = size(u, 4);
Q_sum = zeros(size(u, 1), size(u, 2), size(u, 3));
Q_pos_sum = Q_sum;
n_valid = Q_sum;

for k = 1:n_frames
    % fill holes first: the 9-point derivative kernel in calQlate3D would
    % otherwise spread every NaN over its neighbourhood
    uk = fill3D(u(:,:,:,k));
    vk = fill3D(v(:,:,:,k));
    wk = fill3D(w(:,:,:,k));

    [~, ~, ~, Qk] = calQlate3D(uk, vk, wk, dx, dy, dz);

    valid = isfinite(Qk);
    Qk(~valid) = 0;
    Q_sum = Q_sum + Qk;
    Q_pos_sum = Q_pos_sum + max(Qk, 0);
    n_valid = n_valid + valid;
end

Q_avg = Q_sum ./ n_valid;         % NaN where no frame had data
Q_pos_avg = Q_pos_sum ./ n_valid;
end
