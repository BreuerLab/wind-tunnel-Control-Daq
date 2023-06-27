function [case_name, wing_freq, AoA, wind_speed] = parse_filename(filename)
    % Get case name from file name
    case_name = erase(filename, ["_experiment_061723.csv", "_experiment_061823.csv"]);
    case_name = strrep(case_name,'_',' ');
    
    case_parts = strtrim(split(case_name));
    wing_freq = -1;
    AoA = -1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            wing_freq = str2double(erase(case_parts(j), "Hz"));
        elseif (contains(case_parts(j), "deg"))
            AoA = str2double(erase(case_parts(j), "deg"));
        elseif (contains(case_parts(j), "m.s"))
            wind_speed = str2double(erase(case_parts(j), "m.s"));
        end
    end
end