function [wind_speed, density, Re] = get_nearby_wind_tunnel_file(file_name, path, wing_freq, wing_freqs, wing_chord)

    cur_ind = find(wing_freqs == wing_freq);
    if (length(cur_ind) > 1)
        cur_ind = cur_ind(1);
    end
    prev_file_name = "";
    after_file_name = "";

    if (cur_ind > 1)
        prev_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind - 1) + "Hz");
        file_parts = split(prev_file_name);
        prev_file_name = file_parts(1);
    end
    
    if (cur_ind < (length(wing_freqs) - 1))
        after_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind + 1) + "Hz");
        file_parts = split(after_file_name);
        after_file_name = file_parts(1);
    end
    
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.mat'); % Change to whatever pattern you need.
    tunnel_files = dir(filePattern);
    
    % Grab each file and process the data from that file, storing the results
    k = 1;
    found_file = false;
    while(k < length(tunnel_files) && ~found_file)
        baseFileName = convertCharsToStrings(tunnel_files(k).name);
        file_parts = split(baseFileName);
        shortedName = file_parts(1);
    
        if (shortedName == prev_file_name)
            disp("Using " + baseFileName)
            [wind_speed, density, Re] = get_tunnel_file_contents(path, baseFileName, wing_chord, wing_freqs);
            found_file = true;
        elseif (shortedName == after_file_name)
            disp("Using " + baseFileName)
            [wind_speed, density, Re] = get_tunnel_file_contents(path, baseFileName, wing_chord, wing_freqs);
            found_file = true;
        end
        k = k + 1;
    end

    if (~found_file)
        error("Oops nearby files can't be found either.")
    end

end