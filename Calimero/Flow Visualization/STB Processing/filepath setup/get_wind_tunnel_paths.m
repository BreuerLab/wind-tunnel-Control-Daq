function filepath = get_wind_tunnel_paths(date)
    map = {
        '02_08_2026',  "AFAM_2026_02_08_11_21_48_log_file.csv"
        '02_09_2026',  "AFAM_2026_02_09_09_11_01_log_file.csv"
        '02_11_2026',  "AFAM_2026_02_11_10_04_52_log_file.csv"
        '02_12_2026',  "AFAM_2026_02_12_08_50_09_log_file.csv"
        '02_15_2026',  "AFAM_2026_02_15_09_06_19_log_file.csv"
    };

    % Convert to Map and Retrieve
    WT_dict = containers.Map(map(:,1), map(:,2));
    
    wind_tunnel_file = WT_dict(date);

    root_path = "R:\ENG_Breuer_Shared\rgissler\Calimero Force Data\STB Final\";

    filepath = root_path + wind_tunnel_file;
end