function [lift, drag] = get_wake_lift(U, L, D, vort_bool, density, opts)
    % opts.edge_taper : width (chords) of the smooth edge taper used for
    %                   the omega_y lift estimate's window-edge terms
    %                   (default 0.75; 0 = no edge terms, old estimate)
    if nargin < 6 || isempty(opts), opts = struct(); end
    if ~isfield(opts, 'edge_taper'), opts.edge_taper = 0.75; end

    % ---------------------------------------------
    % --------- Make values dimensional -----------
    % ---------------------------------------------
    x = D.x;
    y = D.y*L;
    z = D.z*L;
    u = D.u*U;
    v = D.v*U;
    w = D.w*U;
    if vort_bool
    vortX = D.vortX / (L/U);
    vortY = D.vortY / (L/U);
    vortZ = D.vortZ / (L/U);
    end

    % Vorticity is used as computed from the hole-filled velocity field
    % (holes are marked NaN in loadpiv and interpolated before any
    % derivative is taken). It is deliberately NOT zeroed where data is
    % missing and NOT median filtered: zeroing removes circulation from
    % poorly seeded vortex cores, and a median filter is nonlinear and
    % clips concentrated cores, so neither preserves the integral of
    % y*omega_x that the lift estimate depends on.
    % NOTE: .mat files processed before this change contain vorticity
    % computed with holes treated as zero velocity - reprocess them.
    if vort_bool && (any(isnan(vortX), 'all') || any(isnan(vortY), 'all'))
        warning("get_wake_lift:nanVorticity", ...
            "Vorticity contains NaNs; lift/drag integrals will be NaN. " + ...
            "Fill holes in the velocity field before computing vorticity.")
    end

    % Frame (checked on phase-averaged data): x is streamwise and points
    % upstream (u ~ -U, so u + U is the perturbation), y is spanwise
    % (half plane y >= 0, increasing with array index), z is vertical
    % (increasing with array index), and w is positive along +z. The
    % frame is right-handed and the stored vortX, vortY, vortZ are the
    % ordinary right-handed curl, so trapz over y and z are +int dy,
    % +int dz and no sign corrections are needed.

    % THESE CALCULATIONS ONLY WORK FOR AVERAGE LIFT, time varying lift
    % should account for contribution from d/dt term in N-S

    % if vort_bool
    % Q_mask_bool = false;
    % if Q_mask_bool
    %     vortX(Q < 0) = 0;
    %     disp("Q mask active")
    % end
    % end

    % mean convection speed base on vortex centers
    % u_tmp = u;
    % u_tmp(Q <= 0.025) = NaN;
    % 
    % mean_u = squeeze(mean(u_tmp, "all", "omitnan"));

    %% Calculate lift
    if vort_bool
        lift = struct();

        % term1 = -U * dA * x .* -vortZ; 
        % term2 = (w + U) .* -v .* dA; % effectively zero
        % term1 = -U * y .* -vortX;
        % term1 = mean_u * y .* -vortX;
        term1 = -U .* y .* -vortX; % u or -U, doesn't seem to make a big diff
        term2 = -(u + U) .* -w; % effectively zero
        % term3 = y .* (w .* dudy - v .* dudz);
    
        lift_vec_wx = trapz(y(:,1), term1, 1);
        % lift_wx = 2 * density * trapz(z(1,:), lift_vec_wx, 2);
        lift_wx = 2 * density * trapz(z(1,:), lift_vec_wx, 2);
        lift_wx = squeeze(lift_wx);

        % Calculating lift using mean rather than trapz
        % L_y = abs(y(end,1) - y(1,1));
        % L_z = abs(z(1,end) - z(1,1));
        % lift_wx2 = 2 * density * squeeze(mean(term1, [1,2])) * (L_y*L_z);

        % velocity term that goes with the omega_x term, (u+U)*w. Named
        % lift_vel_diff so it isn't confused with the velocity-only lift
        % (u*w) returned when vort_bool is false (saved as lift_vel).
        lift_vec_vel_diff = trapz(y(:,1), term2, 1);
        lift_vel_diff = 2 * density * trapz(z(1,:), lift_vec_vel_diff, 2);
        lift_vel_diff = squeeze(lift_vel_diff);

        % lift_vec_du = trapz(y(:,1), term3, 1);
        % lift_du = 2 * density * trapz(z(1,:), lift_vec_du, 2);
        % lift_du = squeeze(lift_du);

        % Smooth edge taper (see the omega_y block below). The omega_x
        % estimate with the same taper is returned for a like-for-like
        % comparison with lift.vortY; it differs from lift.vortX only by
        % omega_x inside the edge band. Defined for time averages too, so
        % body (0 Hz) subtraction works.
        I2 = @(F) squeeze(trapz(z(1,:), trapz(y(:,1), F, 1), 2));
        [phi, dphi_dy, dphi_dz] = edge_taper_weight(y, z, opts.edge_taper * L);
        lift.vortX_taper = 2 * density * U * I2(y .* phi .* vortX);

        if ~(isscalar(x))
        % ---- omega_y (spanwise starting/stopping vorticity) estimate ----
        % div(omega) = 0 gives, for A = int int y*omega_x dA over the
        % half plane, with a weight phi(y,z) that is 1 inside and goes
        % smoothly to 0 at the outer spanwise edge and the top/bottom edges:
        %
        %   d/dx int int y*phi*wx dA = int int [ phi*wy + y*wy*dphi/dy
        %                                        + y*wz*dphi/dz ] dA
        %
        % The last two terms are the window-edge terms (vortex lines that
        % leave the window: tether wakes, sheets cut by the edges), taken
        % as averages over a band opts.edge_taper chords wide instead of
        % on single noisy edge rows. edge_taper = 0 drops them (the old
        % estimate, integral of omega_y only). The y = 0 (symmetry) side
        % needs no taper: its edge term is weighted by y = 0.
        % Frozen flow (x points upstream): dA/dt = U dA/dx, so
        % lift(t) = 2*rho*U * U * int (...) dt, mean removed (the omega_y
        % route carries no information about the mean).
        % Signs: y and z increase with array index and the stored
        % vorticity is the right-handed curl, so the identity above is
        % used as written (all terms +). Closure can be checked with
        % wake_lift_budget.
        % bin times from the frozen-flow axis (x = U t). These are the
        % actual mean phases of the bins (see bin_times), so they may be
        % unevenly spaced; means and integrals use the actual times.
        t  = x(:) / U;
        if isfield(D, 'period') && isfinite(D.period)
            period = D.period;
        else
            period = numel(t) * median(diff(t));
        end

        wy_integrand = phi .* vortY + y .* vortY .* dphi_dy + y .* vortZ .* dphi_dz;
        rate_wy = U * I2(wy_integrand);                 % = dA/dt, A tapered
        rate_wy = rate_wy - periodic_mean(rate_wy(:), t, period);
        lift_wy_F = 2 * density * U * cumtrapz(t(:), rate_wy(:));

        % same estimate without the edge terms or taper (previous version)
        rate_raw = U * I2(vortY);
        rate_raw = rate_raw - periodic_mean(rate_raw(:), t, period);
        lift.vortY_no_edge = 2 * density * U * cumtrapz(t(:), rate_raw(:));

        total = lift_wx + lift_vel_diff;
        lift.vortY = lift_wy_F;
        else
            total = lift_wx + lift_vel_diff;
        end
        lift.vortX = lift_wx;
        lift.vel_diff = lift_vel_diff;
        lift.tot = total;
    else
        lift_mat_full = -(u .* -w);

        lift_vec_full = trapz(y(:,1), lift_mat_full, 1);
        lift = 2 * density * trapz(z(1,:), lift_vec_full, 2);
        lift = squeeze(lift);
    end

    %% Calculate drag
    if vort_bool
        % Vortex-impulse drag, positive downstream (on the body):
        %   D = rho*U * int int_half (y*Wz - z*Wy) dA
        % with W the right-handed vorticity. y and z both increase with
        % array index (checked on phase-averaged data: z runs -2.5 to
        % 3.4 c) and u ~ -U (x points upstream), so the stored vorticity
        % is the right-handed vorticity and I2 = +int int dA. This is the
        % convention under which drag_vel (momentum deficit) comes out
        % drag-positive, matching the load cell. Each term here carries
        % rho*U (not 2*rho*U) so drag.vortY + drag.vortZ = drag.tot.
        % For a closed wake (cycle mean) the two terms are equal, so
        % 2*drag.vortY or 2*drag.vortZ alone is also an estimate of D.
        % y = 0 must lie on the symmetry plane (y*Wz term); the z origin
        % only drops out when int int Wy dA = 0 (cycle mean).
        I2 = @(F) squeeze(trapz(z(1,:), trapz(y(:,1), F, 1), 2));

        bernoulli_term = v.^2 + w.^2 + (u + U).^2;
        bernoulli = density * I2(bernoulli_term);

        drag_wy = -density * U * I2(z .* vortY);   % -z*Wy term
        drag_wz =  density * U * I2(y .* vortZ);   %  y*Wz term

        total = drag_wy + drag_wz;
        drag.vortY = drag_wy;
        drag.vortZ = drag_wz;
        drag.bernoulli = bernoulli;
        drag.tot = total;
    else
        drag_mat_full = -u .* (u + U); % If w > U in magnitude, should be -
        
        drag_vec_full = trapz(y(:,1), drag_mat_full, 1);
        drag = 2 * density * trapz(z(1,:), drag_vec_full, 2);
        drag = squeeze(drag);
    end
    
