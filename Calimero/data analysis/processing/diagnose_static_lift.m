% Author: Ronan Gissler (diagnostic written with Claude)
% Last updated: October 2026
%
% Static (fixed-wing) lift consistency check across load cell sessions.
%
% Every trial records wind-on "before" and "after" offsets with the wings
% stationary, so each session contains dozens of static lift measurements
% spread over the session. Zeroed with the session's wind-off tare (the
% initial "offsets" file, as process_trial does), they should all agree,
% and agree with the 0 Hz trials, within and across sessions. This script
% prints and plots them so you can see whether a difference between
% sessions comes from:
%   - drift within a session (static lift trends over time),
%   - an offset between sessions (flat within each session, different
%     levels), e.g. tare taken in a different state or wings mounted
%     differently, or
%   - the tare itself (several initial tares in one folder, or a jump at a
%     tare).
%
% A second figure shows the motor current (mA) for the same readings,
% plus the wind-off tares and final offsets. With the wings stationary the
% motor is still holding position, so this current heats the motor (and
% the load cell it is mounted on): compare it with how far each session's
% static lift and tares drift.
%
% A third figure plots static lift against holding current, one tile per
% session. The controller holds the wings at midstroke against the
% shoulder springs, so the holding current reflects how far the crank sits
% from its target and how hard the springs push. Static lift also drifts
% after each tare, so points are coloured by time since the preceding
% wind-off tare, and the printout fits lift = a + b*current + c*time so the
% current effect (b) is separated from that drift (c).
%
% Set the session folders (the <type>_<date> folders containing
% "raw data" and "processed data") below and run.

clear
close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

sessions = [
    "F:\Force Measurements\10 deg wings\4 m.s\wings_2026_09_27"
    "F:\Force Measurements\20 deg wings\4 m.s\wings_2026_09_26"
    "F:\Force Measurements\30 deg wings\4 m.s\wings_2026_09_27"
    "F:\Force Measurements\10 deg body\4 m.s\body_2026_09_27"
    "F:\Force Measurements\20 deg body\4 m.s\body_2026_09_27"
    "F:\Force Measurements\30 deg body\4 m.s\body_2026_09_27"
    ];
AoA = 10; % deg, only files at this AoA are used
lift_row = 3; % lab frame rows: [drag; side; lift; roll; pitch; yaw]
% offsets columns: [6 load cell channels, motor voltage, motor current, ...]
cur_col = 8;

cal_matrix = obtain_cal("../../DAQ/Calibration Files/Mini40/FT52907.cal");

fig_lift = figure(Name="Static lift");
ax_lift = axes(fig_lift); hold(ax_lift, "on"); grid(ax_lift, "on")
xlabel(ax_lift, "Time since session's first tare (min)")
ylabel(ax_lift, "Static lift, zeroed with wind-off tare (N)")

fig_cur = figure(Name="Static current");
ax_cur = axes(fig_cur); hold(ax_cur, "on"); grid(ax_cur, "on")
xlabel(ax_cur, "Time since session's first tare (min)")
ylabel(ax_cur, "Motor current, wings stationary (mA)")
title(ax_cur, "Wind-off tares (filled), before/after (hollow, line), final offsets (x), 0 Hz trials (squares)")
colors = lines(length(sessions));

fig_sc = figure(Name="Static lift vs current", Position=[80 80 1400 800]);
tl_sc = tiledlayout(fig_sc, "flow", TileSpacing="compact");
title(tl_sc, "Static lift vs holding current (circles: before/after, squares: 0 Hz trials; colour: min since tare)")
ax_sc = gobjects(1, length(sessions));
for s = 1:length(sessions)
    ax_sc(s) = nexttile(tl_sc);
    hold(ax_sc(s), "on"); grid(ax_sc(s), "on")
    xlabel(ax_sc(s), "Holding current (mA)")
    ylabel(ax_sc(s), "Static lift (N)")
end
dt_max = 0; % for a shared colour scale

