function force = get_force(path, type, amp, freq, idx)
    parentDir = path + type + "_" + amp + "deg" + "\4 m.s\";
    
    contents = dir(parentDir);
    
    % Remove the '.' and '..' (which are always present in file systems)
    % and filter for actual folders
    contents = contents([contents.isdir] & ~ismember({contents.name}, {'.', '..'}));
    
    % Since there is only one folder, we grab the first (and only) name
    dynamicFolderName = contents(1).name;
    
    force_path = parentDir + dynamicFolderName + "\processed data\";
    
    contents = dir(force_path);
    force_files = contents(~[contents.isdir]);

    for j = 1:length(force_files)
        cur_name = force_files(j).name;
         % 10 deg AoA case and matching frequency
        if contains(cur_name, "10deg") && contains(cur_name, freq + "Hz")
            force_filename = cur_name;
        end
    end

    % var_name_F = "wingbeat_avg_forces_raw";
    var_name_F = "wingbeat_avg_forces";
    % var_name_F = "wingbeat_avg_forces_smoothest";
    % disp("Loading " + force_path + force_filename)
    c = load(force_path + force_filename, var_name_F);
    var_F = c.(var_name_F);

    force = var_F(idx,:);
end