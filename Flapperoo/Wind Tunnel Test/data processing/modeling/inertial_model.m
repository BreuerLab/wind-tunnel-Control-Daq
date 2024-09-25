clear
close all

freq = 4;

[time, ang_disp, ang_vel, ang_acc] = get_kinematics(freq, true);

wing_length = 0.25; % meters
arm_length = 0.016;
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
COM_span = 0.15; % meters

[inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span);

% Inertial Force
fig = figure;
fig.Position = [200 50 900 560];
hold on
plot(time, inertial_force, DisplayName="r = " + COM_span + " m")
xlim([0 max(time)])
plot_wingbeat_patch();
hold off
xlabel("Time (s)")
ylabel("Inertial Force (N)")
title("Inertial Force of Wings Flapping at " + freq + " Hz")
legend(Location="northeast")