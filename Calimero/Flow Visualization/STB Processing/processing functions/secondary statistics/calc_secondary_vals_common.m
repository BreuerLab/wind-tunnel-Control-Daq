function S = calc_secondary_vals_common(D, config, bounds)
% Shared secondary calculations for STB averages.

config = set_defaults(config);

% Spatial resolution
dx = abs(D.x(2,1,1) - D.x(1,1,1));
dy = abs(D.y(1,2,1) - D.y(1,1,1));
dz = abs(D.z(1,1,2) - D.z(1,1,1));

% Compute Q-Criterion
disp("Calculating Q...")
[Qx,Qy,Qz,Q] = calQlate3D(D.(config.uField), D.(config.vField), D.(config.wField), dx,dy,dz);
S.Qx = Qx; S.Qy = Qy; S.Qz = Qz; S.Q = Q;

% Calculated using streamwise speed with freestream speed subtracted.
% 1/2 and 2 (from x2 wings) cancel each other out
S.KE_diff_field = config.density * D.(config.UtotDiffField).^2;
S.power_field = S.KE_diff_field .* -D.(config.uField);

trim_source.u = D.(config.uField);
trim_source.v = D.(config.vField);
trim_source.w = D.(config.wField);
trim_source.vortX = D.(config.vortXField);
trim_source.vortY = D.(config.vortYField);
trim_source.vortZ = D.(config.vortZField);
trim_source.uncTot = D.(config.uncField);
trim_source.Utot = D.(config.UtotField);
trim_source.Utot_diff = D.(config.UtotDiffField);
trim_source.vortTot = D.(config.vortTotField);
trim_source.numP = D.(config.numPField);
trim_source.hel = D.(config.helField);
trim_source.dudx = D.(config.dudxField);
trim_source.dudy = D.(config.dudyField);
trim_source.dudz = D.(config.dudzField);
trim_source.dvdx = D.(config.dvdxField);
trim_source.dwdx = D.(config.dwdxField);
trim_source.KE_diff = S.KE_diff_field;
trim_source.power = S.power_field;
trim_source.Q = Q; % trimmed like the other fields, for the Q centroid

% vorticity of the averaged velocity (only in files processed after it
% was added)
has_uavg = isfield(config, 'vortXUavgField') && isfield(D, config.vortXUavgField);
if has_uavg
    trim_source.vortX_uavg = D.(config.vortXUavgField);
    trim_source.vortY_uavg = D.(config.vortYUavgField);
    trim_source.vortZ_uavg = D.(config.vortZUavgField);
else
    disp("No vorticity of the averaged velocity in this file; lift_uavg / drag_uavg skipped")
end

% TURNED OFF TEMPORARILY SINCE NOT SUPPORTED BY TIME AVERAGE
% trim_source.uu = D.(config.uuField);
% trim_source.vv = D.(config.vvField);
% trim_source.ww = D.(config.wwField);
% trim_source.uv = D.(config.uvField);
% trim_source.uw = D.(config.uwField);
% trim_source.vw = D.(config.vwField);
% trim_source.uwx = D.(config.uwxField);
% trim_source.uwy = D.(config.uwyField);

print_dim_bool = false;
fill_velocity_nans = true;
[F, y_tr, z_tr, T] = prepare_STB_wake_field(D.L, D.y, D.z, print_dim_bool, trim_source, config.xConvBins, bounds, fill_velocity_nans);
F.period = config.period;

y_arr = squeeze(y_tr(:,1));
z_arr = squeeze(z_tr(1,:));

[lift_vel, drag_vel] = get_wake_lift(config.speed, config.length, F, false, config.density);
S.lift_vel = lift_vel; S.drag_vel = drag_vel;

[lift, drag] = get_wake_lift(config.speed, config.length, F, true, config.density);
S.lift = lift; S.drag = drag;

% Same forces using the vorticity of the averaged velocity
if has_uavg
    F_uavg = F;
    F_uavg.vortX = T.vortX_uavg;
    F_uavg.vortY = T.vortY_uavg;
    F_uavg.vortZ = T.vortZ_uavg;
    [lift_uavg, drag_uavg] = get_wake_lift(config.speed, config.length, F_uavg, true, config.density);
    S.lift_uavg = lift_uavg; S.drag_uavg = drag_uavg;
