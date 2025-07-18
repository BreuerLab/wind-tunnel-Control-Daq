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
    
    % R = 0.313;
    % St = (2 * R * wing_freq * amp) / wind_speed;

    % Reduced form of flapping number
    % R = 0.313;
    % St = (2 * R * wing_freq * amp) / wind_speed;
    % St = 0.932627 + 3.94692*St^2;

    % Generalized form
    % l = 0.25;
    % R = 0.313;
    % St = (2 * R * wing_freq * amp) / wind_speed;
    % St = besselj(0, amp) + (2/3) * pi^2 * (St.^2 ./ (amp*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, amp));
    % 
    % if (wing_freq == 0)
    %     amp_temp = 0.001;
    %     St = (2 * R * wing_freq * amp_temp) / wind_speed;
    %     St = besselj(0, amp_temp) + (2/3) * pi^2 * (St.^2 ./ (amp_temp*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, amp_temp));
    % end
    % really this is the Flapping number not Strouhal
end


% FORMS BACK WHEN V = OMEGA * R * COS(THETA)
% Prior to July 2025

% Form specific to my robot setup (l and R built into coefficients)
% St = (wing_freq * amp) / wind_speed;
% St = 0.25*besselj(0,amp) + (St^2 / amp)*(0.600353*besselj(1,amp) + 0.0667059*besselj(1,3*amp));
% 
% if (wing_freq == 0)
%     amp_temp = 0.001;
%     St = (wing_freq * amp_temp) / wind_speed;
%     St = 0.25*besselj(0,amp_temp) + (St^2 / amp_temp)*(0.600353*besselj(1,amp_temp) + 0.0667059*besselj(1,3*amp_temp));
% end

% Reduced form of flapping number
% R = 0.313;
% St = (2 * R * wing_freq * amp) / wind_speed;
% St = besselj(0, amp) * (1 + (3*St.^2));
% 
% if (wing_freq == 0)
%     amp_temp = 0.001;
%     St = (2 * R * wing_freq * amp_temp) / wind_speed;
%     St = besselj(0, amp_temp) * (1 + (3*St.^2));
% end

% Generalized form
% l = 0.25;
% R = 0.313;
% St = (2 * R * wing_freq * amp) / wind_speed;
% St = besselj(0, amp) + (pi^2 / 18) * (St.^2 ./ (amp*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (9*besselj(1, amp) + besselj(1, 3*amp));
% 
% if (wing_freq == 0)
%     amp_temp = 0.001;
%     St = (2 * R * wing_freq * amp_temp) / wind_speed;
%     St = besselj(0, amp_temp) + (pi^2 / 18) * (St.^2 ./ (amp_temp*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (9*besselj(1, amp_temp) + besselj(1, 3*amp_temp));
% end
% really this is the Flapping number not Strouhal