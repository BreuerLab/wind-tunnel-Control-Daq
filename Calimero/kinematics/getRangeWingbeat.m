function [angle_up, angle_down] = getRangeWingbeat()
    numRevs = 1;
    numPts = 1000;
    d = 20; % mm
    r = 6.84; % 20 deg
    theta = linspace(0, numRevs*2*pi, numPts);
    ang_disp = -atand((r*sin(theta)) ./ (d + r*cos(theta)));
    % [time, ang_disp, ang_vel, ~] = get_kinematics(path, wing_freq, amp);
    angle_up = max(ang_disp);
    angle_down = min(ang_disp);
end