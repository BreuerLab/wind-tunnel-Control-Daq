function [freq_avg, norm_time_speed, phase_avg_pos, phase_std_pos,...
    phase_avg_speed, phase_std_speed, phase_avg_acc, phase_std_acc,...
    phase_avg_wing_pos, phase_std_wing_pos,...
    phase_avg_wing_speed, phase_std_wing_speed, phase_avg_wing_acc, phase_std_wing_acc,...
    bin_count, bin_std, phase_avg_volt, phase_std_volt,...
    phase_avg_cur, phase_std_cur] = speed_phase_avg(results, voltAdj, curAdj, pos, speed, acc,...
                wing_pos, wing_speed, wing_acc, pulsesPerRev, plot_bool)

% Find indices where a laser fire has been recorded
las_count = results(:,12);
mid_indices = find(las_count ~= 0 & las_count ~= las_count(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];

% trim off begininning and end when accelerating
pos_tr = pos(mid_indices_adj);
speed_tr = speed(mid_indices_adj);
acc_tr = acc(mid_indices_adj);
wing_pos_tr = wing_pos(mid_indices_adj);
wing_speed_tr = wing_speed(mid_indices_adj);
wing_acc_tr = wing_acc(mid_indices_adj);
volt_tr = voltAdj(mid_indices_adj);
cur_tr = curAdj(mid_indices_adj);

% signal for phase averaging using motor position
norm_pos = get_norm_signal(results, 0, pulsesPerRev);
norm_pos = norm_pos(mid_indices_adj);

% signal for phase averaging using wingbeat time
freq_avg = mean(speed_tr);
norm_signal = get_norm_signal(results, 1, pulsesPerRev, freq_avg);
norm_signal = norm_signal(mid_indices_adj);

% associate t = 0 with theta = 0
[~,I] = min(norm_pos);
t_phase_zero = norm_signal(I);
norm_signal(norm_signal < t_phase_zero) = norm_signal(norm_signal < t_phase_zero) + 1;
norm_signal = norm_signal - t_phase_zero;

bins_list = 500:50:1500;
minFrames = 100;
[num_bins, bin_ind_arr, bin_count, bin_std] = findBestNumBins(norm_signal, bins_list, minFrames);
disp("Using " + num_bins + " bins for speed phase averaging")

% Array preallocation
[phase_avg_pos, phase_std_pos, ...
 phase_avg_speed, phase_std_speed, ...
 phase_avg_acc, phase_std_acc, ...
 phase_avg_wing_pos, phase_std_wing_pos, ...
 phase_avg_wing_speed, phase_std_wing_speed, ...
 phase_avg_wing_acc, phase_std_wing_acc, ...
 phase_avg_volt, phase_std_volt, ...
 phase_avg_cur, phase_std_cur] = deal(zeros(1, num_bins));

pos_tr_adj = mod(pos_tr, 2*pi);
% no adjustment needed for wing position

for j = 1:num_bins
    bin_indices = find(bin_ind_arr == j);

    phase_avg_pos(j) = mean(pos_tr_adj(bin_indices));
    phase_std_pos(j) = std(pos_tr_adj(bin_indices));

    phase_avg_speed(j) = mean(speed_tr(bin_indices));
    phase_std_speed(j) = std(speed_tr(bin_indices));

    phase_avg_acc(j) = mean(acc_tr(bin_indices));
    phase_std_acc(j) = std(acc_tr(bin_indices));

    phase_avg_wing_pos(j) = mean(wing_pos_tr(bin_indices));
    phase_std_wing_pos(j) = std(wing_pos_tr(bin_indices));

    phase_avg_wing_speed(j) = mean(wing_speed_tr(bin_indices));
    phase_std_wing_speed(j) = std(wing_speed_tr(bin_indices));

    phase_avg_wing_acc(j) = mean(wing_acc_tr(bin_indices));
    phase_std_wing_acc(j) = std(wing_acc_tr(bin_indices));

    phase_avg_volt(j) = mean(volt_tr(bin_indices));
    phase_std_volt(j) = std(volt_tr(bin_indices));

    phase_avg_cur(j) = mean(cur_tr(bin_indices));
    phase_std_cur(j) = std(cur_tr(bin_indices));
end

norm_time_speed = linspace(0,1,num_bins);

if plot_bool
figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
bar(bin_std)
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin (% cycle)", FontSize=16)

%% Plot phase averaged speed
%  band around shows variability at each phasepoint

lower_results = phase_avg_speed - phase_std_speed;
upper_results = phase_avg_speed + phase_std_speed;

original_color = "#7f2704"; % hex, some dark red
lighter_color = getLightColor(original_color); % RGB

xconf = [norm_time_speed, norm_time_speed(end:-1:1)];
yconf = [upper_results, lower_results(end:-1:1)];

figure
hold on

p = fill(xconf, yconf, lighter_color);
p.HandleVisibility = 'off';
p.EdgeColor = 'none';

l = plot(norm_time_speed, phase_avg_speed);
l.Color = original_color;
l.LineWidth = 2;

yline(mean(speed_tr),LineWidth=2)

xlabel("Time over a wingbeat (t/T)")
ylabel("Speed (Hz)")

%% Plot phase averaged voltage
lower_results = phase_avg_volt - phase_std_volt;
upper_results = phase_avg_volt + phase_std_volt;

xconf = [norm_time_speed, norm_time_speed(end:-1:1)];
yconf = [upper_results, lower_results(end:-1:1)];

figure
hold on

p = fill(xconf, yconf, lighter_color);
p.HandleVisibility = 'off';
p.EdgeColor = 'none';

l = plot(norm_time_speed, phase_avg_volt);
l.Color = original_color;
l.LineWidth = 2;

yline(mean(volt_tr),LineWidth=2)

xlabel("Time over a wingbeat (t/T)")
ylabel("Voltage (V)")

%% Plot phase averaged current
lower_results = phase_avg_cur - phase_std_cur;
upper_results = phase_avg_cur + phase_std_cur;

xconf = [norm_time_speed, norm_time_speed(end:-1:1)];
yconf = [upper_results, lower_results(end:-1:1)];

figure
hold on

p = fill(xconf, yconf, lighter_color);
p.HandleVisibility = 'off';
p.EdgeColor = 'none';

l = plot(norm_time_speed, phase_avg_cur);
l.Color = original_color;
l.LineWidth = 2;

yline(mean(cur_tr),LineWidth=2)

xlabel("Time over a wingbeat (t/T)")
ylabel("Current (mA)")
end
end