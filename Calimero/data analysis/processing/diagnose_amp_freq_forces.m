% Author: Ronan Gissler (diagnostic written with Claude)
% Last updated: November 2026
%
% Time-averaged lift and drag against wingbeat frequency, one line per
% wingbeat amplitude, from the processed load cell files of each session.
%
% Each case (amplitude, frequency) is measured several times so thermal
% drift can settle; only the repeat with the latest timestamp is used
% (the same choice get_force makes for the UIs).
%
% Plotted value: mean of results_lab over the analysed wingbeats (the
% time average doesn't depend on the low-pass filter). Error bars for
% flapping trials: standard deviation across wingbeats of the per-wingbeat
% means (cycle_avg_forces_raw). 0 Hz trials have no wingbeats, so no
% error bar.
%
% Set the session folders below (same list as diagnose_static_lift) and run.

clear
close all
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

% same session list as diagnose_static_lift.m
sessions = [
    "C:\Users\rgissler\Documents\DAQ Data\10 deg wings data\4 m.s\wings_2026_11_07"
    "C:\Users\rgissler\Documents\DAQ Data\20 deg wings data\4 m.s\wings_2026_11_06"
    "C:\Users\rgissler\Documents\DAQ Data\30 deg wings data\4 m.s\wings_2026_11_06"
    ];
% a type's folder is searched for its session folder(s)
sessions = find_lc_sessions(sessions);
AoA = 10; % deg, only files at this AoA are used

% lab frame rows: [drag; side; lift; roll; pitch; yaw]
comps = struct('row', {3, 1}, 'name', {"Lift", "Drag"});

% ---- collect the latest repeat of each (amplitude, frequency) case ----
% one entry per case: amp, freq, time stamp, mean loads, std across wingbeats
cases = struct('amp', {}, 'freq', {}, 'ts', {}, 'sess', {}, 'mean', {}, 'std', {});
for s = 1:length(sessions)
    processed_dir = fullfile(sessions(s), "processed data");
    pfiles = dir(fullfile(processed_dir, "*.mat"));
    if isempty(pfiles)
        fprintf("No processed files in %s\n", processed_dir)
        continue
    end

    % parse every processed file name
    amp = NaN(1, numel(pfiles)); freq = NaN(1, numel(pfiles));
    aoa = NaN(1, numel(pfiles)); t = NaT(1, numel(pfiles));
    for k = 1:numel(pfiles)
        name = string(pfiles(k).name);
        tt = regexp(name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if isempty(tt), continue, end
        [~, ~, ~, freq(k), aoa(k), ~, amp(k), ~] = parse_filename(name);
        t(k) = timeStr2num(tt{1});
    end
    keep = aoa == AoA & ~isnat(t) & freq >= 0 & amp >= 0;

    % latest timestamp for each (amp, freq)
    combos = unique([amp(keep)' freq(keep)'], 'rows');
    for c = 1:size(combos, 1)
        idx = find(keep & amp == combos(c, 1) & freq == combos(c, 2));
        [~, i] = max(t(idx));
        k = idx(i);
        f = fullfile(pfiles(k).folder, pfiles(k).name);
        fprintf("%s: %g deg, %g Hz -> %s (latest of %d)\n", lc_session_label(sessions(s)),...
            combos(c, 1), combos(c, 2), pfiles(k).name, numel(idx))

        if freq(k) > 0
            d = load(f, "results_lab", "cycle_avg_forces_raw");
            sd = std(d.cycle_avg_forces_raw(1:6, :), 0, 2);
        else
            d = load(f, "results_lab");
            sd = NaN(6, 1);
        end
        cases(end+1) = struct('amp', amp(k), 'freq', freq(k),...
            'ts', string(t(k), "yyyy_MM_dd HH:mm:ss"), 'sess', lc_session_label(sessions(s)),...
            'mean', mean(d.results_lab(1:6, :), 2), 'std', sd); %#ok<SAGROW>
    end
end
if isempty(cases)
    error("No processed files at " + AoA + " deg found in the listed sessions")
end

% ---- printout ----
amps = unique([cases.amp]);
fprintf("\n%6s %8s %12s %12s %12s %12s   %s\n", "amp", "freq", "lift (N)", "lift std", "drag (N)", "drag std", "time stamp")
for a = amps
    sel = find([cases.amp] == a);
    [~, o] = sort([cases(sel).freq]);
    for k = sel(o)
        fprintf("%4g deg %6g Hz %+12.4f %12.4f %+12.4f %12.4f   %s\n", cases(k).amp, cases(k).freq,...
            cases(k).mean(3), cases(k).std(3), cases(k).mean(1), cases(k).std(1), cases(k).ts)
    end
end

% ---- plots: one figure each for lift and drag ----
colors = lines(numel(amps));
for c = 1:numel(comps)
    fig = figure(Name=comps(c).name + " vs wingbeat frequency");
    ax = axes(fig); hold(ax, "on"); grid(ax, "on")
    for a = 1:numel(amps)
        sel = find([cases.amp] == amps(a));
        [fr, o] = sort([cases(sel).freq]);
        sel = sel(o);
        m = arrayfun(@(k) cases(k).mean(comps(c).row), sel);
        e = arrayfun(@(k) cases(k).std(comps(c).row), sel);
        errorbar(ax, fr, m, e, "o-", Color=colors(a, :), MarkerFaceColor=colors(a, :),...
            LineWidth=1.5, CapSize=6, DisplayName=amps(a) + " deg amplitude")
    end
    xlabel(ax, "Wingbeat frequency (Hz)")
    ylabel(ax, "Time-averaged " + lower(comps(c).name) + " (N)")
    title(ax, comps(c).name + ", " + AoA + " deg AoA, latest repeat of each case (error bars: std across wingbeats)",...
        FontWeight="normal")
    yl = yline(ax, 0, "k");
    yl.HandleVisibility = "off";
    legend(ax, Location="best")
end
