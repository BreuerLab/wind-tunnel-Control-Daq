function [amp, type, freq] = parse_name(name)
    name_parts = split(name,"_");

    % Default values
    amp = -1; type = ""; freq = -1;

    for j = 1:length(name_parts)
        if contains(name_parts{j}, "deg")
            amp = str2double(extractBefore(name_parts{j}, "deg"));
            type = strjoin(string(name_parts(1:j-1)), "_");
        elseif contains(name_parts{j}, "Hz")
            freq = str2double(extractBefore(name_parts{j}, "Hz"));
        end
    end
end