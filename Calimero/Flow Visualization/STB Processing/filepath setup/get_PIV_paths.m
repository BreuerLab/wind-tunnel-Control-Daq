function file_path = get_PIV_paths(PIV_case_name)
    % Setup Base Configuration
    drive = "Y:\"; 
    base_dir = drive + "VC7 Data\";
    month_1 = "February\";
    month_2 = "August\";
    
    % Standard processing suffixes
    BIN = "\Binning_48x48x48_75%ov_ord=0";

    % Define the Mapping (Case Name -> Subpath)
    % This is now much easier to read and edit.
    map = {
        'UP_two_flexible_10deg_0Hz',  month_1 + "UP_two_flexible_10deg_0Hz" + BIN
        'UP_two_flexible_10deg_2Hz',  month_1 + "UP_two_flexible_10deg_2Hz" + BIN
        'UP_two_flexible_10deg_4Hz',  month_1 + "UP_two_flexible_10deg_4Hz" + BIN
        'UP_two_flexible_10deg_6Hz',  month_1 + "UP_two_flexible_10deg_6Hz" + BIN
        'UP_two_flexible_10deg_8Hz',  month_1 + "UP_two_flexible_10deg_8Hz" + BIN

        'UP_two_flexible_20deg_2Hz',  month_1 + "UP_two_flexible_20deg_2Hz" + BIN
        'UP_two_flexible_20deg_4Hz',  month_1 + "UP_two_flexible_20deg_4Hz" + BIN
        'UP_two_flexible_20deg_6Hz',  month_1 + "UP_two_flexible_20deg_6Hz" + BIN
        'UP_two_flexible_20deg_8Hz',  month_1 + "UP_two_flexible_20deg_8Hz" + BIN

        'UP_two_flexible_30deg_2Hz',  month_1 + "UP_two_flexible_30deg_2Hz" + BIN
        'UP_two_flexible_30deg_4Hz',  month_1 + "UP_two_flexible_30deg_4Hz" + BIN
        'UP_two_flexible_30deg_6Hz',  month_1 + "UP_two_flexible_30deg_6Hz" + BIN

        'UP_two_body',  month_1 + "UP_two_body" + BIN

        'UP_one_flexible_10deg_2Hz',  month_1 + "UP_one_flexible_10deg_2Hz" + BIN
        'UP_one_flexible_10deg_4Hz',  month_1 + "UP_one_flexible_10deg_4Hz" + BIN
        'UP_one_flexible_10deg_6Hz',  month_1 + "UP_one_flexible_10deg_6Hz" + BIN
        'UP_one_flexible_10deg_8Hz',  month_1 + "UP_one_flexible_10deg_8Hz" + BIN

        'UP_one_flexible_20deg_2Hz',  month_1 + "UP_one_flexible_20deg_2Hz" + BIN
        'UP_one_flexible_20deg_4Hz',  month_1 + "UP_one_flexible_20deg_4Hz" + BIN
        'UP_one_flexible_20deg_6Hz',  month_1 + "UP_one_flexible_20deg_6Hz" + BIN
        'UP_one_flexible_20deg_8Hz',  month_1 + "UP_one_flexible_20deg_8Hz" + BIN

        'UP_one_flexible_30deg_2Hz',  month_1 + "UP_one_flexible_30deg_2Hz" + BIN
        'UP_one_flexible_30deg_4Hz',  month_1 + "UP_one_flexible_30deg_4Hz" + BIN
        'UP_one_flexible_30deg_6Hz',  month_1 + "UP_one_flexible_30deg_6Hz" + BIN
        
        'flexible_10deg_0Hz',         month_1 + "flexible_10deg_0Hz" + BIN
        'flexible_10deg_2Hz',         month_1 + "flexible_10deg_2Hz" + BIN
        'flexible_10deg_4Hz',         month_1 + "flexible_10deg_4Hz" + BIN
        'flexible_10deg_6Hz',         month_1 + "flexible_10deg_6Hz" + BIN
        'flexible_10deg_8Hz',         month_1 + "flexible_10deg_8Hz" + BIN
        
        'flexible_20deg_2Hz',         month_1 + "flexible_20deg_2Hz" + BIN
        'flexible_20deg_4Hz',         month_1 + "flexible_20deg_4Hz" + BIN
        'flexible_20deg_6Hz',         month_1 + "flexible_20deg_6Hz" + BIN
        'flexible_20deg_8Hz',         month_1 + "flexible_20deg_8Hz" + BIN
        
        'flexible_30deg_2Hz',         month_1 + "flexible_30deg_2Hz" + BIN
        'flexible_30deg_4Hz',         month_1 + "flexible_30deg_4Hz" + BIN
        'flexible_30deg_6Hz',         month_1 + "flexible_30deg_6Hz" + BIN
        
        'body',                       month_1 + "body" + BIN
        'ring',                       month_1 + "ring" + BIN
        'turbine_S',                  month_1 + "turbine_6ms_S" + BIN
        'turbine_S_ext',              month_1 + "turbine_6ms_S_ext" + BIN
        'turbine_F_ext'               month_1 + "turbine_6ms_F_ext" + BIN

        'x5_NACA',                    month_2 + "x5_NACA" + BIN
        'x5_NACA_refined',            month_2 + "x5_NACA_refined" + BIN
        'x5_wings_20deg_0Hz',         month_2 + "x5_wings_20deg_0Hz" + BIN
        'x5_wings_20deg_6Hz',         month_2 + "x5_wings_20deg_6Hz" + BIN
        'x5_wings_20deg_6Hz_v2',         month_2 + "x5_wings_20deg_6Hz_v2" + BIN
    };

    % Convert to Map and Retrieve
    PIV_dict = containers.Map(map(:,1), map(:,2));
    
    if isKey(PIV_dict, PIV_case_name)
        file_path = base_dir + PIV_dict(PIV_case_name);
    else
        error('PIV Case "%s" not recognized.', PIV_case_name);
    end
end