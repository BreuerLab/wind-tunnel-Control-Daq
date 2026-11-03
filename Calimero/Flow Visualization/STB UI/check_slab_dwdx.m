% CHECK_SLAB_DWDX  Is the slab x-derivative of w what makes lift.vortY low?
%
% Background (see get_wake_lift). Over the half plane,
%   int omega_y dA = int [u(z_top) - u(z_bottom)] dy  -  d/dx int w dA
% and int y omega_x dA ~ -int w dA (+ edge terms). So with W(x, t) the
% plane integral of w, lift.vortY is essentially the slab estimate of
% dW/dx (integrated over time), and lift.vortX is essentially W itself.
% With frozen flow the two agree only if
%       slab dW/dx  =  (1/U_c) dW/dt     (x points upstream)
% This script measures both sides from the phase-averaged files, per case:
%
%   W_k(t)      mean of w/U over the window on plane k (k = 1..nx), holes
%               filled per plane (nanRegionFill), over the points that have
%               data on every plane in >= min_valid of the bins
%   slab 2-4    (W_4 - W_2) / (x_4 - x_2)        (2nd order, inner planes)
%   slab 1-5    (W_5 - W_1) / (x_5 - x_1)        (outer planes)
%   slab 4th    5-point 4th-order stencil
%   stored      plane mean of the stored dwdx_phase_avg (centre plane)
%   frozen      (L / U_c) dW_3/dt  (periodic_ddt at the actual bin times)
%   vortY       plane mean of the stored omega_y over the full window vs
%               its frozen-flow version (dw/dx swapped for the frozen one):
%               this ratio is the lift.vortY / lift.vortX gap itself
%
% For each: the rms ratio (slab / frozen, over the wingbeat, mean removed),
% the correlation and the lag (t/T) between them. Also each plane's W
% amplitude relative to the centre plane and its lag, next to the lag
% frozen flow predicts for that plane's x offset.
%
% Reading it: ratio ~1 with correlation ~1 = the slab derivative is fine.
% Ratio ~0.65 at every frequency = a fixed gain error in the slab
% derivative. If "slab 2-4" is ~1 but "stored" / "slab 4th" / "slab 1-5"
% are low, the outer planes are the problem; plane amplitudes below 1 on
% planes 1 and 5 show how.
%
% Ronan's question 11/03/2026 (vortY vs vortX gap); written by Claude.

clear
close all

cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

% ------------------------------- settings -------------------------------
data_root  = "F:\";
types      = ["x2_wings", "x4_wings"];
amp        = 20;              % deg
freqs      = [2 4 6 8];       % Hz
conv_speed = [];              % m/s; [] = each case's freestream (U_act*U)
min_valid  = 0.9;             % fraction of bins a point needs data on every plane
detail_case = "x4_wings_20deg_8Hz";   % time series plotted for this case
% ------------------------------------------------------------------------

rows = {};
cases = {};
for type = types
    for f = freqs
        case_name = type + "_" + amp + "deg_" + f + "Hz";
        file = data_root + "Processed Results\phase_avg\" + case_name + "_phase_avg.mat";
        if ~isfile(file)
            fprintf("%s: no file (%s), skipped\n", case_name, file);
            continue
        end
        R = slab_check_case(file, case_name, conv_speed, min_valid);
        R.type = type;
        R.freq = f;
        cases{end+1} = R; %#ok<SAGROW>
        rows{end+1} = R.summary; %#ok<SAGROW>
        print_case(R);
    end
end
if isempty(rows)
    error("No phase-averaged files found under %s", data_root)
end
T = struct2table(same_fields(rows));
disp(T)

plot_ratios(cases, types);
plot_plane_amplitudes(cases);
k = find(cellfun(@(c) c.case_name == detail_case, cases), 1);
if ~isempty(k)
    plot_time_series(cases{k});
end

% =========================================================================

function R = slab_check_case(file, case_name, conv_speed, min_valid)
have = string(who('-file', file));
vars = ["w_phase_avg", "x", "y", "z", "L", "U", "cycle_freq"];
opt = ["U_act", "bin_placement", "dwdx_phase_avg", "vortY_phase_avg"];
vars = [vars, opt(ismember(opt, have))];
d = load(file, vars{:});

speed = d.U;
if isfield(d, "U_act"), speed = d.U_act * d.U; end
Uc = speed;
if ~isempty(conv_speed), Uc = conv_speed; end

freq = d.cycle_freq;
if ~(freq > 0), [~, ~, freq] = parse_name(case_name); end
period = 1 / freq;
nx = size(d.w_phase_avg, 1);
nb = size(d.w_phase_avg, 4);
placement = [];
if isfield(d, "bin_placement"), placement = d.bin_placement; end
t = bin_times(nb, period, placement);   % actual (mean-phase) bin times
ic = ceil(nx / 2);
if nx < 3
    error("%s: only %d planes", case_name, nx)
