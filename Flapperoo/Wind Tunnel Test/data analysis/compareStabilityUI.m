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
    thinAirfoil;
    amplitudes;
    saveFig;
    logScale;
    zeroSlope;
    constSM;
    u_eff;

    x_var;
    y_var;
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
        obj.thinAirfoil = false;
        obj.saveFig = false;
        obj.logScale = false;
        obj.zeroSlope = false;
        obj.constSM = false;
        obj.u_eff = false;

        obj.x_var = 1;
        obj.y_var = 1;

        for i = 1:2
            path = obj.data_path;
            if i == 1
                path = path + "/plot data/" + "Flapperoo/";
                cur_bird = obj.Flapperoo;
            elseif i == 2
                path = path  + "/plot data/" + "MetaBird/";
                cur_bird = obj.MetaBird;
            end
            attachFileListsToBird(path, cur_bird);
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
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        d3.Items = obj.sel_bird.speeds + " m/s";
        d3.ValueChangedFcn = @(src, event) speed_change(src, event);

        d1.ValueChangedFcn = @(src, event) flapper_change(src, event, d2, d3);

        % Subtraction Case Selection
        button1_y = drop_y3 - (unit_height + unit_spacing);
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
        b8.Text = "Aero Model";
        b8.Position = [20 button7_y 160 unit_height];
        b8.BackgroundColor = [1 1 1];
        b8.ValueChangedFcn = @(src, event) model_change(src, event, plot_panel);

        button8_y = button7_y - (unit_height + unit_spacing);
        b9 = uibutton(option_panel,"state");
        b9.Text = "Thin Airfoil";
        b9.Position = [15 button8_y 80 unit_height];
        b9.BackgroundColor = [1 1 1];
        b9.ValueChangedFcn = @(src, event) thinAirfoil_change(src, event, plot_panel);

        b10 = uibutton(option_panel,"state");
        b10.Text = "Amplitudes";
        b10.Position = [105 button8_y 80 unit_height];
        b10.BackgroundColor = [1 1 1];
        b10.ValueChangedFcn = @(src, event) amplitudes_change(src, event, plot_panel);

        AoA_y = 0.05*screen_height;
        s = uislider(option_panel,"range");
        s.Position = [10 AoA_y 180 3];
        s.Limits = obj.range;
        s.Value = obj.range;
        s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        s.ValueChangedFcn = @(src, event) AoA_change(src, event, plot_panel);

        drop_y4 = AoA_y + (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [50 drop_y4 145 unit_height];
        d4.Items = ["Stability Slope", "Equilibrium Angle", "Neutral Position (NP)", "Moment at NP", "COP"];
        d4.ValueChangedFcn = @(src, event) y_var_change(src, event, plot_panel);

        y_txt = uicontrol(option_panel, 'Position', [5 drop_y4 40 unit_height], 'String', 'y_var:');

        drop_y5 = drop_y4 + (unit_height + unit_spacing);
        d5 = uidropdown(option_panel);
        d5.Position = [50 drop_y5 145 unit_height];
        d5.Items = ["Strouhal", "COM", "Static Margin"];
        d5.ValueChangedFcn = @(src, event) x_var_change(src, event, plot_panel);

        x_txt = uicontrol(option_panel, 'Position', [5 drop_y5 40 unit_height], 'String', 'x_var:');

        button9_y = drop_y5 + (unit_height + unit_spacing);
        b11 = uibutton(option_panel);
        b11.Text = "Save Fig";
        b11.Position = [20 button9_y 160 unit_height];
        b11.BackgroundColor = [1 1 1];
        b11.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

        button10_y = button9_y + (unit_height + unit_spacing);
        b12 = uibutton(option_panel,"state");
        b12.Text = "Log Scaling";
        b12.Position = [20 button10_y 160 unit_height];
        b12.BackgroundColor = [1 1 1];
        b12.ValueChangedFcn = @(src, event) log_scaling(src, event, plot_panel);

        button11_y = button10_y + (unit_height + unit_spacing);
        b13 = uibutton(option_panel,"state");
        b13.Text = "Zero Slope";
        b13.Position = [20 button11_y 160 unit_height];
        b13.BackgroundColor = [1 1 1];
        b13.ValueChangedFcn = @(src, event) zero_slope(src, event, plot_panel);

        button12_y = button11_y + (unit_height + unit_spacing);
        b14 = uibutton(option_panel,"state");
        b14.Text = "Constant SM"; % static margin
        b14.Position = [20 button12_y 160 unit_height];
        b14.BackgroundColor = [1 1 1];
        b14.ValueChangedFcn = @(src, event) constant_SM(src, event, plot_panel);

        button13_y = button12_y + (unit_height + unit_spacing);
        b15 = uibutton(option_panel,"state");
        b15.Text = "Effective Speed Norm"; % static margin
        b15.Position = [20 button13_y 160 unit_height];
        b15.BackgroundColor = [1 1 1];
        b15.ValueChangedFcn = @(src, event) u_eff_scale(src, event, plot_panel);

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
            sel_name = typeToSel(obj.sel_bird.name, obj.sel_type);
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

            % removing value from object's list
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

        function thinAirfoil_change(src, ~, plot_panel)
            if (src.Value)
                obj.thinAirfoil = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.thinAirfoil = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function amplitudes_change(src, ~, plot_panel)
            if (src.Value)
                obj.amplitudes = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.amplitudes = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        % ["Stability Slope", "Equilibrium Position", "COM", "Static Margin", "Neutral Position", "Moment at NP", "Equilibrium"];
        function x_var_change(src, ~, plot_panel)
            options = ["Strouhal", "COM", "Static Margin"];
            obj.x_var = find(options == src.Value);

            obj.update_plot(plot_panel);
        end

        function y_var_change(src, ~, plot_panel)
            options = ["Stability Slope", "Equilibrium Angle", "Neutral Position (NP)", "Moment at NP", "COP"];
            obj.y_var = find(options == src.Value);

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

        function save_figure(~, ~, plot_panel)
            obj.saveFig = true;
            obj.update_plot(plot_panel);
            obj.saveFig = false;
        end

        function log_scaling(src, ~, plot_panel)
            if (src.Value)
                obj.logScale = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.logScale = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function zero_slope(src, ~, plot_panel)
            if (src.Value)
                obj.zeroSlope = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.zeroSlope = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function constant_SM(src, ~, plot_panel)
            if (src.Value)
                obj.constSM = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.constSM = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function u_eff_scale(src, ~, plot_panel)
            if (src.Value)
                obj.u_eff = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.u_eff = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end
        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)
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
            % wind_speed = dir_parts(end) + " ";
            wind_speed = regexp(dir_parts(end), '\d+', 'match') + " m/s ";

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

    function matched_filename = get_norm_factors_name(path, plot_data_dir_name)
        % Get a list of all files in the folder with the desired file name pattern.
        filePattern = fullfile(path, '*.mat');
        theFiles = dir(filePattern);
        parsed_dir_name = extractBefore(plot_data_dir_name, "m.s.");

        if (contains(parsed_dir_name, "Sub"))
            parsed_dir_name = strrep(parsed_dir_name, "Sub", "Wings");
        end

        % Grab each file and process the data from that file, storing the results
        for k = 1 : length(theFiles)
            baseFileName = convertCharsToStrings(theFiles(k).name);
            parsed_name = extractBefore(baseFileName, "m.s.");
            if (parsed_name == parsed_dir_name)
                matched_filename = baseFileName;
                break
            end
        end

    end
