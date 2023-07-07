function [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(filename)
    % Get case name from file name
    case_name = erase(filename, ["_experiment_061723.csv", "_experiment_061823.csv", '.mat']);
    case_name = strrep(case_name,'_',' ');
    
    case_parts = strtrim(split(case_name));
    wing_freq = -1;
    AoA = -1;
    wind_speed = -1;
    type = case_parts(1);
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