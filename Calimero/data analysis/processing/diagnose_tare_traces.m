% Author: Ronan Gissler (diagnostic written with Claude)
% Last updated: October 2026
%
% Is the load cell zero still moving while the wind-off tare is recorded?
%
% Each offsets file saves the raw samples it averaged ('results': DAQ
% channels, the first six being the load cell). For every wind-off tare
% ("<case>_offsets_<time>", taken at the start of each repetition right
% after the wind is stopped) this plots the lift and drag traces within
% the recording, relative to the recording's own mean, smoothed. For
% comparison it also plots the first wind-on before_offsets that follows
% each tare (dashed).
%
% A flat trace means the tare was taken at a settled zero. A steady slope
% means the zero was mid-transient: the tare mean is then only valid for
% the middle of the recording, and if the slide continues the first
% wind-on reading (~35 s later) is off by roughly slope x elapsed time,
% which the printout estimates.
%
% Set the session folders (<type>_<date> folders with "raw data") below.

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
AoA = 10;        % deg, only files at this AoA are used
fs = 12000;      % DAQ sampling rate (Hz), as process_trial assumes
smooth_s = 0.5;  % moving-average window for plotting (s)
plot_step = 50;  % plot every n-th sample of the smoothed trace

% lab frame rows: [drag; side; lift; roll; pitch; yaw]
comps = struct('row', {3, 1}, 'name', {"Lift", "Drag"});

cal_matrix = obtain_cal("../../DAQ/Calibration Files/Mini40/FT52907.cal");

fig = figure(Name="Tare traces", Position=[50 50 1700 750]);
tl = tiledlayout(fig, numel(comps), length(sessions), TileSpacing="compact");
title(tl, "Load cell traces within each wind-off tare (solid) and the following wind-on reading (dashed), relative to each recording's mean")
axs = gobjects(numel(comps), length(sessions));
for c = 1:numel(comps)
    for s = 1:length(sessions)
        axs(c, s) = nexttile(tl, (c - 1) * length(sessions) + s);
        hold(axs(c, s), "on"); grid(axs(c, s), "on")
        if s == 1
            ylabel(axs(c, s), comps(c).name + " rel. recording mean (N)")
        end
        if c == numel(comps)
            xlabel(axs(c, s), "Time in recording (s)")
        end
    end
end

summary = strings(0, 1);

for s = 1:length(sessions)
    sess = sessions(s);
    offsets_dir = fullfile(sess, "raw data", "offsets data");
    [~, sess_name] = fileparts(sess);
    sess_label = extractBefore(extractAfter(sess, "Force Measurements\"), "\4 m.s") + " (" + sess_name + ")";
    title(axs(1, s), sess_label, Interpreter="none", FontWeight="normal")

    files = dir(fullfile(offsets_dir, "*.mat"));
    tares = struct('t', {}, 'file', {});
    befores = struct('t', {}, 'file', {});
    for k = 1:length(files)
        [~, ts, ~, ~, aoa, ~, ~, ftype] = parse_filename(string(files(k).name));
        if aoa ~= AoA
            continue
        end
        f = string(fullfile(files(k).folder, files(k).name));
        if ftype == "offsets"
            tares(end+1) = struct('t', timeStr2num(ts), 'file', f); %#ok<SAGROW>
        elseif ftype == "before_offsets"
            befores(end+1) = struct('t', timeStr2num(ts), 'file', f); %#ok<SAGROW>
        end
    end
    if isempty(tares)
        fprintf("\n%s: no wind-off tares found\n", sess_label)
        continue
    end
    [~, o] = sort([tares.t]); tares = tares(o);
    rep_colors = lines(numel(tares));

    fprintf("\n================================================================\n")
    fprintf("%s\n", sess_label)
    fprintf("================================================================\n")
    fprintf("  %-4s %-9s %8s | %-28s | %-28s | %s\n", "rep", "kind", "dur (s)",...
        "lift: slope, change in rec.", "drag: slope, change in rec.", "lift slide by next reading")

    tare_lift_slopes = NaN(1, numel(tares));
    for r = 1:numel(tares)
        % the wind-on reading right after this tare
        nxt = [];
        if ~isempty(befores)
            later = find([befores.t] > tares(r).t);
            if ~isempty(later)
                [~, i] = min([befores(later).t]);
                nxt = befores(later(i));
            end
        end
        recs = struct('file', tares(r).file, 'kind', "tare", 'style', "-", 't', tares(r).t);
        if ~isempty(nxt)
            recs(2) = struct('file', nxt.file, 'kind', "wind-on", 'style', "--", 't', nxt.t);
        end

        for q = 1:numel(recs)
            d = load(recs(q).file);
            if ~isfield(d, "results") || isempty(d.results)
                fprintf("  %-4d %-9s   (no raw samples saved in %s)\n", r, recs(q).kind, recs(q).file)
                continue
            end
            volts = d.results(:, 1:6);
            volts = volts - mean(volts, 1);
            F = coordinate_transformation(cal_matrix * volts', AoA); % 6 x n
            n = size(F, 2);
            t = (0:n-1) / fs;
            dur = t(end);

            slopes = NaN(1, numel(comps)); changes = NaN(1, numel(comps));
            for c = 1:numel(comps)
                y = F(comps(c).row, :);
                p = polyfit(t, y, 1);
                slopes(c) = p(1);            % N/s
                changes(c) = p(1) * dur;     % over the recording
                ys = movmean(y, max(1, round(smooth_s * fs)));
                idx = 1:plot_step:n;
                h = plot(axs(c, s), t(idx), ys(idx), recs(q).style, Color=rep_colors(r, :), LineWidth=1.2);
                if c == 1 && q == 1
                    h.DisplayName = "rep " + r;
                else
                    h.HandleVisibility = "off";
                end
            end

            slide = "";
            if recs(q).kind == "tare"
                tare_lift_slopes(r) = slopes(1);
                if numel(recs) > 1
                    % from the middle of the tare (its mean) to the next
                    % reading's end (files are saved at the end)
                    gap = seconds(recs(2).t - recs(1).t) + dur / 2;
                    slide = sprintf("%+.4f N over %.0f s", slopes(1) * gap, gap);
                end
            end
            fprintf("  %-4d %-9s %8.1f | %+.5f N/s, %+.4f N    | %+.5f N/s, %+.4f N    | %s\n",...
                r, recs(q).kind, dur, slopes(1), changes(1), slopes(2), changes(2), slide)
        end
    end
    summary(end+1) = sprintf("%-45s mean tare lift slope %+.5f N/s (%+.3f N/min)",...
        sess_label, mean(tare_lift_slopes, "omitnan"), 60 * mean(tare_lift_slopes, "omitnan"));
end

for c = 1:numel(comps)
    for s = 1:length(sessions)
        yl = yline(axs(c, s), 0, "k");
        yl.HandleVisibility = "off";
    end
end
for s = 1:length(sessions)
    legend(axs(1, s), Location="best")
end
% same y limits across sessions for each component, so slopes compare
for c = 1:numel(comps)
    linkaxes(axs(c, :), "y")
end

fprintf("\n================================================================\n")
fprintf("Summary: lift slope within the wind-off tares\n")
fprintf("================================================================\n")
fprintf("%s\n", summary)
