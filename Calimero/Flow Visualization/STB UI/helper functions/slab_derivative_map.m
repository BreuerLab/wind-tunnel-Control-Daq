function M = slab_derivative_map(file_path, bounds)
% SLAB_DERIVATIVE_MAP Point-by-point check of the slab-normal derivative
% dw/dx against the frozen-flow estimate (1/U) dw/dt, over the wingbeat.
%
%   M = slab_derivative_map(file_path)
%   M = slab_derivative_map(file_path, bounds)
%
%   file_path  the *_phase_avg.mat file (same one wake_lift_budget uses)
%   bounds     trim bounds (default: default_trim_bounds())
%
%   Plots, on the centre plane:
%     ratio = rms over phase of dw/dx (slab)  /  rms of (1/U) dw/dt
%     rho   = correlation over phase between the two
%   Ratio ~1 with high rho means the slab derivative is trustworthy there.
%   Both fields are nondimensional in the same way, so no rescaling.

if nargin < 2 || isempty(bounds), bounds = default_trim_bounds(); end

d  = load(file_path, 'dwdx_phase_avg', 'w_phase_avg', 'U', 'U_act', 'L', ...
          'cycle_freq', 'y', 'z');
placement = [];
if ismember('bin_placement', who('-file', file_path))
    p = load(file_path, 'bin_placement'); placement = p.bin_placement;
end
U  = d.U_act * d.U;
nb = size(d.w_phase_avg, 4);
period = 1 / d.cycle_freq;
tb = bin_times(nb, period, placement);   % actual (mean-phase) bin times

[y, z, dwdx] = trim_vel_field(d.y, d.z, d.dwdx_phase_avg, bounds);   % [ny nz nb]
[~, ~, w]    = trim_vel_field(d.y, d.z, d.w_phase_avg, bounds);

% w and dw/dx are stored nondimensional (w/U, dw/dx * L/U), so the
% frozen-flow estimate in the same units is (L/U) * dw/dt / U.
dwdt_U = periodic_ddt(w, tb, period, 3) * (d.L / U);

a = dwdx   - mean(dwdx, 3, 'omitnan');
b = dwdt_U - mean(dwdt_U, 3, 'omitnan');
M.ratio = std(a, 0, 3, 'omitnan') ./ std(b, 0, 3, 'omitnan');
M.rho   = sum(a.*b, 3, 'omitnan') ./ sqrt(sum(a.^2, 3, 'omitnan') .* sum(b.^2, 3, 'omitnan'));
M.y = y; M.z = z;

fprintf("median ratio %.2f, median correlation %.2f\n", ...
    median(M.ratio(:), 'omitnan'), median(M.rho(:), 'omitnan'));

figure('Name', "Slab dw/dx vs frozen flow");
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile; pcolor(y, z, M.ratio); shading interp; axis equal tight; colorbar;
clim([0 2]); xlabel('y/c'); ylabel('z/c');
title('rms ratio: slab \partial_x w / (1/U)\partial_t w');
nexttile; pcolor(y, z, M.rho); shading interp; axis equal tight; colorbar;
clim([-1 1]); xlabel('y/c'); ylabel('z/c');
title('correlation over phase');
end
