function [angle_up, angle_down] = getRangeWingbeat(amp)
    numRevs = 1;
    numPts = 1000;
    d = 20; % mm
    if amp == 10
        r = 3.47; % 10 deg
    elseif amp == 20
        r = 6.84; % 20 deg
    elseif amp == 30
        r = 10; % 30 deg
    else
        error("Amp is not 10 or 20")
    end
    theta = linspace(0, numRevs*2*pi, numPts);
    ang_disp = -atand((r*sin(theta)) ./ (d + r*cos(theta)));
    % [time, ang_disp, ang_vel, ~] = get_kinematics(path, wing_freq, amp);
    angle_up = abs(max(ang_disp));
    angle_down = abs(min(ang_disp));
end