function St = freqToSt(flapper, wing_freq, wind_speed, path, amp)
    [~, ~, ~, wing_length, arm_length] = getWingMeasurements(flapper);
    
    [time, ang_disp, ang_vel, ~] = get_kinematics(path, wing_freq, amp);
    angle_up = max(ang_disp);
    angle_down = min(ang_disp);

    full_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    amplitude = full_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    St = (wing_freq * amplitude) / wind_speed;

    % St = (wing_freq * amp) / wind_speed;
    % St = 0.25*besselj(0,amp) + (St^2 / amp)*(0.600353*besselj(1,amp) + 0.0667059*besselj(1,3*amp));
    % 
    % if (wing_freq == 0)
    %     amp_temp = 0.001;
    %     St = (wing_freq * amp_temp) / wind_speed;
    %     St = 0.25*besselj(0,amp_temp) + (St^2 / amp_temp)*(0.600353*besselj(1,amp_temp) + 0.0667059*besselj(1,3*amp_temp));
    % end
end