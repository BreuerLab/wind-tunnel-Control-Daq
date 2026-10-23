function [vortX, vortY, vortZ] = vorticity_of_mean_velocity(x, y, z, u, v, w, uncU, uncV, uncW)
% Vorticity computed from an averaged (phase- or time-averaged) velocity
% field, using the same operators loadpiv applies to each frame:
%   - calculateVorticity (Raffel stencil) for all components and planes
%   - centre-plane omega_y, omega_z replaced by the uncertainty-weighted
%     WLS slab fit (vorticity_slab_wls), planes weighted by 1/sigma^2 with
%     sigma the median averaged uncertainty of each plane
%
% Vorticity is linear in velocity, so this differs from the average of the
% per-frame vorticity only through hole filling (done after averaging here,
% per frame there) and the per-frame WLS plane weights.
%
% x, y, z          grids [nx ny nz]
% u, v, w          [nx ny nz] or [nx ny nz nBins]
% uncU, uncV, uncW same size as u (averaged per-vector uncertainty)

vortX = NaN(size(u));
vortY = vortX;
vortZ = vortX;

nx = size(u, 1);
i0 = ceil(nx / 2);
opts = struct('order', 2, 'i0', i0);

for b = 1:size(u, 4)
    ub = u(:,:,:,b); vb = v(:,:,:,b); wb = w(:,:,:,b);
    [wx, wy, wz] = calculateVorticity(x, y, z, ub, vb, wb);

    if nx >= 3
        [wy_c, wz_c] = vorticity_slab_wls(x, y, z, ub, vb, wb, ...
            plane_sigma(uncU(:,:,:,b)), plane_sigma(uncV(:,:,:,b)), plane_sigma(uncW(:,:,:,b)), opts);
        wy(i0, :, :) = reshape(fill3D(wy_c), [1, size(wy_c)]);
        wz(i0, :, :) = reshape(fill3D(wz_c), [1, size(wz_c)]);
    end

    vortX(:,:,:,b) = wx;
    vortY(:,:,:,b) = wy;
    vortZ(:,:,:,b) = wz;
end
end

function s = plane_sigma(unc)
% one uncertainty per plane: median of the valid values (as in loadpiv)
nx = size(unc, 1);
unc(~isfinite(unc) | unc <= 0) = NaN;
s = median(reshape(unc, nx, []), 2, "omitnan");
end
