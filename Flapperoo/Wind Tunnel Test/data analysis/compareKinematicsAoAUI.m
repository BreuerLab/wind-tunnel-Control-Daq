classdef compareKinematicsAoAUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    data_path;

    selection;

    Flapperoo;
    MetaBird;
    sel_bird;

    sel_freq;
    sel_speed;
    range;

    % booleans
    st;

    plot_id;
end

methods
    function obj = compareKinematicsAoAUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.selection = strings(0);
        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");
        
        obj.sel_bird = obj.Flapperoo;
        obj.sel_freq = obj.sel_bird.freqs(1);
        obj.sel_speed = obj.sel_bird.speeds(1);
        obj.range = [-16 16];

        obj.st = false;

        obj.plot_id = "Effective AoA";
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

        % Dropdown box for wingbeat frequency selection
        drop_y3 = drop_y1 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        d3.Items = obj.sel_bird.freqs;
        d3.ValueChangedFcn = @(src, event) freq_change(src, event);

        % Dropdown box for wind speed selection
        drop_y4 = drop_y3 - (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [10 drop_y4 180 unit_height];
        d4.Items = obj.sel_bird.speeds + " m/s";
        d4.ValueChangedFcn = @(src, event) speed_change(src, event);

        % FIX THIS LINE
        d1.ValueChangedFcn = @(src, event) flapper_change(src, event, d2, d3);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = drop_y4 - (unit_height + unit_spacing);
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

        % Dropdown box for plot type selection
        drop_y6 = list_y - (unit_height + unit_spacing);
        d6 = uidropdown(option_panel);
        d6.Position = [10 drop_y6 180 unit_height];
        d6.Items = ["Effective AoA", "Effective Wind"];
        d6.ValueChangedFcn = @(src, event) plot_type_change(src, event, plot_panel);

        button3_y = drop_y6 - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "St Scaling";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) st_change(src, event, plot_panel);

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
        function flapper_change(src, ~, type_box, speed_box)
            if (src.Value == "Flapperoo")
                obj.sel_bird = obj.Flapperoo;
            elseif (src.Value == "MetaBird")
                obj.sel_bird = obj.MetaBird;
            else
                error("This bird selection is not recognized.")
            end
            type_box.Items = obj.sel_bird.types;
            speed_box.Items = obj.sel_bird.speeds + " m/s";

            obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
            obj.sel_speed = obj.sel_bird.speeds(1);

            type_box.Value = obj.sel_bird.types(1);
            speed_box.Value = obj.sel_bird.speeds(1) + " m/s";
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~)
            obj.sel_freq = src.Value;
        end

        % update speed variable with new value selected by user
        function speed_change(src, ~)
            speed = str2double(extractBefore(src.Value, " m/s"));
            obj.sel_speed = speed;
        end
    
        function addToList(~, ~, plot_panel, lbox)
            case_name = obj.sel_bird.name + "/" + obj.sel_speed + " m/s " + obj.sel_freq;

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

            % removing value from object's list
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
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

        function plot_type_change(src, ~, plot_panel)
            obj.plot_id = convertCharsToStrings(src.Value);
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
    function [flapper_name, sel_speed, sel_freq] = parseSelection(sel)
        flapper_name = string(extractBefore(sel, "/"));
        dir_name = string(extractAfter(sel, "/"));

        dir_parts = split(dir_name, ' ');
        for k = 1:length(dir_parts)
            if (contains(dir_parts(k), "m/s"))
                sel_speed = str2double(dir_parts(k-1));
            elseif (contains(dir_parts(k), "Hz"))
                sel_freq = str2double(dir_parts(k-1));
            end
        end
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

methods (Access = private)
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)

        x_label = "Angle of Attack";
        if (obj.plot_id == "Effective AoA")
            y_label = "Effective AoA (deg)";
            sub_title = "Effective AoA";
        elseif (obj.plot_id == "Effective Wind")
            y_label = "Effective Wind Speed (m/s)";
            sub_title = "Effective Wind Speed";
        end

        if (~isempty(obj.selection))
        uniq_speeds = [];
        uniq_freqs = [];
        for j = 1:length(obj.selection)
            [flapper_name, cur_speed, cur_freq] = compareKinematicsAoAUI.parseSelection(obj.selection(j));

            if (sum(uniq_speeds == cur_speed) == 0)
                uniq_speeds = [uniq_speeds cur_speed];
            end
            if (sum(strcmp(uniq_freqs, cur_freq)) == 0)
                uniq_freqs = [uniq_freqs cur_freq];
            end
        end

        abbr_sel = compareKinematicsAoAUI.get_abbr_names(obj.selection);
        colors = getColors(1, length(uniq_freqs), length(uniq_speeds), length(obj.selection));
        end

        % -----------------------------------------------------
        % -------------------- Plotting -----------------------
        % -----------------------------------------------------
        ax = axes(plot_panel);
        hold(ax, 'on');

        AoA_vals = linspace(obj.range(1), obj.range(2), 30);

        for i = 1:length(obj.selection)
            [flapper_name, cur_speed, cur_freq] = compareKinematicsAoAUI.parseSelection(obj.selection(i));

            [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements(flapper_name);

            amp = -1;
            [time, ang_disp, ang_vel, ang_acc] = get_kinematics(obj.data_path, cur_freq, amp);
            
            full_length = wing_length + arm_length;
            r = arm_length:0.001:full_length;
            lin_disp = cosd(ang_disp) * r;
            lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;
            lin_acc = (deg2rad(ang_acc) .* cosd(ang_disp)) * r;
            
            mean_eff_AoA = zeros(size(AoA_vals));
            mean_u_rel = zeros(size(AoA_vals));
            for j = 1:length(AoA_vals)
                cur_angle = AoA_vals(j);
                [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, cur_angle, cur_speed);
                mean_eff_AoA(j) = mean(eff_AoA, 'all');
                mean_u_rel(j) = mean(u_rel, 'all');
            end

            if (obj.plot_id == "Effective AoA")
                y_var = mean_eff_AoA;
            elseif (obj.plot_id == "Effective Wind")
                y_var = mean_u_rel;
            end

            p = plot(ax, AoA_vals, y_var);
            p.LineWidth = 2;
            p.DisplayName = abbr_sel(i);

        end

        title(ax, sub_title);
        xlabel(ax, x_label);
        ylabel(ax, y_label)
        grid(ax, 'on');
        ax.FontSize = 18;
        legend(ax)
    end
end
end