end

function [phi, dphi_dy, dphi_dz] = edge_taper_weight(y, z, ell)
% Weight that is 1 in the interior and ramps to 0 (0.5 - 0.5cos) over a
% band ell wide at the outer spanwise edge (max y) and both z edges, plus
% its derivatives with respect to the coordinate values (array order does
% not matter). ell = 0 gives phi = 1 and zero derivatives.
yv = y(:,1);  zv = z(1,:);
[Ty, dTy] = cos_ramp(yv, min(yv), max(yv), ell, false, true);
[Tz, dTz] = cos_ramp(zv(:), min(zv), max(zv), ell, true, true);
phi     = Ty  * Tz';
dphi_dy = dTy * Tz';
dphi_dz = Ty  * dTz';
end

function [t, dt] = cos_ramp(c, lo, hi, ell, do_lo, do_hi)
tl = ones(size(c)); dtl = zeros(size(c));
th = ones(size(c)); dth = zeros(size(c));
if ell > 0 && do_lo
    m = c < lo + ell; s = (c(m) - lo) / ell;
    tl(m) = 0.5 - 0.5*cos(pi*s);  dtl(m) =  0.5*pi/ell*sin(pi*s);
end
if ell > 0 && do_hi
    m = c > hi - ell; s = (hi - c(m)) / ell;
    th(m) = 0.5 - 0.5*cos(pi*s);  dth(m) = -0.5*pi/ell*sin(pi*s);
end
t  = tl .* th;
dt = dtl .* th + tl .* dth;
end
