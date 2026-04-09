function St = freqToSt(wing_freq, wind_speed, amp)
    wing_length = 0.216; % meters, distance from wingtip to axis of rotation
    arm_length = 0.063;
    full_length = wing_length + arm_length;
    
    [angle_up, angle_down] = getRangeWingbeat(amp);

    % full_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    amplitude = full_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    St = (wing_freq * amplitude) / wind_speed;
end