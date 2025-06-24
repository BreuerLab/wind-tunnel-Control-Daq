clear
close all

addpath plotting
addpath general
addpath robot_parameters
addpath modeling
% addpath \process_trial\functions\

data_bool = false; % compare model with real data?
fit_data_bool = false; % fit data with curve?
pitch_slopes_plot_bool = false;
wing_freq_sel = [0,2,3,4,5];
wind_speed_sel = [4];
AoA_sel = -8:1:8;
type_sel = -1;
norm_bool = true;
shift_bool = true; % shift pitch moment to LE

if (data_bool)
    type_sel = ["blue wings"];
    % type_sel = ["no wings with tail"];
    % subtraction_string = "none";
    sub_strings = ["no wings"];
    
    % path to folder where all processed data (.mat files) are stored
    processed_data_path = "../processed data/";
    
    if (fit_data_bool)
        % Put all our selected variables into a struct called selected_vars
        selected_vars.AoA = AoA_sel;
        selected_vars.freq = [0];
        selected_vars.wind = wind_speed_sel;
        selected_vars.type = type_sel;

        [avg_forces, err_forces, names, sub_title, norm_factors] = ...
        get_data_AoA(selected_vars, processed_data_path, norm_bool, sub_strings, shift_bool);

        fitAeroData(AoA_sel, wind_speed_sel, avg_forces);
    end

    % Put all our selected variables into a struct called selected_vars
    selected_vars.AoA = AoA_sel;
    selected_vars.freq = wing_freq_sel;
    selected_vars.wind = wind_speed_sel;
    selected_vars.type = type_sel;

    [avg_forces, err_forces, names, sub_title, norm_factors] = ...
    get_data_AoA(selected_vars, processed_data_path, norm_bool, sub_strings, shift_bool);
end

C_L_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_D_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_N_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_M_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));

for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for k = 1:length(AoA_sel)

AoA = AoA_sel(k);
case_name = wind_speed_sel + "m/s " + wing_freq_sel(j) + "Hz " + AoA + "deg";

[time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq_sel(j), true);

[center_to_LE, chord, COM_span, ...
    wing_length, arm_length] = getWingMeasurements();

full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
lin_vel = deg2rad(ang_vel) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed_sel);

thinAirfoil = true;
[C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, wind_speed_sel, wing_length, thinAirfoil);

C_L_vals(k,j,m) = mean(C_L);
C_D_vals(k,j,m) = mean(C_D);
C_N_vals(k,j,m) = mean(C_N);
C_M_vals(k,j,m) = mean(C_M);
% AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type
end
end
end

avg_pitch_moment = -1; % for data_bool = false case
if (data_bool)
avg_drag = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel),length(type_sel));
avg_lift = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel),length(type_sel));
avg_pitch_moment = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel),length(type_sel));
COP_chord = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel),length(type_sel));

for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
for k = 1:length(AoA_sel)

AoA = AoA_sel(k);

avg_drag(k, j, m, n) = avg_forces(1, k, j, m, n);
avg_lift(k, j, m, n) = avg_forces(3, k, j, m, n);
avg_pitch_moment(k, j, m, n) = avg_forces(5, k, j, m, n);

normal_force = avg_lift(k, j, m, n)*cosd(AoA) + avg_drag(k, j, m, n)*sind(AoA);

if (shift_bool)
    COP = avg_pitch_moment(k, j, m, n) / normal_force;
else
    error("Can't plot COP without shifted pitch moment")
end
% something more needed here for dimensional case
COP_chord(k, j, m, n) = COP * 100;

case_plot_bool = false;
if (case_plot_bool)
if (AoA == 10) % to prevent it from printing out continously for every AoA
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
end
end
end
end

if (pitch_slopes_plot_bool)
    pitch_slopes_plot(wing_freq_sel, AoA_sel, wind_speed_sel, type_sel, C_M_vals, data_bool, avg_pitch_moment);
end

if (length(wing_freq_sel) == 5 || length(wind_speed_sel) == 5)
    colors(:,:,1) = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
    colors(:,:,2) = ["#fdd49e"; "#fdbb84"; "#fc8d59"; "#e34a33"; "#b30000"];
elseif (length(wing_freq_sel) == 4 || length(wind_speed_sel) == 4)
    colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#43a2ca"; "#0868ac"];
    colors(:,:,2) = ["#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
elseif (length(wing_freq_sel) == 3 || length(wind_speed_sel) == 3)
    colors(:,:,1) = ["#bae4bc"; "#7bccc4"; "#2b8cbe"];
    colors(:,:,2) = ["#fdcc8a"; "#fc8d59"; "#d7301f"];
elseif (length(wing_freq_sel) == 2 || length(wind_speed_sel) == 2)
    colors(:,:,1) = ["#a8ddb5"; "#43a2ca"];
    colors(:,:,2) = ["#fdbb84"; "#e34a33"];
elseif (length(wing_freq_sel) == 1 || length(wind_speed_sel) == 1)
    colors(:,:,1) = ["#43a2ca"];
    colors(:,:,2) = ["#e34a33"];
end
% colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250];...
%     [0.4940 0.1840 0.5560]; [0.4660 0.6740 0.1880]; [0.3010 0.7450 0.9330];...
%     [1 0 0]; [0 1 0]; [0 0 1];...
%     [0 1 1]; [1 0 1]; [1 1 0];...
%     [0 0 0]; [1 1 1]];

