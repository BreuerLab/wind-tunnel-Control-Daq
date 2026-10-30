% Author: Ronan Gissler (diagnostic written with Claude)
% Last updated: October 2026
%
% How the load cell tare changes over a data collection run.
%
% run_experiment (called by main.m with AoA = 10*ones(1,5)) loops over the
% AoA list once per repetition. Each repetition:
%   1. initial_tare: wind OFF, wings stationary  -> "<case>_offsets_<time>"
%   2. every frequency, wind on                  -> before/after offsets
%   3. final offsets: wind still ON (the wind is only stopped by the next
%      repetition's initial_tare, or at the end of the experiment)
%                                                -> "<case>_final_offsets_<time>"
%
% For each session this converts the offsets (channel means, volts) to
% drag, lift and pitch moment in the lab frame, as process_trial does, and
% plots them over the run relative to the session's first wind-off tare:
%   - wind-off tares (filled circles): drift of the load cell zero. Each
%     trial is zeroed with the tare at the start of its repetition, so the
%     change from one tare to the next is drift that tare didn't capture.
%   - final offsets (hollow squares): wind on, so they sit above the tares
%     by the static aerodynamic load (compare with diagnose_static_lift).
% The value printed for each final offset relative to the tare before it
% is the static load at the end of that repetition, including any drift
% over that repetition.
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
AoA = 10; % deg, only files at this AoA are used

% lab frame rows: [drag; side; lift; roll; pitch; yaw]
comp_rows = [1 3 5];
comp_names = ["Drag (N)", "Lift (N)", "Pitch moment (N m)"];

cal_matrix = obtain_cal("../../DAQ/Calibration Files/Mini40/FT52907.cal");

fig = figure(Position=[100 100 1300 900]);
tl = tiledlayout(fig, length(comp_rows), 1, TileSpacing="compact");
axs = gobjects(1, length(comp_rows));
for c = 1:length(comp_rows)
    axs(c) = nexttile(tl);
    hold(axs(c), "on"); grid(axs(c), "on")
    ylabel(axs(c), comp_names(c) + " rel. first tare")
end
xlabel(axs(end), "Time since session's first wind-off tare (min)")
title(tl, "Wind-off tares (filled) and wind-on final offsets (hollow), " + AoA + " deg AoA")
colors = lines(length(sessions));

for s = 1:length(sessions)
    sess = sessions(s);
    offsets_dir = fullfile(sess, "raw data", "offsets data");
    [~, sess_name] = fileparts(sess);
    sess_label = extractBefore(extractAfter(sess, "Force Measurements\"), "\4 m.s") + " (" + sess_name + ")";

    files = dir(fullfile(offsets_dir, "*.mat"));
    t = NaT(0, 1); v = zeros(0, 6); sd = zeros(0, 6); kind = strings(0, 1);
    for k = 1:length(files)
        [~, ts, ~, ~, aoa, ~, ~, ftype] = parse_filename(string(files(k).name));
        if aoa ~= AoA || ~ismember(ftype, ["offsets", "final_offsets"])
            continue
        end
        d = load(fullfile(files(k).folder, files(k).name), "offsets");
        t(end+1, 1) = timeStr2num(ts); %#ok<SAGROW>
        v(end+1, :) = d.offsets(1, 1:6);  % channel means (volts)
        if size(d.offsets, 1) > 1
            sd(end+1, :) = d.offsets(2, 1:6); % channel std (volts)
        else
            sd(end+1, :) = NaN(1, 6);
        end
        kind(end+1, 1) = ftype;
    end

    fprintf("\n================================================================\n")
    fprintf("%s\n", sess_label)
    fprintf("================================================================\n")
    is_tare = kind == "offsets";
    if ~any(is_tare)
        fprintf("No wind-off tare found in %s\n", offsets_dir)
        continue
    end
    [t, o] = sort(t); v = v(o, :); sd = sd(o, :); kind = kind(o); is_tare = is_tare(o);
    first = find(is_tare, 1);
    t0 = t(first);

    % loads relative to the first tare, and the noise of each reading
    F = to_lab(v - v(first, :), cal_matrix, AoA);   % 6 x n
    noise = abs(to_lab(sd, cal_matrix, AoA));       % rough, per reading

    fprintf("  %-20s %-14s %10s %10s %12s   %s\n", "time", "kind", "drag (N)", "lift (N)", "pitch (N m)", "(rel. first tare)")
    last_tare = first;
    for k = 1:numel(t)
        extra = "";
        if is_tare(k)
            if k ~= first
                dF = F(:, k) - F(:, last_tare);
                extra = sprintf("   change since previous tare: lift %+.4f N", dF(3));
            end
            last_tare = k;
        else
            dF = F(:, k) - F(:, last_tare);
            extra = sprintf("   rel. previous tare: lift %+.4f N (wind on)", dF(3));
        end
        fprintf("  %-20s %-14s %+10.4f %+10.4f %+12.5f%s\n", string(t(k), "yyyy_MM_dd HH:mm:ss"),...
            kind(k), F(1, k), F(3, k), F(5, k), extra)
    end
    tare_lift = F(3, is_tare);
    fprintf("Wind-off tares: %d, lift spread %.4f N (max - min), typical reading noise (std) %.4f N\n",...
        nnz(is_tare), range(tare_lift), median(noise(3, is_tare), "omitnan"))

    mins = minutes(t - t0);
    for c = 1:length(comp_rows)
        r = comp_rows(c);
        plot(axs(c), mins(is_tare), F(r, is_tare), "o-", Color=colors(s, :),...
            MarkerFaceColor=colors(s, :), DisplayName=sess_label + " wind-off tares")
        if any(~is_tare)
            plot(axs(c), mins(~is_tare), F(r, ~is_tare), "s", MarkerSize=8, Color=colors(s, :),...
                MarkerFaceColor="none", DisplayName=sess_label + " final offsets (wind on)")
        end
    end
end
for c = 1:length(comp_rows)
    yl = yline(axs(c), 0, "k");
    yl.HandleVisibility = "off";
end
lg = legend(axs(1), Interpreter="none");
lg.Layout.Tile = "east";

function F = to_lab(volts, cal_matrix, AoA)
    % volts (n x 6) -> lab frame loads (6 x n), as process_trial does
    F = coordinate_transformation(cal_matrix * volts', AoA);
end
