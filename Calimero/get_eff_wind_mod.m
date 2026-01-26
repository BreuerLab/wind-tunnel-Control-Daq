% Get the effective wind speed and angle of attack for a flapping and
% pitching wing

% Inputs:
% time - (1 x n) vector of time values for a single cycle
% lin_vel - (n x m) matrix of linear velocity values along the wing where
%           the first index corresponds to time and then second corresponds
%           to spanwise position on the wing
% AoA - (1 x 1) scalar geometric angle of attack
% wind_speed - (1 x 1) scalar freestream wind speed

% Outputs:
% eff_AoA - (n x m) matrix of effective angle of attack values, first index
%           is time, second is spanwise position
% lin_vel - (n x m) matrix of effective wind speed values along the wing

% for a pitching wing, linear velocity is not only a function of spanwise
% position but also chordwise position, but how does a blade element model
% account for that?
function [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed)
    
    eff_AoA = zeros(size(lin_vel));
    u_rel = zeros(size(lin_vel)); % u_rel is opposite lin_vel

    v_x = -lin_vel .* sind(AoA);
    v_y = -lin_vel .* cosd(AoA);
    for i = 1:length(time)
        vec_mag = ((v_x(i,:) + wind_speed).^2 + v_y(i,:).^2).^(1/2);
        u_rel(i,:) = vec_mag;

        cross_prod = -((v_x(i,:) + wind_speed)*(-sind(AoA(i))) - v_y(i,:)*(cosd(AoA(i))));
        eff_AoA(i,:) = asind(cross_prod ./ vec_mag);
    %     dot_prod = (v_x(i,:) + wind_speed)*(cosd(AoA)) + v_y(i,:)*(-sind(AoA));
    %     eff_AoA(i,:) = acosd(dot_prod ./ vec_mag);
    end
end