end

% lift integration window (same bounds as the stored forces)
[~, stem] = fileparts(file);
bounds = old_flapper_compat("trim_bounds_for", stem, default_trim_bounds());
yv = squeeze(d.y(1, :, 1));
zv = squeeze(d.z(1, 1, :))';
iy = find(yv > bounds.ybounds(1) & yv < bounds.ybounds(2) & yv >= bounds.y_cen);
iz = find(zv > bounds.zbounds(1) & zv < bounds.zbounds(2));
xk = d.x(:, 1, 1);                       % plane positions (x/L, signed)

w = d.w_phase_avg(:, iy, iz, :);         % [nx ny nz nb], w/U
ny = numel(iy); nz = numel(iz);
valid = squeeze(mean(all(isfinite(w), 1), 4)) >= min_valid;   % [ny nz]
coverage = mean(valid(:));
if ~any(valid(:))
    error("%s: no point has data on every plane in %.0f%% of the bins", case_name, 100*min_valid)
end

% W_k(t): mean over the common points, holes filled per plane and bin
W = NaN(nx, nb);
for k = 1:nx
    wk = nanRegionFill(reshape(w(k, :, :, :), [ny nz nb]));
    wk = reshape(wk, ny*nz, nb);
    W(k, :) = mean(wk(valid(:), :), 1);
end

% slab estimates of dW/dx at the centre plane
S = struct();
S.slab_24 = (W(ic+1, :) - W(ic-1, :)) / (xk(ic+1) - xk(ic-1));
if nx >= 5
    S.slab_15 = (W(ic+2, :) - W(ic-2, :)) / (xk(ic+2) - xk(ic-2));
    h = xk(ic+1) - xk(ic);
    S.slab_4th = (-W(ic+2, :) + 8*W(ic+1, :) - 8*W(ic-1, :) + W(ic-2, :)) / (12*h);
end
if isfield(d, "dwdx_phase_avg")
    g = reshape(d.dwdx_phase_avg(ic, iy, iz, :), ny*nz, nb);
    S.stored = mean(g(valid(:), :), 1, "omitnan");
end

% frozen flow: dW/dx = (1/U_c) dW/dt; in the stored units (w/U, d/d(x/L))
% that is (L / U_c) d(W)/dt
F = periodic_ddt(W(ic, :), t, period, 2) * (d.L / Uc);

R.case_name = string(case_name);
R.t = t; R.period = period; R.W = W; R.xk = xk; R.S = S; R.F = F;
R.Uc = Uc; R.nb = nb; R.coverage = coverage;

s.case_name = string(case_name);
s.freq = freq;
s.nb = nb;
s.coverage = coverage;
for n = string(fieldnames(S))'
    [ratio, rho, lag] = compare(S.(n), F);
    s.("ratio_" + n) = ratio;
    s.("corr_" + n) = rho;
    s.("lag_" + n) = lag;
end

% the lift gap itself: plane mean of omega_y (full window, like the lift)
% vs the same with dw/dx swapped for its frozen-flow version
if isfield(d, "vortY_phase_avg") && isfield(d, "dwdx_phase_avg")
    wy = nanRegionFill(reshape(d.vortY_phase_avg(ic, iy, iz, :), [ny nz nb]));
    gx = nanRegionFill(reshape(d.dwdx_phase_avg(ic, iy, iz, :), [ny nz nb]));
    wf = nanRegionFill(reshape(w(ic, :, :, :), [ny nz nb]));
    Wfull = squeeze(mean(wf, [1 2]))';
    Ffull = periodic_ddt(Wfull, t, period, 2) * (d.L / Uc);
    wy_slab = squeeze(mean(wy, [1 2]))';
    wy_ff = wy_slab + squeeze(mean(gx, [1 2]))' - Ffull;
    [s.ratio_vortY, s.corr_vortY] = compare(wy_slab, wy_ff);
    R.wy_slab = wy_slab; R.wy_ff = wy_ff;
else
    s.ratio_vortY = NaN; s.corr_vortY = NaN;
end

% each plane's W relative to the centre plane: amplitude, lag, and the lag
% frozen flow predicts (plane further upstream, larger x, sees it earlier)
Wc = W(ic, :) - mean(W(ic, :));
R.plane_amp = NaN(nx, 1);
R.plane_lag = NaN(nx, 1);
R.plane_lag_ff = (xk - xk(ic)) * d.L / Uc / period;   % lead, in t/T
for k = 1:nx
    Wk = W(k, :) - mean(W(k, :));
    R.plane_amp(k) = rms0(Wk) / rms0(Wc);
    [~, ~, lag] = compare(Wk, Wc);
    R.plane_lag(k) = lag;
