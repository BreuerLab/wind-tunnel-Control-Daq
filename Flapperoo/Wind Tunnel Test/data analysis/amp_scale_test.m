clear
close all

cur_bird = flapper("Flapperoo");
data_path = "F:\Final Force Data/";

amplitude_list = pi/12:0.01:pi/6;
wing_freqs = 0:1:5;
lim_AoA_sel = -16:1:16;
wind_speed = 4;

AR = 2.5;
lift_slope = ((2*pi) / (1 + 2/AR));
pitch_slope = -lift_slope / 4;

mod_slopes = zeros(length(amplitude_list), length(wing_freqs));
mod_x_intercepts = zeros(length(amplitude_list), length(wing_freqs));

St_list = zeros(length(amplitude_list), length(wing_freqs));

for j = 1:length(amplitude_list)
amp = amplitude_list(j);

for k = 1:length(wing_freqs)
wing_freq = wing_freqs(k);
St_list(j,k) = amp*wing_freq;

[time, ang_disp, ang_vel, ang_acc] = get_kinematics(obj.data_path, cur_freq, cur_amp);
                
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;

lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, cur_angle, cur_speed);

eff_AoA_span_mean = mean(eff_AoA, 2);
u_rel_span_mean = mean(u_rel, 2);
eff_AoA_span_mean_r = mean(eff_AoA .* r, 2);
eff_AoA_span_mean_r2 = mean(eff_AoA .* r.^2, 2);

mean_eff_AoA(j,k) = mean(eff_AoA_span_mean.* (cos(ang_disp)));
mean_u_rel(j,k) = mean(u_rel_span_mean);
mean_eff_AoA_sin(j,k) = mean(eff_AoA_span_mean_r.*sin(2*pi*cur_freq*time).*sin(cur_angle).* (cos(ang_disp)));
mean_eff_AoA_sin2(j,k) = mean(eff_AoA_span_mean_r2.*(sin(2*pi*cur_freq*time)).^2 .* (cos(ang_disp)));

% % temp code to block out x_int inclusion in model
% zero_lift_alpha = 0;
% zero_pitch_alpha = 0;
% aero_force = get_model(cur_bird.name, data_path, lim_AoA_sel, wing_freq, wind_speed,...
%     lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, amp);
% 
% idx = 5; % pitch moment
% x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
% y = aero_force(idx,:)';
% b = x\y;
% % model = x*b;
% % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
% x_int = - b(1) / b(2);
% 
% mod_slopes(j,k) = b(2);
% mod_x_intercepts(j,k) = x_int;
    end
    x = [ones(size(AoA_vals')), AoA_vals'];
    y = mean_eff_AoA(j,:)';
    b = x\y;
    slopes(j) = b(2);
    
    y = mean_eff_AoA_sin(j,:)';
    b = x\y;
    slopes_sin(j) = b(2);
    
    y = mean_eff_AoA_sin2(j,:)';
    b = x\y;
    slopes_sin2(j) = b(2);
end

figure
for i=1:length(wing_freqs)
    hold on
    plot(amplitude_list, mod_slopes(:,i));
    % plot(St_list(:,i), mod_slopes(:,i));
end