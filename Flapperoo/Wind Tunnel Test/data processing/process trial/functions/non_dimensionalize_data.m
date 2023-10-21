% Inputs: results - (n x 7) force transducer data in time
% Returns: norm_data - (n x 7) same data but
%                                non-dimensionalized
function [norm_data, St, Re] = non_dimensionalize_data(results, case_name, wing_freq, U)
    % Constant values based on geometry of wings
    wing_span = 0.266; % m
    wing_chord = 0.088; % m
    total_area = wing_span * wing_chord * 2; % m^2, roughly
    
    % Values obtained from wind tunnel measurements
    path = "../wind tunnel data/";
    file_name = strrep(case_name,' ','_');
    file_ending = "_wind_tunnel_101223.mat";
    load(path + file_name + file_ending);
    
    wing_length = 0.257; % meters
    angle_up = 32; % degrees
    angle_down = 30; % degrees
    amplitude = wing_length * (sind(angle_up) + sind(angle_down));
    
    wind_speed = AFAM_Tunnel.Speed;
    density = AFAM_Tunnel.Density;
    Re = AFAM_Tunnel.Reynolds * wing_length;
    
    if (isnan(wind_speed) || isnan(density) || isnan(Re))
        disp("Using default values for air speed, density, and viscosity for case:")
        disp(case_name)
        density = 1.204; % kg/m^3 at 20 C 1 atm
        kin_vis = 1.6 * 10^(-5); % m^2/s
        wind_speed = U;
        Re = (wind_speed * wing_length) / kin_vis;
    end
    St = (wing_freq * amplitude) / wind_speed;
    
    % should vel be 60 deg times wing_freq instead of 2pi?
    norm_F_factor = (0.5 * density * total_area * (wind_speed + ((amplitude*2)*wing_freq))^2);
    norm_M_factor = norm_F_factor * wing_chord;

    norm_F = results(:,1:3) / norm_F_factor;
    norm_M = results(:,4:6) / norm_M_factor;
    norm_data = [norm_F, norm_M];
end