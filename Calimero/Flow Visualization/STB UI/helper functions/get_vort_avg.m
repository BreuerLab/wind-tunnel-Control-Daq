function avg = get_vort_avg(file_name, var_name, bounds)
% GET_VORT_AVG Live calculation of the planar average of a vorticity
% component (vortX_avg, vortY_avg, vortZ_avg) with the trim bounds,
% uncertainty mask and Crop Box in bounds.
%
%   avg = get_vort_avg(file_name, var_name, bounds)
%
%   file_name - averaged file (_time_avg.mat / _phase_avg.mat): y, z, the
%               vorticity (mean_vortX / vortX_phase_avg, ...) and the
%               total uncertainty
%   var_name  - "vortX_avg", "vortY_avg" or "vortZ_avg"
%   bounds    - trim limits, centre point, uncertainty mask and Crop Box
%               (default_trim_bounds / timeAvg_UI Live Calc Bounds)
%
%   Same definition as calc_secondary_vals_common (mean over the trimmed,
%   recentred centre plane, one value per phase bin). Points removed by
%   the uncertainty mask (unc_mask_region, same threshold and mode as the
%   forces) or inside the Crop Box (crop_box_region) are treated as
%   undisturbed freestream, as for the forces: zero vorticity, still part
%   of the plane the average is taken over. Remaining holes (NaN) are left
%   out of the average.

var_name = string(var_name);
comps = ["vortX_avg", "vortY_avg", "vortZ_avg"];
if ~ismember(var_name, comps)
    error("get_vort_avg: var_name must be vortX_avg, vortY_avg or vortZ_avg")
end
comp = extractBefore(var_name, "_avg"); % vortX, vortY, vortZ

% old flapper cases use the bounds they were analysed with
bounds = old_flapper_compat("trim_bounds_for", stb_name(file_name), bounds);

file_vars = string(stb_who(file_name));
if ismember("mean_" + comp, file_vars)
    vort_name = "mean_" + comp;         % time average
elseif ismember(comp + "_phase_avg", file_vars)
    vort_name = comp + "_phase_avg";    % phase average
else
    error("get_vort_avg: no %s in %s", comp, stb_name(file_name))
end
if ismember("mean_uncTot", file_vars)
    unc_name = "mean_uncTot";
elseif ismember("uncTot_phase_avg", file_vars)
    unc_name = "uncTot_phase_avg";
else
    unc_name = "";
end
load_vars = {'y', 'z', char(vort_name)};
if unc_name ~= "", load_vars{end+1} = char(unc_name); end
d = stb_load(file_name, load_vars{:});

[y_tr, z_tr, vort_tr] = trim_vel_field(d.y, d.z, d.(vort_name), bounds);

thresh = [];
mode = "threshold";
if isfield(bounds, 'unc_mask'), thresh = bounds.unc_mask; end
if isfield(bounds, 'unc_mask_mode'), mode = bounds.unc_mask_mode; end
mask = [];
if unc_name ~= "" && ~isempty(thresh) && thresh > 0
    [~, ~, unc_tr] = trim_vel_field(d.y, d.z, d.(unc_name), bounds);
    mask = unc_mask_region(unc_tr, thresh, mode);
end
% Crop Box, merged with the uncertainty mask (as for the forces)
crop = crop_box_region(y_tr, z_tr, bounds);
if ~isempty(crop)
    if isempty(mask) || ~isequal(size(mask), size(crop))
        mask = crop;
    else
        mask = mask | crop;
    end
end
if ~isempty(mask)
    vort_tr(repmat(mask, 1, 1, size(vort_tr, 3))) = 0;
end

avg = squeeze(mean(vort_tr, [1, 2], "omitnan"));
end
