% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% results - (n x 6) raw force transducer data
% file_name - raw data file name

% Returns:
% norm_data - (n x 6) non-dimensionalized force transducer data
% St - Strouhal number for this trial
% Re - Reynolds number for this trial
function [norm_data, norm_factors, St, Re] = non_dimensionalize_data(path, results, file_name)
    [case_name, time_stamp, type, wing_freq, AoA, U] = parse_filename(file_name);
    
    % Constant values based on geometry of wings and robot design
    wing_span = 0.25; % meters, length of single wing
    wing_chord = 0.10; % meters
    wing_length = 0.31; % meters, distance from wingtip to axis of rotation
    angle_up = 30; % degrees
    angle_down = 30; % degrees

    % wing_freqs = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 4.5, 5, 2, 4];
    wing_freqs = [3.5, 4, 3.75, 2, 3, 0, 0.1, 2.5, 4.5, 5, 2, 4];
    
    total_area = wing_span * wing_chord * 2; % m^2
    amplitude = wing_length * (sind(angle_up) + sind(angle_down));
    % m, vertical distance traversed by wings during a full stroke, a
    % single wingbeat consists of two strokes: upstroke & downstroke
    
    % Grab data recorded for wind tunnel air properties
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.mat');
    theFiles = dir(filePattern);
    
    % Grab each file and process the data from that file, storing the results
    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        [case_name_cur, ~, ~, ~, ~] = parse_filename(baseFileName);
        if strcmp(case_name,case_name_cur)
            file_name = convertCharsToStrings(baseFileName);
            break
        end
    end
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