function file_name = findInitialOffsetsFile(path, case_name)
    % Grab data recorded for wind tunnel air properties
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.mat');
    theFiles = dir(filePattern);
    parts = split(case_name);
    case_name = strjoin(parts(1:end-1), " ");
    
    % Grab each file and process the data from that file, storing the results
    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        [case_name_cur, ~, ~, ~, ~] = parse_filename(baseFileName);
        parts = split(case_name_cur);
        case_name_cur = strjoin(parts(1:end-1), " ");
        if strcmp(case_name, case_name_cur)
            if ~(contains(baseFileName, "before") || contains(baseFileName, "after") || contains(baseFileName, "final"))
                file_name = convertCharsToStrings(baseFileName);
                break
            end
        end
    end
end