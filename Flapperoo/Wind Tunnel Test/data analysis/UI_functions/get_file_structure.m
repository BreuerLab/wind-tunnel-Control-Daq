function data_struct = get_file_structure(path, baseFileName, parsed_name)
    load(path + baseFileName, "names");
    data_struct.file_name = baseFileName;
    data_struct.dir_name = parsed_name;

    for j = 1:length(names)
    % distinguish repeat trials with unique name
    if(sum(names == names(j)) > 1)
        ind = find(names == names(j), 1, 'last');
        names(ind) = names(ind) + " v2";
    end
    end

    data_struct.trial_names = names;
end