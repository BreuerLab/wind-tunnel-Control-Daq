function wing_freq = stToFreq(flapper, St, wind_speed, freqs)
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

    amplitude = wing_length * (sind(angle_up) + sind(angle_down));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    wing_freq = (St * wind_speed) / amplitude;
    [M, I] = min(abs(wing_freq - freqs)); % find closest match
    wing_freq = freqs(I);
end