end

if config.includeHelmDecomp
    [y_B, z_B, velX_B, velY_B, velZ_B, iy_B, iz_B] = helm_decomp(config.xConv, y_arr, z_arr, config.length, F);
    S.y_B = y_B; S.z_B = z_B; S.velX_B = velX_B; S.velY_B = velY_B; S.velZ_B = velZ_B;

    % Velocity-only lift/drag (same as lift_vel / drag_vel, vort_bool
    % false) but on the extrapolated field instead of the measured window.
    % velX_B is the induced perturbation (u + U)/U, so the full streamwise
    % velocity is velX_B - 1 (x points upstream, u ~ -U), as in
    % flowField_UI. Fields are stored [time y z]; get_wake_lift wants
    % [y z time].
    F_B.x = config.xConv;
    F_B.y = y_B;
    F_B.z = z_B;
    F_B.u = permute(velX_B, [2 3 1]) - 1;
    F_B.v = permute(velY_B, [2 3 1]);
    F_B.w = permute(velZ_B, [2 3 1]);
    [lift_vel_B, drag_vel_B] = get_wake_lift(config.speed, config.length, F_B, false, config.density);
    % get_wake_lift integrates a half plane and doubles it, but y_B/z_B
    % cover the full mirrored plane. The integrands (u*w, u*(u+U)) are
    % symmetric about the centreline, so halve the full-plane result
    % rather than cutting the plane (y_B need not have a row at y = 0).
    S.lift_vel_B = lift_vel_B / 2;
    S.drag_vel_B = drag_vel_B / 2;

    % Same again on a filled field: the measured velocity inside the field
    % of view, the extrapolated velocity only outside it. The measured
    % half plane (F, already hole-filled) is mirrored like the vorticity in
    % helm_decomp and put where helm_decomp placed the field of view
    % (iy_B, iz_B; same grid spacing), so the two line up point for point.
    % Mirroring y -> -y: u and w are even, v is odd.
    F_fill = F_B;
    u_meas = mirror_half_plane(F.u, 1);
    v_meas = mirror_half_plane(F.v, -1);
    w_meas = mirror_half_plane(F.w, 1);
    y_fov = iy_B;
    z_fov = iz_B;
    F_fill.u(y_fov, z_fov, :) = u_meas;
    F_fill.v(y_fov, z_fov, :) = v_meas;
    F_fill.w(y_fov, z_fov, :) = w_meas;
    [lift_vel_B_fill, drag_vel_B_fill] = get_wake_lift(config.speed, config.length, F_fill, false, config.density);
    % full mirrored plane, halved as above
    S.lift_vel_B_fill = lift_vel_B_fill / 2;
    S.drag_vel_B_fill = drag_vel_B_fill / 2;

    % Extrapolated minus measured velocity on the field of view, / U, for
    % checking the extrapolation (flowField_UI: "u/v/w: extrap - meas").
    % Same [time y z] layout as velX_B, on the grid y_B_fov, z_B_fov.
    S.y_B_fov = y_B(y_fov, z_fov);
    S.z_B_fov = z_B(y_fov, z_fov);
    S.velX_B_diff = permute(F_B.u(y_fov, z_fov, :) - u_meas, [3 1 2]);
    S.velY_B_diff = permute(F_B.v(y_fov, z_fov, :) - v_meas, [3 1 2]);
    S.velZ_B_diff = permute(F_B.w(y_fov, z_fov, :) - w_meas, [3 1 2]);

    Utot_full = velX_B.^2 + velY_B.^2 + velZ_B.^2;
    KE_tot_field = permute(Utot_full,[2 3 1]);
    KE_tot = trapz(squeeze(y_B(:,1)), KE_tot_field, 1);
    KE_tot = trapz(squeeze(z_B(1,:)), KE_tot, 2);
    S.KE_tot = squeeze(KE_tot) * config.density;
end

% Integral quantities
S.KE = integrate_planar(y_arr, z_arr, T.Utot.^2 * config.density);
S.KE_diff = integrate_planar(y_arr, z_arr, T.KE_diff);
S.power = integrate_planar(y_arr, z_arr, T.power);
S.enst = integrate_planar(y_arr, z_arr, T.vortTot.^2);
S.div = D.(config.dudxField) + D.(config.dvdyField) + D.(config.dwdzField);

