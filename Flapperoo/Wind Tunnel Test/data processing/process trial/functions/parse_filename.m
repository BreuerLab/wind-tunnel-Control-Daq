function [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(filename)
    % Get case name from file name
    if (contains(filename,"_experiment"))
        case_name = extractBefore(filename,"_experiment");
    elseif (contains(filename,"_before_offsets"))
        case_name = extractBefore(filename,"_before_offsets");
    elseif (contains(filename,"_after_offsets"))
        case_name = extractBefore(filename,"_after_offsets");
    elseif (contains(filename,".mat"))
        case_name = extractBefore(filename,".mat");
    else
        case_name = filename;
    end
    
    case_name = strrep(case_name,'_',' ');
    
    case_parts = strtrim(split(case_name));
    type="";
    wing_freq = -1;
    AoA = -1;
    wind_speed = -1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            wing_freq = str2double(erase(case_parts(j), "Hz"));
        elseif (contains(case_parts(j), "deg"))
            AoA = str2double(erase(case_parts(j), "deg"));
        elseif (contains(case_parts(j), "m.s"))
            wind_speed = str2double(erase(case_parts(j), "m.s"));
            type = strjoin(case_parts(1:j-1)); % speed is first thing after type
        end
    end
end