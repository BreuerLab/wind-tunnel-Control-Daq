clear
close all

addpath plotting\
addpath process_trial\functions\
addpath robot_parameters\

wing_freq_sel = [4];
wind_speed_sel = [4];
type_sel = ["blue wings with tail"];
% type_sel = ["no wings with tail"];
AoA_sel = -10:1:10;
% AoA_sel = -8:1:8;
% subtraction_string = "none";
subtraction_string = "no wings with tail";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

norm_bool = false;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

[avg_forces, err_forces, names, sub_title, norm_factors] = ...
    get_data_AoA(selected_vars, processed_data_path, norm_bool, subtraction_string);

figure
hold on
s = scatter(AoA_sel, avg_forces(1, :), 25, HandleVisibility="off");
s.MarkerEdgeColor = [0 0.4470 0.7410];
s.MarkerFaceColor = [0 0.4470 0.7410];
[w,B,C] = cos_curve_fit(AoA_sel, avg_forces(1,:));
model = B*cosd(w*AoA_sel) + C;
y = avg_forces(1, :);
Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
label = "y = " + B + "*cos(" + w + "*\alpha) + " + C + "   R^2 = " + Rsq;
plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
legend()
xlabel("Angle of Attack \alpha")
ylabel("Drag Coefficient")
title(["Drag" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
s = scatter(AoA_sel, avg_forces(3, :), 25, HandleVisibility="off");
s.MarkerEdgeColor = [0 0.4470 0.7410];
s.MarkerFaceColor = [0 0.4470 0.7410];
x = [ones(size(AoA_sel')), AoA_sel'];
y = avg_forces(3, :)';
b_lift = x\y;
model = x*b_lift;
lift_slope = b_lift(2);
lift_intercept = b_lift(1);
Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
label = "y = " + lift_slope + "x + " + lift_intercept + "   R^2 = " + Rsq;
plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
legend()
xlabel("Angle of Attack \alpha")
ylabel("Lift Coefficient")
title(["Lift" "Wind Speed: " + wind_speed_sel + " m/s"])

% sub_title = "Wind Speed: " + wind_speed_sel + " m/s";
% [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, true, sub_title);

figure
hold on
s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
s.MarkerEdgeColor = [0 0.4470 0.7410];
s.MarkerFaceColor = [0 0.4470 0.7410];
x = [ones(size(AoA_sel')), AoA_sel'];
y = avg_forces(5, :)';
b_pitch = x\y;
model = x*b_pitch;
pitch_slope = b_pitch(2);
pitch_intercept = b_pitch(1);
Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
label = "y = " + pitch_slope + "x + " + pitch_intercept + "   R^2 = " + Rsq;
plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
legend()
xlabel("Angle of Attack \alpha")
ylabel("Pitch Moment Coefficient")
title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
plot(AoA_sel, abs(y - model), Color=[0 0.4470 0.7410])
s = scatter(AoA_sel, abs(y - model), 25);
s.MarkerEdgeColor = [0 0.4470 0.7410];
s.MarkerFaceColor = [0 0.4470 0.7410];
xlabel("Angle of Attack \alpha")
ylabel("Residual")
title(["Pitch Moment Residual from Linear Fit" "Wind Speed: " + wind_speed_sel + " m/s"])

% figure
% hold on
% s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
% s.MarkerEdgeColor = [0 0.4470 0.7410];
% s.MarkerFaceColor = [0 0.4470 0.7410];
% [off_pitch, w_pitch, B_pitch, C_pitch] = sin_curve_fit(AoA_sel, avg_forces(5, :), 5);
% model = B_pitch*sind(w_pitch*AoA_sel + off_pitch) + C_pitch;
% % [w_pitch, B_pitch, C_pitch] = sin_curve_fit(AoA_sel, avg_forces(5, :));
% % model = B_pitch*sind(w_pitch*AoA_sel) + C_pitch;
% y = avg_forces(5, :);
% Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
% label = "y = " + B_pitch + "sin(" + w_pitch +"*x + " + off_pitch + ") + " + C_pitch + "   R^2 = " + Rsq;
% % label = "y = " + B_pitch + "sin(" + w_pitch +"*x) + " + C_pitch + "   R^2 = " + Rsq;
% plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
% legend()
% xlabel("Angle of Attack \alpha")
% ylabel("Pitch Moment Coefficient")
% title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])
% 
% figure
% hold on
% s = scatter(AoA_sel, avg_forces(5, :), 25, HandleVisibility="off");
% s.MarkerEdgeColor = [0 0.4470 0.7410];
% s.MarkerFaceColor = [0 0.4470 0.7410];
% p = polyfit(AoA_sel, avg_forces(5, :), 4);
% y = avg_forces(5, :);
% model = p(1)*AoA_sel.^4 + p(2)*AoA_sel.^3 + p(3)*AoA_sel.^2 + p(4)*AoA_sel + p(5);
% Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
% label = "   R^2 = " + Rsq;
% plot(AoA_sel, model, DisplayName=label, Color=[0 0.4470 0.7410])
% legend()
% xlabel("Angle of Attack \alpha")
% ylabel("Pitch Moment Coefficient")
% title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])

% SineParams = sineFit(AoA_sel, avg_forces(5, :),true);
% [offs, amp, freq, phi, MSE]

wing_freq_vals = 1:1:4;

C_L_vals = zeros(length(wing_freq_vals),length(AoA_sel));
C_D_vals = zeros(length(wing_freq_vals),length(AoA_sel));
C_N_vals = zeros(length(wing_freq_vals),length(AoA_sel));
C_M_vals = zeros(length(wing_freq_vals),length(AoA_sel));

for m = 1:length(wing_freq_vals)

wing_freq = wing_freq_vals(m);

for k = 1:length(AoA_sel)

AoA = AoA_sel(k);
case_name = wind_speed_sel + "m/s " + wing_freq + "Hz " + AoA + "deg";

% wind_speed = 100;
[time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq, true);

wing_length = 0.25; % meters
arm_length = 0.016;
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
lin_vel = deg2rad(ang_vel) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed_sel);

thinAirfoil = true;
[C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, wind_speed_sel, wing_length, thinAirfoil);

C_L_vals(m,k) = mean(C_L);
C_D_vals(m,k) = mean(C_D);
C_N_vals(m,k) = mean(C_N);
C_M_vals(m,k) = mean(C_M);

plots_bool = false;
if (plots_bool)
if (AoA == 10)
fig = figure;
fig.Position = [200 50 900 560];
hold on
plot(time, u_rel(:,51), DisplayName="r = 0.05")
plot(time, u_rel(:,151), DisplayName="r = 0.15")
plot(time, u_rel(:,251), DisplayName="r = 0.25")
xlim([0 max(time)])
plot_wingbeat_patch();
hold off
xlabel("Time (s)")
ylabel("Effective Wind Speed (m/s)")
title("Effective Wind Speed during Flapping for " + case_name)
legend(Location="northeast")

fig = figure;
fig.Position = [200 50 900 560];
hold on
plot(time, eff_AoA(:,51), DisplayName="r = 0.05")
plot(time, eff_AoA(:,151), DisplayName="r = 0.15")
plot(time, eff_AoA(:,251), DisplayName="r = 0.25")
xlim([0 max(time)])
plot_wingbeat_patch();
hold off
xlabel("Time (s)")
ylabel("Effective Angle of Attack (deg)")
title("Effective Angle of Attack during Flapping for " + case_name)
legend(Location="northeast")

fig = figure;
fig.Position = [200 50 900 560];
yyaxis left
plot(time, C_L)
ylabel("Lift Coefficient")

yyaxis right
plot(time, C_M)
ylabel("Pitch Moment Coefficient")

xlim([0 max(time)])
% plot_wingbeat_patch();
xlabel("Time (s)")
title("Aerodynamic Model for " + case_name)
legend(Location="northeast")
end
end
end

% figure
% scatter(AoA_sel, C_L_vals, 40, 'filled', DisplayName="0 Hz Simulation")
% xlabel("Angle of Attack")
% ylabel("Lift Coefficient")
% 
% figure
% scatter(AoA_sel, C_M_vals,40,'filled')
% xlabel("Angle of Attack")
% ylabel("Moment Coefficient")
end

colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250];...
    [0.4940 0.1840 0.5560]; [0.4660 0.6740 0.1880]; [0.3010 0.7450 0.9330];...
    [1 0 0]; [0 1 0]; [0 0 1];...
    [0 1 1]; [1 0 1]; [1 1 0];...
    [0 0 0]; [1 1 1]];

