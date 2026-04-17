function [daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name)
    % Define the base directory shortcuts to keep paths readable
    base_rg = 'R:\ENG_Breuer_Shared\rgissler\Calimero Force Data\STB Final\';
    base_group = 'R:\ENG_Breuer_Shared\group\Wind turbine\Turbine_STB\DAQ Data\';

    % Map experimental dates to their specific subfolders
    d11 = [base_rg, 'STB_02_11_2026\data\experiment data\'];
    d12 = [base_rg, 'STB_02_12_2026\data\experiment data\'];
    d15 = [base_rg, 'STB_02_15_2026\data\experiment data\'];

    % Create an organized lookup structure
    % Format: cases.(alias) = {filename, path}
    cases = struct();
    
    % Feb 15th Data
    cases.UP_two_flexible_10deg_2Hz = {'UP_two_PIV_flexible_10_4m.s_10deg_2Hz_2026-02-15 13-19-51_experiment_2026_02_15_13_21_12.mat', d15};
    cases.UP_two_flexible_10deg_4Hz = {'UP_two_PIV_flexible_10_4m.s_10deg_4Hz_2026-02-15 13-48-19_experiment_2026_02_15_13_49_41.mat', d15};
    cases.UP_two_flexible_10deg_6Hz = {'UP_two_PIV_flexible_10_4m.s_10deg_6Hz_2026-02-15 14-35-23_experiment_2026_02_15_14_36_45.mat', d15};
    cases.UP_two_flexible_10deg_8Hz = {'UP_two_PIV_flexible_10_4m.s_10deg_8Hz_2026-02-15 15-11-10_experiment_2026_02_15_15_12_32.mat', d15};
    
    cases.UP_two_flexible_20deg_2Hz = {'UP_two_PIV_flexible_20_4m.s_10deg_2Hz_2026-02-15 15-56-23_experiment_2026_02_15_15_57_42.mat', d15};
    cases.UP_two_flexible_20deg_4Hz = {'UP_two_PIV_flexible_20_4m.s_10deg_4Hz_2026-02-15 16-36-23_experiment_2026_02_15_16_37_43.mat', d15};
    cases.UP_two_flexible_20deg_6Hz = {'UP_two_PIV_flexible_20_4m.s_10deg_6Hz_2026-02-15 17-23-13_experiment_2026_02_15_17_24_35.mat', d15};
    cases.UP_two_flexible_20deg_8Hz = {'UP_two_PIV_flexible_20_4m.s_10deg_8Hz_2026-02-15 18-07-00_experiment_2026_02_15_18_08_22.mat', d15};

    cases.UP_two_flexible_30deg_2Hz = {'UP_two_PIV_flexible_30_4m.s_10deg_2Hz_2026-02-15 11-43-30_experiment_2026_02_15_11_44_52', d15};
    cases.UP_two_flexible_30deg_4Hz = {'UP_two_PIV_flexible_30_4m.s_10deg_4Hz_2026-02-15 12-22-08_experiment_2026_02_15_12_23_31', d15};
    cases.UP_two_flexible_30deg_6Hz = {'UP_two_PIV_flexible_30_4m.s_10deg_6Hz_2026-02-15 12-51-01_experiment_2026_02_15_12_52_27.mat', d15};

    % Feb 12th Data
    cases.UP_one_flexible_20deg_2Hz = {'UP_one_PIV_flexible_20_4m.s_10deg_2Hz_2026-02-12 11-00-21_experiment_2026_02_12_11_02_30.mat', d12};
    cases.UP_one_flexible_20deg_6Hz = {'UP_one_PIV_flexible_20_4m.s_10deg_6Hz_2026-02-12 11-57-03_experiment_2026_02_12_11_58_20.mat', d12};
    cases.UP_one_flexible_30deg_2Hz = {'UP_one_PIV_flexible_30_4m.s_10deg_2Hz_2026-02-12 15-31-47_experiment_2026_02_12_15_33_07.mat', d12};

    % Feb 11th Data
    cases.flexible_10deg_2Hz = {'PIV_flexible_10_4m.s_10deg_2Hz_2026-02-11 13-57-37_experiment_2026_02_11_13_59_51.mat', d11};
    cases.flexible_10deg_4Hz = {'PIV_flexible_10_4m.s_10deg_4Hz_2026-02-11 14-27-00_experiment_2026_02_11_14_28_29.mat', d11};
    cases.flexible_10deg_6Hz = {'PIV_flexible_10_4m.s_10deg_6Hz_2026-02-11 14-55-06_experiment_2026_02_11_14_56_23.mat', d11};
    cases.flexible_10deg_8Hz = {'PIV_flexible_10_4m.s_10deg_8Hz_2026-02-11 15-25-48_experiment_2026_02_11_15_26_58.mat', d11};
    
    cases.flexible_20deg_2Hz = {'PIV_flexible_20_4m.s_10deg_2Hz_2026-02-11 17-46-16_experiment_2026_02_11_17_48_26.mat', d11};
    cases.flexible_20deg_4Hz = {'PIV_flexible_20_4m.s_10deg_4Hz_2026-02-11 18-15-29_experiment_2026_02_11_18_16_57.mat', d11};
    cases.flexible_20deg_6Hz = {'PIV_flexible_20_4m.s_10deg_6Hz_2026-02-11 18-43-27_experiment_2026_02_11_18_44_44.mat', d11};
    cases.flexible_20deg_8Hz = {'PIV_flexible_20_4m.s_10deg_8Hz_2026-02-11 19-11-05_experiment_2026_02_11_19_12_18.mat', d11};
    
    cases.flexible_30deg_2Hz = {'PIV_flexible_30_4m.s_10deg_2Hz_2026-02-11 16-22-07_experiment_2026_02_11_16_24_25.mat', d11};
    cases.flexible_30deg_4Hz = {'PIV_flexible_30_4m.s_10deg_4Hz_2026-02-11 16-48-47_experiment_2026_02_11_16_50_16.mat', d11};
    cases.flexible_30deg_6Hz = {'PIV_flexible_30_4m.s_10deg_6Hz_2026-02-11 17-16-55_experiment_2026_02_11_17_18_14.mat', d11};

    % Turbine Data
    cases.turbine     = {'turbine_6ms_S_2026_02_16_16_15_13.mat', base_group};
    cases.turbine_ext = {'turbine_6ms_S_ext_2026_02_17_16_55_48.mat', base_group};

    % Retrieve the data
    if isfield(cases, PIV_case_name)
        data = cases.(PIV_case_name);
        daq_data_filename = data{1};
        daq_data_path     = data{2};
    else
        error('Case name "%s" not found in the DAQ database.', PIV_case_name);
    end
end