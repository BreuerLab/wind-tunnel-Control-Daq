function [F, mask] = apply_unc_mask(F, unc, thresh)
% APPLY_UNC_MASK Leave high-uncertainty points out of the wake force
% integrals.
%
%   [F, mask] = apply_unc_mask(F, unc, thresh)
%
%   F      - trimmed, hole-filled, nondimensional fields as passed to
%            get_wake_lift (u, v, w and any of vortX, vortY, vortZ,
%            vortX_uavg, vortY_uavg, vortZ_uavg), [ny nz] or [ny nz nb]
%   unc    - total uncertainty on the same grid (uncTot / U), [ny nz] for a
%            time average or [ny nz nb] for a phase average
%   thresh - threshold as a fraction of the freestream speed (e.g. 0.04);
%            [] or <= 0 leaves F unchanged and returns mask = []
%
%   The mask is fixed over the wingbeat: a point is masked where its
%   uncertainty averaged over the phase bins (the time averaged
%   uncertainty) is above thresh, or where it has no uncertainty at all
%   (never measured). Masked points are set to undisturbed freestream,
%   u = -1 (x points upstream, u ~ -U), v = w = 0 and zero vorticity, so
%   every integrand in get_wake_lift is zero there and they add nothing
%   to any force. mask is [ny nz] logical.
%
%   Threshold set in default_trim_bounds (bounds.unc_mask); used for the
%   saved forces (calc_secondary_vals_common) and the live forces in the
%   UIs (get_PIV_force).

mask = [];
if nargin < 3 || isempty(thresh) || thresh <= 0
    return
end

unc_t = mean(unc, 3, "omitnan");
mask = unc_t > thresh | isnan(unc_t);

if isfield(F, 'u')
    F.u(repmat(mask, 1, 1, size(F.u, 3))) = -1;
end
zero_names = {'v', 'w', 'vortX', 'vortY', 'vortZ', 'vortX_uavg', 'vortY_uavg', 'vortZ_uavg'};
for k = 1:numel(zero_names)
    n = zero_names{k};
    if isfield(F, n) && ~isempty(F.(n))
        F.(n)(repmat(mask, 1, 1, size(F.(n), 3))) = 0;
    end
end
end
