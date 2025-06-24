restoredefaultpath
% There are a lot of functions in the data processing folder,
% simply right click on the function you want to learn about to
% be brought to the file where it is defined. Of course this runs
% the risk of the same function name existing twice (an
% overloaded function).
addpath(genpath('C:\Users\rgissler\Documents\GitHub\wind-tunnel-Control-Daq\Flapperoo\Wind Tunnel Test/data processing'))

clear
close all
data_path = 'F:\Final Force Data/';

%-------------------------------------------------------------
%------------------------User selects files-------------------
%-------------------------------------------------------------

% raw_data_path = "../Experimental Data/Data 10_22_2024/Impulse/experiment data/";
raw_data_path = "F:\Final Force Data/Vibes/";
files = ["impulse_L_100_0Hz_experiment_2024-10-22 08-50-06.csv",...
         "impulse_R_100_0Hz_experiment_2024-10-22 08-42-36.csv"];
% files = ["impulse_L_100_0Hz_experiment_2024-10-22 08-50-06.csv",...
%          "impulse_R_100_0Hz_experiment_2024-10-22 08-40-46"];

%-------------------------------------------------------------
%----------------------Processing Trial-----------------------
%-------------------------------------------------------------

[time_L, data_L, trim_time_L, trim_data_L] = getData(raw_data_path + files(1));
[time_R, data_R, trim_time_R, trim_data_R] = getData(raw_data_path + files(2));

%%%%%%%%%%%%%%%%%%%%%%%
% ADD SOME TRIMMING OF THE SIGNAL
%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------------------------------
%--------------------------Plotting---------------------------
%-------------------------------------------------------------

% if index = 0, plots all axes
% if index = 1-6, plots the axes specified by the index
index = 0;

titles = ["F_x","F_y","F_z","M_x","M_y","M_z"];
y_labels = ["Force (N)","Moment (N m)"];
x_label = "Time (s)";

if (index == 0)
    % Open a new figure.
    f = figure;
    f.Position = [260, 160, 1250, 800];
    tcl = tiledlayout(2,3);
    
    for k = 1:6
        nexttile(tcl)
        hold on
        L_line = plot(time_L, data_L(k, :));
        L_line.DisplayName = "Left Wing 100g";
        % L_line.LineWidth = 2;
        R_line = plot(time_R, data_R(k, :));
        R_line.DisplayName = "Right Wing 100g";
        % R_line.LineWidth = 2;
        title(titles(k));
        xlabel(x_label);
        ylabel(y_labels(ceil(k/3)));
        legend()
    end

    hL.Layout.Tile = 'East';
    sgtitle("Force Transducer Data for Wing Impulse Tests")
else
    figure;
    hold on
    R_line = plot(time_R, data_R(index, :));
    R_line.DisplayName = "Right Wing 100g";
    title(titles(index));
    xlabel(x_label);
    ylabel(y_labels(ceil(index/3)));
end

%-------------------------------------------------------------
%------------------Plotting gradient of data------------------
%-------------------------------------------------------------

if (index == 0)
    % Open a new figure.
    f = figure;
    f.Position = [260, 160, 1250, 800];
    tcl = tiledlayout(2,3);
    
    for k = 1:6
        nexttile(tcl)
        hold on
        L_line = plot(time_L, gradient(data_L(k, :)));
        L_line.DisplayName = "Left Wing 100g";
        % L_line.LineWidth = 2;
        R_line = plot(time_R, gradient(data_R(k, :)));
        R_line.DisplayName = "Right Wing 100g";
        % R_line.LineWidth = 2;
        title(titles(k));
        xlabel(x_label);
        ylabel(y_labels(ceil(k/3)));
        legend()
    end

    hL.Layout.Tile = 'East';
    sgtitle("Force Transducer Data for Wing Impulse Tests")
else
    figure;
    hold on
    plot(time_data, filtered_data(index, :));
    title(titles(index));
    xlabel("Time (s)");
    ylabel(yLabs(index));
end

%-------------------------------------------------------------
%-------------------Plotting trimmed data---------------------
%-------------------------------------------------------------

