% This kinematic data for the wing motion is calculated from the
% Solidworks model. Since some pieces of the robot were manufactured
% by hand they may vary slightly from the dimensions estimated in
% Solidworks. Therefore this kinematic information should be viewed
% with a grain of salt as it may not exactly describe the true
% kinematics.
function [time_cycle, lin_vel_cycle, lin_acc_cycle] = get_kinematics(freq)

wing_length = 0.25; % meters
arm_length = 0.016;
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;

if (freq == 0)
time_cycle = zeros(2,1);
lin_vel_cycle = zeros(2,length(r));
lin_acc_cycle = zeros(2,length(r));
else
disp_data = readtable("../kinematics/ang_disp_flapperoo.xlsx","NumHeaderLines",2);
vel_data = readtable("../kinematics/ang_vel_flapperoo.xlsx","NumHeaderLines",2);
acc_data = readtable("../kinematics/ang_acc_flapperoo.xlsx","NumHeaderLines",2);

time_disp = disp_data.Time / freq;
displacement = disp_data.Displacement;
time_vel = vel_data.Time / freq;
velocity = vel_data.Velocity * freq;
time_acc = acc_data.Time / freq;
acc = acc_data.Acceleration * freq^2;

% Make sure data starts at beginning of downstroke
% Find first instance of a maximum
[pks,locs] = findpeaks(displacement);
i = locs(1);

time_disp = time_disp(i:end) - time_disp(i);
displacement = displacement(i:end);
time_vel = time_vel(i:end) - time_vel(i);
velocity = velocity(i:end);
time_acc = time_acc(i:end) - time_acc(i);
acc = acc(i:end);

% one cycle lasts (1/freq) seconds
j = 1;
while (time_vel(j) <= time_vel(1) + 1/freq)
    j = j + 1;
end
time_cycle = time_vel(1:j);
ang_disp_cycle = displacement(1:j);
ang_vel_cycle = velocity(1:j);
ang_acc_cycle = acc(1:j);

% flip first portion of ang vel data which should be negative
% k = 1;
% num_steps = length(ang_vel_cycle);
% [pks,locs] = findpeaks(-ang_vel_cycle);
% i = locs(1);
% ang_vel_cycle(1:i) = -ang_vel_cycle(1:i);

% while (ang_vel_cycle(k) ~= min(ang_vel_cycle(num_steps*(1/4):num_steps*(3/4))))
%     k = k + 1;
% end
% for m = k:num_steps
%     ang_vel_cycle(m) = - ang_vel_cycle(m);
% end


% get linear velocity for a single wingbeat cycle
lin_vel_cycle = deg2rad(ang_vel_cycle) * r;
lin_acc_cycle = deg2rad(ang_acc_cycle) * r;

end
end