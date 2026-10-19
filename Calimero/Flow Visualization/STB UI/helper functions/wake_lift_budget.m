function B = wake_lift_budget(file_path, case_name, bounds, opts)
% WAKE_LIFT_BUDGET Term-by-term check of the identity that links the
% y*omega_x and x*omega_y lift estimates, for one phase-averaged case.
%
%   B = wake_lift_budget(file_path, case_name)
%   B = wake_lift_budget(file_path, case_name, bounds, opts)
%
%   With A = int int y*omega_x dA over the trimmed half plane
%   (y in [0, Y], z in [z1, z2]), div(omega) = 0 gives exactly
%
%     dA/dx = Gamma_y  -  Y * int omega_y(Y, z) dz            (E_y: outer spanwise edge)
%                      -  int y [omega_z(z2) - omega_z(z1)] dy (E_z: top/bottom edges)
%
%   and with frozen flow (x points upstream in this frame) dA/dt = U dA/dx.
%   get_wake_lift keeps only Gamma_y, so lift.vortY can only match
%   lift.vortX if E_y and E_z are negligible AND frozen flow holds AND
%   omega_y is measured without bias. This function evaluates each piece.
%
%   It also splits Gamma_y with the divergence theorem:
%     Gamma_y = int [u(y,z2) - u(y,z1)] dy   -   int int dw/dx dA
%               (u on top/bottom rows only)      (slab derivative)
%   and checks the slab derivative against frozen flow:
%     int int dw/dx dA  vs  (1/U) d/dt int int w dA
%
%   Everything is in the frame and sign conventions of get_wake_lift
%   (same trimming, same dimensionalisation), expressed as lift-equivalent
%   rates (N/s, multiplied by 2*rho*U) so terms compare directly.
%
%   opts.nEdge  number of edge columns/rows averaged for E_y, E_z and the
%               u-edge term (default 1 = the identity exactly; >1 is less
%               noisy but approximate)
%   opts.plot   (default true)
%
%   Sign checks: the code-frame analysis says omega_x, omega_y are stored
%   with the opposite sign to a right-handed curl and z decreases with
%   array index, which cancel in A and Gamma_y. omega_z is stored with the
%   right-handed sign. If E_z comes out anti-correlated with the residual,
%   flip its sign (opts.signEz = -1) and re-check closure.

if nargin < 3 || isempty(bounds), bounds = default_trim_bounds(); end
if nargin < 4, opts = struct(); end
if ~isfield(opts, 'nEdge'), opts.nEdge = 1; end
if ~isfield(opts, 'plot'), opts.plot = true; end
if ~isfield(opts, 'signEz'), opts.signEz = 1; end