peak_thresh = 0.08;
sel_ind = 4;
[pks_L, locs_L, w_L, p_L] = findpeaks(trim_data_L(sel_ind, :));
peak_times_L = trim_time_L(locs_L(p_L > peak_thresh));
peaks_L = trim_data_L(sel_ind, locs_L(p_L > peak_thresh));
[pks_R, locs_R, w_R, p_R] = findpeaks(trim_data_R(sel_ind, :));
peak_times_R = trim_time_R(locs_R(p_R > peak_thresh));
peaks_R = trim_data_R(sel_ind, locs_R(p_R > peak_thresh));

index = sel_ind;
if (index == 0)
    % Open a new figure.
    f = figure;
    f.Position = [260, 160, 1250, 800];
    tcl = tiledlayout(2,3);
    
    for k = 1:6
        nexttile(tcl)
        hold on
        L_line = plot(trim_time_L, trim_data_L(k, :));
        L_line.DisplayName = "Left Wing 100g";
        % L_line.LineWidth = 2;
        R_line = plot(trim_time_R, trim_data_R(k, :));
        R_line.DisplayName = "Right Wing 100g";
        % R_line.LineWidth = 2;
        title(titles(k));
        xlabel(x_label);
        ylabel(y_labels(ceil(k/3)));
        legend()
    end

    hL.Layout.Tile = 'East';
    sgtitle("Force Transducer Data for Wing Impulse Tests")
else
    figure;
    hold on
    L_line = plot(trim_time_L, trim_data_L(index, :));
    L_line.DisplayName = "Left Wing 100g";
    R_line = plot(trim_time_R, trim_data_R(index, :));
    R_line.DisplayName = "Right Wing 100g";

    scatter(peak_times_L, peaks_L, 40, "filled", HandleVisibility="off")
    scatter(peak_times_R, peaks_R, 40, "filled", HandleVisibility="off")
    title(titles(index));
    xlabel(x_label);
    ylabel(y_labels(ceil(index/3)));
    legend()
end

%-------------------------------------------------------------
%----------------Focusing on right wing only------------------
%-------------------------------------------------------------

figure;
hold on
R_line = plot(trim_time_R, trim_data_R(index, :));
R_line.DisplayName = "Right Wing 100g";
scatter(peak_times_R, peaks_R, 40, "filled", HandleVisibility="off")
title(titles(index));
xlabel(x_label);
ylabel(y_labels(ceil(index/3)));
legend()

delta = [log(peaks_R(1) / peaks_R(2)), log(peaks_R(2) / peaks_R(3))];
T = [peak_times_R(2) - peak_times_R(1), peak_times_R(3) - peak_times_R(2)];
zeta = delta ./ sqrt(4*pi^2 + delta.^2);
omega_d = 1 ./ T; % in Hz
disp("Looking at right wing only")
disp("Damped natural frequency: " + omega_d + " Hz")
omega_d = (2*pi) ./ T; % in rad
omega_n = omega_d ./ sqrt(1 - zeta.^2);

const = 0.45; % what should this value be?
z = mean(zeta);
w_d = mean(omega_d);
w_n = mean(omega_n);

[pks_R, locs_R, w_R, p_R] = findpeaks(-trim_data_R(sel_ind, :));
%  trim_time_R(locs_R(2)), the peak around t = 0.025
new_start = locs_R(2);
trim_time_R = trim_time_R(new_start:end);
trim_time_R = trim_time_R - min(trim_time_R);
trim_data_R = trim_data_R(:, new_start:end);

t = trim_time_R;
% switched from sin to cos to better phase align
disp("\zeta = " + z)
disp("w_n = " + w_n)
disp("w_d = " + w_d)
response = -const*(exp(-z*w_d*t) .* cos(w_d*t));

figure;
hold on
R_line = plot(trim_time_R, trim_data_R(index, :));
R_line.DisplayName = "Right Wing 100g";
R_mod = plot(trim_time_R, response);
R_mod.DisplayName = "Model";
title(titles(index));
xlabel(x_label);
ylabel(y_labels(ceil(index/3)));
legend()

