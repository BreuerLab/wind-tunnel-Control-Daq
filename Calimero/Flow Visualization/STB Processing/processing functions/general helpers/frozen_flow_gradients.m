function G = frozen_flow_gradients(F, t, period, L, U)
% FROZEN_FLOW_GRADIENTS Streamwise velocity gradients on the centre plane
% from the frozen-flow assumption, and omega_y, omega_z rebuilt with them.
%
%   G = frozen_flow_gradients(F, t, period, L, U)
%
%   F       struct of centre-plane fields, [ny nz nb] (y along dim 1, z
%           along dim 2, phase bins along dim 3), nondimensional like the
%           processed files (velocity / U, gradients and vorticity * L/U):
%             u, v, w       hole-filled velocity (required)
%             vortY, vortZ  slab vorticity (optional)
%             dwdx, dvdx    slab gradients (needed for vortY_ff / vortZ_ff)
%   t       time of each bin within the period (s), e.g. from bin_times.
%           [] or a scalar for a time average (no time axis)
%   period  wingbeat period (s)
%   L, U    chord (m) and convection speed (m/s, the freestream speed)
%
%   G.dudx_ff, G.dvdx_ff, G.dwdx_ff  frozen-flow d/dx of u, v, w
%   G.vortY_ff, G.vortZ_ff           omega_y, omega_z with those gradients
%   (same size and nondimensionalisation as the inputs)
%
% Frozen flow: x points upstream and the wake convects downstream at U, so
% a field is A(x, t) = f(x + U t) and dA/dx = (1/U) dA/dt. In the units
% used here (velocity / U, gradient * L/U) that is
%   dudx_ff = (L/U) * d(u/U)/dt
% taken with periodic_ddt (second order, at the actual unevenly spaced bin
% times, wrapping around the period).
%
% The slab gradients in the processed files carry the [1 2 1]/4 transverse
% smoothing of the Raffel stencil (loadpiv get_gradients; the WLS slab fit
% keeps the in-plane part of it): dv/dx is smoothed along y, dw/dx along
% z, du/dx along y and z. The frozen-flow gradients get the same smoothing
% so the two differ only in how d/dx is estimated.
%
% The vorticity components that contain a streamwise derivative,
%   omega_y = du/dz - dw/dx,   omega_z = dv/dx - du/dy,
% are rebuilt by swapping the slab x-derivative for the frozen-flow one:
%   vortY_ff = vortY + dwdx - dwdx_ff
%   vortZ_ff = vortZ - dvdx + dvdx_ff
% so the in-plane derivatives stay exactly as in the stored vorticity (the
% stored omega_y, omega_z and the gradients come from the same stencil,
% see loadpiv slab_wls_gradients). omega_x has no x-derivative.
%
% For a time average there is no time axis: the frozen-flow derivative of
% a steady field is zero (x-invariant flow), so the gradients are zero and
% vortY_ff, vortZ_ff are just the in-plane parts.

has_t = numel(t) >= 3 && isfinite(period);
sz = size(F.u);

if has_t
    if size(F.u, 3) ~= numel(t)
        error("frozen_flow_gradients: %d bins in the fields but %d bin times", size(F.u, 3), numel(t));
    end
    s = L / U;   % d(u/U)/dt * L/U = (1/U) du/dt * L/U
    G.dudx_ff = smooth121(smooth121(periodic_ddt(F.u, t, period, 3) * s, 1), 2);
    G.dvdx_ff = smooth121(periodic_ddt(F.v, t, period, 3) * s, 1);
    G.dwdx_ff = smooth121(periodic_ddt(F.w, t, period, 3) * s, 2);
else
    G.dudx_ff = zeros(sz);
    G.dvdx_ff = zeros(sz);
    G.dwdx_ff = zeros(sz);
end

if isfield(F, 'vortY') && isfield(F, 'dwdx')
    G.vortY_ff = F.vortY + fill_nans(F.dwdx) - G.dwdx_ff;
end
if isfield(F, 'vortZ') && isfield(F, 'dvdx')
    G.vortZ_ff = F.vortZ - fill_nans(F.dvdx) + G.dvdx_ff;
end
end

function A = smooth121(A, dim)
% [1 2 1]/4 smoothing along dim, edge values replicated (as in loadpiv)
n = size(A, dim);
if n < 2, return; end
idx = repmat({':'}, 1, ndims(A));
lo = idx; lo{dim} = [1, 1:n-1];
hi = idx; hi{dim} = [2:n, n];
A = (A(lo{:}) + 2*A + A(hi{:})) / 4;
end

function A = fill_nans(A)
% slab gradients of older files can have holes; fill them so a hole
% doesn't turn into NaN vorticity (and NaN forces)
if any(isnan(A), 'all')
    A = nanRegionFill(A);
end
end
