function [file_path, case_folder] = get_PIV_paths(PIV_case_name)
    % file_path = get_PIV_paths(PIV_case_name): path to the case's data
    %   (its combined binning folder of .vc7 files)
    % [file_path, case_folder] = get_PIV_paths(PIV_case_name): also the
    %   case folder (the binning folder's parent), where a trial processed
    %   in batches keeps its particle sets, each with its own binning
    %   folder inside its Shake-the-Box folder. Use get_case_frames for the
    %   case's frames in either layout; file_path is "" when there is no
    %   combined binning folder but the case folder exists.
    % case_names = get_PIV_paths(): list of all available case names
    %
    % September cases are found from their names, in one folder per
    % downstream position:
    %   F:\VC7 Data\September\<pos>\<case>\Binning_48x48x48_75%ov_ord=1
    % with <pos> = x1 ... x5 or MPS (the case name's prefix, e.g. x3 for
    % x3_wings_20deg_2Hz). Older cases (February, August, turbine) are
    % listed in the map below.
    % Setup Base Configuration
    % drive = "Y:\";
    drive = "F:\"; 
    base_dir = drive + "VC7 Data\";
    month_1 = "February\";
    month_2 = "August\";
    month_3 = "September\";
    
    % Standard processing suffixes
    BIN = "\Binning_48x48x48_75%ov_ord=0";
    BIN2 = "\Binning_48x48x48_75%ov_ord=1";
    % BIN3 = "\VIC\FineScaleReconst_grid=12_GPU";
    % BIN4 = "\VIC\FineScaleReconst_grid=12_GPU_01";
    % BIN5 = "\Binning_48x48x48_75%ov_ord=2";

    % Define the Mapping (Case Name -> Subpath)
    % This is now much easier to read and edit.
    map = {
        'freestream',  month_3 + "freestream" + BIN2
        % 'x2_wings_20deg_8Hz_VIC',  month_3 + "x2\x2_wings_20deg_8Hz" + BIN3
        % 'x2_wings_20deg_8Hz_VIC3',  month_3 + "x2\x2_wings_20deg_8Hz" + BIN4
        % 'x2_wings_20deg_8Hz_BIN2',  month_3 + "x2\x2_wings_20deg_8Hz" + BIN5

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

        % 'x5_NACA',                    month_2 + "x5_NACA" + BIN
        % 'x5_NACA_refined',            month_2 + "x5_NACA_refined" + BIN
        % 'x5_wings_20deg_0Hz',         month_2 + "x5_wings_20deg_0Hz" + BIN
        % 'x5_wings_20deg_6Hz',         month_2 + "x5_wings_20deg_6Hz" + BIN
        % 'x5_wings_20deg_6Hz_v2',         month_2 + "x5_wings_20deg_6Hz_v2" + BIN
        % 'x5_wings_20deg_6Hz_v3',         month_2 + "x5_wings_20deg_6Hz_v3" + BIN

        % September cases (x1-x5, MPS) aren't listed: their paths are built
        % from the case name (september_path below)
    };

    % Called with no input: return every available case name (listed
    % cases plus the September case folders found on disk)
    if nargin == 0
        file_path = unique([string(map(:,1)); list_september_cases(base_dir + month_3)], 'stable');
        return
    end

    % Listed cases first (February, August, turbine), so e.g. the August
    % x5 runs aren't looked for in September
    PIV_dict = containers.Map(map(:,1), map(:,2));
    PIV_case_name = char(PIV_case_name);
    if isKey(PIV_dict, PIV_case_name)
        file_path = base_dir + PIV_dict(PIV_case_name);
    elseif strlength(get_downstream_prefix(PIV_case_name)) > 0
        file_path = september_path(base_dir + month_3, PIV_case_name, BIN2);
    else
        error('PIV Case "%s" not recognized.', PIV_case_name);
    end

    case_folder = string(fileparts(char(file_path)));
    if ~isfolder(file_path)
        if nargout >= 2 && isfolder(case_folder)
            file_path = "";      % batch layout: frames from get_case_frames
            return
        end
        error('get_PIV_paths:missingFolder', ...
            'PIV data folder for "%s" not found:\n  %s', PIV_case_name, file_path);
    end
end

% September\<pos>\<case>\<binning>, <pos> from the case name (x3, MPS)
function file_path = september_path(month_dir, case_name, bin)
    pos = position_of(case_name);
    file_path = month_dir + pos + "\" + case_name + bin;
end

function pos = position_of(case_name)
    pos = regexprep(get_downstream_prefix(case_name), "_$", "");
end

% Case folders in September\<pos>\ for every position folder present
function case_names = list_september_cases(month_dir)
    case_names = strings(0, 1);
    if ~isfolder(month_dir)
        return
    end
    pos_dirs = dir(month_dir);
    pos_dirs = pos_dirs([pos_dirs.isdir] & ~startsWith({pos_dirs.name}, "."));
    for i = 1:numel(pos_dirs)
        pos = string(pos_dirs(i).name);
        if position_of(pos + "_") ~= pos
            continue % not a position folder (x1-x5, MPS)
        end
        cases = dir(fullfile(month_dir, pos));
        cases = cases([cases.isdir] & ~startsWith({cases.name}, "."));
        names = string({cases.name})';
        % only cases at that position (x3\x3_wings_20deg_2Hz, ...)
        names = names(startsWith(names, pos + "_"));
        case_names = [case_names; names]; %#ok<AGROW>
    end
end
