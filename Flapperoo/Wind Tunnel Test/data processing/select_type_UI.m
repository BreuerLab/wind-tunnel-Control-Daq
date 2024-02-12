function select_type_UI(processed_data_path)
    all_fig = findall(0, 'type', 'figure');
    close(all_fig)


    types = strings(1);
    total_wind_speeds = [];
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);

    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(theFiles)
        baseFileName = theFiles(i).name;
        [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);
        if (~contains(types,type))
            types = [types type];
        end
        if (~ismember(wind_speed, total_wind_speeds))
            total_wind_speeds = [total_wind_speeds, wind_speed];
        end
    end

    types = types(2:end); % delete first empty string
    num_wind_speeds = length(total_wind_speeds);
    
    fig = uifigure;
    fig.Position = [600 500 300 160];
    movegui(fig, 'center')
    g = uigridlayout(fig);
    g.RowHeight = {'fit','fit'};
    g.ColumnWidth = {'fit'};
    dd_types = uilistbox(g, "Items", types,"Multiselect","on");
    dd_types.Layout.Row = 1;
    dd_types.Layout.Column = 1;
    type_sel = convertCharsToStrings(dd_types.Value);
    dd_types.ValueChangedFcn = @(src,event) select_wind(src,event,processed_data_path,dd_types.Value,num_wind_speeds);
end

function select_wind(src,event,processed_data_path,type_sel,num_wind_speeds)
    h = findall(groot,'Type','figure');
    g = get(h,'children');
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    wind_speeds = [];
    type_counter = 0;
    wind_speed_configs = zeros(length(type_sel,num_wind_speeds);
     for i = 1 : length(theFiles)
        baseFileName = theFiles(i).name;
        [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);
        if (ismember(type,type_sel) && ~ismember(wind_speed, wind_speeds))
            for j = 1:length(type_sel)
                if (type == type_sel(j))
                    wind_speeds = [wind_speeds, wind_speed];
                    wind_speed_configs(j,:) = wind_speeds;
                end
            end
        end
     end
     
     disp(wind_speed_configs)
     
     dd_wind = uilistbox(g, "Items", string(wind_speeds),"Multiselect","on");
     dd_wind.Layout.Row = 2;
     dd_wind.Layout.Column = 1;
     wind_speed_sel = str2double(dd_wind.Value);
%      dd_wind.ValueChangedFcn = @(src,event) select_AoA(src,event,processed_data_path,dd_types.Value,dd_wind.Value);
end
% 
% function select_AoA(src,event,processed_data_path,type_sel,wind_speed_sel)
%     h = findall(groot,'Type','figure');
%     g = get(h,'children');
%     % Get a list of all files in the folder with the desired file name pattern.
%     filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
%     theFiles = dir(filePattern);
%     
%     AoAs = [];
%     
%      for i = 1 : length(theFiles)
%         baseFileName = theFiles(i).name;
%         [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
%         type = convertCharsToStrings(type);
%         if (type == type_sel && wind_speed == wind_speed_sel && ~ismember(AoA, AoAs))
%             AoAs = [AoAs; AoA];
%         end
%      end
%      
%      dd_AoA = uidropdown(g, "Items", string(AoAs));
%      dd_AoA.Layout.Row = 2;
%      dd_AoA.Layout.Column = 1;
%      AoA_sel = str2num(dd_wind.Value);
%      
% end