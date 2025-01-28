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
    St = round(St,3,"significant");

    % Trying some like advance ratio
    % r = arm_length:0.001:full_length;
    % % lin_vel = deg2rad(ang_vel) * r;
    % lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;

    % % mean_w = max(abs(lin_vel),[],"all");
    % % mean_w = mean(abs(lin_vel),"all"); % mean positive wing velocity
    % mean_w = mean(abs(lin_vel(:,end)),"all"); % mean positive tip velocity
    % % amplitude = lever_length * deg2rad(abs(angle_down) + abs(angle_up));
    % St = (mean_w) / wind_speed;
    % % St = round(St,3,"significant");

    % [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, 0, wind_speed);
    % % mean_w = mean(abs(lin_vel),"all"); % mean positive wing velocity
    % % mean_w = mean(abs(u_rel(:,end)),"all"); % mean positive tip velocity
    % mean_w = max(abs(u_rel),[],"all"); % mean positive tip velocity
    % St = (mean_w) / wind_speed;
    % St = round(St,3,"significant");

end