end
s.plane_amp = strjoin(compose("%.2f", R.plane_amp(:)'), " ");
R.summary = s;
end

function [ratio, rho, lag] = compare(a, b)
% rms ratio a/b (means removed), correlation, and the lag (t/T, circular)
% that best aligns a onto b (positive: a is delayed to match b)
a = a(:)' - mean(a); b = b(:)' - mean(b);
ratio = rms0(a) / rms0(b);
rho = sum(a .* b) / sqrt(sum(a.^2) * sum(b.^2));
n = numel(a);
lags = -floor(n/2):(ceil(n/2) - 1);
c = arrayfun(@(k) sum(b .* circshift(a, k)), lags);
[~, i] = max(c);
lag = lags(i) / n;
end

function r = rms0(a)
r = sqrt(mean(a(:).^2));
end

function s = same_fields(rows)
% struct array of the summaries, NaN for fields a case doesn't have
names = {};
for i = 1:numel(rows), names = union(names, fieldnames(rows{i}), 'stable'); end
for i = 1:numel(rows)
    for j = 1:numel(names)
        if ~isfield(rows{i}, names{j}), rows{i}.(names{j}) = NaN; end
    end
    rows{i} = orderfields(rows{i}, names);
end
s = [rows{:}];
end

function print_case(R)
fprintf("\n%s  (U_c = %.2f m/s, %d bins, %.0f%% of the window has all planes)\n", ...
    R.case_name, R.Uc, R.nb, 100*R.coverage);
s = R.summary;
for n = string(fieldnames(R.S))'
    fprintf("  %-9s rms ratio %.2f   corr %+.2f   lag %+.3f T\n", n, ...
        s.("ratio_" + n), s.("corr_" + n), s.("lag_" + n));
end
fprintf("  omega_y   rms ratio %.2f   corr %+.2f   (stored / frozen-flow plane mean)\n", ...
    s.ratio_vortY, s.corr_vortY);
fprintf("  plane W amplitude / centre: %s\n", s.plane_amp);
fprintf("  plane lag (t/T) measured:   %s\n", strjoin(compose("%+.3f", R.plane_lag(:)'), " "));
fprintf("  plane lead, frozen flow:    %s\n", strjoin(compose("%+.3f", R.plane_lag_ff(:)'), " "));
end

function plot_ratios(cases, types)
fields = ["slab_24", "slab_15", "slab_4th", "stored", "vortY"];
labels = ["slab 2-4", "slab 1-5", "slab 4th", "stored dw/dx", "\omega_y (lift gap)"];
markers = ["o", "s", "^", "d", "p"];
lines = ["-", "--", ":", "-."];
figure("Name", "Slab vs frozen-flow dW/dx");
hold on
for i = 1:numel(types)
    sel = cases(cellfun(@(c) c.type == types(i), cases));
    if isempty(sel), continue, end
    f = cellfun(@(c) c.freq, sel);
    for j = 1:numel(fields)
        name = "ratio_" + fields(j);
        if ~isfield(sel{1}.summary, name), continue, end
        r = cellfun(@(c) c.summary.(name), sel);
        plot(f, r, lines(mod(i-1, numel(lines)) + 1) + markers(j), "LineWidth", 1.5, ...
            "MarkerSize", 8, "DisplayName", types(i) + ": " + labels(j));
    end
end
yline(1, "k:", "HandleVisibility", "off");
xlabel("Wingbeat frequency (Hz)");
ylabel("rms ratio  slab / frozen flow");
legend("Location", "bestoutside", "Interpreter", "tex");
grid on
hold off
end

function plot_plane_amplitudes(cases)
figure("Name", "W amplitude per plane");
hold on
for i = 1:numel(cases)
    c = cases{i};
    plot(1:numel(c.plane_amp), c.plane_amp, "-o", "LineWidth", 1.2, ...
        "DisplayName", c.case_name);
end
yline(1, "k:", "HandleVisibility", "off");
xlabel("Plane"); ylabel("rms of W_k / rms of W_{centre}");
legend("Location", "bestoutside", "Interpreter", "none");
grid on
hold off
end

function plot_time_series(c)
figure("Name", "dW/dx over the wingbeat: " + c.case_name);
tT = c.t / c.period;
hold on
plot(tT, c.F - mean(c.F), "k-", "LineWidth", 2, "DisplayName", "frozen (L/U_c) dW/dt");
for n = string(fieldnames(c.S))'
    v = c.S.(n);
    plot(tT, v - mean(v), "-", "LineWidth", 1.2, "DisplayName", n);
end
xlabel("t/T"); ylabel("dW/dx  (w/U per x/L)");
title(c.case_name, "Interpreter", "none");
legend("Location", "best", "Interpreter", "none");
grid on
hold off
end
