classdef compareStabilityUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    data_path;

    selection;

    % force and moment axes labels used in dropdown box
    range;

    Flapperoo;
    MetaBird;
    sel_bird;

    sel_type;
    sel_speed;

    % booleans
    sub;
    norm;
    st;
    shift;
    drift;
    aero_model;
end

methods
    function obj = compareStabilityUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.selection = strings(0);
        obj.range = [-16 16];
        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");
        
        obj.sel_bird = obj.Flapperoo;
        obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
        obj.sel_speed = obj.sel_bird.speeds(1);

        obj.sub = false;
        obj.norm = false;
        obj.st = false;
        obj.shift = false;
        obj.drift = false;
        obj.aero_model = false;

        for i = 1:2
            path = obj.data_path;
        if i == 1
            path = path + "/plot data/" + "Flapperoo/";
            cur_bird = obj.Flapperoo;
        elseif i == 2
            path = path  + "/plot data/" + "MetaBird/";
            cur_bird = obj.MetaBird;
        end
        % Get a list of all files in the folder with the desired file name pattern.
        filePattern = fullfile(path, '*.mat');
        theFiles = dir(filePattern);
        
        % Grab each file and process the data from that file, storing the results
        for k = 1 : length(theFiles)
            baseFileName = convertCharsToStrings(theFiles(k).name);
            parsed_name = extractBefore(baseFileName, "_saved");

            [data_struct] = compareStabilityUI.get_file_structure(path, baseFileName, parsed_name);
            cur_bird.file_list = [cur_bird.file_list data_struct];

            case_name = extractBefore(baseFileName, "._");

            % Add to list if not already on list
            if (isempty(cur_bird.uniq_list) || sum([cur_bird.uniq_list.dir_name] == case_name) == 0)
                [data_struct] = compareStabilityUI.get_file_structure(path, baseFileName, case_name);
                data_struct.file_name = [];
                cur_bird.uniq_list = [cur_bird.uniq_list data_struct];
            end

            if (contains(parsed_name, "norm"))
                data_struct = compareStabilityUI.get_file_structure(path, baseFileName, parsed_name);
                cur_bird.norm_list = [cur_bird.norm_list data_struct];
            end
            if (contains(parsed_name, "shift"))
                data_struct = compareStabilityUI.get_file_structure(path, baseFileName, parsed_name);
                cur_bird.shift_list = [cur_bird.shift_list data_struct];
            end
            if (contains(parsed_name, "drift"))
                data_struct = compareStabilityUI.get_file_structure(path, baseFileName, parsed_name);
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
    end

    function dynamic_plotting(obj)

        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
       
        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        % Dropdown box for flapper selection
        drop_y1 = screen_height - round(0.06*screen_height);
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.Items = ["Flapperoo", "MetaBird"];

        % Dropdown box for flapper type selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 30];
        d2.Items = obj.sel_bird.types;
        d2.ValueChangedFcn = @(src, event) type_change(src, event);

        % Dropdown box for wind speed selection
        drop_y4 = drop_y2 - (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [10 drop_y4 180 unit_height];
        d4.Items = obj.sel_bird.speeds + " m/s";
        d4.ValueChangedFcn = @(src, event) speed_change(src, event);

        d1.ValueChangedFcn = @(src, event) flapper_change(src, event, d2, d3, d4);

        % Subtraction Case Selection
        button1_y = drop_y4 - (unit_height + unit_spacing);
        b1 = uibutton(option_panel,"state");
        b1.Text = "Subtraction";
        b1.Position = [20 button1_y 160 unit_height];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) subtraction_change(src, event, plot_panel);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = button1_y - (unit_height + unit_spacing);
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

        button3_y = list_y - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "Normalize Moment";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) norm_change(src, event, plot_panel);

        button4_y = button3_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel,"state");
        b5.Text = "St Scaling";
        b5.Position = [20 button4_y 160 unit_height];
        b5.BackgroundColor = [1 1 1];
        b5.ValueChangedFcn = @(src, event) st_change(src, event, plot_panel);

        button5_y = button4_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel,"state");
        b6.Text = "Shift Pitch Moment";
        b6.Position = [20 button5_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) shift_change(src, event, plot_panel);

        button6_y = button5_y - (unit_height + unit_spacing);
        b7 = uibutton(option_panel,"state");
        b7.Text = "Drift Correction";
        b7.Position = [20 button6_y 160 unit_height];
        b7.BackgroundColor = [1 1 1];
        b7.ValueChangedFcn = @(src, event) drift_change(src, event, plot_panel);

        button7_y = button6_y - (unit_height + unit_spacing);
        b8 = uibutton(option_panel,"state");
        b8.Text = "Aerodynamics Model";
        b8.Position = [20 button7_y 160 unit_height];
        b8.BackgroundColor = [1 1 1];
        b8.ValueChangedFcn = @(src, event) model_change(src, event, plot_panel);

        AoA_y = 0.05*screen_height;
        s = uislider(option_panel,"range");
        s.Position = [10 AoA_y 180 3];
        s.Limits = obj.range;
        s.Value = obj.range;
        s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        s.ValueChangedFcn = @(src, event) AoA_change(src, event, plot_panel);

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
        function flapper_change(src, ~, type_box, freq_box, speed_box)
            if (src.Value == "Flapperoo")
                obj.sel_bird = obj.Flapperoo;
            elseif (src.Value == "MetaBird")
                obj.sel_bird = obj.MetaBird;
            else
                error("This bird selection is not recognized.")
            end
            type_box.Items = obj.sel_bird.types;
            freq_box.Items = obj.sel_bird.freqs;
            speed_box.Items = obj.sel_bird.speeds + " m/s";

            obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
            obj.sel_speed = obj.sel_bird.speeds(1);

            type_box.Value = obj.sel_bird.types(1);
            freq_box.Value = obj.sel_bird.freqs(1);
            speed_box.Value = obj.sel_bird.speeds(1) + " m/s";
        end

        % update type variable with new value selected by user
        function type_change(src, ~)
            obj.sel_type = nameToType(obj.sel_bird.name, src.Value);
        end

        % update speed variable with new value selected by user
        function speed_change(src, ~)
            speed = str2double(extractBefore(src.Value, " m/s"));
            obj.sel_speed = speed;
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
            sel_name = compareStabilityUI.typeToSel(obj.sel_bird.name, obj.sel_type);
            speed = obj.sel_speed + "m.s";
            folder = sel_name + " " + speed;
            case_name = obj.sel_bird.name + "/" + strrep(folder, " ", "_");

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

            % removing value from list used for plotting
            if (obj.norm)
                flapper_name = string(extractBefore(obj.selection(i), "/"));
                dir_name = string(extractAfter(obj.selection(i), "/"));

                wing_freq = str2double(extractBefore(trial_name, " Hz"));
                dir_parts = split(dir_name, '_');
                wind_speed = sscanf(dir_parts(end), '%g', 1);

                St = freqToSt(obj.sel_bird.name, wing_freq, wind_speed);
                case_name = dir_name + "/" + ['St: ' num2str(St)];
            end
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function norm_change(src, ~, plot_panel)
            if (src.Value)
                obj.norm = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.norm = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function st_change(src, ~, plot_panel)
            if (src.Value)
                obj.st = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.st = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function shift_change(src, ~, plot_panel)
            if (src.Value)
                obj.shift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.shift = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function drift_change(src, ~, plot_panel)
            if (src.Value)
                obj.drift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.drift = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function model_change(src, ~, plot_panel)
            if (src.Value)
                obj.aero_model = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.aero_model = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end
    
        function AoA_change(src, ~, plot_panel)
            % ensure that slider can only be moved to discrete
            % acceptable locations where a measurement was
            % recorded
            AoA = obj.sel_bird.angles;
            [M, I] = min(abs(AoA - src.Value(1)));
            AoA_min = AoA(I);
            [M, I] = min(abs(AoA - src.Value(2)));
            AoA_max = AoA(I);
            src.Value = [AoA_min AoA_max];
    
            % update range property
            obj.range = src.Value;
    
            obj.update_plot(plot_panel);
        end
        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)

    function sel = typeToSel(flapper, type)
        if (flapper == "Flapperoo")
            if (type == "blue wings")
                sel = "Full Wings";
            elseif (type == "tail blue wings")
                sel = "Tail Wings";
            elseif (type == "blue wings half body")
                sel = "Half Wings";
            elseif (type == "no wings")
                sel = "Full Body";
            elseif (type == "tail no wings")
                sel = "Tail Body";
            elseif (type == "half body no wings")
                sel = "Half Body";
            elseif (type == "inertial wings")
                sel = "Full Inertial";
            else
                sel = type;
            end
        elseif (flapper == "MetaBird")
            if (type == "full body short tail low")
                sel = "Tail Low Wings";
            end
        else
            sel = type;
        end
    end

    function [sub_title, abbr_sel] = get_abbr_names(sel)
        sub_title = "";
        abbr_sel = "";
        if (isscalar(sel))
            abbr_sel = strrep(strrep(sel, "_", " "), "/", " ");
        elseif (length(sel) > 1)
        flappers = [];
        types = [];
        speeds = [];
        freqs = [];

        for i = 1:length(sel)
            flapper_name = string(extractBefore(sel(i), "/"));
            dir_name = string(extractAfter(sel(i), "/"));
            
            dir_parts = split(dir_name, '_');
            type = strjoin(dir_parts(1:end-1));
            wind_speed = sscanf(dir_parts(end), '%g', 1);

            flappers = [flappers flapper_name];
            types = [types type];
            speeds = [speeds wind_speed];
        end

        num_uniq_flappers = length(unique(flappers));
        num_uniq_types = length(unique(types));
        num_uniq_speeds = length(unique(speeds));

        % For attributes shared by all cases, add to sub_title
        if (num_uniq_flappers == 1)
            sub_title = sub_title + flapper_name + " ";
        end
        if (num_uniq_types == 1)
            sub_title = sub_title + type + " ";
        end
        if (num_uniq_speeds == 1)
            sub_title = sub_title + wind_speed + " m/s ";
        end

        for i = 1:length(sel)
            flapper_name = string(extractBefore(sel(i), "/"));
            dir_name = string(extractAfter(sel(i), "/"));
            
            dir_parts = split(dir_name, '_');
            type = strjoin(dir_parts(1:end-1)) + " ";
            wind_speed = dir_parts(end) + " ";

            if (num_uniq_flappers == 1)
                flapper_name = "";
            end
            if (num_uniq_types == 1)
                type = "";
            end
            if (num_uniq_speeds == 1)
                wind_speed = "";
            end

            cur_abbr_sel = flapper_name + type + wind_speed;
            abbr_sel(i) = cur_abbr_sel;
        end
        end
    end

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

    function aero_force = get_model(flapper, path, AoA_list, freq, speed)
        C_L_vals = zeros(1, length(AoA_list));
        C_D_vals = zeros(1, length(AoA_list));
        C_N_vals = zeros(1, length(AoA_list));
        C_M_vals = zeros(1, length(AoA_list));
        aero_force = zeros(6, length(AoA_list));

        [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, freq, true);
            
        [center_to_LE, chord, COM_span, ...
            wing_length, arm_length] = getWingMeasurements(flapper);
        
        full_length = wing_length + arm_length;
        r = arm_length:0.001:full_length;
        lin_vel = deg2rad(ang_vel) * r;

        thinAirfoil = true;
        if (flapper == "Flapperoo")
            single_AR = 2.5;
        elseif (flapper == "MetaBird")
            single_AR = 2.5; % NEEDS UPDATING
        else
            error("Oops. Unknown flapper")
        end

        for i = 1:length(AoA_list)
            AoA = AoA_list(i);
            
            [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, speed);
            
            [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, speed, wing_length, thinAirfoil, single_AR);
            
            C_L_vals(i) = mean(C_L);
            C_D_vals(i) = mean(C_D);
            C_N_vals(i) = mean(C_N);
            C_M_vals(i) = mean(C_M);
        end

        aero_force(1,:) = C_D_vals;
        aero_force(3,:) = C_L_vals;
        aero_force(5,:) = C_M_vals;
    end

    function idx = findClosestStString(strToMatch, strList)
        cur_St = str2double(extractAfter(strToMatch, "St: ")); % fails for v2 cases
        available_Sts = [];
        for k = 1:length(strList)
            St_num = str2double(extractAfter(strList(k), "St: "));
            if (~isnan(St_num))
                available_Sts = [available_Sts St_num];
            end
        end
        [M, I] = min(abs(available_Sts - cur_St));
        idx = I;
        disp("Closest match to St: " + cur_St + " is St: " + available_Sts(I))
    end