%-------------------------------------------------------------
%-------------Angular Displacement based on Mx----------------
%-------------------------------------------------------------

int_const = (z^2 * w_n^2 - w_d^2) / (z^2 * w_n^2 + w_d^2);
I = 0.01 * 0.2^2; % 10 grams offset by 20 cm from center
const = const * int_const / I;
response = -const*(exp(-z*w_n*t) .* cos(w_d*t));
response = rad2deg(response);

figure;
hold on
R_mod = plot(trim_time_R, response);
R_mod.DisplayName = "Model";
title(titles(index));
xlabel(x_label);
ylabel("Angular Displacement");
legend()

% using convolution approach to find angle

t = trim_time_R;

mass = 0.010; % kg
dropped_mass = 0.1;
r = 0.2; % 20 cm from rotation axis, where is COM of wing?
I = mass * r^2;
T = dropped_mass * 9.81 * 0.03 * ones(1, length(t) - 1);
T = [0 T]; % choosing to include this or not doesn't really change anything

% repeat time, theta_b arrays
g = -(exp(-z*w_n*t) .* cos(w_d*t)) / (I*w_d);
% just recently changed from sin to -cos, should be -cos since that's same
% in Mx case so theta should have same phase

dt = t(2) - t(1);
response = dt*conv(T, g);
response = response(1:(length(response) - 1)/2 + 1);
response = rad2deg(response);
% response = response - response(end); % assuming it ends back up at zero

% what should be unit impulse response function
figure;
hold on
R_mod = plot(trim_time_R, g);
R_mod.DisplayName = "Model";
title("Unit Impulse Response Function");
xlabel(x_label);
ylabel("Angular Displacement (deg)");
legend()

% online there is no mass/inertia term for unit response
% g = -(exp(-z*w_n*t) .* cos(w_d*t)) / (w_d);
% figure;
% hold on
% R_mod = plot(trim_time_R, g);
% R_mod.DisplayName = "Model";
% title("Unit Impulse Response Function");
% xlabel(x_label);
% ylabel("Angular Displacement (deg)");
% legend()

figure;
hold on
R_mod = plot(trim_time_R, response);
R_mod.DisplayName = "Model";
title(titles(index));
xlabel(x_label);
ylabel("Angular Displacement (deg)");
legend()

% Response for unit-impulse gives a number that's closer but what I've done
% is not a unit-impulse response, it's something else...
% T = ones(1, length(t) - 1);
% T = [0 T]; % choosing to include this or not doesn't really change anything
% dt = t(2) - t(1);
% response = dt*conv(T, g);
% response = response(1:(length(response) - 1)/2 + 1);
% response = rad2deg(response);
% % response = response - response(end); % assuming it ends back up at zero

% Using angular response to predict moment
theta_ddot = gradient(gradient(response, dt), dt);
M_x = I * deg2rad(theta_ddot);

figure;
hold on
R_mod = plot(t, M_x);
R_mod.DisplayName = "Model";
title(titles(index));
xlabel(x_label);
ylabel("Moment (N*m)");
legend()

%-------------------------------------------------------------
%------------------------Right wing F_z-----------------------
%-------------------------------------------------------------

I = 0.005; % r = 0.03, m = 0.010
response = -(exp(-z*w_d*t) .* cos(w_d*t)) / (I*w_d);
figure;
hold on
R_line = plot(trim_time_R, trim_data_R(3, :));
R_line.DisplayName = "Right Wing 100g";
R_mod = plot(trim_time_R, response);
R_mod.DisplayName = "Model";
title(titles(3));
xlabel(x_label);
ylabel(y_labels(ceil(3/3)));
legend()

%-------------------------------------------------------------
%---------Estimating response to flapping forcing-------------
%-------------------------------------------------------------

wing_freq = 3;
amp = -1; % use CAD values
path = data_path;
[time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, wing_freq, amp);
dt = (time(2) - time(1));

I = 0.005; % r = 0.03, m = 0.010 + 0.100, roughly mr^2 * 50
g = (exp(-z*w_d*time) .* sin(w_d*time)) / (I*w_d);