for s = 1:length(sessions)
    sess = sessions(s);
    offsets_dir = fullfile(sess, "raw data", "offsets data");
    processed_dir = fullfile(sess, "processed data");
    [~, sess_name] = fileparts(sess);
    sess_label = extractBefore(extractAfter(sess, "Force Measurements\"), "\4 m.s") + " (" + sess_name + ")";

    fprintf("\n================================================================\n")
    fprintf("%s\n", sess_label)
    fprintf("================================================================\n")

    % ---- initial (wind-off) tares ----
    files = dir(fullfile(offsets_dir, "*.mat"));
    tare_t = datetime.empty(0,1); tare_v = zeros(0, 6); tare_names = strings(0,1);
    tare_c = zeros(0,1);
    final_t = datetime.empty(0,1); final_c = zeros(0,1);
    static = struct('t', {}, 'kind', {}, 'freq', {}, 'v', {}, 'c', {});
    for k = 1:length(files)
        [~, ts, ~, freq, aoa, ~, ~, ftype] = parse_filename(string(files(k).name));
        if aoa ~= AoA
            continue
        end
        d = load(fullfile(files(k).folder, files(k).name), "offsets");
        v = d.offsets(1, 1:6); % channel means (volts)
        c = NaN; % motor current (mA), as process_data converts it
        if size(d.offsets, 2) >= cur_col
            c = volt_to_cur(d.offsets(1, cur_col), 0);
        end
        switch ftype
            case "offsets"
                tare_t(end+1,1) = timeStr2num(ts); tare_v(end+1,:) = v;
                tare_c(end+1,1) = c;
                tare_names(end+1,1) = string(files(k).name);
            case {"before_offsets", "after_offsets"}
                static(end+1) = struct('t', timeStr2num(ts), 'kind', ftype, 'freq', freq, 'v', v, 'c', c);
            case "final_offsets"
                final_t(end+1,1) = timeStr2num(ts); final_c(end+1,1) = c;
        end
    end
    if isempty(tare_t)
        fprintf("No initial tare found in %s\n", offsets_dir)
        continue
    end
    [tare_t, o] = sort(tare_t); tare_v = tare_v(o,:); tare_names = tare_names(o); tare_c = tare_c(o);
    fprintf("Initial (wind-off) tares: %d\n", numel(tare_t))
    for k = 1:numel(tare_t)
        fprintf("  %s\n", tare_names(k))
    end
    if numel(tare_t) > 1
        % lift difference between tares (a jump here shifts every trial)
        for k = 2:numel(tare_t)
            dl = to_lift(tare_v(k,:) - tare_v(1,:), cal_matrix, AoA, lift_row);
            fprintf("  tare %d - tare 1 = %+.4f N lift\n", k, dl)
        end
    end
    t0 = tare_t(1);
    % mark each wind-off tare (one per repetition: run_experiment takes a
    % tare at the start of every pass through the AoA list in main.m)
    for k = 1:numel(tare_t)
        for ax = [ax_lift, ax_cur]
            xl = xline(ax, minutes(tare_t(k) - t0), ":", Color=colors(s,:));
            xl.HandleVisibility = "off";
        end
    end

    % ---- motor current at the wind-off tares and final offsets ----
    plot(ax_cur, minutes(tare_t - t0), tare_c, 'o', MarkerSize=8, Color=colors(s,:),...
        MarkerFaceColor=colors(s,:), DisplayName=sess_label + " wind-off tares")
    if ~isempty(final_t)
        plot(ax_cur, minutes(final_t - t0), final_c, 'x', MarkerSize=10, LineWidth=1.5,...
            Color=colors(s,:), DisplayName=sess_label + " final offsets (wind on)")
    end

    % ---- wind-on static readings (before / after each trial) ----
    if isempty(static)
        fprintf("No before/after offsets found\n")
    else
        [~, o] = sort([static.t]); static = static(o);
        st_t = NaT(1, numel(static)); st_l = NaN(1, numel(static));
        st_c = [static.c];
        st_dt = NaN(1, numel(static)); % min since preceding wind-off tare
        fprintf("\nStatic wind-on readings (zeroed with the latest tare before each):\n")
        fprintf("  %-20s %-15s %7s %10s %12s\n", "time", "kind", "freq", "lift (N)", "current (mA)")
        for k = 1:numel(static)
            ti = find(tare_t <= static(k).t, 1, 'last');
            if isempty(ti), ti = 1; end
            st_t(k) = static(k).t;
            st_dt(k) = minutes(static(k).t - tare_t(ti));
            st_l(k) = to_lift(static(k).v - tare_v(ti,:), cal_matrix, AoA, lift_row);
            fprintf("  %-20s %-15s %6gHz %+10.4f %12.1f\n", string(static(k).t, "yyyy_MM_dd HH:mm:ss"),...
                static(k).kind, static(k).freq, st_l(k), st_c(k))
        end
        mins = minutes(st_t - t0);
        p = polyfit(mins, st_l, 1);
        fprintf("\nStatic lift: mean %.4f N, std %.4f N, range %.4f N over %.0f min\n",...
            mean(st_l), std(st_l), range(st_l), max(mins) - min(mins))
        fprintf("Linear trend: %+.4f N per hour\n", 60 * p(1))
        fprintf("Static current: mean %.1f mA, range %.1f mA; wind-off tares mean %.1f mA\n",...
            mean(st_c, "omitnan"), range(st_c), mean(tare_c, "omitnan"))
        plot(ax_lift, mins, st_l, 'o-', Color=colors(s,:), MarkerFaceColor="none",...
            DisplayName=sess_label + " static (before/after)")
        plot(ax_cur, mins, st_c, 'o-', Color=colors(s,:), MarkerFaceColor="none",...
            DisplayName=sess_label + " static (before/after)")

        % ---- static lift vs holding current ----
        scatter(ax_sc(s), st_c, st_l, 45, st_dt, "filled", MarkerEdgeColor="k")
        title(ax_sc(s), sess_label, Interpreter="none", FontWeight="normal")
        dt_max = max(dt_max, max(st_dt));
        good = isfinite(st_c) & isfinite(st_l) & isfinite(st_dt);
        if nnz(good) > 3
            R = corrcoef(st_c(good), st_l(good));
            X = [ones(nnz(good),1), st_c(good)', st_dt(good)'];
            coef = X \ st_l(good)';
            res = st_l(good)' - X*coef;
            % fit of lift on time since tare alone, for comparison
            X0 = X(:, [1 3]);
            res0 = st_l(good)' - X0*(X0 \ st_l(good)');
            fprintf("Lift vs current: r = %+.2f\n", R(1,2))
            fprintf("Fit lift = a + b*current + c*time since tare:\n")
            fprintf("  b = %+.5f N/mA (%+.4f N over the %.1f mA current range)\n",...
                coef(2), coef(2)*range(st_c(good)), range(st_c(good)))
            fprintf("  c = %+.5f N/min since tare\n", coef(3))
            fprintf("  residual std: %.4f N with current, %.4f N with time since tare only\n",...
                std(res), std(res0))
        end
    end

    % ---- 0 Hz trials (processed) ----
    pfiles = dir(fullfile(processed_dir, "*.mat"));
    z_t = NaT(1,0); z_l = zeros(1,0); z_u = zeros(1,0); z_c = zeros(1,0);
    for k = 1:length(pfiles)
        name = string(pfiles(k).name);
        if isempty(regexp(name, "(?<![\d.])" + AoA + "deg", 'once')) ||...
                isempty(regexp(name, "(?<![\d.])0Hz", 'once'))
            continue
        end
        tt = regexp(name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if isempty(tt), continue, end
        d = load(fullfile(pfiles(k).folder, pfiles(k).name), "results_lab", "U_act", "mod_results");
        z_t(end+1) = timeStr2num(tt{1});
        z_l(end+1) = mean(d.results_lab(lift_row, :));
        z_u(end+1) = d.U_act;
        % mod_results rows: [6 lab loads; home; voltage; current (mA)]
        z_c(end+1) = mean(d.mod_results(9, :));
    end
    if ~isempty(z_t)
        [z_t, o] = sort(z_t); z_l = z_l(o); z_u = z_u(o); z_c = z_c(o);
        fprintf("\n0 Hz trials (mean lift of results_lab, i.e. unfiltered):\n")
        for k = 1:numel(z_t)
            fprintf("  %s  lift %+.4f N   U = %.3f m/s   current %.1f mA\n",...
                string(z_t(k), "yyyy_MM_dd HH:mm:ss"), z_l(k), z_u(k), z_c(k))
        end
        plot(ax_lift, minutes(z_t - t0), z_l, 's', MarkerSize=10, Color=colors(s,:),...
            MarkerFaceColor=colors(s,:), DisplayName=sess_label + " 0 Hz trials")
        plot(ax_cur, minutes(z_t - t0), z_c, 's', MarkerSize=10, Color=colors(s,:),...
            MarkerFaceColor=colors(s,:), DisplayName=sess_label + " 0 Hz trials")
        z_dt = NaN(size(z_t));
        for k = 1:numel(z_t)
            ti = find(tare_t <= z_t(k), 1, 'last');
            if ~isempty(ti), z_dt(k) = minutes(z_t(k) - tare_t(ti)); end
        end
        scatter(ax_sc(s), z_c, z_l, 110, z_dt, "filled", "s", MarkerEdgeColor="k", LineWidth=1.2)
        dt_max = max(dt_max, max(z_dt));
    end
end
legend(ax_lift, Location="bestoutside", Interpreter="none")
for s = 1:length(sessions)
    colormap(ax_sc(s), parula)
    if dt_max > 0
        clim(ax_sc(s), [0 dt_max])
    end
end
cb = colorbar(ax_sc(end));
cb.Layout.Tile = "east";
cb.Label.String = "Minutes since preceding wind-off tare";
legend(ax_cur, Location="bestoutside", Interpreter="none")

function lift = to_lift(volt_diff, cal_matrix, AoA, lift_row)
    % volts (6 channels) -> lift in the lab frame, as process_trial does
    F = coordinate_transformation(cal_matrix * volt_diff(:), AoA);
    lift = F(lift_row);
end
