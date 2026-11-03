function centroid = get_Q_centroid(file_name, secondary_file_name, var_name, bounds)
% GET_Q_CENTROID Live calculation of the Q-weighted vortex core centroid
% (Qx_y or Qx_z), with the trim bounds and uncertainty mask in bounds.
%
%   centroid = get_Q_centroid(file_name, secondary_file_name, var_name, bounds)
%
%   file_name           - averaged file (_time_avg.mat / _phase_avg.mat):
%                         y, z and the total uncertainty
%   secondary_file_name - matching _integral.mat, which holds Q
%   var_name            - "Qx_y" or "Qx_z"
%   bounds              - trim limits, centre point and uncertainty mask
%                         (default_trim_bounds / timeAvg_UI Live Calc Bounds)
%
%   Same definition as calc_secondary_vals_common: positive Q only, on the
%   trimmed and recentred plane (y/L, z/L), one value per phase bin. Points
%   removed by the uncertainty mask (unc_mask_region, same threshold and
%   mode as the forces) carry no weight.

var_name = string(var_name);
if ~ismember(var_name, ["Qx_y", "Qx_z"])
    error("get_Q_centroid: var_name must be ""Qx_y"" or ""Qx_z""")
end

% old flapper cases use the bounds they were analysed with
[~, file_stem] = fileparts(string(file_name));
bounds = old_flapper_compat("trim_bounds_for", file_stem, bounds);

file_vars = string(who('-file', file_name));
if ismember("mean_uncTot", file_vars)
    unc_name = "mean_uncTot";
elseif ismember("uncTot_phase_avg", file_vars)
    unc_name = "uncTot_phase_avg";
else
    unc_name = "";
end
load_vars = {'y', 'z'};
if unc_name ~= "", load_vars{end+1} = char(unc_name); end
d = load(file_name, load_vars{:});

if ~ismember("Q", string(who('-file', secondary_file_name)))
    error("get_Q_centroid: Q not in %s, reprocess the case", secondary_file_name)
end
q = load(secondary_file_name, 'Q');

[y_tr, z_tr, Q_tr] = trim_vel_field(d.y, d.z, q.Q, bounds);
Q_pos = max(Q_tr, 0);

thresh = [];
mode = "threshold";
if isfield(bounds, 'unc_mask'), thresh = bounds.unc_mask; end
if isfield(bounds, 'unc_mask_mode'), mode = bounds.unc_mask_mode; end
if unc_name ~= "" && ~isempty(thresh) && thresh > 0
    [~, ~, unc_tr] = trim_vel_field(d.y, d.z, d.(unc_name), bounds);
    mask = unc_mask_region(unc_tr, thresh, mode);
    Q_pos(repmat(mask, 1, 1, size(Q_pos, 3))) = 0;
end

y_arr = y_tr(:, 1);
z_arr = z_tr(1, :);
if var_name == "Qx_y"
    coord = y_tr;
else
    coord = z_tr;
end
num = squeeze(trapz(z_arr, trapz(y_arr, coord .* Q_pos, 1), 2));
den = squeeze(trapz(z_arr, trapz(y_arr, Q_pos, 1), 2));
centroid = num ./ den;
end
