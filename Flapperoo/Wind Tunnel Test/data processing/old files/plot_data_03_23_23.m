clear
close all

% Ronan Gissler April 2023

% This file is used to analyze the data from the experiments Sakthi
% and I ran with the 1 DOF flapper robot in the wind tunnel on March
% 23rd 2023. We recorded over a hundred trials, tested 3 different
% wings and their inertial equivalents, and tested wingbeat
% frequencies up to 5 Hz for most configurations.

%%

disp("Section 1");
% ----------------------------------------------------------------
% ------------------------Plot All Data---------------------------
% ----------------------------------------------------------------

files = ["..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_5Hz_PDMS_heavy_experiment_032323.csv"];

%"..\Experiment Data\PDMS_heavy\0ms\0deg_0ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...

frame_rate = 6000; % Hz
num_wingbeats = 180;
trig_errs = zeros(1, length(files));
speeds = zeros(1, length(files));
lengths = zeros(1, length(files));

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["_experiment_032323.csv", "..\Experiment Data\PDMS_heavy\0ms\"]);
    case_name = strrep(case_name,'_',' ');
    case_parts = strtrim(split(case_name));
    speed = 0;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            speed = str2double(erase(case_parts(j), "Hz"));
        end
    end
    
    % Get data from file
    data = readmatrix(files(i));
    
    % Trim all data based on trigger data
    these_trigs = data(:, 8);
    these_low_trigs_indices = find(these_trigs < 3);
    trigger_start_frame = these_low_trigs_indices(1);
    trigger_end_frame = these_low_trigs_indices(end);

    trimmed_data = data(trigger_start_frame:trigger_end_frame, :);

    trimmed_time = trimmed_data(:,1) - trimmed_data(1,1);

    % Calculate the error associated with the DAQ and Galil using
    % different clocks
    expected_length = (num_wingbeats / speed) * frame_rate;
    trigger_error = length(trimmed_data) - expected_length;
    expected_period = frame_rate / speed;
    wingbeat_period = vpa(length(trimmed_data) / num_wingbeats, 10);
    disp(trigger_error)

    trig_errs(i) = trigger_error;
    speeds(i) = speed;
    lengths(i) = length(trimmed_data(:,4));

%     disp(trigger_error)
%     disp((trigger_error * speed) / (num_wingbeats * frame_rate))

%     frame_error = 0;
%     while(trigger_error > 0.1)
%         frame_error = frame_error + 0.001;
%         true_speed = speed * (1 - (frame_error / frame_rate));
%         expected_frames = (num_wingbeats / true_speed) * frame_rate;
%         trigger_error = length(trimmed_data) - expected_frames;
%     end
%     disp(frame_error);

    % Observing the output of expected_period and wingbeat_period
    % above, it's apparent that the error for a given wingbeat period
    % is equal to the following:
    frame_error = 1.14 / speed;

    times = data(1:end,1);
    force_vals = data(1:end,2:7);

    force_means = round(mean(force_vals), 3);
    force_SDs = round(std(force_vals), 3);
    
     % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(data(:, 1), data(:, 2), 'DisplayName', 'raw');
    trigger_line = plot(trimmed_data(:,1), trimmed_data(:, 2), ...
        'DisplayName', 'trigger');
    title(["F_x" ("avg: " + force_means(1) + " SD: " + force_SDs(1))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 3));
    plot(trimmed_data(:,1), trimmed_data(:, 3));
    title(["F_y" ("avg: " + force_means(2) + " SD: " + force_SDs(2))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 4));
    plot(trimmed_data(:,1), trimmed_data(:, 4));
    title(["F_z" ("avg: " + force_means(3) + " SD: " + force_SDs(3))]);
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 5));
    plot(trimmed_data(:,1), trimmed_data(:, 5));
    title(["M_x" ("avg: " + force_means(4) + " SD: " + force_SDs(4))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 6));
    plot(trimmed_data(:,1), trimmed_data(:, 6));
    title(["M_y" ("avg: " + force_means(5) + " SD: " + force_SDs(5))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(data(:, 1), data(:, 7));
    plot(trimmed_data(:,1), trimmed_data(:, 7));
    title(["M_z" ("avg: " + force_means(6) + " SD: " + force_SDs(6))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    hL = legend([raw_line, trigger_line]);
    % Move the legend to the right side of the figure
    hL.Layout.Tile = 'East';
    
    % Label the whole figure.
    sgtitle("Force Transducer Measurement for " + case_name);
    
    save([char(case_parts(1)),'_',char(case_parts(2)),'_',char(case_parts(3)),'.mat'], 'data','trimmed_data','trimmed_time','speed')
end

figure;
plot(trig_errs, speeds)

figure;
plot(trig_errs, num_wingbeats*ones(length(trig_errs)))

figure;
plot(trig_errs, frame_rate*ones(length(trig_errs)))

frame_error = 0;
extra_frames = 10*ones(1, length(lengths));
while((sum(abs(extra_frames)) > 0) && (frame_error < 1.5))
    frame_error = frame_error + 0.001;
    for i = 1:length(lengths)
        true_speed = speeds(i) * (1 - (frame_error / frame_rate));
        expected_frames = round((num_wingbeats / true_speed) * frame_rate);
        extra_frames(i) = lengths(i) - expected_frames;
    end
end
disp(vpa(frame_error,4));

%%

disp("Section 3");
clearvars -except frame_rate num_wingbeats
% ----------------------------------------------------------------
% -------------------------Plot PDMS Data-------------------------
% ----------------------------------------------------------------
     
cases = ["0deg_0ms_2Hz", "0deg_0ms_3Hz", "0deg_0ms_4Hz", "0deg_0ms_4.5Hz", "0deg_0ms_5Hz"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Time (s)");
ylabel("Lift Coefficient");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');

    rho = 1.204; % kg/m^3 at 20 C 1 atm
    wing_area = 0.266 * 0.088 * 2; % m^2, roughly
    half_span = 0.266; % m, roughly
    norm_factor = (0.5 * rho * wing_area * (2*pi*speed * half_span)^2);

    norm_lift = trimmed_data(:,4) / norm_factor;
    avg_norm_lift = std(norm_lift);
    disp("For " + case_name + ", the std of dimensionless lift is:");
    disp(avg_norm_lift);
    
    % Plot lift force
    plot(trimmed_time, norm_lift, 'DisplayName', case_name);
    save(cases(i) + '.mat', 'data','trimmed_data','trimmed_time','speed','norm_lift','norm_factor')
end
legend("Location","Southwest");

% Plot each case individually so that the speeds can be visually
% verified
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    title("Lift Force (z-direction) - PDMS Wings" + case_name);
    xlabel("Time (s)");
    ylabel("Force (N)");
    hold on

    % Plot lift force
    plot(trimmed_time, trimmed_data(:, 4))

    xlim([30, 32])
    ylim([-11, 11])
end

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Time (s)");
ylabel("Force (N)");
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(trimmed_time, trimmed_data(:, 4), 'DisplayName', case_name)
end
xlim([30, 32])
ylim([-11, 11])
line(xlim, [0 0], 'Color','black','HandleVisibility','off'); % x-axis
legend("Location","Southwest");

%%

disp("Section 4");
clearvars -except frame_rate num_wingbeats
% ----------------------------------------------------------------
% --------Plot PDMS Data normalized by wingbeat cycles------------
% ----------------------------------------------------------------

cases = ["0deg_0ms_2Hz", "0deg_0ms_3Hz", "0deg_0ms_4Hz", "0deg_0ms_4.5Hz", "0deg_0ms_5Hz"];
cases = flip(cases);

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on

for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');

    frame_error = 1.145; % due to clock mismatch
    true_speed = speed * (1 - (frame_error / frame_rate));
    frames_per_beat = (9000 / speed);
    expected_frames = (num_wingbeats / speed) * frame_rate;
    true_frames = round((num_wingbeats / true_speed) * frame_rate);
    total_error = true_frames - length(trimmed_data(:,4));
    extra_frames = round(true_frames - expected_frames);
    wingbeats = linspace(0, num_wingbeats, true_frames);
    
%     disp("For " + case_name + ", the average lift is:");
%     disp(mean(trimmed_data(:, 4)));

    % Plot lift force
    plot(wingbeats, trimmed_data(:, 4), 'DisplayName', case_name);
    save(cases(i) + ".mat", 'data','trimmed_data','trimmed_time','speed','norm_lift','norm_factor','wingbeats','true_speed');
end
legend("Location","Southwest");


% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction) - PDMS Wings");
xlabel("Wingbeat Number");
ylabel("Force (N)");
hold on
for i = 1:length(cases)
    % Load data
    mat_name = cases(i) + ".mat";
    load(mat_name);
    
    case_name = strrep(cases(i),'_',' ');
    
    % Plot lift force
    plot(wingbeats, trimmed_data(:, 4), 'DisplayName', case_name)
end
xlim([32, 34])
ylim([-11, 11])
line(xlim, [0 0], 'Color','black','HandleVisibility','off'); % x-axis
legend("Location","Southwest");