markers = ["o", "pentagram", "x"];

figure
hold on
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    model = plot(AoA_sel, C_D_vals(:, j, m));
    model.HandleVisibility = "off";
    % model.DisplayName = "Model: " + wing_freq_sel(j) + "Hz";
    model.Color = colors(j,:,m);
    model.LineStyle = "--";
    model.LineWidth = 2;
end
end

if (data_bool)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
    s = scatter(AoA_sel, avg_drag(:, j, m, n), 50, 'filled');
    s.DisplayName = names(j,m,n);
    s.MarkerFaceColor = colors(j,:,n);
    s.MarkerEdgeColor = colors(j,:,n);
end
end
end
end
legend(Location='best', FontSize=18, Interpreter='latex')
xlabel("Angle of Attack", FontSize=18, Interpreter='latex')
ylabel("Drag Coefficient", FontSize=18, Interpreter='latex')
if (data_bool)
title(["\bf{Drag}" "\bf{" + sub_title + "}"], FontSize=20, FontName='Times New Roman')
else
title(["\bf{Drag}" "\bf{Wind Speed: " + wind_speed_sel + " m/s}"], FontSize=20, FontName='Times New Roman')
end

figure
hold on
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    model = plot(AoA_sel, C_L_vals(:, j, m));
    model.HandleVisibility = "off";
    % model.DisplayName = "Model: " + wing_freq_sel(j) + "Hz";
    model.Color = colors(j,:,m);
    model.LineStyle = "--";
    model.LineWidth = 2;
end
end

if (data_bool)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
    s = scatter(AoA_sel, avg_lift(:, j, m, n), 50, 'filled');
    s.DisplayName = names(j,m,n);
    s.MarkerFaceColor = colors(j,:,n);
    s.MarkerEdgeColor = colors(j,:,n);
end
end
end
end
legend(Location='best', FontSize=18, Interpreter='latex')
xlabel("Angle of Attack", FontSize=18, Interpreter='latex')
ylabel("Lift Coefficient", FontSize=18, Interpreter='latex')
if (data_bool)
title(["\bf{Lift}" "\bf{" + sub_title + "}"], FontSize=20, FontName='Times New Roman')
else
title(["\bf{Lift}" "\bf{Wind Speed: " + wind_speed_sel + " m/s}"], FontSize=20, FontName='Times New Roman')
end

figure
hold on
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    model = plot(AoA_sel, C_M_vals(:, j, m));
    model.HandleVisibility = "off";
    % model.DisplayName = "Model: " + wing_freq_sel(j) + "Hz";
    model.Color = colors(j,:,n);
    model.LineStyle = "--";
    model.LineWidth = 2;
end
end

if (data_bool)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
    s = scatter(AoA_sel, avg_pitch_moment(:, j, m, n), 50, 'filled');
    s.DisplayName = names(j,m,n);
    s.MarkerFaceColor = colors(j,:,n);
    s.MarkerEdgeColor = colors(j,:,n);
end
end
end
end
legend(Location='best', FontSize=18, Interpreter='latex')
xlabel("Angle of Attack", FontSize=18, Interpreter='latex')
ylabel("Pitching Moment Coefficient", FontSize=18, Interpreter='latex')
if (data_bool)
title(["\bf{Pitch Moment}" "\bf{" + sub_title + "}"], FontSize=20, FontName='Times New Roman')
else
title(["\bf{Pitch Moment}" "\bf{Wind Speed: " + wind_speed_sel + " m/s}"], FontSize=20, FontName='Times New Roman')
end

figure
legend
hold on
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    if (thinAirfoil)
        COP_model_chord = -(C_M_vals(:, j, m) ./ C_N_vals(:, j, m)) * 100;
    else
        COP_model(:, j, m) = (C_M_vals(:, j, m) ./ C_N_vals(:, j, m)) * chord;
        [COP_model_LE, COP_model_chord] = posToChord(COP_model);
    end
    
    model = scatter(AoA_sel, COP_model_chord, 50, 'filled');
    model.HandleVisibility = "off";
    % model.DisplayName = "Model: " + wing_freq_sel(j) + "Hz";
    model.MarkerFaceColor = colors(j,:,n);
    model.MarkerEdgeColor = colors(j,:,n);
    model.Marker = markers(1);
end
end

if (data_bool)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
    s = scatter(AoA_sel, COP_chord(:, j, m, n), 50, 'filled');
    s.DisplayName = names(j,m,n);
    s.MarkerFaceColor = colors(j,:,n);
    s.MarkerEdgeColor = colors(j,:,n);
    s.Marker = markers(2);
end
end
end
end
xlabel("Angle of Attack", FontSize=18, Interpreter='latex')
ylabel("Chordwise Location (\% chord)", FontSize=18, Interpreter='latex')
if (data_bool)
title(["\bf{Center of Pressure}" "\bf{" + sub_title + "}"], FontSize=20, FontName='Times New Roman')
else
title(["\bf{Center of Pressure}" "\bf{Wind Speed: " + wind_speed_sel + " m/s}"], FontSize=20, FontName='Times New Roman')
end