function G = frozen_flow_gradients(F, t, period, L, U, opts)
% FROZEN_FLOW_GRADIENTS Streamwise velocity gradients on the centre plane
% from the frozen-flow assumption, and omega_y, omega_z and the velocity
% divergence rebuilt with them.
%
%   G = frozen_flow_gradients(F, t, period, L, U)
%   G = frozen_flow_gradients(F, t, period, L, U, opts)
%
%   F       struct of centre-plane fields, [ny nz nb] (y along dim 1, z
%           along dim 2, phase bins along dim 3), nondimensional like the
%           processed files (velocity / U, gradients and vorticity * L/U):
%             u, v, w       hole-filled velocity (required)
%             vortY, vortZ  slab vorticity (optional)
%             dwdx, dvdx    slab gradients (needed for vortY_ff / vortZ_ff)
%             dudx, dvdy, dwdz  slab gradients (needed for div_slab / div_ff)
%   t       time of each bin within the period (s), e.g. from bin_times.
%           [] or a scalar for a time average (no time axis)
%   period  wingbeat period (s)
%   L, U    chord (m) and convection speed (m/s, the freestream speed)
%   opts.H  number of wingbeat harmonics of a harmonic regression file
%           (its saved hr.H). Given, d/dt is the exact derivative of the
%           fitted Fourier series (spectral, see below) instead of a finite
%           difference between bins. [] or omitted = finite difference.
%
%   G.dudx_ff, G.dvdx_ff, G.dwdx_ff  frozen-flow d/dx of u, v, w
%   G.vortY_ff, G.vortZ_ff           omega_y, omega_z with those gradients
%   G.div_slab = dudx + dvdy + dwdz       (slab du/dx)
%   G.div_ff   = dudx_ff + dvdy + dwdz    (frozen-flow du/dx)
%   (same size and nondimensionalisation as the inputs; zero for an
%   incompressible flow, so these show which du/dx closes continuity)
%   G.ddt_method  "harmonic", "finite difference" or "none"
%
% Frozen flow: x points upstream and the wake convects downstream at U, so
% a field is A(x, t) = f(x + U t) and dA/dx = (1/U) dA/dt. In the units
% used here (velocity / U, gradient * L/U) that is
%   dudx_ff = (L/U) * d(u/U)/dt
% taken with periodic_ddt (second order, at the actual unevenly spaced bin
% times, wrapping around the period).
%
% Harmonic regression files (opts.H): the saved *_phase_avg fields are the
% fitted series sum_{h<=H} a_h cos(2 pi h f t) + b_h sin(...) evaluated at
% nb evenly spaced bin centres. With nb >= 2H+1 those samples determine the
% series exactly (no aliasing), so the FFT of each point's bins recovers
% the coefficients and multiplying by i 2 pi h f gives the exact time
% derivative at the bins - identical to harmonic_eval(<field>_hr_coef, phi,
% 1, freq), without needing the (large, optional) saved coefficients. A
% central difference instead attenuates harmonic h by
% sin(2 pi h/nb)/(2 pi h/nb) (0.47 for h = 10 of 32 bins). Points the
% regression left NaN are hole-filled first like everywhere else, so they
% are only approximately band limited. With nb < 2H+1 the finite
% difference is used (with a warning).
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

if nargin < 6 || isempty(opts), opts = struct(); end
H = [];
if isfield(opts, 'H') && ~isempty(opts.H), H = opts.H; end

has_t = numel(t) >= 3 && isfinite(period);
sz = size(F.u);

if has_t
    nb = size(F.u, 3);
    if nb ~= numel(t)
        error("frozen_flow_gradients: %d bins in the fields but %d bin times", nb, numel(t));
    end
    use_hr = ~isempty(H);
    if use_hr && nb < 2*H + 1
        warning("frozen_flow_gradients:fewBins", ...
            "%d bins can't resolve %d harmonics (need %d): finite difference used", nb, H, 2*H + 1)
        use_hr = false;
    end
    if use_hr
        ddt = @(f) spectral_ddt(f, period, H, 3);    % bins evenly spaced
        G.ddt_method = "harmonic";
    else
        ddt = @(f) periodic_ddt(f, t, period, 3);
        G.ddt_method = "finite difference";
    end
    s = L / U;   % d(u/U)/dt * L/U = (1/U) du/dt * L/U
    G.dudx_ff = smooth121(smooth121(ddt(F.u) * s, 1), 2);
    G.dvdx_ff = smooth121(ddt(F.v) * s, 1);
    G.dwdx_ff = smooth121(ddt(F.w) * s, 2);
else
    G.dudx_ff = zeros(sz);
    G.dvdx_ff = zeros(sz);
    G.dwdx_ff = zeros(sz);
    G.ddt_method = "none";
end

if isfield(F, 'vortY') && isfield(F, 'dwdx')
    G.vortY_ff = F.vortY + fill_nans(F.dwdx) - G.dwdx_ff;
end
if isfield(F, 'vortZ') && isfield(F, 'dvdx')
    G.vortZ_ff = F.vortZ - fill_nans(F.dvdx) + G.dvdx_ff;
end

% Continuity check: the in-plane part dv/dy + dw/dz is the same for both,
% only du/dx differs. du/dx carries the same y and z smoothing either way.
if all(isfield(F, {'dudx', 'dvdy', 'dwdz'}))
    inplane = fill_nans(F.dvdy) + fill_nans(F.dwdz);
    G.div_slab = fill_nans(F.dudx) + inplane;
    G.div_ff = G.dudx_ff + inplane;
end
end

function df = spectral_ddt(f, period, H, dim)
% Exact time derivative of a Fourier series of H harmonics sampled at n
% evenly spaced times over one period (n >= 2H+1), along dim
n = size(f, dim);
k = [0:ceil(n/2)-1, -floor(n/2):-1];   % harmonic number of each FFT bin
mult = 1i * 2*pi * k / period;
mult(abs(k) > H) = 0;
if mod(n, 2) == 0
    mult(n/2 + 1) = 0;                 % Nyquist term (not in the fit)
end
shp = ones(1, max(ndims(f), dim)); shp(dim) = n;
df = real(ifft(fft(f, [], dim) .* reshape(mult, shp), [], dim));
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
