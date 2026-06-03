function [wind_speed, density, Re] = get_tunnel_file_contents(path, file_name, wing_chord, wing_freqs)
    [case_name, time_stamp, type, wing_freq, AoA, U] = parse_filename(file_name);

    % If file wasn't saved or wind tunnel GUI glitched out when data was
    % recorded, use values from adjacent tests
    if (~isfile(path + file_name))
        [wind_speed, density, Re] = get_nearby_wind_tunnel_file(file_name, path, wing_freq, wing_freqs, wing_chord);

        sendSlack("File missing. Using nearby values for air speed, density, and viscosity for: " + case_name);
    else
        load(path + file_name); % loads AFAM_Tunnel struct into workspace

        wind_speed = AFAM_Tunnel.Speed;
        density = AFAM_Tunnel.Density;
        Re = AFAM_Tunnel.Reynolds * wing_chord;

        if (abs(wind_speed - U) > 0.2 && ~(U == 0))
            [wind_speed, density, Re] = get_nearby_wind_tunnel_file(file_name, path, wing_freq, wing_freqs, wing_chord);

            sendSlack("High Error Detected in Speed Reading for: " + case_name);
        end

        if(isnan(wind_speed) || isnan(density) || isnan(Re))
            [wind_speed, density, Re] = get_nearby_wind_tunnel_file(file_name, path, wing_freq, wing_freqs, wing_chord);

            disp(case_name)
            error("File corrupted. Using nearby values for air speed, density, and viscosity.")
        end
    end
end