figure
hold on
for m = 1:length(wing_freq_vals)
    plot(AoA_sel, C_D_vals(m,:), Color=colors(m,:), HandleVisibility="off")
    s = scatter(AoA_sel, C_D_vals(m,:),40,'filled');
    s.DisplayName = wing_freq_vals(m) + "Hz";
    s.MarkerFaceColor = colors(m,:);
    s.MarkerEdgeColor = colors(m,:);
end
legend()
xlabel("Angle of Attack")
ylabel("Drag Coefficient")
title(["Drag" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
for m = 1:length(wing_freq_vals)
    plot(AoA_sel, C_L_vals(m,:), Color=colors(m,:), HandleVisibility="off")
    s = scatter(AoA_sel, C_L_vals(m,:),40,'filled');
    s.DisplayName = wing_freq_vals(m) + "Hz";
    s.MarkerFaceColor = colors(m,:);
    s.MarkerEdgeColor = colors(m,:);
end
legend()
xlabel("Angle of Attack")
ylabel("Lift Coefficient")
title(["Lift" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
for m = 1:length(wing_freq_vals)
    plot(AoA_sel, C_M_vals(m,:), Color=colors(m,:), HandleVisibility="off")
    s = scatter(AoA_sel, C_M_vals(m,:),40,'filled');
    s.DisplayName = wing_freq_vals(m) + "Hz";
    s.MarkerFaceColor = colors(m,:);
    s.MarkerEdgeColor = colors(m,:);
end
legend()
xlabel("Angle of Attack")
ylabel("Pitching Moment Coefficient")
title(["Pitch Moment" "Wind Speed: " + wind_speed_sel + " m/s"])

pitch_slopes = zeros(1,length(wing_freq_vals));
pitch_slopes_percent_increase = zeros(1,length(wing_freq_vals) - 1);
for m = 1:length(wing_freq_vals)
    pitch_slopes(m) = (C_M_vals(m,1) - C_M_vals(m,end)) / (AoA_sel(1) - AoA_sel(end));
    if (m > 1)
        pitch_slopes_percent_increase(m-1) = ((pitch_slopes(m) - pitch_slopes(m-1)) / pitch_slopes(m-1))*100;
    end
end

x = [ones(size(wing_freq_vals))', log(wing_freq_vals)'];
y = log(abs(pitch_slopes - pitch_slopes(1)))';
x = x(2:end,:);
y = y(2:end);
b_pitch_log = x\y;
model_log = x*b_pitch_log;
pitch_slope_log = b_pitch_log(2);
pitch_intercept_log = b_pitch_log(1);

model_power = exp(pitch_intercept_log)*wing_freq_vals.^pitch_slope_log;
y_power = abs(pitch_slopes - pitch_slopes(1));
Rsq_power = 1 - sum((y_power - model_power).^2)/sum((y_power - mean(y_power)).^2);

figure
hold on
plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
s = scatter(wing_freq_vals, pitch_slopes, 40, 'filled');
s.MarkerFaceColor = colors(1,:);
s.MarkerEdgeColor = colors(1,:);
xlabel("Flapping Frequency (Hz)")
ylabel("Pitch Slope")
title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
% plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
plot(x(:,2), model_log,"DisplayName","y = " + pitch_slope_log + "*x + " + pitch_intercept_log)
s = scatter(x(:,2), y, 40, 'filled');
s.HandleVisibility = "off";
s.MarkerFaceColor = colors(1,:);
s.MarkerEdgeColor = colors(1,:);
xlabel("Log(Flapping Frequency)")
ylabel("Log(Pitch Slope)")
title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
legend();

figure
hold on
% plot(wing_freq_vals, pitch_slopes, Color=colors(1,:))
plot(wing_freq_vals, model_power,"DisplayName","y = " + exp(pitch_intercept_log) + "*x^{" + pitch_slope_log + "}, R^2 = " + Rsq_power)
s = scatter(wing_freq_vals, y_power, 40, 'filled');
s.HandleVisibility = "off";
s.MarkerFaceColor = colors(1,:);
s.MarkerEdgeColor = colors(1,:);
xlabel("Flapping Frequency (Hz)")
ylabel("Pitch Slope")
title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])
legend();

figure
hold on
plot(wing_freq_vals(2:end), pitch_slopes_percent_increase, Color=colors(1,:))
s = scatter(wing_freq_vals(2:end), pitch_slopes_percent_increase, 40, 'filled');
s.MarkerFaceColor = colors(1,:);
s.MarkerEdgeColor = colors(1,:);
xlabel("Flapping Frequency (Hz)")
ylabel("Pitch Slope Percent Increase")
title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

figure
hold on
plot(wing_freq_vals.^2, pitch_slopes, Color=colors(1,:))
s = scatter(wing_freq_vals.^2, pitch_slopes, 40, 'filled');
s.MarkerFaceColor = colors(1,:);
s.MarkerEdgeColor = colors(1,:);
xlabel("Flapping Frequency Squared (Hz)")
ylabel("Pitch Slope")
title(["Pitch Slope Scaling with Flapping Frequency" "Wind Speed: " + wind_speed_sel + " m/s"])

[center_to_LE, chord] = getWingMeasurements();
figure
legend
hold on
for m = 1:length(wing_freq_vals)
    if (thinAirfoil)
        COP_chord = -(C_M_vals(m,:) ./ C_N_vals(m,:)) * 100;
    else
        COP = (C_M_vals(m,:) ./ C_N_vals(m,:)) * chord;
        [COP_LE, COP_chord] = posToChord(COP);
    end
    s = scatter(AoA_sel,COP_chord,40,'filled');
    s.DisplayName = wing_freq_vals(m) + "Hz";
end
xlabel("Angle of Attack")
ylabel("Chordwise Location (% chord)")
title(["Center of Pressure" "Wind Speed: " + wind_speed_sel + " m/s"])

% fits a curve to the data of the form:
% y = B*cos(w*x) + C
% B, C are solved for using linear regression
% Assumption: xvals and yvals have the same size
function [w, B, C] = cos_curve_fit(x_vals, y_vals)

w_vals = 10:0.01:20;
lowest_err = -1;

for j = 1:length(w_vals)
w_cur = w_vals(j);
% allocate empty arrays on which to construct sums
coeff_mat = zeros(2,2);
y_mat = zeros(2,1);
for i = 1:length(x_vals)
    coeff_mat(1,1) = coeff_mat(1,1) + (cosd(w_cur*x_vals(i)))^2;

    coeff_mat(1,2) = coeff_mat(1,2) + cosd(w_cur*x_vals(i));

    coeff_mat(2,1) = coeff_mat(2,1) + cosd(w_cur*x_vals(i));

    coeff_mat(2,2) = coeff_mat(2,2) + 1;

    y_mat(1) = y_mat(1) + y_vals(i) * cosd(w_cur*x_vals(i));

    y_mat(2) = y_mat(2) + y_vals(i);
end

% calculate the coefficients B, C
coeffs = coeff_mat \ y_mat;
B_temp = coeffs(1);
C_temp = coeffs(2);

% evaluate the error associated with this fit
err_sum = 0;
model = B_temp*cosd(w_cur*x_vals) + C_temp;

for i = 1:length(x_vals)
    err_sum = err_sum + abs(y_vals(i) - model(i));
end
avg_err = err_sum / length(x_vals);
if (avg_err < lowest_err || j==1)
    lowest_err = avg_err;
    B = B_temp;
    C = C_temp;
    w = w_cur;
end

end

end

% % fits a curve to the data of the form:
% % y = B*sin(w*x) + C
% % B, C are solved for using linear regression
% % Assumption: xvals and yvals have the same size
% function [w, B, C] = sin_curve_fit(x_vals, y_vals)
% 
% w_vals = 10:0.01:20;
% lowest_err = -1;
% 
% for j = 1:length(w_vals)
% w_cur = w_vals(j);
% % allocate empty arrays on which to construct sums
% coeff_mat = zeros(2,2);
% y_mat = zeros(2,1);
% for i = 1:length(x_vals)
%     coeff_mat(1,1) = coeff_mat(1,1) + (sind(w_cur*x_vals(i)))^2;
% 
%     coeff_mat(1,2) = coeff_mat(1,2) + sind(w_cur*x_vals(i));
% 
%     coeff_mat(2,1) = coeff_mat(2,1) + sind(w_cur*x_vals(i));
% 
%     coeff_mat(2,2) = coeff_mat(2,2) + 1;
% 
%     y_mat(1) = y_mat(1) + y_vals(i) * sind(w_cur*x_vals(i));
% 
%     y_mat(2) = y_mat(2) + y_vals(i);
% end
% 
% % calculate the coefficients B, C
% coeffs = coeff_mat \ y_mat;
% B_temp = coeffs(1);
% C_temp = coeffs(2);
% 
% % evaluate the error associated with this fit
% err_sum = 0;
% model = B_temp*sind(w_cur*x_vals) + C_temp;
% 
% for i = 1:length(x_vals)
%     err_sum = err_sum + abs(y_vals(i) - model(i));
% end
% avg_err = err_sum / length(x_vals);
% if (avg_err < lowest_err || j==1)
%     lowest_err = avg_err;
%     B = B_temp;
%     C = C_temp;
%     w = w_cur;
% end
% 
% end
% 
% end

% fits a curve to the data of the form:
% y = B*sin(w*x + off) + C
% B, C are solved for using linear regression
% Assumption: xvals and yvals have the same size
function [off, w, B, C] = sin_curve_fit(x_vals, y_vals, iter)
if(iter > 1)
[off, w, B, C] = sin_curve_fit(x_vals, y_vals, iter - 1);
else
    off = 0;
end

w_vals = 10:0.01:30;
lowest_err = -1;

for j = 1:length(w_vals)
w_cur = w_vals(j);
% allocate empty arrays on which to construct sums
coeff_mat = zeros(2,2);
y_mat = zeros(2,1);
for i = 1:length(x_vals)
    coeff_mat(1,1) = coeff_mat(1,1) + (sind(w_cur*x_vals(i) + off))^2;

    coeff_mat(1,2) = coeff_mat(1,2) + sind(w_cur*x_vals(i) + off);

    coeff_mat(2,1) = coeff_mat(2,1) + sind(w_cur*x_vals(i) + off);

    coeff_mat(2,2) = coeff_mat(2,2) + 1;

    y_mat(1) = y_mat(1) + y_vals(i) * sind(w_cur*x_vals(i) + off);

    y_mat(2) = y_mat(2) + y_vals(i);
end

% calculate the coefficients B, C
coeffs = coeff_mat \ y_mat;
B_temp = coeffs(1);
C_temp = coeffs(2);

% evaluate the error associated with this fit
err_sum = 0;
model = B_temp*sind(w_cur*x_vals + off) + C_temp;

for i = 1:length(x_vals)
    err_sum = err_sum + abs(y_vals(i) - model(i));
end
avg_err = err_sum / length(x_vals);
if (avg_err < lowest_err || j==1)
    lowest_err = avg_err;
    B = B_temp;
    C = C_temp;
    w = w_cur;
end

end

off_vals = -80:0.01:80;

for j = 1:length(off_vals)
off_cur = off_vals(j);
% allocate empty arrays on which to construct sums
coeff_mat = zeros(2,2);
y_mat = zeros(2,1);
for i = 1:length(x_vals)
    coeff_mat(1,1) = coeff_mat(1,1) + (sind(w*x_vals(i) + off_cur))^2;

    coeff_mat(1,2) = coeff_mat(1,2) + sind(w*x_vals(i) + off_cur);

    coeff_mat(2,1) = coeff_mat(2,1) + sind(w*x_vals(i) + off_cur);

    coeff_mat(2,2) = coeff_mat(2,2) + 1;

    y_mat(1) = y_mat(1) + y_vals(i) * sind(w*x_vals(i) + off_cur);

    y_mat(2) = y_mat(2) + y_vals(i);
end

% calculate the coefficients B, C
coeffs = coeff_mat \ y_mat;
B_temp = coeffs(1);
C_temp = coeffs(2);

% evaluate the error associated with this fit
err_sum = 0;
model = B_temp*sind(w*x_vals + off_cur) + C_temp;

for i = 1:length(x_vals)
    err_sum = err_sum + abs(y_vals(i) - model(i));
end
avg_err = err_sum / length(x_vals);
if (avg_err < lowest_err || j==1)
    lowest_err = avg_err;
    B = B_temp;
    C = C_temp;
    off = off_cur;
end

end

disp("y = " + B + "sin(" + w +"*x + " + off + ") + " + C)
end