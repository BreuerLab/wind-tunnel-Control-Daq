function S = calc_secondary_vals_common(D, config)
% Shared secondary calculations for STB averages.

config = set_defaults(config);

% Spatial resolution
dx = abs(D.x(2,1,1) - D.x(1,1,1));
dy = abs(D.y(1,2,1) - D.y(1,1,1));
dz = abs(D.z(1,1,2) - D.z(1,1,1));

% Compute Q-Criterion
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
trim_source.dvdx = D.(config.dvdxField);
trim_source.dwdx = D.(config.dwdxField);
trim_source.KE_diff = S.KE_diff_field;
trim_source.power = S.power_field;

print_dim_bool = false;
fill_velocity_nans = true;
[F, y_tr, z_tr, T] = prepare_STB_wake_field(D.L, D.y, D.z, print_dim_bool, trim_source, config.xConv, fill_velocity_nans);

y_arr = squeeze(y_tr(:,1));
z_arr = squeeze(z_tr(1,:));

[lift_vel, drag_vel] = get_wake_lift(config.speed, config.length, F, false, config.density);
S.lift_vel = lift_vel; S.drag_vel = drag_vel;

[lift, drag] = get_wake_lift(config.speed, config.length, F, true, config.density);
S.lift = lift; S.drag = drag;

if config.includeHelmDecomp
    [y_B, z_B, velX_B, velY_B, velZ_B] = helm_decomp(config.xConv, y_arr, z_arr, config.length, F);
    S.y_B = y_B; S.z_B = z_B; S.velX_B = velX_B; S.velY_B = velY_B; S.velZ_B = velZ_B;

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
S.u_avg = mean(T.u, [1, 2]);
S.v_avg = mean(T.v, [1, 2]);
S.w_avg = mean(T.w, [1, 2]);
S.vortX_avg = mean(T.vortX, [1, 2]);
S.vortY_avg = mean(T.vortY, [1, 2]);
S.vortZ_avg = mean(T.vortZ, [1, 2]);
S.numP_avg = mean(T.numP, [1, 2]);
S.unc_avg = mean(T.uncTot, [1, 2]);
S.hel_avg = mean(T.hel, [1, 2]);
S.dudx_avg = mean(T.dudx, [1, 2]);
S.dvdx_avg = mean(T.dvdx, [1, 2]);
S.dwdx_avg = mean(T.dwdx, [1, 2]);
end

function config = set_defaults(config)
if ~isfield(config, 'xConv')
    config.xConv = 0;
end

if ~isfield(config, 'includeHelmDecomp')
    config.includeHelmDecomp = false;
end
end

function value = integrate_planar(y_arr, z_arr, field)
value = trapz(y_arr, field, 1);
value = trapz(z_arr, value, 2);
value = squeeze(value);
end
