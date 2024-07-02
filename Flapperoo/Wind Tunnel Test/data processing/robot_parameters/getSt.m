function St = getSt(wind_speed, wing_freq)
    % Constant values based on geometry of wings and robot design
    wing_span = 0.25; % meters, length of single wing
    wing_length = 0.31; % meters, distance from wingtip to axis of rotation
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    
    amplitude = wing_length * (sind(angle_up) + sind(angle_down));

    St = (wing_freq * amplitude) ./ wind_speed;
end