vars = {"L","U","U_act","rho_act","cycle_freq","y","z", ...
        "u_phase_avg","w_phase_avg", ...
        "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
has_dwdx = ismember('dwdx_phase_avg', who('-file', file_path));
if has_dwdx, vars{end+1} = "dwdx_phase_avg"; end
d = load(file_path, vars{:});

U   = d.U_act * d.U;
rho = d.rho_act;
L   = d.L;

freq = 0;
if nargin >= 2 && strlength(string(case_name)) > 0
    [~, ~, freq] = parse_name(case_name);
end
if freq <= 0, freq = d.cycle_freq; end
nb = size(d.u_phase_avg, 4);
dt = 1 / (freq * nb);

% Trim exactly as get_PIV_force does, then dimensionalise as get_wake_lift
[y, z, wx] = trim_vel_field(d.y, d.z, d.vortX_phase_avg, bounds);
[~, ~, wy] = trim_vel_field(d.y, d.z, d.vortY_phase_avg, bounds);
[~, ~, wz] = trim_vel_field(d.y, d.z, d.vortZ_phase_avg, bounds);
[~, ~, u ] = trim_vel_field(d.y, d.z, d.u_phase_avg, bounds);
[~, ~, w ] = trim_vel_field(d.y, d.z, d.w_phase_avg, bounds);
u = nanRegionFill(u); w = nanRegionFill(w);
y = y * L; z = z * L;
s = U / L;
wx = wx * s; wy = wy * s; wz = wz * s;
u = u * U;  w = w * U;
if has_dwdx
    [~, ~, dwdx] = trim_vel_field(d.y, d.z, d.dwdx_phase_avg, bounds);
    dwdx = fill3D(dwdx) * s;
end

yv = y(:,1);  zv = z(1,:);
I2 = @(F) squeeze(trapz(zv, trapz(yv, F, 1), 2));        % [nb,1]

% Edge indices (by coordinate, not by array order)
ne = opts.nEdge;
[~, iy] = sort(yv, 'descend');  iyY = iy(1:ne);         % outer spanwise edge
[~, iz] = sort(zv, 'descend');  izT = iz(1:ne);  izB = iz(end-ne+1:end);
Y = mean(yv(iyY));

A     = I2(y .* wx);
Gam   = I2(wy);
E_y   = Y * squeeze(trapz(zv, mean(wy(iyY,:,:), 1), 2));
E_z   = opts.signEz * squeeze(trapz(yv, yv .* (mean(wz(:,izT,:), 2) - mean(wz(:,izB,:), 2)), 1));
Uedge = squeeze(trapz(yv, mean(u(:,izT,:), 2) - mean(u(:,izB,:), 2), 1));
Wint  = I2(w);

% the y_cen sensitivity: shifting the symmetry plane by dy0 adds
% -dy0 * int omega_y(0, z) dz to dA/dx
[~, iy0] = min(yv);
S0 = squeeze(trapz(zv, wy(iy0,:,:), 2));

ddt = @(f) (circshift(f, -1) - circshift(f, 1)) / (2*dt);  % periodic
K = 2 * rho * U;                                            % lift factor

B.t_over_T  = ((1:nb)' - 1) / nb;
B.dLdt_wx   = K * ddt(A);            % what lift.vortX says
B.rate_Gam  = K * U * Gam;           % what lift.vortY uses
B.rate_Ey   = -K * U * E_y;          % dropped: outer y edge
B.rate_Ez   = -K * U * E_z;          % dropped: top/bottom edges
B.rate_ycen = -K * U * S0 * (0.1 * L);   % per +0.1c shift of y_cen
B.residual  = B.dLdt_wx - (B.rate_Gam + B.rate_Ey + B.rate_Ez);

% Gamma_y split and frozen-flow check of the slab derivative
B.rate_Gam_uedge = K * U * Uedge;
if has_dwdx
    B.rate_Gam_dwdx  = -K * U * I2(dwdx);            % sign: see header
    B.frozen_slab    = I2(dwdx);                     % int int dw/dx from the slab
    B.frozen_time    = ddt(Wint) / U;                % (1/U) d/dt int int w
end

% Integrated lift curves (mean removed), as in the UI comparison
cum = @(r) cumtrapz(r) * dt;
B.L_wx      = K * (A - mean(A));
B.L_wy      = cum(B.rate_Gam - mean(B.rate_Gam));
B.L_wy_corr = cum((B.rate_Gam + B.rate_Ey + B.rate_Ez) - mean(B.rate_Gam + B.rate_Ey + B.rate_Ez));
B.L_wy      = B.L_wy - mean(B.L_wy);
B.L_wy_corr = B.L_wy_corr - mean(B.L_wy_corr);

% Summary
r = @(f) std(f);
fprintf("\n%s  (f = %.2f Hz, U = %.2f m/s, %d bins)\n", string(case_name), freq, U, nb);
fprintf("  rms rates (N/s):  dL/dt from wx %.3f | U*Gamma_y %.3f | outer edge %.3f | top/bottom %.3f | residual %.3f\n", ...
    r(B.dLdt_wx), r(B.rate_Gam), r(B.rate_Ey), r(B.rate_Ez), r(B.residual));
fprintf("  corr with dL/dt(wx):  Gamma_y %.2f | Gamma_y+edges %.2f\n", ...
    cc(B.dLdt_wx, B.rate_Gam), cc(B.dLdt_wx, B.rate_Gam + B.rate_Ey + B.rate_Ez));
fprintf("  Gamma_y split (rms):  u on top/bottom rows %.3f | slab dw/dx %.3f\n", ...
    r(B.rate_Gam_uedge), ternary(has_dwdx, r(B.rate_Gam_dwdx), NaN));
if has_dwdx
    fprintf("  frozen-flow check of slab dw/dx:  rms ratio slab/time %.2f, corr %.2f\n", ...
        r(B.frozen_slab) / r(B.frozen_time), cc(B.frozen_slab, B.frozen_time));
end
fprintf("  mean(Gamma_y)/rms(Gamma_y) = %.2f (should be ~0 for a closed periodic wake)\n", ...
    mean(Gam) / std(Gam));
fprintf("  y_cen sensitivity: rms %.3f N/s per 0.1c shift\n", r(B.rate_ycen));
fprintf("  lift amplitude (ptp, N):  wx %.3f | wy %.3f | wy+edges %.3f\n", ...
    ptp(B.L_wx), ptp(B.L_wy), ptp(B.L_wy_corr));

if opts.plot
    figure('Name', "Wake lift budget: " + string(case_name));
    tiledlayout(3, 1, 'TileSpacing', 'compact');
    t = B.t_over_T;

    nexttile; hold on; box on; grid on
    plot(t, B.L_wx, '-o', 'DisplayName', 'y\omega_x');
    plot(t, B.L_wy, '-s', 'DisplayName', 'x\omega_y (current)');
    plot(t, B.L_wy_corr, '-^', 'DisplayName', 'x\omega_y + edge terms');
    ylabel('Lift - mean (N)'); legend('Location', 'best');

    nexttile; hold on; box on; grid on
    plot(t, B.dLdt_wx, 'k-', 'LineWidth', 1.5, 'DisplayName', 'dL/dt from y\omega_x');
    plot(t, B.rate_Gam, 'DisplayName', '2\rhoU^2\Gamma_y');
    plot(t, B.rate_Ey, 'DisplayName', 'outer y edge');
    plot(t, B.rate_Ez, 'DisplayName', 'top/bottom edges');
    plot(t, B.residual, ':', 'DisplayName', 'residual');
    ylabel('Rate (N/s)'); legend('Location', 'best');

    nexttile; hold on; box on; grid on
    plot(t, B.rate_Gam_uedge, 'DisplayName', '\Gamma_y part: u on top/bottom rows');
    if has_dwdx
        plot(t, B.rate_Gam_dwdx, 'DisplayName', '\Gamma_y part: slab \partialw/\partialx');
        plot(t, -K * U * B.frozen_time, '--', 'DisplayName', 'same, from (1/U) d/dt \int\int w');
    end
    ylabel('Rate (N/s)'); xlabel('t/T'); legend('Location', 'best');
end
end

function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end

function c = cc(a, b)
R = corrcoef(a, b); c = R(1, 2);
end

function p = ptp(a)
p = max(a) - min(a);
end
