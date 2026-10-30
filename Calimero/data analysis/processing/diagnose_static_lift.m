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

cal_matrix = obtain_cal("../../DAQ/Calibration Files/Mini40/FT52907.cal");

figure; hold on; grid on
xlabel("Time since session's first tare (min)")
ylabel("Static lift, zeroed with wind-off tare (N)")
colors = lines(length(sessions));

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
    static = struct('t', {}, 'kind', {}, 'freq', {}, 'v', {});
    for k = 1:length(files)
        [~, ts, ~, freq, aoa, ~, ~, ftype] = parse_filename(string(files(k).name));
        if aoa ~= AoA
            continue
        end
        d = load(fullfile(files(k).folder, files(k).name), "offsets");
        v = d.offsets(1, 1:6); % channel means (volts)
        switch ftype
            case "offsets"
                tare_t(end+1,1) = timeStr2num(ts); tare_v(end+1,:) = v;
                tare_names(end+1,1) = string(files(k).name);
            case {"before_offsets", "after_offsets"}
                static(end+1) = struct('t', timeStr2num(ts), 'kind', ftype, 'freq', freq, 'v', v);
        end
    end
    if isempty(tare_t)
        fprintf("No initial tare found in %s\n", offsets_dir)
        continue
    end
    [tare_t, o] = sort(tare_t); tare_v = tare_v(o,:); tare_names = tare_names(o);
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

    % ---- wind-on static readings (before / after each trial) ----
    if isempty(static)
        fprintf("No before/after offsets found\n")
    else
        [~, o] = sort([static.t]); static = static(o);
        st_t = NaT(1, numel(static)); st_l = NaN(1, numel(static));
        fprintf("\nStatic wind-on readings (zeroed with the latest tare before each):\n")
        fprintf("  %-20s %-15s %7s %10s\n", "time", "kind", "freq", "lift (N)")
        for k = 1:numel(static)
            ti = find(tare_t <= static(k).t, 1, 'last');
            if isempty(ti), ti = 1; end
            st_t(k) = static(k).t;
            st_l(k) = to_lift(static(k).v - tare_v(ti,:), cal_matrix, AoA, lift_row);
            fprintf("  %-20s %-15s %6gHz %+10.4f\n", string(static(k).t, "yyyy_MM_dd HH:mm:ss"),...
                static(k).kind, static(k).freq, st_l(k))
        end
        mins = minutes(st_t - t0);
        p = polyfit(mins, st_l, 1);
        fprintf("\nStatic lift: mean %.4f N, std %.4f N, range %.4f N over %.0f min\n",...
            mean(st_l), std(st_l), range(st_l), max(mins) - min(mins))
        fprintf("Linear trend: %+.4f N per hour\n", 60 * p(1))
        plot(mins, st_l, 'o-', Color=colors(s,:), MarkerFaceColor="none",...
            DisplayName=sess_label + " static (before/after)")
    end

    % ---- 0 Hz trials (processed) ----
    pfiles = dir(fullfile(processed_dir, "*.mat"));
    z_t = NaT(1,0); z_l = zeros(1,0); z_u = zeros(1,0);
    for k = 1:length(pfiles)
        name = string(pfiles(k).name);
        if isempty(regexp(name, "(?<![\d.])" + AoA + "deg", 'once')) ||...
                isempty(regexp(name, "(?<![\d.])0Hz", 'once'))
            continue
        end
        tt = regexp(name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if isempty(tt), continue, end
        d = load(fullfile(pfiles(k).folder, pfiles(k).name), "results_lab", "U_act");
        z_t(end+1) = timeStr2num(tt{1});
        z_l(end+1) = mean(d.results_lab(lift_row, :));
        z_u(end+1) = d.U_act;
    end
    if ~isempty(z_t)
        [z_t, o] = sort(z_t); z_l = z_l(o); z_u = z_u(o);
        fprintf("\n0 Hz trials (mean lift of results_lab, i.e. unfiltered):\n")
        for k = 1:numel(z_t)
            fprintf("  %s  lift %+.4f N   U = %.3f m/s\n", string(z_t(k), "yyyy_MM_dd HH:mm:ss"), z_l(k), z_u(k))
        end
        plot(minutes(z_t - t0), z_l, 's', MarkerSize=10, Color=colors(s,:),...
            MarkerFaceColor=colors(s,:), DisplayName=sess_label + " 0 Hz trials")
    end
end
legend(Location="bestoutside", Interpreter="none")

function lift = to_lift(volt_diff, cal_matrix, AoA, lift_row)
    % volts (6 channels) -> lift in the lab frame, as process_trial does
    F = coordinate_transformation(cal_matrix * volt_diff(:), AoA);
    lift = F(lift_row);
end