% Planar averages
S.u_avg = squeeze(mean(T.u, [1, 2]));
S.v_avg = squeeze(mean(T.v, [1, 2]));
S.w_avg = squeeze(mean(T.w, [1, 2]));
S.vortX_avg = squeeze(mean(T.vortX, [1, 2]));
S.vortY_avg = squeeze(mean(T.vortY, [1, 2]));
S.vortZ_avg = squeeze(mean(T.vortZ, [1, 2]));
if has_uavg
    S.vortX_uavg_avg = squeeze(mean(T.vortX_uavg, [1, 2]));
    S.vortY_uavg_avg = squeeze(mean(T.vortY_uavg, [1, 2]));
    S.vortZ_uavg_avg = squeeze(mean(T.vortZ_uavg, [1, 2]));
end
S.numP_avg = squeeze(mean(T.numP, [1, 2]));
S.unc_avg = squeeze(mean(T.uncTot, [1, 2]));
S.hel_avg = squeeze(mean(T.hel, [1, 2]));
S.dudx_avg = squeeze(mean(T.dudx, [1, 2]));
S.dvdx_avg = squeeze(mean(T.dvdx, [1, 2]));
S.dwdx_avg = squeeze(mean(T.dwdx, [1, 2]));

% TURNED OFF TEMPORARILY SINCE NOT SUPPORTED BY TIME AVERAGE
% S.uu_avg = squeeze(mean(T.uu, [1, 2]));
% S.vv_avg = squeeze(mean(T.vv, [1, 2]));
% S.ww_avg = squeeze(mean(T.ww, [1, 2]));
% S.uv_avg = squeeze(mean(T.uv, [1, 2]));
% S.uw_avg = squeeze(mean(T.uw, [1, 2]));
% S.vw_avg = squeeze(mean(T.vw, [1, 2]));
% S.uwx_avg = squeeze(mean(T.uwx, [1, 2]));
% S.uwy_avg = squeeze(mean(T.uwy, [1, 2]));

% Vortex centroids from streamwise vorticity, perhaps a flawed metric since
% this has a singularity when the planar average of vorticity is zero
S.wx_z = integrate_planar(y_arr, z_arr, z_tr .* T.vortX) ./ integrate_planar(y_arr, z_arr, T.vortX);
S.wx_y = integrate_planar(y_arr, z_arr, y_tr .* T.vortX) ./ integrate_planar(y_arr, z_arr, T.vortX);

% Vortex core centroids weighted by positive Q only (Q > 0 marks vortex
% cores; the negative, strain-dominated regions would partly cancel the
% denominator). Q is trimmed and recentred like y_tr, z_tr.
Q_pos = max(T.Q, 0);
S.Qx_z = integrate_planar(y_arr, z_arr, z_tr .* Q_pos) ./ integrate_planar(y_arr, z_arr, Q_pos);
S.Qx_y = integrate_planar(y_arr, z_arr, y_tr .* Q_pos) ./ integrate_planar(y_arr, z_arr, Q_pos);

% Vortex stretching/tilting terms for \omega_x term
S.wx_stretch = integrate_planar(y_arr, z_arr, T.vortX .* T.dudx);
S.wx_tilt_y = integrate_planar(y_arr, z_arr, T.vortY .* T.dudy);
S.wx_tilt_z = integrate_planar(y_arr, z_arr, T.vortZ .* T.dudz);

end

function config = set_defaults(config)
if ~isfield(config, 'xConv')
    config.xConv = 0;
end
if ~isfield(config, 'xConvBins')
    config.xConvBins = config.xConv;
end
if ~isfield(config, 'period')
    config.period = NaN;
end

if ~isfield(config, 'includeHelmDecomp')
    config.includeHelmDecomp = false;
end
end

function full = mirror_half_plane(half, parity)
% Reflect a [y z time] half-plane field about its first y row (the
% centreline), as in helm_decomp, skipping that row so it isn't doubled.
% parity is 1 for components even in y (u, w) and -1 for odd ones (v).
full = cat(1, parity * flip(half(2:end,:,:), 1), half);
end

function value = integrate_planar(y_arr, z_arr, field)
value = trapz(y_arr, field, 1);
value = trapz(z_arr, value, 2);
value = squeeze(value);
end
