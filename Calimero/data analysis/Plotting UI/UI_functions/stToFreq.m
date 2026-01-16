function wing_freq = stToFreq(flapper, St, wind_speed, freqs, amp)
    [~, ~, ~, wing_length, arm_length] = getWingMeasurements(flapper);
    
    if (flapper == "Flapperoo")
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    elseif (flapper == "MetaBird")
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    elseif (flapper == "Calimero")
        [angle_up, angle_down] = getRangeWingbeat(amp);
    else
        error("Oops. Unknown flapper")
    end

    % full_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    % USE FULL LENGTH INSTEAD
    amplitude = wing_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    wing_freq = (St * wind_speed) / amplitude;
    [M, I] = min(abs(wing_freq - freqs)); % find closest match
    wing_freq = freqs(I);
end