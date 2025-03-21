function St = freqToSt(flapper, wing_freq, wind_speed, path, amp)
    [~, ~, ~, wing_length, arm_length] = getWingMeasurements(flapper);
    
    [time, ang_disp, ang_vel, ~] = get_kinematics(path, wing_freq, amp);
    angle_up = max(ang_disp);
    angle_down = min(ang_disp);

    full_length = wing_length + arm_length; % meters, distance from wingtip to axis of rotation
    amplitude = 2 * full_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke

    % temporary test for amp scaling
    len = mean(cosd(ang_disp));
    % tried multiplying by this, dividing, multiplying by amp*len
    % dividing seemed pretty good but that doesn't make sense
    % tried defining len with sum instead of mean
    % tried amp*len
    % What are all the length scales:
    % - vertical amplitude
    % - average span
    % - arc length traveled by tip

    amp_ang = deg2rad(abs(angle_up) + abs(angle_down)) / 2;
    %  cos(0.69*amp) 
    % 0.64*cos(0.55*amp)
    % 0.43*cos(0.43*amp)
    % * (0.64*cos(0.55*amp) + 0.43*cos(0.43*amp))
    % St = ((wing_freq * amp) / wind_speed)^2 * 0.43*cos(0.43*amp) + 0.64*cos(0.55*amp);
    % St = 4*pi^2*((wing_freq * amp) / wind_speed)^2.2 * (0.43 / 25.3)*cos(0.43*amp) + ((wing_freq * amp) / wind_speed)^0.2 * 0.64*cos(0.55*amp);
    % St = 4*pi^2*((wing_freq * amp) / wind_speed)^1.8 * (0.43 / 25.3)*cos(0.43*amp) + ((wing_freq * amp) / wind_speed)^(0.1) * 0.64*cos(0.55*amp);
    % St = ((wing_freq * amp) / wind_speed)^2.2 * cos(0.43*amp);
    % St = ((wing_freq * amp_ang) / wind_speed) * besselj(0,amp_ang);
    % St = ((wing_freq * amp) / wind_speed)^2 * besselj(0,amp) / amp;
    % ----------------------------------------
    % St = ((wing_freq * amp) / wind_speed)^2;
    % St = (1.5708*besselj(0,amp) + (St/amp)*(3.77213*besselj(1,amp) + 0.419126*besselj(1,3*amp)));

    St = (wing_freq * amp) / wind_speed;
    % 03/21 -------------
    % St = wing_freq*(1.5708*besselj(0,amp) + 1.04781*(St^2 / amp)*(9*besselj(1,amp) + besselj(1,3*amp)));
    % St = 0.25*besselj(0,amp) + (St^2 / amp)*(1.50088*besselj(1,amp) + 0.166765*besselj(1,3*amp));
    St = 0.25*besselj(0,amp) + (St^2 / amp)*(0.600353*besselj(1,amp) + 0.0667059*besselj(1,3*amp));
    % St expansion, solution doesn't change from 2 terms to 4 terms
    % Expression for wing_freq = 0 fails. Since we expand about St = 0,
    % we'd expect to be able to handle the case where f = 0 perfectly well.
    % When A is also made to a very small number at f = 0, then it works
    % fine. 

    if (wing_freq == 0)
        amp_temp = 0.1;
        St = (wing_freq * amp_temp) / wind_speed;
        St = 0.25*besselj(0,amp_temp) + (St^2 / amp_temp)*(0.600353*besselj(1,amp_temp) + 0.0667059*besselj(1,3*amp_temp));
    end
    % St = 0.25 - 0.0625*amp^2 + 0.400235*St^2; % A expansion, 2 terms
    % St = 0.25 + 0.00390625*amp^4 + 0.400235*St^2 - 0.234028*St^4 + amp^2*(-0.0625 - 0.150088*St^2); % A expansion, 4 terms
    % -----------

    % St = wing_freq*((-1.5708 - 12.5738*St^2)*besselj(0, amp) + St*((12.5738*wing_freq*besselj(1, amp))/wind_speed...
    %     - 12.5738*St*besselj(2, amp)));
    % St = wing_freq*(1.5708*besselj(0, amp) + (1.04781*amp*(wing_freq^2)*(9*besselj(1, amp) + besselj(1, 3*amp)))/wind_speed^2);
    % St = wing_freq*(1.5708*besselj(0,amp) +...
    %     1.46694*(((wing_freq * amp) / wind_speed)^2 / amp)*(9*besselj(1,amp) + besselj(1,3*amp)) +...
    %     (51.4654*(((wing_freq * amp) / wind_speed)^4 / amp^2 )* (besselj(2, amp) ...
    %     + 0.0555556*besselj(2, 3*amp) + 0.004*besselj(2, 5*amp))));
    % St = (wing_freq * amp) / wind_speed;
    % St = wing_freq*((-1.5708 - 17.6033*St^2)*besselj(0, amp) + (St^2 *((17.6033 + 17.6033*amp^2)*besselj(1, amp) -...
    % 70.4131*amp*besselj(2, amp)))/amp);
    % St = ((wing_freq * amp) / wind_speed)^2;
    % St = wing_freq*(1.5708*besselj(0,amp) + 1.46694*(St/amp)*(9*besselj(1,amp) + besselj(1,3*amp)));
    % ----------------------------------------
    % St = ((wing_freq * amp) / wind_speed)^2;
    % St = 1.5708*besselj(0,amp) + (2.51475*St*besselj(1,amp)) / amp;
    % St = 1.5708*besselj(0,amp) + (2.51475*St*besselj(1,amp)) / amp ...
    %     + 4*pi*St*(-0.100059 + 0.0125074*amp^2 + 0.0750442*besselj(0,2*amp) +...
    %     ((-0.175103 + 0.0500294*amp^2)*besselj(1,2*amp)) / amp);
    % ******************************************
    % St = ((wing_freq * amp_ang) / wind_speed);
    % ******************************************
    % St = wing_freq*sin(57.32*amp_ang - 5.461);
    % St = round(St,3,"significant");

    % reduced freq: (wing_freq * 0.1) / wind_speed;
    % advance ratio: wind_speed / (2 * deg2rad(angle_up + angle_down) * wing_freq * full_length);
    % St = wind_speed / (2 * deg2rad(angle_up + angle_down) * wing_freq * full_length);
    % St = round(St,3,"significant");

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
    % mean_w = max(abs(lin_vel),[],"all"); % max positive tip effective velocity
    % mean_w = mean(abs(u_rel(:,end)),"all"); % mean positive tip effective velocity
    % mean_w = max(abs(u_rel),[],"all"); % max positive tip effective velocity
    % St = (mean_w) / wind_speed;
    % St = round(St,3,"significant");

end