% This kinematic data for the wing motion is calculated from the
% Solidworks model. Since some pieces of the robot were manufactured
% by hand they may vary slightly from the dimensions estimated in
% Solidworks. Therefore this kinematic information should be viewed
% with a grain of salt as it may not exactly describe the true
% kinematics.
function [time_cycle, lin_vel_cycle] = get_kinematics(plots_on)

[time_disp, displacement] = readvars("../kinematics/angular_displacement_flapperoo.csv");
[time_vel, velocity] = readvars("../kinematics/angular_velocity_flapperoo.csv");

% Make sure data starts at beginning of upstroke
i = 1;
while (displacement(i) ~= min(displacement))
    i = i + 1;
end
time_disp = time_disp(i:end) - time_disp(i);
displacement = displacement(i:end);
time_vel = time_vel(i:end) - time_vel(i);
velocity = velocity(i:end);

% get data from a single cycle
j = 1;
while (time_vel(j) <= time_vel(1) + 1)
    j = j + 1;
end
time_cycle = time_vel(1:j);
ang_vel_cycle = velocity(1:j);

% flip second portion of ang vel data which should be negative
k = 1;
num_steps = length(ang_vel_cycle);
while (ang_vel_cycle(k) ~= min(ang_vel_cycle(num_steps*(1/4):num_steps*(3/4))))
    k = k + 1;
end
for m = k:num_steps
    ang_vel_cycle(m) = - ang_vel_cycle(m);
end


% get linear velocity for a single wingbeat cycle
wing_length = 0.266; % meters
r = 0:0.001:wing_length;
lin_vel_cycle = deg2rad(ang_vel_cycle) * r;

if (plots_on)

% Just angular displacement
fig = figure;
fig.Position = [200 50 900 560];
plot(time_disp, displacement, DisplayName="Angular Displacement (deg)")
xlabel("Time (s)")
ylabel("Angular Displacement (deg)")
title("Angular Displacement of Wings Flapping at 1 Hz")

% Just angular velocity
fig = figure;
fig.Position = [200 50 900 560];
plot(time_vel, velocity)
xlabel("Time (s)")
ylabel("Angular Velocity (deg/s)")
title("Angular Velocity of Wings Flapping at 1 Hz")

% Both displacement and velocity
fig = figure;
fig.Position = [200 50 900 560];
hold on
yyaxis left
plot(time_disp, displacement, DisplayName="Angular Displacement (deg)")
yyaxis right
plot(time_vel, velocity, DisplayName="Angular Velocity (deg/s)")
hold off
xlabel("Time (s)")
ylabel("Angular Displacement/Velocity")
title("Angular Motion of Wings Flapping at 1 Hz")
legend(Location="northeast")

% Linear velocity
fig = figure;
fig.Position = [200 50 900 560];
hold on
plot(time_cycle, lin_vel_cycle(:,51), DisplayName="r = 0.05")
plot(time_cycle, lin_vel_cycle(:,151), DisplayName="r = 0.15")
plot(time_cycle, lin_vel_cycle(:,251), DisplayName="r = 0.25")
hold off
xlabel("Time (s)")
ylabel("Linear Velocity (m/s)")
title("Linear Velocity of Wings Flapping at 1 Hz")
legend(Location="northeast")
end
end