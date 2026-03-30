% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef compareWingbeatUI < handle
properties
    mon_num; % 1 or 2, monitor to display plot on

    data_path; % file path to data

    % integer, 0-6, defines which force/moment axes to display
    index;
    % force and moment axes labels used in dropdown box
    axes_labels;

    y_labels;

    % boolean, normalization/non-dimensionalization on or off
    norm;
    % boolean, normalization for x-axis (divided by period)
    norm_period;
    % boolean, move pitch moment from center of transducer to LE
    pitch_shift;
    % boolean, subtraction on or off
    sub;
    % boolean, spectrum plot overrides phase averaged plot
    spectrum;
    % boolean, scale frequencies of spectrum by wingbeat freq
    freq_scale;
    % boolean, log scale frequencies of spectrum when plotting
    log_scale;
    % 1, 2, or 3.
    % 1 - Raw, no filter
    % 2 - Filtered - 50 Hz cutoff frequency
    % 3 - Filtered - 10*wingbeat frequency cutoff frequency
    filt_num;
    saveFig;

    force_bool;
    method; % 1 - velocity, 2 - vorticity
    % used to calculate forces from vector field data

    % ------- Available parameters user can select from -------
    available_selections;

    selection; % list of selected cases
    sel_type;
    sel_freq;
    sel_amp;

    % Curves currently displayed on plot
    plot_curves;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = compareWingbeatUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.index = 1;
        obj.axes_labels = ["Lift", "Drag", "Speed", "Voltage", "Current"];
        obj.y_labels = ["Lift (N)", "Drag (N)", "Speed (Hz)", "Voltage (V)", "Current (mA)"];
        obj.norm = false;
        obj.norm_period = true;
        obj.sub = false;
        obj.freq_scale = false;
        obj.log_scale = false;
        obj.filt_num = 3;
        obj.saveFig = false;

        obj.force_bool = false;
        obj.method = 2;

        % Search through files in path to get types and speeds

        contents = dir(obj.data_path);
        files = contents(~[contents.isdir]);

        obj.available_selections = zeros(length(files),3);

        for i = 1:length(files)
            name = files(i).name;
            name = extractBefore(name, "_phase_avg");

            if ~contains(name, "Hz") % body or ring only case
                continue
            end
            name_parts = split(name,"_");

            for j = 1:length(name_parts)
                if contains(name_parts{j}, "deg")
                    amp = str2double(extractBefore(name_parts{j}, "deg"));
                    type = string(name_parts{j-1});
                elseif contains(name_parts{j}, "Hz")
                    freq = str2double(extractBefore(name_parts{j}, "Hz"));
                end
            end

            % Add to list of amplitudes and frequencies
            obj.available_selections(i,1) = 1;
            obj.available_selections(i,2) = amp;
            obj.available_selections(i,3) = freq;
        end

        % Deletes rows where all elements are 0 - body/ring case
        obj.available_selections(~any(obj.available_selections, 2), :) = [];

        obj.sel_type = type;
        obj.sel_amp = obj.available_selections(1,2);
        obj.sel_freq = obj.available_selections(1,3);

        obj.plot_curves = [];
        % attachFileListsToBird(path, cur_bird);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);

        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        % Dropdown box for flapper type selection
        drop_y1 = screen_height*0.85 - 30;
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.Items = ("flexible");
        d1.ValueChangedFcn = @(src, event) type_change(src, event);

        % Dropdown box for wingbeat frequency selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 unit_height];
        cur_freqs = obj.available_selections(obj.available_selections(:,2) == obj.sel_amp,3);
        d2.Items = string(cur_freqs) + " Hz";

        % Dropdown box for wingbeat amplitude selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        cur_amps = obj.available_selections(obj.available_selections(:,3) == obj.sel_freq,2);
        d3.Items = string(cur_amps) + " deg";

        d2.ValueChangedFcn = @(src, event) freq_change(src, event, d3);
        d3.ValueChangedFcn = @(src, event) amp_change(src, event, d2);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = drop_y3 - (unit_height + unit_spacing);
        b2 = uibutton(option_panel);
        b2.Position = [15 button2_y 80 unit_height];
        b2.Text = "Add entry";

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b3 = uibutton(option_panel);
        b3.Position = [105 button2_y 80 unit_height];
        b3.Text = "Delete entry";

        % List of cases currently displayed on the plots
        list_y = button2_y - (4*(unit_height + unit_spacing) + unit_spacing);
        lbox = uilistbox(option_panel);
        lbox.Items = strings(0);
        lbox.Position = [10 list_y 180 4*(unit_height + unit_spacing)];

        b2.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
        b3.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

        % Dropdown box for which force/moment axes to display
        drop_y9 = list_y - (unit_height + unit_spacing);
        d9 = uidropdown(option_panel);
        d9.Position = [10 drop_y9 180 unit_height];
        d9.Items = obj.axes_labels;
        d9.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        button4_y = drop_y9 - (unit_height + unit_spacing);
        b4 = uibutton(option_panel, "state");
        b4.Text = "Show Force";
        b4.FontSize = 18;
        b4.Position = [20 button4_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) force_change(src, event, plot_panel);

        button5_y = button4_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel, "state");
        b5.Text = "Use Velocity";
        b5.FontSize = 18;
        b5.Position = [20 button5_y 160 unit_height];
        b5.BackgroundColor = [1 1 1];
        b5.ValueChangedFcn = @(src, event) method_change(src, event, plot_panel);

        button6_y = button5_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel, "state");
        b6.Text = "Subtraction";
        b6.FontSize = 18;
        b6.Position = [20 button6_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) subtraction_change(src, event, plot_panel);

        % ------------------------------------------------------
        % -------Buttons built up from bottom of screen---------
        % ------------------------------------------------------

        button8_y = unit_spacing;
        field_y = button8_y + (unit_height + unit_spacing);
        label_y = field_y + unit_height - unit_spacing;

        fnl = uilabel(option_panel);
        fnl.Position = [65 label_y 80 unit_height];
        fnl.Text = "File Name";

        ef = uieditfield(option_panel);
        ef.Position = [15 field_y 160 unit_height];
        ef.Placeholder = "test";

        % Button to export data on plot to .mat file
        b10 = uibutton(option_panel);
        b10.Position = [15 button8_y 160 unit_height];
        b10.Text = "Export Data";
        b10.ButtonPushedFcn = @(src, event) exportData(src, event, ef);

        button9_y = label_y + (unit_height + unit_spacing);
        b4 = uibutton(option_panel);
        b4.Text = "Save Fig";
        b4.Position = [20 button9_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

        % Set up plot titles and axes
        obj.update_plot(plot_panel);

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        % Callback functions to respond to user inputs. These
        % functions must be nested inside this function otherwise
        % they will reference the object snapshot at the time the
        % callback function was defined rather than updating with
        % the object
        %-----------------------------------------------------%
        %-----------------------------------------------------%
    
        % update type variable with new value selected by user
        function flapper_change(src, ~, type_box, freq_box, angle_box, speed_box)
            if (src.Value == "Flapperoo")
                obj.sel_bird = obj.Flapperoo;
            elseif (src.Value == "MetaBird")
                obj.sel_bird = obj.MetaBird;
            else
                error("This bird selection is not recognized.")
            end
            type_box.Items = obj.sel_bird.types;
            freq_box.Items = obj.sel_bird.freqs;
            angle_box.Items = obj.sel_bird.angles + " deg";
            speed_box.Items = obj.sel_bird.speeds + " m/s";

            obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
            obj.sel_freq = obj.sel_bird.freqs(2);
            obj.sel_angle = 0;
            obj.sel_speed = obj.sel_bird.speeds(1);

            % type_box.Value = obj.sel_bird.types(1);
            % freq_box.Value = obj.sel_bird.freqs(1);
            % angle_box.Value = obj.sel_bird.angles(1) + " deg";
            % speed_box.Value = obj.sel_bird.speeds(1) + " m/s";
        end

        % update type variable with new value selected by user
        function type_change(src, ~)
            obj.sel_type = nameToType(obj.sel_bird.name, src.Value);
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~, d)
            obj.sel_freq = str2double(regexp(src.Value, '\d+', 'match'));
            
            % Change amplitude list to only show those available at this
            % wingbeat frequency
            amps = obj.available_selections(obj.available_selections(:,3) == obj.sel_freq,2);
            d.Items = string(amps) + " deg";
        end

        % update speed variable with new value selected by user
        function amp_change(src, ~, d)
            obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));

            % Change frequency list to only show those available at this
            % wingbeat amplitude
            freqs = obj.available_selections(obj.available_selections(:,2) == obj.sel_amp,3);
            d.Items = string(freqs) + " Hz";
        end

        function subtraction_change(src, ~, plot_panel)
            if (src.Value)
                obj.sub = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];              
            else
                obj.sub = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function addToList(~, ~, plot_panel, lbox)

            case_name = obj.sel_type + "_" + obj.sel_amp +...
                "deg_" + obj.sel_freq + "Hz";

            if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                lbox.Items = [lbox.Items, case_name];
                obj.selection = [obj.selection, case_name];
            end

            obj.update_plot(plot_panel);
        end

        function removeFromList(~, ~, plot_panel, lbox)
            case_name = lbox.Value;
            % removing value from list that's displayed
            new_list_indices = string(lbox.Items) ~= case_name;
            lbox.Items = lbox.Items(new_list_indices);

            % OLD CODE 10/07/2024 - CODE USED TO DISPLAY ST IN
            % LBOX, RESULTED IN PROBLEMS WHEN CAME TO DELETE
            % if (obj.norm)
            %     [cur_type, cur_speed, cur_freq, cur_angle] = compareWingbeatUI.parseCases(case_name);
            %     % Extract first number after 'St: '
            %     St = sscanf(extractAfter(cur_freq, "St: "), '%g', 1);
            %     abbr_freqs = str2double(extractBefore(obj.freqs(1:end-2), " Hz")); % remove v2 trials
            %     sel_freq = compareWingbeatUI.stToFreq(St, cur_speed, abbr_freqs);
            %     case_name = cur_type + " " + cur_speed + " m/s " + sel_freq + " Hz " + cur_angle + " deg";
            % end

            % removing value from list used for plotting
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function index_change(src, ~, plot_panel)
            obj.index = find(obj.axes_labels == src.Value);
            obj.update_plot(plot_panel);
        end

        function norm_change(src, ~, plot_panel, d2)
            if (src.Value)
                obj.norm = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                % replace freqs with strouhal numbers
                for i = 1:length(d2.Items)
                    wing_freq = str2double(extractBefore(d2.Items{i}, " Hz"));
                    St = freqToSt(obj.sel_bird.name, wing_freq, obj.sel_speed, obj.data_path, -1);
                    d2.Items{i} = ['St: ' num2str(St)];
                end
            else
                obj.norm = false;
                src.BackgroundColor = [1 1 1];
                % replace strouhal numbers with freqs
                if (obj.sel_speed == 6)
                    shortened_list = obj.sel_bird.freqs(obj.sel_bird.freqs ~= "4.5 Hz" & obj.sel_bird.freqs ~= "5 Hz");
                    d2.Items = shortened_list;
                else
                    d2.Items = obj.sel_bird.freqs;
                end
            end

            obj.update_plot(plot_panel);
        end

        function norm_period_change(src, ~, plot_panel)
            if (src.Value)
                obj.norm_period = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.norm_period = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        
        % update angle variable with new value selected by user
        function filt_change(src, ~, plot_panel)
            if (src.Value == "Raw")
                obj.filt_num = 1;
            elseif (src.Value == "Filtered - F_c = 50 Hz")
                obj.filt_num = 2;
            elseif (src.Value == "Filtered - F_c = 10*w_f Hz")
                obj.filt_num = 3;
            end

            obj.update_plot(plot_panel);
        end

        function force_change(src, ~, plot_panel)
            if (src.Value)
                obj.force_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                src.Text = "Hide Force";
            else
                obj.force_bool = false;
                src.BackgroundColor = [1 1 1];
                src.Text = "Show Force";
            end

            obj.update_plot(plot_panel);
        end

        function method_change(src, ~, plot_panel)
            if (src.Value)
                obj.method = 1;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                src.Text = "Use Vorticity";
            else
                obj.method = 2;
                src.BackgroundColor = [1 1 1];
                src.Text = "Use Velocity";
            end

            obj.update_plot(plot_panel);
        end

        function freq_scale_change(src, ~, plot_panel)
            if (src.Value)
                obj.freq_scale = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];              
            else
                obj.freq_scale = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function log_scale_change(src, ~, plot_panel)
            if (src.Value)
                obj.log_scale = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];              
            else
                obj.log_scale = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function exportData(~, ~, ef)
            filename = [ef.Value '.mat'];
            curves = obj.plot_curves;
            save(filename, "curves")
        end

        function save_figure(~, ~, plot_panel)
            obj.saveFig = true;
            obj.update_plot(plot_panel);
            obj.saveFig = false;
        end

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)

    function dir_name = getDataFolder(flapper, type, speed, norm)
        dir_name = strrep(typeToSel(flapper, type), " ", "_") + "_" + speed + "m.s._";
        if norm
            dir_name = dir_name + "norm_shift_drift";
        else
            dir_name = dir_name + "shift_drift";
        end
    end

    function [sel_type, sel_speed, sel_freq, sel_angle] = parseCases(case_name)
        flapper_name = string(extractBefore(case_name, "/"));
        case_name = string(extractAfter(case_name, "/"));

        % Parse relevant trial information from case name 
        case_parts = strtrim(split(case_name));
        sel_type = "";
        sel_freq = -1;
        sel_angle = -1;
        sel_speed = -1;
        for j=1:length(case_parts)
            if (contains(case_parts(j), "deg"))
                sel_angle = str2double(case_parts(j-1));
                end_ind = j-2;
            elseif (contains(case_parts(j), "m/s"))
                sel_speed = str2double(case_parts(j-1));
                sel_type = strjoin(case_parts(1:j-2)); % speed is first thing after type
                start_ind = j+1;
            end
        end
        sel_freq = strjoin(case_parts(start_ind:end_ind));
    end

    function [uniq_types, uniq_speeds, uniq_freqs] = getUniqParams(selected_cases, bird, sub_bool)
        uniq_types = [];
        uniq_speeds = [];
        uniq_freqs = [];
        for i = 1:length(selected_cases)
            case_name = selected_cases(i);
            % Parse relevant trial information from case name 
            [sel_type, sel_speed, sel_freq, sel_angle] = compareWingbeatUI.parseCases(case_name);

            if (sum(strcmp(uniq_types, sel_type)) == 0)
                uniq_types = [uniq_types sel_type];
            end
            if (sum(uniq_speeds == sel_speed) == 0)
                uniq_speeds = [uniq_speeds sel_speed];
            end
            if (sum(strcmp(uniq_freqs, sel_freq)) == 0)
                uniq_freqs = [uniq_freqs sel_freq];
            end

            if (sub_bool)
                sub_type = compareWingbeatUI.getSubType(sel_type, bird);
                if (sum(strcmp(uniq_types, sub_type)) == 0)
                    uniq_types = [uniq_types sub_type];
                end
            end
        end
        uniq_freqs = sort(uniq_freqs);
        uniq_speeds = sort(uniq_speeds);
    end

    function sub_type = getSubType(sel_type, bird)
        sub_type = "";
        for k = 1:length(bird.types)
            % 'Wing with Full Body' will contain 'Full
            % Body', but the inverse will never be true
            if (contains(typeToName(bird.name, sel_type), bird.types(k)))
                sub_type = nameToType(bird.name, bird.types(k));
            end
        end
    end

    function [data_filename, data_folder] = findMatchFile(sel_type, sel_speed, sel_freq, sel_angle, freqs, processed_data_files)
        wing_freq_sel = str2double(extractBefore(freqs, " Hz"));
        wing_freq_sel_count = wing_freq_sel;
        for i = 1:length(wing_freq_sel)
            wing_freq_sel_count(i) = sum(wing_freq_sel == wing_freq_sel(i));
        end

        wing_freq = str2double(extractBefore(sel_freq, " Hz"));
        for i = 1 : length(processed_data_files)
            baseFileName = processed_data_files(i).name;
            [case_name_cur, time_stamp_cur, type_cur, wing_freq_cur, AoA_cur, wind_speed_cur] = parse_filename(baseFileName);
            type_cur = convertCharsToStrings(type_cur);

            if (wing_freq == wing_freq_cur ...
            && sel_angle == AoA_cur ...
            && sel_speed == wind_speed_cur ...
            && strcmp(sel_type, type_cur))

                data_filename = baseFileName;
                data_folder = processed_data_files(i).folder;

                % Check if any other files were recorded for the same set
                % of parameters but at a different time
                count = 0;
                timestamps_str = {};
                timestamps_val = [];
                for m = 1 : length(processed_data_files)
                    baseFileName = processed_data_files(m).name;
                    if (contains(baseFileName, case_name_cur))
                        count = count + 1;
                        time_str = strtrim(extractBefore(extractAfter(baseFileName, case_name_cur), ".mat"));
                        split_time_str = split(time_str, "_");
                        h_m_s = str2double(split_time_str(4:6));
                        time_val = h_m_s(1)*3600 + h_m_s(2)*60 + h_m_s(3);
        
                        timestamps_str = [timestamps_str; time_str];
                        timestamps_val = [timestamps_val; time_val];
                    end
                end
        
                [B,I] = sort(timestamps_val);
                timestamps_str_sorted = timestamps_str(I);
                cur_time_index = find(timestamps_str_sorted == time_stamp_cur);
        
                num_repeat_freqs = wing_freq_sel_count(find(wing_freq_sel == wing_freq, 1, 'first'));
        
                disp("Obtaining data for " + type_cur + " " + wing_freq_cur + " Hz " + wind_speed_cur + " m/s "  + AoA_cur + " deg trial")
                if (count > 1) % counted multiple repeats in datastream
                if (num_repeat_freqs == count)
                    % num_repeat_freqs > 1 && cur_time_index > length(timestamps_str) - num_repeat_freqs
                    wing_freq_ind = find(wing_freq_sel == wing_freq);
                    wing_freq_ind = wing_freq_ind(cur_time_index);
        
                    disp("Found " + count + " files, timestamps: ")
                    disp(timestamps_str)
                    disp("    Using current timestamp: " + time_stamp_cur)
                    disp(" ")
                else
                    disp("Extra files found and current file too old, moving on...")
                    continue
                    % wing_freq_ind = wing_freq_sel == wing_freq;
                    % 
                    % modFileName = case_name + string(timestamps_str_sorted(end)) + ".mat";
                    % 
                    % disp("Found " + count + " files, timestamps: " + timestamps_str)
                    % disp("    Using last timestamp: " + timestamps_str_sorted(end))
                    % disp(" ")
                end
                end

                break

            end
        end
        if (~exist('data_filename'))
            error("CANT FIND THAT FILE. ARE YOU SURE IT EXISTS?")
        end
    end

    function theFiles = getFiles(filepath, filetype)
        % Get a list of all files in the folder with the desired file name pattern.
        filePattern = fullfile(filepath, filetype); % Change to whatever pattern you need.
        theFiles = [];
        for i = 1:length(filePattern)
            theFiles = [theFiles; dir(filePattern(i))];
        end
    end

    function abbr_name = getAbbrName(case_name, abbr_sel)
        abbr_name = "";
        for k = 1:length(abbr_sel)
            if (contains(case_name, abbr_sel(k)))
                abbr_name = abbr_sel(k);
            end
        end
    end

    function [frames, cycle_avg_forces, cycle_std_forces, ...
            cycle_min_forces, cycle_max_forces, cycle_rmse_forces, norm_factors] ...
            = load_data(data_folder, data_filename, filt_num, shift_bool, center_to_LE, AoA, norm_bool)
        if (filt_num == 1)
            vars = {'wingbeat_avg_forces_raw', 'wingbeat_std_forces_raw',...
            'wingbeat_min_forces_raw', 'wingbeat_max_forces_raw',...
            'wingbeat_rmse_forces_raw', 'frames', 'Re', 'St', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading wingbeat data from " + data_filename)
            disp("From: " + data_folder)
        
            cycle_avg_forces = wingbeat_avg_forces_raw;
            cycle_std_forces = wingbeat_std_forces_raw;
            cycle_min_forces = wingbeat_min_forces_raw;
            cycle_max_forces = wingbeat_max_forces_raw;
            cycle_rmse_forces = wingbeat_rmse_forces_raw;
        elseif (filt_num == 2)
            vars = {'wingbeat_avg_forces', 'wingbeat_std_forces',...
            'wingbeat_min_forces', 'wingbeat_max_forces',...
            'wingbeat_rmse_forces', 'frames', 'Re', 'St', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading smooth data from " + data_filename)
            disp("From: " + data_folder)
        
            cycle_avg_forces = wingbeat_avg_forces;
            cycle_std_forces = wingbeat_std_forces;
            cycle_min_forces = wingbeat_min_forces;
            cycle_max_forces = wingbeat_max_forces;
            cycle_rmse_forces = wingbeat_rmse_forces;
        elseif (filt_num == 3)
            vars = {'wingbeat_avg_forces_smoothest', 'wingbeat_std_forces_smoothest',...
            'wingbeat_min_forces_smoothest', 'wingbeat_max_forces_smoothest',...
            'wingbeat_rmse_forces_smoothest', 'frames', 'Re', 'St', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading smoothest data from " + data_filename)
            disp("From: " + data_folder)
        
            cycle_avg_forces = wingbeat_avg_forces_smoothest;
            cycle_std_forces = wingbeat_std_forces_smoothest;
            cycle_min_forces = wingbeat_min_forces_smoothest;
            cycle_max_forces = wingbeat_max_forces_smoothest;
            cycle_rmse_forces = wingbeat_rmse_forces_smoothest;
        else
            disp(filt_num)
            error("Bad filt number")
        end
        disp(" ")

        % Shift pitch moment from center of force transducer to LE
        if (shift_bool)
            cycle_avg_forces = shiftPitchMomentToLE(cycle_avg_forces, center_to_LE, AoA);
            cycle_std_forces = shiftPitchMomentToLE(cycle_std_forces, center_to_LE, AoA);
        end

        if (norm_bool)
            cycle_avg_forces(1:3,:) = cycle_avg_forces(1:3,:) / norm_factors(1);
            cycle_avg_forces(4:6,:) = cycle_avg_forces(4:6,:) / norm_factors(2);

            cycle_std_forces(1:3,:) = cycle_std_forces(1:3,:) / norm_factors(1);
            cycle_std_forces(4:6,:) = cycle_std_forces(4:6,:) / norm_factors(2);

            cycle_min_forces(1:3,:) = cycle_min_forces(1:3,:) / norm_factors(1);
            cycle_min_forces(4:6,:) = cycle_min_forces(4:6,:) / norm_factors(2);

            cycle_max_forces(1:3,:) = cycle_max_forces(1:3,:) / norm_factors(1);
            cycle_max_forces(4:6,:) = cycle_max_forces(4:6,:) / norm_factors(2);

            cycle_rmse_forces(1:3,:) = cycle_rmse_forces(1:3,:) / norm_factors(1);
            cycle_rmse_forces(4:6,:) = cycle_rmse_forces(4:6,:) / norm_factors(2);
        end
    end

    function [time_data, force_data, f, power, norm_factors] ...
            = load_spectrum_data(data_folder, data_filename, filt_num, norm_bool)
        if (filt_num == 1)
            vars = {'time_data', 'results_lab', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading raw data from " + data_filename)
            disp("From: " + data_folder)
        
            force_data = results_lab;
        elseif (filt_num == 2)
            vars = {'time_data', 'filtered_data', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading smooth data from " + data_filename)
            disp("From: " + data_folder)
        
            force_data = filtered_data;
        elseif (filt_num == 3)
            vars = {'time_data', 'filtered_data_smooth', 'norm_factors'};
            load([data_folder '\' data_filename], vars{:});
        
            disp("Loading smoothest data from " + data_filename)
            disp("From: " + data_folder)
        
            force_data = filtered_data_smooth;
        else
            disp(filt_num)
            error("Bad filt number")
        end
        disp(" ")

        if (norm_bool)
            force_data(1:3,:) = force_data(1:3,:) / norm_factors(1);
            force_data(4:6,:) = force_data(4:6,:) / norm_factors(2);
        end

        % Get spectrum from this data
        frame_rate = 9000; % Hz
        [f, power, num_windows, f_min] = compareWingbeatUI.freq_spectrum(force_data, frame_rate);
    end

    function [x_label, y_labels] = get_labels(x_norm, y_norm, spectrum, freq_scale)
        % Variables for plotting later
        if (x_norm)
            x_label = "Wingbeat Period (t/T)";
        else
            x_label = "Time (s)";
        end

        if (y_norm)
            y_label_F = "Cycle Average Force Coefficient";
            y_label_M = "Cycle Average Moment Coefficient";
        else
            y_label_F = "Cycle Average Force (N)";
            y_label_M = "Cycle Average Moment (N*m)";
        end

        if (spectrum)
            if freq_scale
                x_label = "Wingbeat Normalized Frequency (Hz)";
            else
                x_label = "Frequency (Hz)";
            end
            y_label_F = "Power/Frequency (dB/Hz)";
            y_label_M = "Power/Frequency (dB/Hz)";
        end

        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M,...
            y_label_M, y_label_M, "Voltage (V)", "Current (mA)"];
    end
    
    function [abbr_sel] = get_abbr_names(sel)
        non_type_words = ["deg", "m/s", "Hz"];
        ind_to_remove = [];
        first_sel = sel(1);
        sel_parts = split(first_sel);
        for i = 1:length(sel_parts)
            count = 0;
            for j = 1:length(sel)
            % Check if this part is contained in all selected
            % case names
            cur_parts = split(sel(j));
            if (cur_parts(i) == sel_parts(i))
                match = sel_parts(i);
                count = count + 1;
            end
            if (count == length(sel))
                % Check if last value was saved and was numeric,
                % then don't erase next string as that's the
                % units (i.e. Hz following 2)
                if (i == 1 || ~( ...
                    sum(ind_to_remove == i-1) == 0 ... % last value was saved
                    && (sum(isstrprop(sel_parts(i-1), 'alpha')) == 0 ... % last value was numeric
                    || (sum(sel_parts(i-1) == non_type_words) == 0))...% last value was non-type word
                    ))
                    ind_to_remove = [ind_to_remove i];
                end
            end
            end
        end
        abbr_sel = sel;
        for i = 1:length(sel)
            cur_parts = split(sel(i));
            cur_parts(ind_to_remove) = [];
            abbr_sel(i) = strjoin(cur_parts);
            % abbr_sel = strtrim(abbr_sel);
        end
    end

end

%% --------------------------------------------------------------
%---------------------------------------------------------------%
%---------------------------------------------------------------%
% The only function contained in this section is update_plot
methods (Access = private)
    % update plot after user changes selected variables
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)

        uniq_types = unique(obj.available_selections(:,1));
        uniq_amps = unique(obj.available_selections(:,2));
        uniq_freqs = unique(obj.available_selections(:,3));

        colors = getColors(length(uniq_types),...
                           length(uniq_amps),...
                           length(uniq_freqs),...
                           length(obj.selection));

        colors = flip(colors,1);

        uniq_counts = [length(uniq_types), length(uniq_amps)];
        [B, I] = sort(uniq_counts);

        if (I(2) == 1)
            common_var = uniq_types;
        else
            common_var = string(uniq_amps);
        end

        ax = axes(plot_panel);
        hold(ax, 'on');
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);

            name_parts = split(cur_sel,"_");

            for j = 1:length(name_parts)
                if contains(name_parts{j}, "deg")
                    amp = str2double(extractBefore(name_parts{j}, "deg"));
                    type = string(name_parts{j-1});
                elseif contains(name_parts{j}, "Hz")
                    freq = str2double(extractBefore(name_parts{j}, "Hz"));
                end
            end

            filename = cur_sel + "_phase_avg.mat";

            if ismember(obj.index,[1,2])
                vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
            end

            switch obj.index
                case 1
                    switch obj.method
                        case 1
                            var_name = "lift_vel";
                        case 2
                            var_name = "lift";
                    end
                case 2
                    switch obj.method
                        case 1
                            var_name = "drag_vel";
                        case 2
                            var_name = "drag";
                    end
                case 3
                    var_name = "phase_avg_speed";
                case 4
                    var_name = "phase_avg_volt";
                case 5
                    var_name = "phase_avg_cur";
            end

            if ismember(obj.index,[1,2])
                d = load(obj.data_path + filename, vars{:});

                % Compute Lift force
                avg_type = 1;
                y_cen = -0.142 / d.L;
                z_cen = -0.03 / d.L;
    
                % 1. Capture all outputs into a cell array
                [outputs{1:4}] = get_wake_lift(d.U, d.L, d.y, d.z, d, avg_type, y_cen, z_cen);
                
                % 2. Define your field names
                fields = {'lift_vel', 'lift', 'drag_vel', 'drag'};
                
                % 3. Convert to a struct
                F = cell2struct(outputs, fields, 2);
    
                var = F.(var_name);
            else
                d = load(obj.data_path + filename, var_name);
                var = d.(var_name);
            end
            
            load(obj.data_path + filename, "phase_avg_speed")
            freq_cor = mean(phase_avg_speed);

            if obj.sub
                % filename = "body_phase_avg.mat";
                filename = "ring_time_avg.mat";
                d = load(obj.data_path + "time_avg/" + filename, var_name);
                var = var - d.(var_name);
            end

            % Shift data given convection time downstream to target
            if ismember(obj.index,[1,2])
            dist = 0.9;
            speed = 4;
            conv_time = dist / speed; % 0.9 m downstream, 4 m/s
            shift = conv_time * freq;
            var = circshift(var, round(shift*length(var)));
            end

            % If first value less than mean value, shift array since we
            % must have started on the other midstroke position
            % if var(1) < min(var) + range(var)/3
            %     var = circshift(var, 0.4*length(var));
            %     disp("Shifted STB curve for " + cur_sel)
            % end

            time = 1:length(var);
            time = time / length(var);

            if obj.force_bool
            % path = "Y:\Force Measurements\" + type + "_" + amp + "deg" +...
            %     "\4 m.s\flexible_2026_03_22\processed data\";

            % 1. Define the parent directory
            parentDir = "Y:\Force Measurements\" + type + "_" + amp + "deg" + "\4 m.s\";
            
            % 2. Get a list of everything inside that folder
            % We filter for directories only ([parentDir, '\*']) to be safe
            contents = dir(parentDir);
            
            % 3. Remove the '.' and '..' (which are always present in file systems)
            % and filter for actual folders
            contents = contents([contents.isdir] & ~ismember({contents.name}, {'.', '..'}));
            
            % 4. Since there is only one folder, we grab the first (and only) name
            dynamicFolderName = contents(1).name;

            path = parentDir + dynamicFolderName + "\processed data\";

            contents = dir(path);
            files = contents(~[contents.isdir]);

            for j = 1:length(files)
                cur_name = files(j).name;
                if contains(cur_name, "10deg") && contains(cur_name, freq + "Hz")
                    force_filename = files(j).name;
                end
            end

            % var_name_F = "wingbeat_avg_forces_raw";
            % var_name_F = "wingbeat_avg_forces";
            var_name_F = "wingbeat_avg_forces_smoothest";
            c = load(path + force_filename, var_name_F);
            var_F = c.(var_name_F);

            switch obj.index
                case 1
                    force = var_F(3,:);
                case 2
                    force = var_F(1,:);
            end

            time_F = 1:length(force);
            time_F = time_F / length(force);

            if force(1) < mean(force)
                force = circshift(force, round(0.4*length(force)));
                disp("Shifted force curve for " + cur_sel)
            end
            end

            % Get color for this case name
            sels = [type, amp];
            original_color = colors(find(uniq_freqs == freq), find(common_var == sels(I(2)))); % hex

            line = plot(ax, time, var);
            line.DisplayName = strrep(cur_sel,"_"," ");
            line.Color = original_color;
            line.LineWidth = 2;

            if obj.force_bool
                line = plot(ax, time_F, force);
                line.DisplayName = strrep(cur_sel,"_"," ") + " F";
                line.Color = original_color;
                line.LineWidth = 2;
                line.LineStyle = "--";
            end
        end
        hold(ax, 'off');

        grid(ax, 'on');
        l = legend(ax, Location="northeast");
        ylabel(ax, obj.y_labels(obj.index))
        ax.FontSize = 18;

        if (obj.saveFig)
            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            fignew.Position = [500,491,800,600];
            if (exist("l", "var"))
                copyobj([l ax], fignew); % Copy the appropriate axes
            elseif (exist("cb", "var"))
                copyobj([ax cb], fignew); % Copy the appropriate axes
            else
                copyobj(ax, fignew); % Copy the appropriate axes
            end

            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

        return

        if (~isempty(obj.selection))
        % Parse selected cases
        [uniq_types, uniq_speeds, uniq_freqs] = compareWingbeatUI.getUniqParams(obj.selection, obj.sel_bird, obj.sub);
        
        % Get all type folders in the speed folders
        type_dir_names = [];
        for i = 1:length(uniq_speeds)
            speed_path = obj.data_path + obj.sel_bird.name + "/" + uniq_speeds(i) + " m.s/";
            type_dir_names = [type_dir_names; dir(speed_path)];
        end
        
        % remove . and .. directories
        ind_to_remove = [];
        for i = 1:length(type_dir_names)
            if (type_dir_names(i).name == "." || type_dir_names(i).name == "..")
                ind_to_remove = [ind_to_remove i];
            end
        end
        type_dir_names(ind_to_remove) = [];

        if isempty(type_dir_names)
            error("No type directories found...")
        end
        
        paths = [];
        % path to folders where processed data (.mat files) are stored
        for i = 1:length(type_dir_names)
            cur_name_parts = split(type_dir_names(i).name);
            cur_type = strrep(cur_name_parts{1},'_',' ');
            cur_speed = string(extractBefore(extractAfter(type_dir_names(i).folder, obj.sel_bird.name + "\")," m.s"));
            if (sum(uniq_types == cur_type) > 0 && sum(uniq_speeds == str2double(cur_speed)) > 0) % find matches
                filepath = obj.data_path + obj.sel_bird.name + "/" + cur_speed + " m.s/" + type_dir_names(i).name;
                processed_data_path = filepath + "/processed data/";
                paths = [paths processed_data_path];
            end
        end
        
        processed_data_files = [];
        for i = 1:length(paths)
            processed_data_path = paths(i);
            processed_data_files = [processed_data_files; compareWingbeatUI.getFiles(processed_data_path, '*.mat')];
        end

        if isempty(processed_data_files)
            error("No processed data files found...")
        end

        colors = getColors(length(uniq_types), length(uniq_speeds), length(uniq_freqs), length(obj.selection));

        uniq_counts = [length(uniq_types), length(uniq_speeds)];
        [B, I] = sort(uniq_counts);
        
        if (I(2) == 1)
            common_var = uniq_types;
        else
            common_var = string(uniq_speeds);
        end

        end

        if (length(obj.selection) > 1)
            [abbr_sel] = compareWingbeatUI.get_abbr_names(obj.selection);
        end
    
        ax = axes(plot_panel);
        idx = obj.index;

        last_freq = 0;
        last_speed = 0;
        for i = 1:length(obj.selection)
        
        [cur_type, cur_speed, cur_freq, cur_angle] = compareWingbeatUI.parseCases(obj.selection(i));
        wing_freq = str2double(extractBefore(cur_freq, " Hz"));

        flapper_name = string(extractBefore(obj.selection(i), "/"));
        cur_bird = getBirdFromName(flapper_name, obj.Calimero);

        % Get color for this case name
        sels = [cur_type, cur_speed];
        original_color = colors(find(uniq_freqs == cur_freq), find(common_var == sels(I(2)))); % hex
        lighter_color = getLightColor(original_color); % RGB

        % Using what all case names have in common, come up
        % with an abbreviated name
        case_name = cur_type + " " + cur_speed + " m/s " + cur_freq + " " + cur_angle + " deg";
        if (exist("abbr_sel", "var"))
            abbr_name = compareWingbeatUI.getAbbrName(case_name, abbr_sel);
        else
            abbr_name = case_name;
        end

        % Find exact filename matching this case
        [data_filename, data_folder]...
            = compareWingbeatUI.findMatchFile(cur_type, cur_speed, cur_freq, cur_angle, cur_bird.freqs, processed_data_files);

        [frames, cycle_avg_forces, upper_results, lower_results,...
         time, inertial_force, added_mass_force, aero_force, total_force] = ...
        obj.get_forces(data_folder, data_filename, processed_data_files,...
                       cur_bird, cur_type, cur_speed, cur_freq, cur_angle);

        if (~obj.norm_period)
            % Scale x-axis back to time domain
            frames = (frames / wing_freq);
        end

        hold(ax, 'on');
        xconf = [frames, frames(end:-1:1)];         
        yconf = [upper_results(idx, :), lower_results(idx, end:-1:1)];
        p = fill(ax, xconf, yconf, lighter_color);
        p.HandleVisibility = 'off';      
        p.EdgeColor = 'none';
        line = plot(ax, frames, cycle_avg_forces(idx, :));
        line.DisplayName = abbr_name;
        line.Color = original_color;
        line.LineWidth = 2;

        abbr_name_chars = convertStringsToChars(abbr_name);
        % v added to struct name since it can't start with a
        % numeric value
        struct_name = "v" + abbr_name_chars(~isspace(abbr_name_chars));
        % obj.plot_curves.(struct_name) = [frames; cycle_avg_forces(idx, :)];

        if (last_freq ~= wing_freq || last_speed ~= cur_speed)
        obj.plot_model(idx, ax, original_color, time, inertial_force, added_mass_force, aero_force, total_force, abbr_name);
        last_freq = wing_freq;
        last_speed = cur_speed;
        end
        hold(ax, 'off');

        end

        title(ax, titles(idx));
        xlabel(ax, x_label);
        ylabel(ax, y_labels(idx))
        grid(ax, 'on');
        l = legend(ax, Location="northeast");
        ax.FontSize = 18;
    end

    function [frames, cycle_avg_forces, upper_results, lower_results,...
              time, inertial_force, added_mass_force, aero_force, total_force] = ...
            get_forces(obj, data_folder, data_filename, processed_data_files,...
            cur_bird, sel_type, sel_speed, sel_freq, sel_angle)
        AR = cur_bird.AR;
        if (obj.sub)
            sub_type = compareWingbeatUI.getSubType(sel_type, cur_bird);
        end

        thinAirfoil = true;
        disp("THIN AIRFOIL IS: " + thinAirfoil)
        if thinAirfoil
            lift_slope = ((2*pi) / (1 + 2/AR));
            pitch_slope = -lift_slope / 4;
            zero_lift_alpha = 0;
            zero_pitch_alpha = 0;
        else
            % Find slopes for all wind speeds and average
            path = obj.data_path + "plot data/" + cur_bird.name;
            range = [-16, 16];
            dir_name = compareWingbeatUI.getDataFolder(cur_bird.name, sel_type, sel_speed, obj.norm);
            [lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha] ...
                = getGlideSlopesFromData(path, cur_bird, dir_name, range);
        end
        disp("Lift Slope: " + lift_slope)
        disp("Pitch Slope: " + pitch_slope)

        [center_to_LE, chord, ~, ~, ~] = getWingMeasurements(cur_bird.name);

        % Load data from file
        [frames, cycle_avg_forces, cycle_std_forces, ...
            cycle_min_forces, cycle_max_forces, cycle_rmse_forces, norm_factors] ...
        = compareWingbeatUI.load_data(data_folder, data_filename, obj.filt_num, obj.pitch_shift, center_to_LE, sel_angle, obj.norm);

        if (obj.sub)
        % Find exact filename matching this case
        try
        [sub_filename, sub_folder] = compareWingbeatUI.findMatchFile(sub_type, sel_speed, sel_freq, sel_angle, cur_bird.freqs, processed_data_files);
        catch ME
        error("Are you sure that subtraction data exists?")
        end

        disp("Subtracting from: " + sub_folder + "  /  " + sub_filename)

        % Load data from file
        [sub_frames, sub_cycle_avg_forces, sub_cycle_std_forces, ...
            sub_cycle_min_forces, sub_cycle_max_forces, sub_cycle_rmse_forces, sub_norm_factors] ...
        = compareWingbeatUI.load_data(sub_folder, sub_filename, obj.filt_num, obj.pitch_shift, center_to_LE, sel_angle, obj.norm);

        cycle_avg_forces = cycle_avg_forces - sub_cycle_avg_forces;
        cycle_std_forces = cycle_std_forces + sub_cycle_std_forces;

        % How should the following be modified by
        % subtraction?
        % cycle_min_forces = cycle_min_forces;
        % cycle_max_forces = cycle_max_forces;
        % cycle_rmse_forces = cycle_rmse_forces;
        end

        upper_results = cycle_avg_forces + cycle_std_forces;
        lower_results = cycle_avg_forces - cycle_std_forces;
    end
end

end