end

methods (Access = private)
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)
        
        struct_matches = [];
        for i = 1:length(obj.selection)
            flapper_name = string(extractBefore(obj.selection(i), "/"));
            dir_name = string(extractAfter(obj.selection(i), "/"));

            cur_bird = getBirdFromName(flapper_name, obj.Flapperoo, obj.MetaBird);

            if (obj.sub)
                    dir_parts = split(dir_name, '_');
                    dir_parts(2) = "Sub";
                    dir_name = strjoin(dir_parts, "_");
            end

            if (obj.norm)
                if (obj.shift)
                    if (obj.drift)
                        shortened_list = intersect(intersect([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                                   [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(intersect([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                                 [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                else
                    if (obj.drift)
                        shortened_list = intersect(setdiff([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                                   [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(setdiff([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                                 [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                end
            else
                if (obj.shift)
                    if (obj.drift)
                        shortened_list = intersect(intersect(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                        [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(intersect(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                        [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                else
                    if (obj.drift)
                        shortened_list = intersect(setdiff(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                        [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(setdiff(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                        [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                end
            end

            for j = 1:length(cur_bird.file_list)
                if (cur_bird.file_list(j).file_name == name_match)
                    struct_match = cur_bird.file_list(j);
                    selector = char(obj.selection(i));
                    struct_match.selector = string(selector);
                end
            end

            % check for repeat files to load
            if (length(struct_matches) == 0 || sum(contains([struct_matches.dir_name], struct_match.dir_name)) == 0)
                struct_matches = [struct_matches struct_match];
            end
        end
        disp("Found following matches:")
        disp(struct_matches)

        if (length(struct_matches) ~= length(obj.selection))
            disp("--------------------------------------------")
            disp("Oops looks like a data file is missing")
            disp("--------------------------------------------")
        end

        if (obj.st)
            x_label = "Strouhal Number";
        else
            x_label = "Wingbeat Frequency (Hz)";
        end

        if (obj.norm)
            y_label = "Normalized Pitch Stability Slope";
        else
            y_label = "Pitch Stability Slope";
        end

        if (~isempty(obj.selection))
        unique_dir = [];
        unique_speeds = [];
        unique_types = [];
        for j = 1:length(obj.selection)
            flapper_name = string(extractBefore(obj.selection(j), "/"));
            dir_name = string(extractAfter(obj.selection(j), "/"));

            if (obj.sub)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
            end

            dir_parts = split(dir_name, '_');
            wind_speed = sscanf(dir_parts(end), '%g', 1);
            type = strjoin(dir_parts(1:end-1));

            if(isempty(unique_speeds) || sum(unique_speeds == wind_speed) == 0)
                unique_speeds = [unique_speeds wind_speed];
            end
            if(isempty(unique_types) || sum(unique_types == type) == 0)
                unique_types = [unique_types type];
            end
            if(isempty(unique_dir) || sum([unique_dir.dir_name] == dir_name) == 0)
                data_struct.dir_name = dir_name;
                unique_dir = [unique_dir data_struct];
            end
        end

        colors = getColors(1, length(unique_types), length(unique_speeds), length(obj.selection));
        end
        [sub_title, abbr_sel] = compareStabilityUI.get_abbr_names(obj.selection);

        % -----------------------------------------------------
        % -------------------- Plotting -----------------------
        % -----------------------------------------------------
        ax = axes(plot_panel);

        last_t_ind = 0;
        last_s_ind = 0;
        for i = 1:length(obj.selection)
            for j = 1:length(struct_matches)
                if (obj.selection(i) == struct_matches(j).selector)
                    cur_struct_match = struct_matches(j);
                    break;
                end
            end

            flapper_name = string(extractBefore(obj.selection(i), "/"));
            dir_name = string(extractAfter(obj.selection(i), "/"));

            cur_bird = getBirdFromName(flapper_name, obj.Flapperoo, obj.MetaBird);

            dir_parts = split(dir_name, '_');

            if (obj.sub)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
            end

            dir_parts = split(dir_name, '_');
            wind_speed = sscanf(dir_parts(end), '%g', 1);
            s_ind = find(unique_speeds == wind_speed);

            type = strjoin(dir_parts(1:end-1));
            t_ind = find(unique_types == type);

            lim_AoA_sel = cur_bird.angles(cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2));
            
            cur_file = obj.data_path + "/plot data/" + cur_bird.name + "/" + cur_struct_match.file_name;
            disp("Loading " + cur_file)
            load(cur_file, "avg_forces", "err_forces")
            lim_avg_forces = avg_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
            lim_err_forces = err_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);

            slopes = [];
            err_slopes = [];
            for k = 1:length(cur_bird.freqs) - 2
                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = lim_avg_forces(idx,:,k)';
                b = x\y;
                model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
                err_slopes = [err_slopes SE_slope];
                slopes = [slopes b(2)];
            end

            wing_freqs = cur_bird.freqs;
            wing_freqs = str2double(extractBefore(wing_freqs, " Hz"));
            wing_freqs = wing_freqs(1:end-2);
            
            % Get Quasi-Steady Model Force
            % Predictions
            mod_slopes = [];
            if (obj.aero_model)
                for k = 1:length(wing_freqs)
                wing_freq = wing_freqs(k);
                aero_force = compareStabilityUI.get_model(cur_bird.name, obj.data_path, lim_AoA_sel, wing_freq, wind_speed);

                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = aero_force(idx,:)';
                b = x\y;
                % model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                mod_slopes = [mod_slopes b(2)];
                end
            end

            hold(ax, 'on');

            if (obj.st)
                St = freqToSt(cur_bird.name, wing_freqs, wind_speed);
                x_vals = St;
            else
                x_vals = wing_freqs;
            end
            
            e = errorbar(ax, x_vals, slopes, err_slopes, '.');
            e.MarkerSize = 25;
            e.Color = colors(s_ind, t_ind);
            e.MarkerFaceColor = colors(s_ind, t_ind);
            e.DisplayName = abbr_sel(i);
            
            % ---------Plotting model-----------
            % aerodynamics model is nondimensionalized, so
            % data should also be nondimensionalized when
            % comparing the two. Also only occurs if
            % frequency or wind speed have changed
            if (obj.norm && obj.aero_model)
            e = errorbar(ax, x_vals, mod_slopes, zeros(1,length(mod_slopes)), '.');
            e.MarkerSize = 25;
            e.Color = colors(s_ind, t_ind);
            e.MarkerFaceColor = colors(s_ind, t_ind);
            e.DisplayName = "Model: " + abbr_sel(i);
            end

        end

        title(ax, sub_title);
        xlabel(ax, x_label);
        ylabel(ax, y_label)
        grid(ax, 'on');
        legend(ax, Location="best");
        ax.FontSize = 18;
    end
end
end