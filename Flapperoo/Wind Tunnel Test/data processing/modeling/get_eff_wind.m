function [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed)
    
    % wind_speed = 100;
    % time = time / wing_freq;
    eff_AoA = zeros(size(lin_vel));
    u_rel = zeros(size(lin_vel)); % u_rel is opposite lin_vel

    v_x = -lin_vel * sind(AoA);
    v_y = -lin_vel * cosd(AoA);
    for i = 1:length(time)
        vec_mag = ((v_x(i,:) + wind_speed).^2 + v_y(i,:).^2).^(1/2);
        u_rel(i,:) = vec_mag;

        cross_prod = -((v_x(i,:) + wind_speed)*(-sind(AoA)) - v_y(i,:)*(cosd(AoA)));
        eff_AoA(i,:) = asind(cross_prod ./ vec_mag);
    %     dot_prod = (v_x(i,:) + wind_speed)*(cosd(AoA)) + v_y(i,:)*(-sind(AoA));
    %     eff_AoA(i,:) = acosd(dot_prod ./ vec_mag);
    end

    

    % Relative AoA

    % for i = 1:length(time)
    %     if (lin_vel(i,5) < 0) % downstroke
    %         mid_angle = 90 + AoA; % angle between freestream and wing vel
    %     else % downstroke 
    %         mid_angle = 90 - AoA; % angle between freestream and wing vel
    %     end
    % 
    % %     if (wind_speed == 0)
    % %         u_rel(i,:) = -lin_vel(i,:);
    % %     else
    %         u_rel(i,:) = (wind_speed^2 + lin_vel(i,:).^2 - 2*wind_speed*abs(lin_vel(i,:))*cosd(mid_angle)).^(1/2); % Law of Cosines
    %     end
    % %     if (lin_vel(i,5) > 0)
    % %         u_rel(i,:) = -u_rel(i,:);
    % %     end
    % %     U_angle = asind(lin_vel(i,:) .* (sind(mid_angle) ./ u_rel(i,:))); % Law of Sines
    % %     eff_AoA(i,:) = AoA - U_angle;
    % %     if (lin_vel(i,5) < 0) % downstroke 
    % %         eff_AoA(i,:) = -eff_AoA(i,:);
    % %     end
    % end

    % case_name = "100m.s 14deg 5Hz";
end

