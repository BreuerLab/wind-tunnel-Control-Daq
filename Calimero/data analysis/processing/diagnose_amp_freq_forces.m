% Author: Ronan Gissler (diagnostic written with Claude)
% Last updated: November 2026
%
% Time-averaged lift and drag against wingbeat frequency, one line per
% wingbeat amplitude, from the processed load cell files of each session.
%
% Each case (amplitude, frequency) is measured several times so thermal
% drift can settle; one repeat per case is used, chosen per amplitude with
% repeat_sel below (default: the latest timestamp, as get_force uses for
% the UIs).
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

% Which repeat of each case to use, one entry per wingbeat amplitude in
% ascending order (e.g. [10 20 30] deg): 0 = latest timestamp, -1 = second
% to last, -2 = third to last, ... [] uses the latest for every amplitude.
% The same choice applies at every frequency of that amplitude; a case
% with fewer repeats than asked falls back on its earliest one.
% e.g. [-1 0 0]: second to last repeat for 10 deg, latest for 20 and 30 deg
repeat_sel = [0 0 0];

% lab frame rows: [drag; side; lift; roll; pitch; yaw]
comps = struct('row', {3, 1}, 'name', {"Lift", "Drag"});

% ---- list the processed files of every session ----
files = struct('folder', {}, 'name', {}, 'sess', {}, 'amp', {}, 'freq', {}, 't', {});
for s = 1:length(sessions)
    processed_dir = fullfile(sessions(s), "processed data");
    pfiles = dir(fullfile(processed_dir, "*.mat"));
    if isempty(pfiles)
        fprintf("No processed files in %s\n", processed_dir)
        continue
    end
    for k = 1:numel(pfiles)
        name = string(pfiles(k).name);
        tt = regexp(name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if isempty(tt), continue, end
        [~, ~, ~, fr, aoa, ~, am, ~] = parse_filename(name);
        if aoa ~= AoA || fr < 0 || am < 0, continue, end
        files(end+1) = struct('folder', string(pfiles(k).folder), 'name', name,...
            'sess', lc_session_label(sessions(s)), 'amp', am, 'freq', fr,...
            't', timeStr2num(tt{1})); %#ok<SAGROW>
    end
end
if isempty(files)
    error("No processed files at " + AoA + " deg found in the listed sessions")
end

amps = unique([files.amp]);
if isempty(repeat_sel)
    repeat_sel = zeros(1, numel(amps));
elseif numel(repeat_sel) ~= numel(amps)
    error("repeat_sel has %d entries but %d amplitudes were found (%s deg)",...
        numel(repeat_sel), numel(amps), strjoin(string(amps), ", "))
elseif any(repeat_sel > 0 | repeat_sel ~= round(repeat_sel))
    error("repeat_sel entries must be 0 (latest) or negative integers")
end

% ---- pick the selected repeat of each (amplitude, frequency) case ----
% one entry per case: amp, freq, time stamp, mean loads, std across wingbeats
cases = struct('amp', {}, 'freq', {}, 'ts', {}, 'sess', {}, 'mean', {}, 'std', {});
combos = unique([[files.amp]' [files.freq]'], 'rows');
for c = 1:size(combos, 1)
    idx = find([files.amp] == combos(c, 1) & [files.freq] == combos(c, 2));
    [~, o] = sort([files(idx).t], 'descend'); % latest first
    idx = idx(o);
    back = -repeat_sel(amps == combos(c, 1)); % 0 = latest, 1 = second to last, ...
    if back + 1 > numel(idx)
        warning("%g deg, %g Hz has only %d repeat(s); using the earliest instead of %d back",...
            combos(c, 1), combos(c, 2), numel(idx), back)
        back = numel(idx) - 1;
    end
    file = files(idx(back + 1));
    f = fullfile(file.folder, file.name);
    fprintf("%s: %g deg, %g Hz -> %s (repeat %d of %d, %d back from latest)\n", file.sess,...
        combos(c, 1), combos(c, 2), file.name, numel(idx) - back, numel(idx), back)

    if file.freq > 0
        d = load(f, "results_lab", "cycle_avg_forces_raw");
        sd = std(d.cycle_avg_forces_raw(1:6, :), 0, 2);
    else
        d = load(f, "results_lab");
        sd = NaN(6, 1);
    end
    cases(end+1) = struct('amp', file.amp, 'freq', file.freq,...
        'ts', string(file.t, "yyyy_MM_dd HH:mm:ss"), 'sess', file.sess,...
        'mean', mean(d.results_lab(1:6, :), 2), 'std', sd); %#ok<SAGROW>
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
    sel_str = strjoin(amps + " deg: " + string(repeat_sel), ", ");
    title(ax, comps(c).name + ", " + AoA + " deg AoA, repeats (0 = latest) " + sel_str + ...
        " (error bars: std across wingbeats)",...
        FontWeight="normal")
    yl = yline(ax, 0, "k");
    yl.HandleVisibility = "off";
    legend(ax, Location="best")
end
