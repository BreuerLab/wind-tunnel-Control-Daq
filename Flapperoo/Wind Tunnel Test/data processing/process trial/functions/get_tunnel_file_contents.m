function [wind_speed, density, Re] = get_tunnel_file_contents(path, file_name, wing_chord)
    [case_name, type, wing_freq, AoA, U] = parse_filename(file_name);

    wing_freqs = [0,2,3,4,5];
    cur_ind = find(wing_freqs == wing_freq);
    prev_file_name = "";
    after_file_name = "";

    % If file wasn't saved or wind tunnel GUI glitched out when data was
    % recorded, use values from adjacent tests
    if (~isfile(path + file_name))
        disp("File missing. Using nearby values for air speed, density, and viscosity for case:")
        disp(file_name)
        
        if (cur_ind > 1)
        prev_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind - 1) + "Hz");
        end

        if (cur_ind < 5)
        after_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind + 1) + "Hz");
        end

        if isfile(path + prev_file_name)
            disp("Using " + prev_file_name)
            [wind_speed, density, Re] = get_tunnel_file_contents(path, prev_file_name, wing_chord);
        elseif isfile(path + after_file_name)
            disp("Using " + after_file_name)
            [wind_speed, density, Re] = get_tunnel_file_contents(path, after_file_name, wing_chord);
        else
            error("Oops nearby files can't be found either.")
        end
    else
        load(path + file_name); % loads AFAM_Tunnel struct into workspace

        wind_speed = AFAM_Tunnel.Speed;
        density = AFAM_Tunnel.Density;
        Re = AFAM_Tunnel.Reynolds * wing_chord;

        if(isnan(wind_speed) || isnan(density) || isnan(Re))
            disp("File corrupted. Using nearby values for air speed, density, and viscosity for case:")
            disp(case_name)
            
            if (cur_ind > 1)
            prev_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind - 1) + "Hz");
            end

            if (cur_ind < 5)
            after_file_name = strrep(file_name, wing_freq + "Hz", wing_freqs(cur_ind + 1) + "Hz");
            end
            
            if isfile(path + prev_file_name)
                disp("Using " + prev_file_name)
                [wind_speed, density, Re] = get_tunnel_file_contents(path, prev_file_name, wing_chord);
            elseif isfile(path + after_file_name)
                disp("Using " + after_file_name)
                [wind_speed, density, Re] = get_tunnel_file_contents(path, after_file_name, wing_chord);
            else
                error("Oops nearby files are corrupted too.")
            end
        end
    end
end