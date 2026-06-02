function [norm_time_speed, phase_avg_pos, phase_std_pos,...
    phase_avg_speed, phase_std_speed, phase_avg_acc, phase_std_acc,...
    phase_avg_wing_pos, phase_std_wing_pos,...
    phase_avg_wing_speed, phase_std_wing_speed, phase_avg_wing_acc, phase_std_wing_acc,...
    bin_count_speed, bin_std_speed, phase_avg_volt, phase_std_volt,...
    phase_avg_cur, phase_std_cur] = speed_phase_avg(PIV_case_name, plot_bool)

[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);
[amp, type, freq] = parse_name(PIV_case_name);

% Get raw data from file
load([daq_data_path daq_data_filename]);

% no load cell mounted, so blank values used
offsets = zeros(1,size(results,2));
cal_mat = zeros(6,6);

ticksPerRev = 18432;
OC_pulse_step = 4;
[time_data, force_data, voltAdj, curAdj, pos, speed, acc, wing_pos, wing_speed, wing_acc] = ...
    process_data(results, offsets, cal_mat, ticksPerRev, OC_pulse_step, amp, true);

OC_pulse_count = results(:,11);
raw_pos = OC_pulse_count / (ticksPerRev / OC_pulse_step);

% Find indices where a laser fire has been recorded
las_count = results(:,12);
mid_indices = find(las_count ~= 0 & las_count ~= las_count(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];

% trim off begininning and end when accelerating
raw_pos_tr = raw_pos(mid_indices_adj);
time_tr = time_data(mid_indices_adj);
pos_tr = pos(mid_indices_adj);
speed_tr = speed(mid_indices_adj);
acc_tr = acc(mid_indices_adj);
wing_pos_tr = wing_pos(mid_indices_adj);
wing_speed_tr = wing_speed(mid_indices_adj);
wing_acc_tr = wing_acc(mid_indices_adj);
volt_tr = voltAdj(mid_indices_adj);
cur_tr = curAdj(mid_indices_adj);

% figure
% plot(time_tr,wing_pos_tr)

norm_frame_pos_full = mod(raw_pos_tr,1);

% figure
% plot(norm_frame_pos_full)

bins_list_speed = 500:50:1500;
best_num_bins_speed = 0;
for num_bins_speed = bins_list_speed
bins_speed = linspace(0,1,num_bins_speed+1);
bin_ind_arr_speed = discretize(norm_frame_pos_full, bins_speed);

bin_count_speed = zeros(1,num_bins_speed);

for j = 1:num_bins_speed
    bin_indices_speed = find(bin_ind_arr_speed == j);
    bin_count_speed(j) = length(bin_indices_speed);
end

% ensure at least 100 frames per bin and number of bins is divis by 5
if min(bin_count_speed) > 100 && mod(num_bins_speed,5) == 0
    best_num_bins_speed = num_bins_speed;
end
end

num_bins_speed = best_num_bins_speed;
% num_bins_speed = 1000;
disp("Using " + num_bins_speed + " bins for speed phase averaging")

bins_speed = linspace(0,1,num_bins_speed+1);
bin_ind_arr_speed = discretize(norm_frame_pos_full, bins_speed);

bin_count_speed = zeros(1,num_bins_speed);
bin_std_speed = zeros(1,num_bins_speed);

phase_avg_pos = zeros(1,num_bins_speed);
phase_std_pos = zeros(1,num_bins_speed);

phase_avg_speed = zeros(1,num_bins_speed);
phase_std_speed = zeros(1,num_bins_speed);

phase_avg_acc = zeros(1,num_bins_speed);
phase_std_acc = zeros(1,num_bins_speed);

phase_avg_wing_pos = zeros(1,num_bins_speed);
phase_std_wing_pos = zeros(1,num_bins_speed);

phase_avg_wing_speed = zeros(1,num_bins_speed);
phase_std_wing_speed = zeros(1,num_bins_speed);

phase_avg_wing_acc = zeros(1,num_bins_speed);
phase_std_wing_acc = zeros(1,num_bins_speed);

phase_avg_volt = zeros(1,num_bins_speed);
phase_std_volt = zeros(1,num_bins_speed);

phase_avg_cur = zeros(1,num_bins_speed);
phase_std_cur = zeros(1,num_bins_speed);

pos_tr_adj = mod(pos_tr, 2*pi);
% no adjustment needed for wing position

for j = 1:num_bins_speed
    bin_indices_speed = find(bin_ind_arr_speed == j);
    bin_count_speed(j) = length(bin_indices_speed);
    bin_std_speed(j) = std(norm_frame_pos_full(bin_indices_speed))*100;

    phase_avg_pos(j) = mean(pos_tr_adj(bin_indices_speed));
    phase_std_pos(j) = std(pos_tr_adj(bin_indices_speed));

    phase_avg_speed(j) = mean(speed_tr(bin_indices_speed));
    phase_std_speed(j) = std(speed_tr(bin_indices_speed));

    phase_avg_acc(j) = mean(acc_tr(bin_indices_speed));
    phase_std_acc(j) = std(acc_tr(bin_indices_speed));

    phase_avg_wing_pos(j) = mean(wing_pos_tr(bin_indices_speed));
    phase_std_wing_pos(j) = std(wing_pos_tr(bin_indices_speed));

    phase_avg_wing_speed(j) = mean(wing_speed_tr(bin_indices_speed));
    phase_std_wing_speed(j) = std(wing_speed_tr(bin_indices_speed));

    phase_avg_wing_acc(j) = mean(wing_acc_tr(bin_indices_speed));
    phase_std_wing_acc(j) = std(wing_acc_tr(bin_indices_speed));

    phase_avg_volt(j) = mean(volt_tr(bin_indices_speed));
    phase_std_volt(j) = std(volt_tr(bin_indices_speed));

    phase_avg_cur(j) = mean(cur_tr(bin_indices_speed));
    phase_std_cur(j) = std(cur_tr(bin_indices_speed));
end

norm_time_speed = linspace(0,1,num_bins_speed);

if plot_bool
figure
bar(bin_count_speed)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
bar(bin_std_speed)
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