function file_name = findFileMatchingCase(path, case_name)
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
end