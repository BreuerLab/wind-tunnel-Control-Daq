% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% results - (n x 6) raw force transducer data
% file_name - raw data file name

% Returns:
% norm_data - (n x 6) non-dimensionalized force transducer data
% St - Strouhal number for this trial
% Re - Reynolds number for this trial

function [norm_data, norm_factors, St, Re] = non_dimensionalize_data(path, results, file_name, type)
    
% I don't want to use wing_type_from_name, I want type from eval_params.m
[case_name, time_stamp, wing_type_from_name, wing_freq, AoA, U, amp, file_type] = parse_filename(file_name);
    
    % angle_up = 21.3153; % degrees
    % angle_down = 21.3153; % degrees
    [angle_up, angle_down] = getRangeWingbeat(amp);
    
    % Constant values based on geometry of wings and robot design

switch lower(string(type))  % Case-insensitive, converts to string
    case {"default", "bodydefault"}
        wing_span = 0.177; % meters, length of single wing
        wing_chord = 0.073; % meters
        wing_length = 0.201; % meters, distance from wingtip to axis of rotation
    case {"chord_half", "bodychordhalf"}
        wing_span = 0.177;
        wing_chord = 0.0365;
        wing_length = 0.201;
    case {"span_half", "bodyspanhalf"}
        wing_span = 0.0885;
        wing_chord = 0.073;
        wing_length = 0.1125;
    case {"flexible","body"}
        wing_span = 0.12;
        wing_chord = 0.07;
        wing_length = wing_span + 0.024;
    otherwise
        warning('Oops, wing type "%s" not found', type);
        wing_span = 1;
        wing_chord = 1;
        wing_length = 10;
end

    % if (strcmp(type,"default") || strcmp(type,"bodyDefault")) 
    %     wing_span = 0.177; % meters, length of single wing
    %     wing_chord = 0.073; % meters
    %     wing_length = 0.201; % meters, distance from wingtip to axis of rotation
    % 
    % elseif (strcmp(type,"chord half") || strcmp(type,"bodyChordhalf"))
    %     wing_span = 0.177; % meters, length of single wing
    %     wing_chord = 0.0365; % meters
    %     wing_length = 0.201; % meters, distance from wingtip to axis of rotation
    % 
    % elseif (strcmp(type,"span half") || strcmp(type,"bodySpanhalf")) 
    %     wing_span = 0.0885; % meters, length of single wing
    %     wing_chord = 0.073; % meters
    %     wing_length = 0.1125; % meters, distance from wingtip to axis of rotation
    % 
    % else       
    %     error('Oops, wing type not found');  % throw error and stop execution
    % 
    % end

    % wing_freqs = [0, 2, 4, 6, 8, 10];
    % wing_freqs = [10, 4, 8, 0, 2, 6];
    wing_freqs = [0, 2, 3, 4];
    
    total_area = wing_span * wing_chord * 2; % m^2
    amplitude = wing_length * (abs(sind(angle_up)) + abs(sind(angle_down)));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke
    
    file_name = findFileMatchingCase(path, case_name);
    disp("Matched wind tunnel filename: ")
    disp(file_name)
        
    [wind_speed, density, Re] = get_tunnel_file_contents(path, file_name, wing_chord, wing_freqs);
    
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