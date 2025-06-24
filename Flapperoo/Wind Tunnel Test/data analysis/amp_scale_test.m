clear
close all

cur_bird = flapper("Flapperoo");
data_path = "F:\Final Force Data/";

amplitude_list = linspace(pi/12,pi/4,100);
freq_vals = [2,3];
AoA_vals = -16:1:16;
wind_speed = 4;

[center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements(cur_bird.name);

full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;

mean_eff_AoA = zeros(length(AoA_vals));
slopes = zeros(length(amplitude_list),length(freq_vals));
mean_eff_AoA_sin = zeros(length(AoA_vals));
slopes_sin = zeros(length(amplitude_list),length(freq_vals));
mean_eff_AoA_sin2 = zeros(length(AoA_vals));
slopes_sin2 = zeros(length(amplitude_list),length(freq_vals));
for i = 1:length(amplitude_list)
cur_amp = amplitude_list(i);

for j = 1:length(freq_vals)
cur_freq = freq_vals(j);

[time, ang_disp, ang_vel, ang_acc] = get_kinematics(data_path, cur_freq, cur_amp);
lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;

for k = 1:length(AoA_vals)
cur_angle = AoA_vals(k);

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, cur_angle, wind_speed);

eff_AoA_span_mean = mean(eff_AoA, 2);
u_rel_span_mean = mean(u_rel, 2);
eff_AoA_span_mean_r = mean(eff_AoA .* r, 2);
eff_AoA_span_mean_r2 = mean(eff_AoA .* r.^2, 2);

mean_eff_AoA(k) = mean(eff_AoA_span_mean.* (cos(ang_disp)));
mean_u_rel(k) = mean(u_rel_span_mean);
mean_eff_AoA_sin(k) = mean(eff_AoA_span_mean_r.*sin(2*pi*cur_freq*time).*sin(cur_angle).* (cos(ang_disp)));
mean_eff_AoA_sin2(k) = mean(eff_AoA_span_mean_r2.*(sin(2*pi*cur_freq*time)).^2 .* (cos(ang_disp)));

end
x = [ones(size(AoA_vals')), AoA_vals'];
y = mean_eff_AoA';
b = x\y;
slopes(i,j) = b(2);

y = mean_eff_AoA_sin';
b = x\y;
slopes_sin(i,j) = b(2);

y = mean_eff_AoA_sin2';
b = x\y;
slopes_sin2(i,j) = b(2);
end
end

figure
for j=1:length(freq_vals)
    % sin1   -> 	Y = a1*sin(b1*x+c1)
    test_fit = fit(amplitude_list', slopes(:,j), 'sin1')
    y_mod = test_fit.a1 * sin(test_fit.b1 * amplitude_list + test_fit.c1);

    hold on
    plot(amplitude_list, slopes(:,j));
    plot(amplitude_list, y_mod, LineStyle="--",Color="black")
end
legend()

% figure
% for j=1:length(freq_vals)
%     hold on
%     plot(amplitude_list, slopes_sin(:,j));
%     % plot(St_list(:,i), mod_slopes(:,i));
% end

figure
for j=1:length(freq_vals)
    hold on
    plot(amplitude_list, slopes_sin2(:,j));
    % plot(St_list(:,i), mod_slopes(:,i));
end