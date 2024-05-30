% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% file_name - raw data file name or other versions of that same file name

% Returns:
% case_name - trial name containing the values of the variables for that
%             particular configuration
% type - name of the wing type used, ex: "mylar"
% AoA - angle of attack, ex: 10
function [case_name, type, AoA] = parse_filename_tare(filename)
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
    
    % Parse relevant trial information from case name 
    case_parts = strtrim(split(case_name));
    type="";
    AoA = -1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "deg"))
            AoA = str2double(erase(case_parts(j), "deg"));
            type = strjoin(case_parts(1:j-1)); % type is before AoA
        end
    end
end