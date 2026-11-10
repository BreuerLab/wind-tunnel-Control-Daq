function [vortY, vortZ, sigY, sigZ, info] = vorticity_slab_wls(x, y, z, u, v, w, sig_u, sig_v, sig_w, opts)
% VORTICITY_SLAB_WLS Out-of-plane vorticity (omega_y, omega_z) at the centre
% plane of the STB slab, using an uncertainty-weighted polynomial fit across
% ALL binned planes instead of a 3-plane central difference.
%
%   [vortY, vortZ, sigY, sigZ, info] = vorticity_slab_wls(x, y, z, u, v, w, ...
%                                         sig_u, sig_v, sig_w, opts)
%
%   x, y, z      grids [nx, ny, nz] (x = slab-normal/streamwise, dim 1)
%   u, v, w      velocity [nx, ny, nz] for ONE frame or ONE phase bin
%   sig_u/v/w    1-sigma uncertainty of u/v/w, same size (or [nx,1] for a
%                single value per plane)
%   opts.order   polynomial order across planes (default 2)
%   opts.i0      plane to evaluate at (default centre plane, (nx+1)/2)
%   opts.transverseSmooth  apply the [1 2 1]/4 in-plane smoothing that the
%                Raffel stencil in calculateVorticity applies (default true)
%
%   omega_y = du/dz - dw/dx,   omega_z = dv/dx - du/dy
%
%   Same sign convention as calculateVorticity: derivatives are taken with
%   respect to array index times |grid spacing|, so results are directly
%   comparable with vortY/vortZ already in the processed files.
%
%   How the planes are used:
%   - d(w)/dx, d(v)/dx: slope of the WLS fit across all planes at i0.
%   - u in d(u)/dz, d(u)/dy: the WLS-fitted value of u at i0, i.e. u is
%     smoothed across the slab with weights that favour the well-lit,
%     in-focus planes (the Raffel stencil uses fixed 1-2-1 weights).
%   Planes with large sigma contribute little; a plane with NaN sigma is
%   ignored.
%
%   Called per frame from loadpiv (extractData -> slab_wls_centre_plane),
%   with one DaVis-uncertainty sigma per plane.
%
%   Outputs are [ny, nz]. sigY/sigZ propagate the WLS covariances through
%   the in-plane differencing/smoothing (neighbouring points treated as
%   independent). info holds the intermediate terms and fit diagnostics.

if nargin < 10, opts = struct(); end
if ~isfield(opts, 'order'), opts.order = 2; end
if ~isfield(opts, 'i0'), opts.i0 = (size(u, 1) + 1) / 2; end
if ~isfield(opts, 'transverseSmooth'), opts.transverseSmooth = true; end

dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));

[u0, ~,    su0, ~,      chi_u, n_u] = slab_poly_fit(u, sig_u, dx, opts.order, opts.i0);
[~,  dvdx, ~,   s_dvdx, chi_v]      = slab_poly_fit(v, sig_v, dx, opts.order, opts.i0);
[~,  dwdx, ~,   s_dwdx, chi_w]      = slab_poly_fit(w, sig_w, dx, opts.order, opts.i0);

% In-plane derivatives of the slab-fitted u (dim 1 = y, dim 2 = z)
[dudy, s_dudy] = diff_with_unc(u0, su0, dy, 1);
[dudz, s_dudz] = diff_with_unc(u0, su0, dz, 2);

% Transverse smoothing that matches the Raffel/Sobel stencil:
% dw/dx smoothed along z, dv/dx smoothed along y.
if opts.transverseSmooth
    [dwdx, s_dwdx] = smooth121(dwdx, s_dwdx, 2);
    [dvdx, s_dvdx] = smooth121(dvdx, s_dvdx, 1);
end

vortY = dudz - dwdx;
vortZ = dvdx - dudy;
sigY  = sqrt(s_dudz.^2 + s_dwdx.^2);
sigZ  = sqrt(s_dvdx.^2 + s_dudy.^2);

info = struct('u0', u0, 'sig_u0', su0, 'dudy', dudy, 'dudz', dudz, ...
    'dvdx', dvdx, 'dwdx', dwdx, 'sig_dvdx', s_dvdx, 'sig_dwdx', s_dwdx, ...
    'sig_dudy', s_dudy, 'sig_dudz', s_dudz, ...
    'chi2red_u', chi_u, 'chi2red_v', chi_v, 'chi2red_w', chi_w, 'n_planes', n_u);
end

% -------------------------------------------------------------------------
function [d, sd] = diff_with_unc(f, sf, h, dim)
% Central difference (one-sided at the edges) with error propagation,
% assuming independent errors at neighbouring points.
if dim == 2, f = f.'; sf = sf.'; end
n = size(f, 1);
d = nan(size(f)); sd = nan(size(f));
if n >= 3
    d(2:n-1, :)  = (f(3:n, :) - f(1:n-2, :)) / (2*h);
    sd(2:n-1, :) = sqrt(sf(3:n, :).^2 + sf(1:n-2, :).^2) / (2*h);
end
d(1, :)  = (f(2, :) - f(1, :)) / h;
sd(1, :) = sqrt(sf(2, :).^2 + sf(1, :).^2) / h;
d(n, :)  = (f(n, :) - f(n-1, :)) / h;
sd(n, :) = sqrt(sf(n, :).^2 + sf(n-1, :).^2) / h;
if dim == 2, d = d.'; sd = sd.'; end
end

function [g, sg] = smooth121(f, sf, dim)
% [1 2 1]/4 smoothing along dim with replicated edges, plus propagation.
if dim == 2, f = f.'; sf = sf.'; end
fp = [f(1, :); f; f(end, :)];
sp = [sf(1, :); sf; sf(end, :)];
g  = (fp(1:end-2, :) + 2*fp(2:end-1, :) + fp(3:end, :)) / 4;
sg = sqrt(sp(1:end-2, :).^2 + 4*sp(2:end-1, :).^2 + sp(3:end, :).^2) / 4;
if dim == 2, g = g.'; sg = sg.'; end
end