theta_b = deg2rad(ang_acc);
mass = 0.010; % kg
r = 0.02; % 20 cm from rotation axis, where is center of mass of wing?

T = mass * r^2 * theta_b;
theta = dt*conv(T, g);
theta = theta(1:(length(theta) - 1)/2 + 1);

figure
hold on
yyaxis left
plot(time, ang_acc)
yyaxis right
plot(time, theta)

%-------------------------------------------------------------
%-------Estimating response to after many wingbeats-----------
%-------------------------------------------------------------

% repeat time, theta_b arrays
dt = (time(2) - time(1));
time_long = 0:dt:1;
theta_b_long = [theta_b(1:end-1); theta_b(1:end-1); theta_b(1:end)]';
g = (exp(-z*w_d*time_long) .* sin(w_d*time_long)) / (I*w_d);

T = mass * r^2 * theta_b_long;
theta = dt*conv(T, g);
theta = theta(1:(length(theta) - 1)/2 + 1);

figure
plot(time_long, theta)

% forcing appears to be dominating over body dynamics except in very
% beginning

% forcing appears to be dominating over body dynamics except in very
% beginning

% mass, r, I are just constants that don't change balance between vibration
% and forcing signal. They simply shift the amplify the whole signal. 

%-------------------------------------------------------------
%------Including impulse at beginning of each cycle-----------
%-------------------------------------------------------------

% repeat time, theta_b arrays
dt = (time(2) - time(1));
time_long = 0:dt:3;
theta_b(1) = -5000; % the magnitude of this number definetly influences response,
% I imagine the duration of the impulse determine by dt from
% get_kinematics() would also influence the response
theta_b_long = [theta_b(1:end-1); theta_b(1:end-1); theta_b(1:end-1);...
                theta_b(1:end-1); theta_b(1:end-1); theta_b(1:end-1);...
                theta_b(1:end-1); theta_b(1:end-1); theta_b(1:end)]';
g = (exp(-z*w_d*time_long) .* sin(w_d*time_long)) / (I*w_d);

T = mass * r^2 * theta_b_long;
theta = dt*conv(T, g);
theta = theta(1:(length(theta) - 1)/2 + 1);

figure
hold on
yyaxis left
plot(time_long, theta, DisplayName="Convolution")
yyaxis right
plot(time_long, g, DisplayName="Impulse")
legend()

theta_later = theta(end-length(theta_b)+1:end);
figure
plot(time, theta_later)

function [time_data, filtered_data, trimmed_time, trimmed_force] = getData(filename)
AoA = 0;
frame_rate = 9000;

% Get raw data from file
data = readmatrix(filename);
time_data = data(:,1)';
force_data = data(:,2:7)';

% Rotate the data from the force transducer reference frame to the wind
% tunnel reference frame (body frame to global frame)
results_lab = coordinate_transformation(force_data, AoA);

% Smooth the data with a butterworth filter
fc = 50; % cutoff frequency
filtered_data = filter_data(results_lab, frame_rate, fc);
data_diff = gradient(filtered_data);

sel_ind = 4;
baseline_noise = 4*std(data_diff(sel_ind, 1:frame_rate)); % roll moment has high magnitude
disp("Threshold: " + 4*std(gradient(filtered_data(sel_ind, 1:frame_rate))))

init_idx = 1;
end_idx = 2;
% Find where signal departs baseline noise level
for i = 1:length(filtered_data(sel_ind, :))
    if abs(data_diff(sel_ind, i)) > baseline_noise
        init_idx = i;
        break
    end
end

% Find where signal returns to baseline noise level
for i = 1:length(filtered_data(sel_ind, init_idx + frame_rate:end))
    if abs(data_diff(sel_ind, i)) < baseline_noise
        end_idx = i + init_idx + frame_rate;
        break
    end
end

trimmed_time = time_data(init_idx:end_idx);
trimmed_time = trimmed_time - min(trimmed_time);
trimmed_force = filtered_data(:, init_idx:end_idx);
trimmed_force = trimmed_force - mean(filtered_data(:, end_idx:end), 2);

end