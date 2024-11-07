function St = freqToSt(flapper, wing_freq, wind_speed, path, amp)
    [~, ~, ~, wing_length, arm_length] = getWingMeasurements(flapper);
    
    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, wing_freq, amp);
    angle_up = max(ang_disp);
    angle_down = min(ang_disp);

    lever_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    amplitude = lever_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    St = (wing_freq * amplitude) / wind_speed;
    St = round(St,2,"significant");
end