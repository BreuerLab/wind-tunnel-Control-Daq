function St = freqToSt(flapper, wing_freq, wind_speed)
    [~, ~, ~, wing_length, arm_length] = getWingMeasurements(flapper);
    
    if (flapper == "Flapperoo")
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    elseif (flapper == "MetaBird")
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    else
        error("Oops. Unknown flapper")
    end

    lever_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    amplitude = lever_length * (sind(angle_up) + sind(angle_down));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    St = (wing_freq * amplitude) / wind_speed;
    St = round(St,2,"significant");
end