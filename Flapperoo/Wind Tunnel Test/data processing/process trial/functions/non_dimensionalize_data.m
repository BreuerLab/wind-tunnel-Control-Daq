% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% results - (n x 6) raw force transducer data
% file_name - raw data file name

% Returns:
% norm_data - (n x 6) non-dimensionalized force transducer data
% St - Strouhal number for this trial
% Re - Reynolds number for this trial
function [norm_data, norm_factors, St, Re] = non_dimensionalize_data(results, file_name)
    [case_name, type, wing_freq, AoA, U] = parse_filename(file_name);
    
    % Constant values based on geometry of wings and robot design
    wing_span = 0.25; % meters, length of single wing
    wing_chord = 0.10; % meters
    wing_length = 0.31; % meters, distance from wingtip to axis of rotation
    angle_up = 30; % degrees
    angle_down = 30; % degrees
    
    total_area = wing_span * wing_chord * 2; % m^2
    amplitude = wing_length * (sind(angle_up) + sind(angle_down));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke
    
    % Grab data recorded for wind tunnel air properties
    path = "../../raw data/wind tunnel data/";
    file_name = strrep(file_name,"experiment","wind_tunnel");
    file_name = strrep(file_name,"csv","mat");
        
    [wind_speed, density, Re] = get_tunnel_file_contents(path, file_name, wing_chord);
    
    St = (wing_freq * amplitude) / wind_speed;
    
    % Calculate normalization factors
    if (wind_speed == 0)
        norm_F_factor = (0.5 * density * total_area * (((amplitude*2)*wing_freq))^2);
    else
        norm_F_factor = (0.5 * density * total_area * wind_speed^2);
    end
    norm_M_factor = norm_F_factor * wing_chord;

    % Normalize/Non-dimensionalize data
    norm_F = results(1:3,:) / norm_F_factor;
    norm_M = results(4:6,:) / norm_M_factor;
    norm_data = [norm_F; norm_M];
    norm_factors = [norm_F_factor; norm_M_factor];
end