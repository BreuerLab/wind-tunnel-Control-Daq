function R = get_frozen_flow_fields(file_name, case_name, bounds)
% GET_FROZEN_FLOW_FIELDS Slab and frozen-flow streamwise gradients and
% omega_y, omega_z on the centre plane of a phase-averaged file.
%
%   R = get_frozen_flow_fields(file_name, case_name)
%   R = get_frozen_flow_fields(file_name, case_name, bounds)
%
%   file_name  the *_phase_avg.mat file
%   case_name  case name (only used for old flapper trim bounds)
%   bounds     trim bounds (trim_vel_field, recentred on y_cen, z_cen);
%              [] or omitted = the untrimmed centre plane
%
%   R.slab.(q) and R.ff.(q) for q = dudx, dvdx, dwdx, vortY, vortZ and
%   div (du/dx + dv/dy + dw/dz; only if dvdy, dwdz are in the file):
%   [ny nz nb], nondimensional like the processed files (* L/U). slab is
%   what's stored (derivative across the measured planes), ff the
%   frozen-flow version (frozen_flow_gradients, d/dx = (1/U) d/dt).
%   R.y, R.z (y/c, z/c), R.t (bin times, s), R.period, R.L, R.U,
%   R.ddt_method ("harmonic" for harmonic regression files, where d/dt is
%   the exact derivative of the fitted series, else "finite difference").
%
%   Same steps as calc_secondary_vals_common / get_PIV_force: velocity
%   hole-filled plane by plane (nanRegionFill) before d/dt.

if nargin < 3, bounds = []; end

need = ["u_phase_avg", "v_phase_avg", "w_phase_avg", "vortY_phase_avg", "vortZ_phase_avg", ...
        "dudx_phase_avg", "dvdx_phase_avg", "dwdx_phase_avg"];
have = string(stb_who(file_name));
missing = need(~ismember(need, have));
if ~isempty(missing)
    error("get_frozen_flow_fields: %s not in %s", strjoin(missing, ", "), stb_name(file_name))
end
optional = ["dvdy_phase_avg", "dwdz_phase_avg"];   % divergence check
optional = optional(ismember(optional, have));
has_div = numel(optional) == 2;
vars = ["L", "U", "cycle_freq", "y", "z", need, optional];
if ismember("U_act", have), vars(end+1) = "U_act"; end
if ismember("hr", have), vars(end+1) = "hr"; end
if ismember("bin_placement", have), vars(end+1) = "bin_placement"; end
d = stb_load(file_name, vars{:});

speed = d.U;
if isfield(d, 'U_act'), speed = d.U_act * d.U; end
freq = 0;
if isfield(d, 'cycle_freq'), freq = d.cycle_freq; end
if ~(freq > 0)
    [~, ~, freq] = parse_name(case_name);
end
if ~(freq > 0)
    error("get_frozen_flow_fields: no cycle frequency for %s", string(case_name))
end
period = 1 / freq;
nb = size(d.u_phase_avg, 4);
placement = [];
if isfield(d, 'bin_placement'), placement = d.bin_placement; end
t = bin_times(nb, period, placement);   % actual (mean-phase) bin times

names = ["u", "v", "w", "vortY", "vortZ", "dudx", "dvdx", "dwdx"];
if has_div, names = [names, "dvdy", "dwdz"]; end
if isempty(bounds)
    ip = ceil(size(d.u_phase_avg, 1) / 2);   % centre plane
    R.y = squeeze(d.y(ip, :, :));
    R.z = squeeze(d.z(ip, :, :));
    for n = names
        P.(n) = reshape(d.(n + "_phase_avg")(ip, :, :, :), [size(R.y), nb]);
    end
else
    file_stem = stb_name(file_name);
    bounds = old_flapper_compat("trim_bounds_for", file_stem, bounds);
    for n = names
        [R.y, R.z, P.(n)] = trim_vel_field(d.y, d.z, d.(n + "_phase_avg"), bounds);
    end
end

P.u = nanRegionFill(P.u);
P.v = nanRegionFill(P.v);
P.w = nanRegionFill(P.w);

ff_opts = struct();
if isfield(d, 'hr') && isstruct(d.hr) && isfield(d.hr, 'H'), ff_opts.H = d.hr.H; end
G = frozen_flow_gradients(P, t, period, d.L, speed, ff_opts);

for q = ["dudx", "dvdx", "dwdx", "vortY", "vortZ"]
    R.slab.(q) = nanRegionFill(P.(q));
    R.ff.(q) = G.(q + "_ff");
end
if has_div
    R.slab.div = G.div_slab;
    R.ff.div = G.div_ff;
end
R.ddt_method = G.ddt_method;
R.t = t; R.period = period; R.L = d.L; R.U = speed;
end
