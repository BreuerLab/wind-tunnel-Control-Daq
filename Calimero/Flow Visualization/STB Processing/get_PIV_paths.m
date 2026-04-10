function file_path = get_PIV_paths(PIV_case_name)
    % Setup Base Configuration
    drive = "Y:\"; 
    base_dir = drive + "VC7 Data\";
    
    % Standard processing suffixes
    BIN = "\Binning_48x48x48_75%ov_ord=0";

    % Define the Mapping (Case Name -> Subpath)
    % This is now much easier to read and edit.
    map = {
        'UP_two_flexible_10deg_2Hz',  "UP_two_flexible_10deg_2Hz" + BIN
        'UP_two_flexible_10deg_4Hz',  "UP_two_flexible_10deg_4Hz" + BIN
        'UP_two_flexible_10deg_6Hz',  "UP_two_flexible_10deg_6Hz" + BIN
        'UP_two_flexible_10deg_8Hz',  "UP_two_flexible_10deg_8Hz" + BIN

        'UP_two_flexible_20deg_2Hz',  "UP_two_flexible_20deg_2Hz" + BIN
        'UP_two_flexible_20deg_4Hz',  "UP_two_flexible_20deg_4Hz" + BIN
        'UP_two_flexible_20deg_6Hz',  "UP_two_flexible_20deg_6Hz" + BIN
        'UP_two_flexible_20deg_8Hz',  "UP_two_flexible_20deg_8Hz" + BIN

        'UP_two_flexible_30deg_2Hz',  "UP_two_flexible_30deg_2Hz" + BIN
        'UP_two_flexible_30deg_4Hz',  "UP_two_flexible_30deg_4Hz" + BIN
        'UP_two_flexible_30deg_6Hz',  "UP_two_flexible_30deg_6Hz" + BIN

        'UP_one_flexible_20deg_2Hz',  "UP_one_flexible_20deg_2Hz" + BIN
        'UP_one_flexible_20deg_6Hz',  "UP_one_flexible_20deg_6Hz" + BIN
        'UP_one_flexible_30deg_2Hz',  "UP_one_flexible_30deg_2Hz" + BIN
        
        'flexible_10deg_2Hz',         "flexible_10deg_2Hz" + BIN
        'flexible_10deg_4Hz',         "flexible_10deg_4Hz" + BIN
        'flexible_10deg_6Hz',         "flexible_10deg_6Hz" + BIN
        'flexible_10deg_8Hz',         "flexible_10deg_8Hz" + BIN
        'flexible_20deg_2Hz',         "flexible_20deg_2Hz" + BIN
        'flexible_20deg_4Hz',         "flexible_20deg_4Hz" + BIN
        'flexible_20deg_6Hz',         "flexible_20deg_6Hz" + BIN
        'flexible_20deg_8Hz',         "flexible_20deg_8Hz" + BIN
        'flexible_30deg_2Hz',         "flexible_30deg_2Hz" + BIN
        'flexible_30deg_4Hz',         "flexible_30deg_4Hz" + BIN
        'flexible_30deg_6Hz',         "flexible_30deg_6Hz" + BIN
        'body',                       "body" + BIN
        'ring',                       "ring" + BIN
        'turbine',                    "turbine_6ms_S" + BIN
        'turbine_ext',                "turbine_6ms_S_ext" + BIN
    };

    % Convert to Map and Retrieve
    PIV_dict = containers.Map(map(:,1), map(:,2));
    
    if isKey(PIV_dict, PIV_case_name)
        file_path = base_dir + PIV_dict(PIV_case_name);
    else
        error('PIV Case "%s" not recognized.', PIV_case_name);
    end
end