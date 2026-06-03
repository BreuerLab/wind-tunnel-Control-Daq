function attachFileListsToBird(path, cur_bird)
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(path, '*.mat');
    theFiles = dir(filePattern);
    
    % Grab each file and process the data from that file, storing the results
    for k = 1 : length(theFiles)
        baseFileName = convertCharsToStrings(theFiles(k).name);
        parsed_name = extractBefore(baseFileName, "_saved");

        [data_struct] = get_file_structure(path, baseFileName, parsed_name);
        cur_bird.file_list = [cur_bird.file_list data_struct];

        case_name = extractBefore(baseFileName, "._");

        % Add to list if not already on list
        if (isempty(cur_bird.uniq_list) || sum([cur_bird.uniq_list.dir_name] == case_name) == 0)
            [data_struct] = get_file_structure(path, baseFileName, case_name);
            data_struct.file_name = [];
            cur_bird.uniq_list = [cur_bird.uniq_list data_struct];
        end

        if (contains(parsed_name, "norm"))
            data_struct = get_file_structure(path, baseFileName, parsed_name);
            cur_bird.norm_list = [cur_bird.norm_list data_struct];
        end
        if (contains(parsed_name, "shift"))
            data_struct = get_file_structure(path, baseFileName, parsed_name);
            cur_bird.shift_list = [cur_bird.shift_list data_struct];
        end
        if (contains(parsed_name, "drift"))
            data_struct = get_file_structure(path, baseFileName, parsed_name);
            cur_bird.drift_list = [cur_bird.drift_list data_struct];
        end
    end

    % Fill any lists that may be empty with one empty struct
    data_struct.file_name = "";
    data_struct.dir_name = "";
    data_struct.trial_names = strings(0);

    if (isempty(cur_bird.norm_list))
        cur_bird.norm_list = [cur_bird.norm_list data_struct];
    end
    if (isempty(cur_bird.shift_list))
        cur_bird.shift_list = [cur_bird.shift_list data_struct];
    end
    if (isempty(cur_bird.drift_list))
        cur_bird.drift_list = [cur_bird.drift_list data_struct];
    end

    uniq_norm_list_str = setdiff(setdiff([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                [cur_bird.drift_list.file_name]);

    for j = 1:length(cur_bird.file_list)
        if (sum(uniq_norm_list_str == cur_bird.file_list(j).file_name) > 0)
            struct_match = cur_bird.file_list(j);
            struct_match.dir_name = extractBefore(struct_match.dir_name, "_norm");
            cur_bird.uniq_norm_list = [cur_bird.uniq_norm_list struct_match];
        end
    end
end