end

methods (Access = private)
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)
        
        struct_matches = get_file_matches(obj.selection, obj.norm, obj.shift, obj.drift, obj.sub, obj.Flapperoo, obj.MetaBird);
        disp("Found following matches:")
        disp(struct_matches)

        if (length(struct_matches) ~= length(obj.selection))
            disp("--------------------------------------------")
            disp("Oops looks like a data file is missing")
            disp("--------------------------------------------")
        end

        if (obj.x_var == 1)
            if (obj.st)
                x_label = "Strouhal Number"; % $\mathbf{St = \frac{f A}{U_{\infty}}}
            else
                x_label = "Wingbeat Frequency (Hz)";
            end
        elseif (obj.x_var == 2)
            x_label = "COM Position (% chord)";
        elseif (obj.x_var == 3)
            x_label = "Static Margin (% chord)";
        end

        if (obj.y_var == 1)
            if (obj.norm)
                % y_label = "Normalized Pitch Stability Slope";
                y_label = "Dimensionless Pitch Stiffness";
            else
                % y_label = "Pitch Stability Slope";
                y_label = "Pitch Stiffness (Nm)";
            end
        elseif (obj.y_var == 2)
            y_label = "Equilibrium Angle (deg)";
            % Previously had a "normalized equilibrium angle", don't know
            % why that should be different, one case I looked at was same
        elseif (obj.y_var == 3)
            y_label = "Neutral Position (% chord)";
        elseif (obj.y_var == 4)
            y_label = "Moment at Neutral Position";
        elseif (obj.y_var == 5)
            y_label = "Center of Pressure (% chord)";
        end
        
        show_data = true;

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
        hold(ax, 'on');

        if (obj.x_var == 2 || obj.x_var == 3)
            % sequential colors
            map = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
            % map = ["#fef0d9"; "#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
            % diverging colors
            % map = ["#d7191c"; "#fdae61"; "#ffffbf"; "#abdda4"; "#2b83ba"];
            map = hex2rgb(map);
            xquery = linspace(0,1,128);
            numColors = size(map);
            numColors = numColors(1);
            map = interp1(linspace(0,1,numColors), map, xquery,'pchip');
            cmap = colormap(ax, map);

            if (obj.st)
                minSt = 0;
                maxSt = 0.55;
                zmap = linspace(minSt, maxSt, length(cmap));
                clim(ax, [minSt, maxSt])
                cb = colorbar(ax);
                ylabel(cb,'Strouhal Number','FontSize',16,'Rotation',270)
            else
                minFreq = 0;
                maxFreq = 5;
                zmap = linspace(minFreq, maxFreq, length(cmap));
                clim(ax, [minFreq, maxFreq])
                cb = colorbar(ax);
                ylabel(cb,'Wingbeat Frequency','FontSize',16,'Rotation',270)
            end
        end

        last_t_ind = 0;
        last_s_ind = 0;
        x_vals_tot = [];
        x_vals_mod_tot = [];
        y_vals_tot = [];
        y_vals_mod_tot = [];
        err_vals_tot = [];
        s_ind_tot = [];
        t_ind_tot = [];
        percent_err_tot = [];

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
            
            % Load associated norm_factors file, used for COM
            % plot where normalization can only be done after
            % shifting pitch moment
            if (obj.x_var ~= 1 || obj.y_var == 3 || obj.y_var == 4 || obj.y_var == 5)
            norm_factors_path = obj.data_path + "/plot data/" + cur_bird.name + "/norm_factors/";
            norm_factors_filename = compareStabilityUI.get_norm_factors_name(norm_factors_path, cur_struct_match.dir_name);

            cur_file = norm_factors_path + norm_factors_filename;
            disp("Loading " + cur_file)
            load(cur_file, "norm_factors")

            % Also strip norm from filename as we want to hand
            % findCOMrange the non-normalized data
            if (obj.norm)
                parsed_name = erase(extractBefore(cur_struct_match.file_name, "_saved"), "_norm");
                for k = 1:length(cur_bird.file_list)
                    cur_struct = cur_bird.file_list(k);
                    if (cur_struct.dir_name == parsed_name)
                        cur_struct_match.file_name = cur_struct.file_name;
                    end
                end
            end
            end

            cur_file = obj.data_path + "/plot data/" + cur_bird.name + "/" + cur_struct_match.file_name;
            disp("Loading " + cur_file)
            load(cur_file, "avg_forces", "err_forces")
            lim_avg_forces = avg_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
            lim_err_forces = err_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);

            if cur_bird.name == "Flapperoo"
                if (wind_speed == 6)
                    wing_freqs_str = cur_bird.freqs(1:end-4);
                else
                    wing_freqs_str = cur_bird.freqs(1:end-2);
                end
            elseif cur_bird.name == "MetaBird"
                wing_freqs_str = cur_bird.freqs;
            end
            wing_freqs = str2double(extractBefore(wing_freqs_str, " Hz"));
            
            % temp test to remove 0 and 0.1 Hz
            % wing_freqs = wing_freqs(3:end);

            % Skip gliding case
            % wing_freqs = wing_freqs(wing_freqs ~= 0);
            % wing_freqs = wing_freqs(wing_freqs ~= 0.1);

            % Get slope from gliding
            idx = 5; % pitch moment
            x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
            y = lim_avg_forces(idx,:,1)';
            b = x\y;
            model = x*b;
            % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
            SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
            x_int = - b(1) / b(2);
            glide_slope = b(2);
            
            [center_to_LE, chord, COM_span, ...
                        wing_length, arm_length] = getWingMeasurements(cur_bird.name);

            slopes = [];
            x_intercepts = [];
            err_slopes = [];
            NP_positions = [];
            NP_pos_errs = [];
            NP_moms = [];
            COPs = [];
            COP_SDs = [];
            [init_NP_pos, ~, ~] = findNP(lim_avg_forces(:,:,1), lim_AoA_sel);
            for k = 1:length(wing_freqs)
                if (obj.u_eff)
                    amp = -1;
                    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(obj.data_path, wing_freqs(k), amp);
                    
                    full_length = wing_length + arm_length;
                    r = arm_length:0.001:full_length;
                    lin_vel = deg2rad(ang_vel) * r;
                    % lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;
                
                    for m = 1:length(lim_AoA_sel)
                        AoA = lim_AoA_sel(m);
                        
                        [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);
                        u_rel_avg = mean(u_rel,"all");
    
                        lim_avg_forces(:,m,k) = lim_avg_forces(:,m,k) * (wind_speed / u_rel_avg)^2;
                    end
                end

                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = lim_avg_forces(idx,:,k)';
                b = x\y;
                model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
                x_int = - b(1) / b(2);
                slope = b(2);

                [center_to_LE, chord, ~, ~, ~] = getWingMeasurements(cur_bird.name);

                [COP] = getCOP(squeeze(lim_avg_forces(:,:,k)), lim_AoA_sel, center_to_LE, chord);

                % try removing stuff around zero angle of attack where COP
                % is singular as normal force goes to zero
                COP = COP(lim_AoA_sel > 2 | lim_AoA_sel < -2);

                % convert COP to chord
                COP = (COP / chord) * 100;
                COPs = [COPs mean(COP)];
                COP_SDs = [COP_SDs std(COP)];

                % zero slope with glide slope so different body types can
                % be better compared
                if (obj.zeroSlope)
                    slope = slope - glide_slope;
                end

                if (obj.y_var == 3 || obj.y_var == 4 || obj.constSM)
                    [NP_pos, NP_pos_err, NP_mom] = findNP(lim_avg_forces(:,:,k), lim_AoA_sel);
                end

                if (obj.y_var == 3 || obj.y_var == 4)
                    if (obj.norm)
                        NP_mom = NP_mom / norm_factors(2);
                    end
                    % NP_pos_chord = (NP_pos / chord) * 100;
                    % Assuming lim_avg_forces fed into findNP was from LE
                    % Otherwise need, shift pitch moment to be off
                    [NP_pos_LE, NP_pos_chord] = posToChord(NP_pos, center_to_LE, chord);
                    NP_positions = [NP_positions NP_pos_chord];
                    NP_moms = [NP_moms NP_mom];
                    NP_pos_errs = [NP_pos_errs NP_pos_err];
                end

                if (obj.constSM)
                    shift_distance = (NP_pos - init_NP_pos);
                    [mod_avg_data] = shiftPitchMom(squeeze(lim_avg_forces(:,:,k)), shift_distance, lim_AoA_sel);
                    idx = 5; % pitch moment
                    x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                    y = mod_avg_data(idx,:)';
                    b = x\y;
                    model = x*b;
                    % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                    SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
                    x_int = - b(1) / b(2);
                    slope = b(2);
                end

                slopes = [slopes slope];
                err_slopes = [err_slopes SE_slope];
                x_intercepts = [x_intercepts x_int];

                if (obj.x_var == 2 || obj.x_var == 3)
                    [distance_vals_chord, static_margin, slopes_pos, x_ints] = ...
                        findCOMrange(lim_avg_forces(:,:,k), lim_AoA_sel, center_to_LE, chord, obj.norm, norm_factors);
                    
                    if (obj.x_var == 2)
                        x_vals = distance_vals_chord;
                        % temp test to see if lines will collapse
                        % y_vals = y_vals / (wing_freqs(k) / wind_speed)^(1.6);
                    elseif (obj.x_var == 3)
                        x_vals = static_margin;
                    end

                    if (obj.y_var == 1)
                        y_vals = slopes_pos;
                    elseif (obj.y_var == 2)
                        y_vals = x_ints;
                    end

                    if (obj.st)
                    St = freqToSt(cur_bird.name, wing_freqs(k), wind_speed, obj.data_path, -1);
                    line_color = interp1(zmap, cmap, St);
                    % slopes_pos = slopes_pos / (wing_freqs(k));
                    else
                    line_color = interp1(zmap, cmap, wing_freqs(k));
                    end

                    line = plot(ax, x_vals, y_vals);
                    line.LineWidth = 2;
                    line.HandleVisibility = 'off';
                    line.Color = line_color;

                    % % For making dots showing M about LE only
                    % [M,I] = min(abs(x_vals));
                    % scatter(ax, x_vals(I), y_vals(I), 50, line_color, "filled")
                    % xlim(ax, [min(x_vals) max(x_vals)])
                    % ylim(ax, [-0.2, 0.3])
                    
                    if obj.x_var == 2
                        xlim(ax, [min(x_vals) max(x_vals)])
                    elseif (obj.x_var == 3)
                        xlim(ax, [-50 50])
                    end
                    
                    if (obj.y_var == 2 && obj.x_var ~= 1)
                        ylim(ax, [-5 5])
                        xlim(ax, [min(x_vals) max(x_vals)])
                    end
                end
            end

            % ------------------------------------------------
            % -----Normalize by values from 3 m/s trials------
            % ------------------------------------------------
            % if i == 1
            %     slopes_init = slopes;
            % end
            % slopes = slopes ./ slopes_init(1:length(slopes));
            % 
            % if i == 1
            %     slopes_init_scaling = wind_speed^2 + (wing_freqs.^2)/3;
            % end
            % % Prediction from simple scaling
            % slopes_scaling = wind_speed^2 + (wing_freqs.^2)/3;
            % slopes_scaling = slopes_scaling ./ slopes_init_scaling(1:length(slopes));
            
            % ------------------------------------------------
            % -----Normalize by values from 3 m/s trials------
            % ------------------------------------------------
            % slopes = slopes / slopes(1);
            % 
            % slopes_scaling = wind_speed^2 + (wing_freqs.^2)/3;
            % slopes_scaling = slopes_scaling / slopes_scaling(1);

            % ------------------------------------------------
            % if (i ~= 1)
            % percent_err = (abs(slopes - slopes_scaling) ./ slopes) * 100;
            % percent_err_tot = [percent_err_tot percent_err];
            % end

            % percent_err = (abs(slopes(2:end) - slopes_scaling(2:end)) ./ slopes(2:end)) * 100;
            % percent_err_tot = [percent_err_tot percent_err];
            % ------------------------------------------------
            
            % Get Quasi-Steady Model Force
            % Predictions
            mod_slopes = [];
            mod_x_intercepts = [];
            mod_NPs = [];
            mod_NP_moms = [];
            mod_COPs = [];
            mult_amp = false;
            if (obj.aero_model)
                if (obj.amplitudes)
                    amplitude_list = [pi/12, pi/6, pi/4, pi/3];
                    show_data = false;
                else
                    amplitude_list = -1;
                    % amplitude_list = pi/6; % appears to have no big diff
                    % amplitude_list = 40*(pi/180);
                end
                % higher resolution wingbeat frequency
                wing_freqs_fine = [0:0.005:0.02 linspace(0.1, max(wing_freqs), 15)];
                % wing_freqs_fine = wing_freqs;

                mod_slopes = zeros(length(amplitude_list), length(wing_freqs_fine));
                mod_x_intercepts = zeros(length(amplitude_list), length(wing_freqs_fine));
                mod_NPs = zeros(length(amplitude_list), length(wing_freqs_fine));
                mod_NP_moms = zeros(length(amplitude_list), length(wing_freqs_fine));
                mod_COPs = zeros(length(amplitude_list), length(wing_freqs_fine));

                AR = cur_bird.AR;

                if obj.thinAirfoil
                    lift_slope = ((2*pi) / (1 + 2/AR));
                    pitch_slope = -lift_slope / 4;
                else
                    % Find slopes for all wind speeds and average
                    path = obj.data_path + "/plot data/" + cur_bird.name;
                    [lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha] = getGlideSlopesFromData(path, cur_bird, cur_struct_match.dir_name, obj.range);
                end
                disp("Lift Slope: " + lift_slope)
                disp("Pitch Slope: " + pitch_slope)

                for j = 1:length(amplitude_list)
                amp = amplitude_list(j);

                for k = 1:length(wing_freqs_fine)
                wing_freq = wing_freqs_fine(k);

                % temp code to block out x_int inclusion in model
                zero_lift_alpha = 0;
                zero_pitch_alpha = 0;
                [aero_force, COP] = get_model(cur_bird.name, obj.data_path, lim_AoA_sel, wing_freq, wind_speed,...
                    lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, amp);
                mod_COPs(j,k) = mean(COP);

                if (obj.u_eff)
                    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(obj.data_path, wing_freq, amp);
            
                    [center_to_LE, chord, COM_span, ...
                        wing_length, arm_length] = getWingMeasurements(cur_bird.name);
                    
                    full_length = wing_length + arm_length;
                    r = arm_length:0.001:full_length;
                    lin_vel = deg2rad(ang_vel) * r;
                    % lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;
                
                    for m = 1:length(lim_AoA_sel)
                        AoA = lim_AoA_sel(m);
                        
                        [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);
                        u_rel_avg = mean(u_rel,"all");
                        aero_force(:,m) = aero_force(:,m) * (wind_speed / u_rel_avg)^2;
                    end
                end

                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = aero_force(idx,:)';
                b = x\y;
                % model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                x_int = - b(1) / b(2);

                mod_slopes(j,k) = b(2);
                mod_x_intercepts(j,k) = x_int;

                if (obj.x_var == 2 || obj.x_var == 3)
                % To find NP, force needs to be non-normalized since
                % shifting must be done with real dimensions
                aero_force_dim = zeros(size(squeeze(aero_force)));
                for m = 1:6
                    if (m <= 3)
                        aero_force_dim(m,:) = aero_force(m,:) * norm_factors(1);
                    else
                        aero_force_dim(m,:) = aero_force(m,:) * norm_factors(2);
                    end
                end

                [NP_pos, NP_pos_err, NP_mom] = findNP(aero_force_dim, lim_AoA_sel);
                % Nondimensionalize moment
                NP_mom = NP_mom / norm_factors(2);

                [NP_pos_LE, NP_pos_chord] = posToChord(NP_pos, center_to_LE, chord);
                mod_NPs(j,k) = NP_pos_chord;
                mod_NP_moms(j,k) = NP_mom;
                end
                end
                end
            end

            if (obj.x_var == 1)

            if (obj.st)
                x_vals = zeros(1, length(wing_freqs));
                for k = 1:length(wing_freqs)
                    x_vals(k) = freqToSt(cur_bird.name, wing_freqs(k), wind_speed, obj.data_path, -1);
                end

                if (obj.aero_model)
                x_vals_mod = zeros(length(amplitude_list), length(wing_freqs_fine));
                for j = 1:length(amplitude_list)
                    for k = 1:length(wing_freqs_fine)
                        x_vals_mod(j,k) = freqToSt(cur_bird.name, wing_freqs_fine(k), wind_speed, obj.data_path, amplitude_list(j));
                    end
                end
                end
            else
                x_vals = wing_freqs;
                
                if (obj.aero_model)
                x_vals_mod = zeros(length(amplitude_list), length(wing_freqs_fine));
                for j = 1:length(amplitude_list)
                    for k = 1:length(wing_freqs_fine)
                        x_vals_mod(j,k) = x_vals(k);
                        % x_vals_mod(j,k) = amplitude_list(j);
                    end
                end
                end
            end

            if (obj.y_var == 1)
                y_vals = slopes;
                err_vals = err_slopes;
                y_vals_mod = mod_slopes;
            elseif (obj.y_var == 2)
                y_vals = x_intercepts;
                err_vals = zeros(1,length(x_intercepts));
                y_vals_mod = mod_x_intercepts;
            elseif (obj.y_var == 3)
                y_vals = NP_positions;
                % err_vals = NP_pos_errs * 10^4;
                err_vals = zeros(size(NP_pos_errs));
                y_vals_mod = mod_NPs;
            elseif (obj.y_var == 4)
                y_vals = NP_moms;
                err_vals = zeros(1,length(NP_moms));
                y_vals_mod = mod_NP_moms;
            elseif (obj.y_var == 5)
                y_vals = COPs;
                % err_vals = COP_SDs; % higher than magnitude of values
                err_vals = zeros(size(COP_SDs));
                y_vals_mod = mod_COPs;
            end

            % mod_diff_vals = abs(y_vals - y_vals_mod);
            % disp("Average disagreement between data and model: " + mean(mod_diff_vals));
            x_vals_tot = [x_vals_tot x_vals];
            y_vals_tot = [y_vals_tot y_vals];
            err_vals_tot = [err_vals_tot err_vals];
            s_ind_tot = [s_ind_tot s_ind*ones(size(err_vals))];
            t_ind_tot = [t_ind_tot t_ind*ones(size(err_vals))];
            
            if (obj.aero_model)
            x_vals_mod_tot = [x_vals_mod_tot x_vals_mod];
            y_vals_mod_tot = [y_vals_mod_tot y_vals_mod];
            end

        % Plot data after getting it all %% ----------------- %%

        if ~obj.logScale
            if show_data

            e = errorbar(ax, x_vals, y_vals, err_vals, '.');
            e.MarkerSize = 25;
            e.Color = colors(s_ind, t_ind);
            e.MarkerFaceColor = colors(s_ind, t_ind);
            e.DisplayName = abbr_sel(i);

            x_var_mod = x_vals(2:end);
            y_var_mod = y_vals(2:end);

            test_fit = fit(x_var_mod', y_var_mod', 'power2');
            y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;
            end
            % fit power law
            % x_var_mod = x_vals(2:end);
            % y_var_mod = y_vals(2:end);

            % logX = log(x_var);
            % logY = log(y_var);
            % 
            % p = polyfit(logX, logY, 1);
            % disp(p(1))

            % y_mod = exp(p(2)) * x_var.^(p(1));

            % test_fit = fit(x_var_mod', y_var_mod', 'power2')
            % y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;

            % plot(ax, x_var_mod, y_mod, LineStyle="--",Color="black")
            
            % ---------Plotting model-----------
            % aerodynamics model is nondimensionalized, so
            % data should also be nondimensionalized when
            % comparing the two. Also only occurs if
            % frequency or wind speed have changed
            if (obj.norm && obj.aero_model)
                marker_list = ["o", "square", "^", "v"];
                % temp_colors is greens used for amplitude plot
                temp_colors(:,1) = ["#bae4b3";"#74c476";"#31a354";...
                       "#006d2c"];

                if (obj.amplitudes)
                for j = 1:length(amplitude_list)
                    % s = scatter(ax, x_vals_mod(j,:), y_vals_mod(j,:), 40);
                    % % s.MarkerEdgeColor = colors(s_ind, t_ind);
                    % s.MarkerEdgeColor = temp_colors(j);
                    % s.LineWidth = 2; % char(176) for degree symbol
                    % s.DisplayName = wind_speed + " m/s, \theta_m = " + rad2deg(amplitude_list(j)) + "°"; % + ", Model: " + abbr_sel(i);
                    % s.Marker = marker_list(j); % + "\textbf{^{\circ}}"

                    l_f = plot(ax, x_vals_mod(j,:), y_vals_mod(j,:));
                    l_f.LineWidth = 2;
                    l_f.DisplayName = "\theta_m = " + rad2deg(amplitude_list(j)) + "°";
                    l_f.Color = temp_colors(j);
                    l_f.LineStyle = "-";
                end

                else
                    % Plot model as line rather than scatter
                    % Only plot 3 m/s as this is the longest line
                    if (wind_speed == 3)
                        l_f = plot(ax, x_vals_mod, y_vals_mod);
                        l_f.LineWidth = 2;
                        l_f.DisplayName = "QSBE Model";
                        l_f.Color = "black";
                        l_f.LineStyle = "-";
                    end

                    % s = scatter(ax, x_vals_mod, y_vals_mod, 40);
                    % s.MarkerEdgeColor = colors(s_ind, t_ind);
                    % s.LineWidth = 2;
                    % % s.HandleVisibility = "off";
                    % s.DisplayName = "Model: " + abbr_sel(i);

                    reducedMod = true;
                    % Only plot 3 m/s as this is the longest line
                    if (wind_speed == 3 && reducedMod)
                        % Data slopes are in pitch / deg. These slopes are
                        % pitch / rad so we multiply by pi / 180
                        A_val = deg2rad(30);
                        St_fine = linspace(min(x_vals_mod), max(x_vals_mod), 100);
                        % Super reduced version of model - this is too
                        % reduced, lose amplitude variation
                        % test_mod = besselj(0,A_val) * (pi/180) * pitch_slope * (1 + 3*(St_fine.^2)); % prior to July 2025
                        
                        test_mod =  (pi/180) * pitch_slope * (0.932627 + 3.94692 * St_fine.^2);
                        % St = (2 * R * wing_freq * amp) / wind_speed;
                        if obj.u_eff
                            % AoA = 0;
                            % [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);
                            % u_rel_avg = mean(u_rel,"all");
                            % test_mod = test_mod * (wind_speed / u_rel_avg)^2;
                            % tried this scaling first, didn't appear to work
                            % test_mod = test_mod * (wind_speed / u_rel_avg)^2;
                            % regularized_0F1 = hypergeom([], 2, -A_val^2) / gamma(2);
                            % ueffNorm = (3 + ((pi/2)^2)*(St_fine.^2)*(1 + regularized_0F1))/3;
                            % ^old code prior to July 2025

                            ueffNorm = 1 + 2.04266 * St_fine.^2;
                            test_mod = test_mod ./ ueffNorm;
                        end
                        % test_mod = -0.028 * (1 + 3*(St_fine.^2));
                        % disp(besselj(0,A_val) * (pi/180) * pitch_slope + " * (1 + 3St^2)")
                        % test_mod = (pi/180) * pitch_slope * (besselj(0,A_val) + 0.5*(St_fine.^2)*((9*besselj(1,A_val) + besselj(1, 3*A_val)) / (A_val)));
                        l_s = plot(ax, St_fine, test_mod);
                        l_s.DisplayName = "Reduced QSBE Model";
                        l_s.Color = "black";
                        l_s.LineStyle = "--";
                        l_s.LineWidth = 2;
                    end

                    % x_var_mod = x_vals_mod(2:end);
                    % y_var_mod = y_vals_mod(2:end);
                    % 
                    % test_fit = fit(x_var_mod', y_var_mod', 'power2')
                    % y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;
                end
            end
        end
            end


        end

        disp("Freq Scaling % error: " + mean(percent_err_tot))

        plot_fit = false;
        if (plot_fit)
            bad_ind = [];
            for n = 1:length(x_vals_tot)
                if (x_vals_tot(n) == 0)
                   bad_ind = [bad_ind n]; 
                end
            end
            x_vals_tot(bad_ind) = [];
            y_vals_tot(bad_ind) = [];
            test_fit = fit(x_vals_tot', y_vals_tot', 'power2')
            y_mod = test_fit.a * sort(x_vals_tot).^(test_fit.b) + test_fit.c;
            plot(ax, sort(x_vals_tot), y_mod)
        end

        if (obj.logScale)
            y_vals_tot = -y_vals_tot; % can't do log of a negative num
            y_vals_tot = y_vals_tot - min(y_vals_tot);
            
            bad_ind = [];
            for n = 1:length(x_vals_tot)
                if (x_vals_tot(n) < 0.01 || y_vals_tot(n) == 0)
                   bad_ind = [bad_ind n]; 
                end
            end
            x_vals_tot(bad_ind) = [];
            y_vals_tot(bad_ind) = [];
            err_vals_tot(bad_ind) = [];
            s_ind_tot(bad_ind) = [];
            t_ind_tot(bad_ind) = [];

            % regression
            x_vals_reg = log(x_vals_tot);
            y_vals_reg = log(y_vals_tot);
            x = [ones(size(x_vals_reg')), x_vals_reg'];
            y = y_vals_reg';
            b = x\y;
            model = x*b;
            Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
            % label = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
            label = "y = " + round(exp(b(1)),3) + "*x^{" + round(b(2),3) + "}, R^2 = " + round(Rsq,3);

            uniq_s = unique(s_ind_tot);
            uniq_t = unique(t_ind_tot);
            for n = 1:length(uniq_t)
                t_ind = uniq_t(n);
            for m = 1:length(uniq_s)
                s_ind = uniq_s(m);
            e = errorbar(ax, x_vals_tot(s_ind_tot == s_ind), y_vals_tot(s_ind_tot == s_ind), err_vals_tot(s_ind_tot == s_ind), '.');
            e.MarkerSize = 25;
            e.Color = colors(s_ind, t_ind);
            e.MarkerFaceColor = colors(s_ind, t_ind);
            e.DisplayName = abbr_sel(m);
            end
            end

            [x_vals_tot_s, sortIndices] = sort(x_vals_tot);
            model_s = model(sortIndices);

            p = plot(ax, x_vals_tot_s, exp(model_s));
            p.Color = 'black';
            p.DisplayName = label;
            p.LineWidth = 2;

            len = length(x_vals_tot_s);
            p = plot(ax, x_vals_tot_s, 0.04*x_vals_tot_s);
            % p = plot(ax, x_vals_tot_s(round(len*(1/4)):round(len*(3/4))), 0.04*x_vals_tot_s(round(len*(1/4)):round(len*(3/4))));
            p.Color = 'black';
            p.DisplayName = "Linear";
            p.LineWidth = 2;
            p.LineStyle = '--';

            % ---------Plotting model-----------
            % aerodynamics model is nondimensionalized, so
            % data should also be nondimensionalized when
            % comparing the two. Also only occurs if
            % frequency or wind speed have changed
            if (obj.norm && obj.aero_model)
                y_vals_mod_tot = -y_vals_mod_tot; % can't do log of a negative num
                y_vals_mod_tot = y_vals_mod_tot - min(y_vals_mod_tot);
                
                bad_ind = [];
                for n = 1:length(x_vals_mod_tot)
                    if (x_vals_mod_tot(n) < 0.01 || y_vals_mod_tot(n) == 0)
                       bad_ind = [bad_ind n]; 
                    end
                end
                x_vals_mod_tot(bad_ind) = [];
                y_vals_mod_tot(bad_ind) = [];

                marker_list = ["o", "square", "^", "v"];
                temp_colors(:,1) = ["#fdbe85";"#fd8d3c";"#e6550d";...
                       "#a63603"];

                if (mult_amp)
                for j = 1:length(amplitude_list)
                    % HAVENT FIXED THIS TO MAKE IT WORK YET
                    s = scatter(ax, x_vals_mod(j,:), y_vals_mod(j,:), 40);
                    % s.MarkerEdgeColor = colors(s_ind, t_ind);
                    s.MarkerEdgeColor = temp_colors(j);
                    s.LineWidth = 2; % char(176) for degree symbol
                    s.DisplayName = "\theta_m = " + rad2deg(amplitude_list(j)); % + ", Model: " + abbr_sel(i);
                    s.Marker = marker_list(j); % + "\textbf{^{\circ}}"
                end
                else
                    s = scatter(ax, x_vals_mod_tot, y_vals_mod_tot, 40);
                    % s.MarkerEdgeColor = colors(s_ind, t_ind);
                    s.LineWidth = 2;
                    % s.DisplayName = "Model: " + abbr_sel(i);

                    % regression
                    x_vals_reg = log(x_vals_mod_tot);
                    y_vals_reg = log(y_vals_mod_tot);
                    x = [ones(size(x_vals_reg')), x_vals_reg'];
                    y = y_vals_reg';
                    b = x\y;
                    model = x*b;
                    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                    % label = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
                    label = "y = " + round(exp(b(1)),3) + "*x^{" + round(b(2),3) + "}, R^2 = " + round(Rsq,3);

                    [x_vals_mod_tot_s, sortIndices] = sort(x_vals_mod_tot);
                    model_s = model(sortIndices);
        
                    p = plot(ax, x_vals_mod_tot_s, exp(model_s));
                    p.DisplayName = label;
                    p.LineWidth = 2;
                end
            end

        else
            % Power law fit for experimental data
            bad_ind = [];
            for n = 1:length(x_vals_tot)
                if (x_vals_tot(n) == 0)
                   bad_ind = [bad_ind n]; 
                   % x_vals_tot(n) = 0.000001;
                end
            end
            x_vals_tot(bad_ind) = [];
            y_vals_tot(bad_ind) = [];

            % [x_mod_sort, sortIndices] = sort(x_vals_mod_tot);
            % y_mod_sort = y_vals_mod_tot(sortIndices);
            if (obj.x_var == 1 && obj.y_var == 1)
                experiment_fit = fit(x_vals_tot', y_vals_tot', 'power2')
            end
            % y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;

            % Power law fit for model data
            if (~isequal(x_vals_mod_tot, zeros(size(x_vals_mod_tot))))
            % Power law for amplitude plot, only necessary for mult amp
            % x_vals_mod_tot = reshape(x_vals_mod_tot(:,2:end), [], 1);
            % y_vals_mod_tot = reshape(y_vals_mod_tot(:,2:end), [], 1);

            bad_ind = [];
            for n = 1:length(x_vals_mod_tot)
                if (x_vals_mod_tot(n) == 0)
                    %  < 0.01 || y_vals_mod_tot(n) == 0
                    % x_vals_mod_tot(n) = 0.000001;
                   bad_ind = [bad_ind n]; 
                end
            end
            x_vals_mod_tot(bad_ind) = [];
            y_vals_mod_tot(bad_ind) = [];

            % [x_mod_sort, sortIndices] = sort(x_vals_mod_tot);
            % y_mod_sort = y_vals_mod_tot(sortIndices);
            model_fit = fit(x_vals_mod_tot', y_vals_mod_tot', 'power2')
            % y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;
            end
        end

        title(ax, sub_title);
        xlabel(ax, x_label);
        ylabel(ax, y_label)
        grid(ax, 'on');
        if ~(obj.x_var == 2 || obj.x_var == 3)
            l = legend(ax, Location="best");
        end
        if (obj.logScale)
            set(ax, 'XScale', 'log');
            set(ax, 'YScale', 'log');
        end
        ax.FontSize = 18;

        % set(findall(ax, 'Type', 'text'), 'Interpreter', 'latex');
        % legH = findall(gcf, "Type", "legend");
        % set(legH, "Interpreter", 'latex')
        % axesH = findall(gcf, "Type", "axes");
        % set(axesH, "TickLabelInterpreter", 'latex')

        if (obj.saveFig)
            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
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
    end
end
end