% This kinematic data for the wing motion is calculated from the
% Solidworks model. Since some pieces of the robot were manufactured
% by hand they may vary slightly from the dimensions estimated in
% Solidworks. Therefore this kinematic information should be viewed
% with a grain of salt as it may not exactly describe the true
% kinematics.
function [time_cycle, ang_disp_cycle, ang_vel_cycle, ang_acc_cycle] = get_kinematics(path, freq, amp)
if (freq == 0)
time_cycle = 0;
ang_disp_cycle = 0;
ang_vel_cycle = 0;
ang_acc_cycle = 0;
return
end

if (amp == -1)
disp_data = readtable(path + "/kinematics/ang_disp_flapperoo.xlsx","NumHeaderLines",2);
vel_data = readtable(path + "/kinematics/ang_vel_flapperoo.xlsx","NumHeaderLines",2);
acc_data = readtable(path + "/kinematics/ang_acc_flapperoo.xlsx","NumHeaderLines",2);

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
while (round(time_vel(j),3) < round(time_vel(1) + 1/freq,3))
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
else
    time_cycle = 0:0.01:1;
    time_cycle = time_cycle' / freq;

    ang_disp_cycle = amp.*cos(2*pi*freq.*time_cycle);
    ang_vel_cycle = -2*pi*freq*amp.*sin(2*pi*freq.*time_cycle);
    ang_acc_cycle = -4* pi^2 * freq^2 * amp .* cos(2*pi*freq.*time_cycle);

    ang_disp_cycle = rad2deg(ang_disp_cycle);
    ang_vel_cycle = rad2deg(ang_vel_cycle);
    ang_acc_cycle = rad2deg(ang_acc_cycle);
end
end