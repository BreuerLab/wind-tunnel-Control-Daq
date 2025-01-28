classdef compareAoAUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    data_path;

    selection;
    index;
    stroke_index;

    % force and moment axes labels used in dropdown box
    axes_labels;
    stroke_labels;
    range;

    Flapperoo;
    MetaBird;
    sel_bird;

    sel_type;
    sel_freq;
    sel_speed;

    % booleans
    sub;
    norm;
    shift;
    drift;
    regress;
    aero_model;
    thinAirfoil;
    saveFig;
end

methods
    function obj = compareAoAUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.selection = strings(0);
        obj.index = 0;
        obj.axes_labels = ["All", "Drag", "Transverse Lift", "Lift",...
            "Roll Moment", "Pitch Moment", "Yaw Moment"];
        obj.stroke_index = 0;
        obj.stroke_labels = ["Full", "Upstroke", "Downstroke"];
        obj.range = [-16 16];
        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");
        
        obj.sel_bird = obj.Flapperoo;
        obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
        obj.sel_freq = obj.sel_bird.freqs(1);
        obj.sel_speed = obj.sel_bird.speeds(1);

        obj.sub = false;
        obj.norm = false;
        obj.regress = false;
        obj.shift = false;
        obj.drift = false;
        obj.aero_model = false;
        obj.thinAirfoil = false;
        obj.saveFig = false;

        for i = 1:2
            path = obj.data_path;
            if i == 1
                path = path + "/plot data/" + "Flapperoo/";
                cur_bird = obj.Flapperoo;
            elseif i == 2
                path = path  + "/plot data/" + "MetaBird/";
                cur_bird = obj.MetaBird;
            end
            attachFileListsToBird(path, cur_bird)
        end
    end

    function dynamic_plotting(obj)

        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
       
        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        %-----------------------------------------------

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

        % Dropdown box for wingbeat frequency selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        d3.Items = obj.sel_bird.freqs;
        d3.ValueChangedFcn = @(src, event) freq_change(src, event);

        % Dropdown box for wind speed selection
        drop_y4 = drop_y3 - (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [10 drop_y4 180 unit_height];
        d4.Items = obj.sel_bird.speeds + " m/s";
        d4.ValueChangedFcn = @(src, event) speed_change(src, event, d3);

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

        %-----------------------------------------------

        drop_y5 = list_y - (unit_height + unit_spacing);
        d5 = uidropdown(option_panel);
        d5.Position = [10 drop_y5 180 unit_height];
        d5.Items = obj.axes_labels;
        d5.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        drop_y6 = drop_y5 - (unit_height + unit_spacing);
        d6 = uidropdown(option_panel);
        d6.Position = [10 drop_y6 180 unit_height];
        d6.Items = obj.stroke_labels;
        d6.ValueChangedFcn = @(src, event) stroke_change(src, event, plot_panel);

        button3_y = drop_y6 - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "Normalize";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) norm_change(src, event, plot_panel, d3);

        button4_y = button3_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel,"state");
        b5.Text = "Regression";
        b5.Position = [20 button4_y 160 unit_height];
        b5.BackgroundColor = [1 1 1];
        b5.ValueChangedFcn = @(src, event) regress_change(src, event, plot_panel);

        button5_y = button4_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel,"state");
        b6.Text = "Shift Pitch Moment";
        b6.Position = [20 button5_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) shift_change(src, event, plot_panel, d5);

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

        button8_y = AoA_y + (unit_height + unit_spacing);
        b9 = uibutton(option_panel);
        b9.Text = "Save Fig";
        b9.Position = [20 button8_y 160 unit_height];
        b9.BackgroundColor = [1 1 1];
        b9.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

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

        % function select(~, event, plot_panel)
        %     % event.SelectedNodes.Text
        %     % event.Source.CheckedNodes
        % 
        %     % Get the selected nodes
        %     selectedNodes = event.CheckedNodes;
        % 
        %     obj.selection = strings(0);
        % 
        %     for i = 1:length(selectedNodes)
        %         % Get the parent node
        %         parentNode = selectedNodes(i).Parent;
        % 
        %         cur_node_str = convertCharsToStrings(selectedNodes(i).Text);
        %         full_str = parentNode.Text + "/" + cur_node_str;
        %         obj.selection = [obj.selection full_str];
        %     end
        % 
        %     obj.update_plot(plot_panel);
        % end

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
            obj.sel_freq = obj.sel_bird.freqs(1);
            obj.sel_speed = obj.sel_bird.speeds(1);

            type_box.Value = obj.sel_bird.types(1);
            freq_box.Value = obj.sel_bird.freqs(1);
            speed_box.Value = obj.sel_bird.speeds(1) + " m/s";
        end

        % update type variable with new value selected by user
        function type_change(src, ~)
            obj.sel_type = nameToType(obj.sel_bird.name, src.Value);
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~)
            obj.sel_freq = src.Value;
        end

        % update speed variable with new value selected by user
        function speed_change(src, ~, d2)
            speed = str2double(extractBefore(src.Value, " m/s"));
            obj.sel_speed = speed;
            % 4.5 Hz and 5 Hz were run for all wind speeds except
            % 6 m/s
            if (speed == 6)
                shortened_list = obj.sel_bird.freqs(obj.sel_bird.freqs ~= "4.5 Hz" & obj.sel_bird.freqs ~= "5 Hz");
                d2.Items = shortened_list;
            else
                d2.Items = obj.sel_bird.freqs;
            end

            if (obj.norm)
                for i = 1:length(d2.Items)
                    wing_freq = str2double(extractBefore(d2.Items{i}, " Hz"));
                    St = freqToSt(obj.sel_bird.name, wing_freq, obj.sel_speed, obj.data_path, -1);
                    d2.Items{i} = ['St: ' num2str(St)];
                end
            end
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
            sel_name = compareAoAUI.typeToSel(obj.sel_bird.name, obj.sel_type);
            speed = obj.sel_speed + "m.s";
            folder = sel_name + " " + speed;
            case_name = obj.sel_bird.name + "/" + strrep(folder, " ", "_") + "/" + obj.sel_freq;
            % if (obj.norm)
            %     % Extract first number after 'St: '
            %     St = sscanf(extractAfter(obj.sel_freq, "St: "), '%g', 1);
            %     abbr_freqs = str2double(extractBefore(obj.freqs(1:end-2), " Hz")); % remove v2 trials
            %     sel_freq = compareWingbeatUI.stToFreq(St, obj.sel_speed, abbr_freqs);
            %     case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + sel_freq + " Hz " + obj.sel_angle + " deg";
            %     % disp_case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + obj.sel_freq + " " + obj.sel_angle + " deg";
            % else
            %     case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + obj.sel_freq + " " + obj.sel_angle + " deg";
            %     % disp_case_name = case_name;
            % end

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
                flapper_name = string(extractBefore(case_name, "/"));
                dir_name = string(extractBefore(extractAfter(case_name, "/"), "/"));
                trial_name = extractAfter(extractAfter(case_name, "/"), "/");

                wing_freq = str2double(extractBefore(trial_name, " Hz"));
                dir_parts = split(dir_name, '_');
                wind_speed = sscanf(dir_parts(end), '%g', 1);

                St = freqToSt(obj.sel_bird.name, wing_freq, wind_speed, obj.data_path, -1);
                case_name = dir_name + "/" + ['St: ' num2str(St)];
            end
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function index_change(src, ~, plot_panel)
            obj.index = find(obj.axes_labels == src.Value) - 1;
            obj.update_plot(plot_panel);
        end

        function stroke_change(src, ~, plot_panel)
            obj.stroke_index = find(obj.stroke_labels == src.Value) - 1;
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

                % replace freqs with strouhal numbers
                for i = 1:length(obj.selection)
                    flapper_name = string(extractBefore(obj.selection(i), "/"));
                    dir_name = string(extractBefore(extractAfter(obj.selection(i), "/"), "/"));
                    trial_name = extractAfter(extractAfter(obj.selection(i), "/"), "/");

                    wing_freq = str2double(extractBefore(trial_name, " Hz"));
                    dir_parts = split(dir_name, '_');
                    wind_speed = sscanf(dir_parts(end), '%g', 1);

                    St = freqToSt(obj.sel_bird.name, wing_freq, wind_speed, obj.data_path, -1);
                    obj.selection(i) = flapper_name + "/" + dir_name + "/" + ['St: ' num2str(St)];
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

                % replace strouhal numbers with freqs
                for i = 1:length(obj.selection)
                    flapper_name = string(extractBefore(obj.selection(i), "/"));
                    dir_name = string(extractBefore(extractAfter(obj.selection(i), "/"), "/"));
                    trial_name = extractAfter(extractAfter(obj.selection(i), "/"), "/");

                    St = str2double(extractAfter(trial_name, "St: "));
                    dir_parts = split(dir_name, '_');
                    wind_speed = sscanf(dir_parts(end), '%g', 1);
                    
                    abbr_freqs = str2double(extractBefore(obj.sel_bird.freqs(1:end-2), " Hz")); % remove v2 trials
                    freq = stToFreq(obj.sel_bird.name, St, wind_speed, abbr_freqs);
                    obj.selection(i) = flapper_name + "/" + dir_name + "/" + freq + " Hz";
                end
            end

            obj.update_plot(plot_panel);
        end

        function regress_change(src, ~, plot_panel)
            if (src.Value)
                obj.regress = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.regress = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function shift_change(src, ~, plot_panel, dropdown)
            if (src.Value)
                obj.shift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                obj.axes_labels(6) = "Pitch Moment (LE)";
            else
                obj.shift = false;
                src.BackgroundColor = [1 1 1];
                obj.axes_labels(6) = "Pitch Moment";
            end
            dropdown.Items = obj.axes_labels;

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
            elseif (type == "no shoulders")
                sel = "No Shoulders";
            else
                sel = type;
            end
        elseif (flapper == "MetaBird")
            if (type == "full body short tail low")
                sel = "Wings Tail Low";
            elseif (type == "full body")
                sel = "Wings";
            elseif (type == "upside down no tail")
                sel = "Wings Flipped";
            elseif (type == "no wings")
                sel = "Body";
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
            dir_name = string(extractBefore(extractAfter(sel(i), "/"), "/"));
            trial_name = extractAfter(extractAfter(sel(i), "/"), "/");
            
            dir_parts = split(dir_name, '_');
            type = strjoin(dir_parts(1:end-1));
            wind_speed = sscanf(dir_parts(end), '%g', 1);

            flappers = [flappers flapper_name];
            types = [types type];
            speeds = [speeds wind_speed];
            freqs = [freqs trial_name];
        end

        num_uniq_flappers = length(unique(flappers));
        num_uniq_types = length(unique(types));
        num_uniq_speeds = length(unique(speeds));
        num_uniq_freqs = length(unique(freqs));

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
        if (num_uniq_freqs == 1)
            sub_title = sub_title + trial_name;
        end

        for i = 1:length(sel)
            flapper_name = string(extractBefore(sel(i), "/")) + " ";
            dir_name = string(extractBefore(extractAfter(sel(i), "/"), "/"));
            trial_name = extractAfter(extractAfter(sel(i), "/"), "/");
            
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
            if (num_uniq_freqs == 1)
                trial_name = "";
            end

            cur_abbr_sel = flapper_name + type + wind_speed + trial_name;
            abbr_sel(i) = cur_abbr_sel;
        end
        end
    end

    % function aero_force = get_model(flapper, path, AoA_list, freq, speed)
    %     C_L_vals = zeros(1, length(AoA_list));
    %     C_D_vals = zeros(1, length(AoA_list));
    %     C_N_vals = zeros(1, length(AoA_list));
    %     C_M_vals = zeros(1, length(AoA_list));
    %     aero_force = zeros(6, length(AoA_list));
    % 
    %     [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, freq, true);
    % 
    %     [center_to_LE, chord, COM_span, ...
    %         wing_length, arm_length] = getWingMeasurements(flapper);
    % 
    %     full_length = wing_length + arm_length;
    %     r = arm_length:0.001:full_length;
    %     lin_vel = deg2rad(ang_vel) * r;
    % 
    %     thinAirfoil = true;
    %     if (flapper == "Flapperoo")
    %         single_AR = 2.5;
    %     elseif (flapper == "MetaBird")
    %         single_AR = 2.5; % NEEDS UPDATING
    %     else
    %         error("Oops. Unknown flapper")
    %     end
    % 
    %     for i = 1:length(AoA_list)
    %         AoA = AoA_list(i);
    % 
    %         [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, speed);
    % 
    %         [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, speed, wing_length, thinAirfoil, single_AR);
    % 
    %         C_L_vals(i) = mean(C_L);
    %         C_D_vals(i) = mean(C_D);
    %         C_N_vals(i) = mean(C_N);
    %         C_M_vals(i) = mean(C_M);
    %     end
    % 
    %     aero_force(1,:) = C_D_vals;
    %     aero_force(3,:) = C_L_vals;
    %     aero_force(5,:) = C_M_vals;
    % end

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
        
        struct_matches = get_file_matches(obj.selection, obj.norm, obj.shift, obj.drift, obj.sub, obj.Flapperoo, obj.MetaBird);
        
        disp("Found following matches:")
        disp(struct_matches)

        if (length(struct_matches) ~= length(obj.selection))
            disp("--------------------------------------------")
            disp("Oops looks like a data file is missing")
            disp("--------------------------------------------")
        end

        x_label = "Angle of Attack (deg)";
        if (obj.norm)
            y_label_F = "Cycle Average Force Coefficient";
            y_label_M = "Cycle Average Moment Coefficient";
        else
            y_label_F = "Cycle Average Force (N)";
            y_label_M = "Cycle Average Moment (N*m)";
        end
        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];
        titles = obj.axes_labels(2:7);

        if (~isempty(obj.selection))
        unique_dir = [];
        num_dir = 0; % number of unique selected directories
        for j = 1:length(obj.selection)
            flapper_name = string(extractBefore(obj.selection(j), "/"));
            dir_name = string(extractBefore(extractAfter(obj.selection(j), "/"), "/"));
            trial_name = extractAfter(extractAfter(obj.selection(j), "/"), "/");

            if (obj.sub)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
            end

            if(isempty(unique_dir) || sum([unique_dir.dir_name] == dir_name) == 0)
                data_struct.dir_name = dir_name;
                data_struct.trial_names = [];
                unique_dir = [unique_dir data_struct];
                num_dir = num_dir + 1;
            end

            for k = 1:length(unique_dir)
                if (dir_name == unique_dir(k).dir_name)
                    cur_idx = k;
                end
            end
            if(isempty(unique_dir(cur_idx).trial_names) || sum(unique_dir(cur_idx).trial_names == trial_name) == 0)
                unique_dir(cur_idx).trial_names = [unique_dir(cur_idx).trial_names trial_name];
            end
        end

        num_freq = 0;
        for k = 1:length(unique_dir)
            if (length(unique_dir(k).trial_names) > num_freq)
                num_freq = length(unique_dir(k).trial_names);
            end
        end

        uniq_counts = [num_dir, num_freq];
        [B, I] = sort(uniq_counts);

        % count is number of type + speed combos
        colors = getColors(1, num_dir, num_freq, length(obj.selection));
        % colors = getColors(1, num_freq, num_dir, length(obj.selection));
        end
        [sub_title, abbr_sel] = compareAoAUI.get_abbr_names(obj.selection);

        % -----------------------------------------------------
        % ---- Plotting all six axes (3 forces, 3 moments) ----
        % -----------------------------------------------------
        if (obj.index == 0)
            % Initialize tiled layout for plots
            tcl = tiledlayout(plot_panel, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

            tiles = [];
            for idx = 1:6
                ax = nexttile(tcl, idx);
                title(ax, titles(idx));
                xlabel(ax, x_label);
                ylabel(ax, y_labels(idx))
                grid(ax, 'on');
                legend(ax);
                tiles = [tiles ax];
            end
            title(tcl, sub_title)

            if (obj.regress)
                error("No point doing regression on all axes")
            end

            last_f_ind = 0;
            last_s_ind = 0;
            for i = 1:length(obj.selection)
                % remove wingbeat frequency from selector
                % selector = char(obj.selection(i));
                % selector = obj.selection(i);ces = strfind(selector, '/');
                % selector = string(selector(1:slashIndices(2) - 1));
                selector = obj.selection(i);

                for j = 1:length(struct_matches)
                    if (selector == struct_matches(j).selector)
                        cur_struct_match = struct_matches(j);
                        break;
                    end
                end

                flapper_name = string(extractBefore(obj.selection(i), "/"));
                dir_name = string(extractBefore(extractAfter(obj.selection(i), "/"), "/"));
                trial_name = extractAfter(extractAfter(obj.selection(i), "/"), "/");

                cur_bird = getBirdFromName(flapper_name, obj.Flapperoo, obj.MetaBird);

                lim_AoA_sel = cur_bird.angles(cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2));
                
                cur_file = obj.data_path + "/plot data/" + cur_bird.name + "/" + cur_struct_match.file_name;
                disp("Loading " + cur_file)
                if (obj.stroke_index == 0)
                    load(cur_file, "avg_forces", "err_forces")
                    disp("Full Stroke")
                    lim_avg_forces = avg_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                elseif (obj.stroke_index == 1)
                    load(cur_file, "avg_up_forces", "err_up_forces")
                    disp("Upstroke")
                    lim_avg_forces = avg_up_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_up_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                elseif (obj.stroke_index == 2)
                    load(cur_file, "avg_down_forces", "err_down_forces")
                    disp("Downstroke")
                    lim_avg_forces = avg_down_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_down_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                end

                dir_parts = split(dir_name, '_');

                if (obj.sub)
                    dir_parts(2) = "Sub";
                    dir_name = strjoin(dir_parts, "_");
                end

                wind_speed = sscanf(dir_parts(end), '%g', 1);
                s_ind = find(cur_bird.speeds == wind_speed);

                ind_c_dir = find([unique_dir.dir_name] == dir_name);
                ind_c_trial = find(unique_dir(ind_c_dir).trial_names == trial_name);
                freq_index = find(strtrim(cur_struct_match.trial_names) == trial_name);

                if (isempty(freq_index))
                    disp("Oops. Didn't find an exact wingbeat frequency match.")
                    freq_index = compareAoAUI.findClosestStString(trial_name, cur_struct_match.trial_names);
                end

                % Get Quasi-Steady Model Force
                % Predictions
                if (obj.aero_model)
                    wing_freq = cur_bird.freqs(freq_index);
                    wing_freq = str2double(extractBefore(wing_freq, " Hz"));
    
                    AR = 2*cur_bird.AR;
    
                    if obj.thinAirfoil
                        lift_slope = ((2*pi) / (1 + 2/AR));
                        pitch_slope = -lift_slope / 4;
                    else
                        [lift_slope, pitch_slope] = getGlideSlopes(lim_AoA_sel, lim_avg_forces);
                    end
    
                    aero_force = get_model(cur_bird.name, obj.data_path, lim_AoA_sel, wing_freq, wind_speed,...
                                                        lift_slope, pitch_slope, AR);
                end

                for idx = 1:6
                ax = tiles(idx);
                hold(ax, 'on');
                e = errorbar(ax, lim_AoA_sel, lim_avg_forces(idx,:,freq_index), lim_err_forces(idx,:,freq_index),'.');
                e.MarkerSize = 25;
                e.Color = colors(ind_c_trial, ind_c_dir);
                e.MarkerFaceColor = colors(ind_c_trial, ind_c_dir);
                e.DisplayName = abbr_sel(i);
                % e.Marker = markers(m);
                

                % ---------Plotting model-----------
                % aerodynamics model is nondimensionalized, so
                % data should also be nondimensionalized when
                % comparing the two. Also only occurs if
                % frequency or wind speed have changed
                if (obj.norm && obj.aero_model && (last_f_ind ~= freq_index || last_s_ind ~= s_ind))
                
                % if index is odd
                if (mod(idx, 2) ~= 0)
                    line = plot(ax, lim_AoA_sel, aero_force(idx, :));
                    line.Color = colors(ind_c_trial, ind_c_dir);
                    line.LineStyle = "--";
                    line.LineWidth = 2;
                    line.DisplayName = "Aero Model - " + abbr_sel(i);
                end

                if (idx == 5)
                last_f_ind = freq_index;
                last_s_ind = s_ind;
                end
                end

                hold(ax, 'off');
                end
           end

        % -----------------------------------------------------
        % ---- Plotting a single axes defined by obj.index ----
        % -----------------------------------------------------
        else
            ax = axes(plot_panel);
            idx = obj.index;


            last_f_ind = 0;
            last_s_ind = 0;
            for i = 1:length(obj.selection)
                % remove wingbeat frequency from selector
                % selector = char(obj.selection(i));
                % slashIndices = strfind(selector, '/');
                % selector = string(selector(1:slashIndices(2) - 1));
                selector = obj.selection(i);
                
                for j = 1:length(struct_matches)
                    if (selector == struct_matches(j).selector)
                        cur_struct_match = struct_matches(j);
                        break;
                    end
                end

                flapper_name = string(extractBefore(obj.selection(i), "/"));
                dir_name = string(extractBefore(extractAfter(obj.selection(i), "/"), "/"));
                trial_name = extractAfter(extractAfter(obj.selection(i), "/"), "/");

                cur_bird = getBirdFromName(flapper_name, obj.Flapperoo, obj.MetaBird);

                lim_AoA_sel = cur_bird.angles(cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2));
                
                cur_file = obj.data_path + "/plot data/" + cur_bird.name + "/" + cur_struct_match.file_name;
                disp("Loading " + cur_file)
                if (obj.stroke_index == 0)
                    load(cur_file, "avg_forces", "err_forces")
                    disp("Full Stroke")
                    lim_avg_forces = avg_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                elseif (obj.stroke_index == 1)
                    load(cur_file, "avg_up_forces", "err_up_forces")
                    disp("Upstroke")
                    lim_avg_forces = avg_up_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_up_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                elseif (obj.stroke_index == 2)
                    load(cur_file, "avg_down_forces", "err_down_forces")
                    disp("Downstroke")
                    lim_avg_forces = avg_down_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                    lim_err_forces = err_down_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
                end

                dir_parts = split(dir_name, '_');

                if (obj.sub)
                    dir_parts(2) = "Sub";
                    dir_name = strjoin(dir_parts, "_");
                end

                wind_speed = sscanf(dir_parts(end), '%g', 1);
                s_ind = find(cur_bird.speeds == wind_speed);

                ind_c_dir = find([unique_dir.dir_name] == dir_name);
                ind_c_trial = find(unique_dir(ind_c_dir).trial_names == trial_name);
                freq_index = find(strtrim(cur_struct_match.trial_names) == trial_name);

                if (isempty(freq_index))
                    disp("Oops. Didn't find an exact wingbeat frequency match.")
                    freq_index = compareAoAUI.findClosestStString(trial_name, cur_struct_match.trial_names);
                end

                % Get Quasi-Steady Model Force
                % Predictions
                if (obj.aero_model)
                    wing_freq = cur_bird.freqs(freq_index);
                    wing_freq = str2double(extractBefore(wing_freq, " Hz"));

                    AR = 2*cur_bird.AR;

                    if obj.thinAirfoil
                        lift_slope = ((2*pi) / (1 + 2/AR));
                        pitch_slope = -lift_slope / 4;
                    else
                        [lift_slope, pitch_slope] = getGlideSlopes(lim_AoA_sel, lim_avg_forces);
                    end
    
                    aero_force = get_model(cur_bird.name, obj.data_path, lim_AoA_sel, wing_freq, wind_speed,...
                                                        lift_slope, pitch_slope, AR);
                end

                hold(ax, 'on');
                if (obj.regress)
                    x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                    y = lim_avg_forces(idx,:,freq_index)';
                    b = x\y;
                    model = x*b;
                    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                    label = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
                    p = plot(ax, lim_AoA_sel, model);
                    p.DisplayName = label;
                    p.Color = colors(ind_c_trial, ind_c_dir);
                    % p.Color = colors(ind_c_dir, ind_c_trial);
                    p.LineWidth = 2;
                end
                e = errorbar(ax, lim_AoA_sel, lim_avg_forces(idx,:,freq_index), lim_err_forces(idx,:,freq_index),'.');
                e.MarkerSize = 25;
                e.Color = colors(ind_c_trial, ind_c_dir);
                e.MarkerFaceColor = colors(ind_c_trial, ind_c_dir);
                % e.Color = colors(ind_c_dir, ind_c_trial);
                % e.MarkerFaceColor = colors(ind_c_dir, ind_c_trial);
                e.DisplayName = abbr_sel(i);
                
                % ---------Plotting model-----------
                % aerodynamics model is nondimensionalized, so
                % data should also be nondimensionalized when
                % comparing the two. Also only occurs if
                % frequency or wind speed have changed
                if (obj.norm && obj.aero_model && (last_f_ind ~= freq_index || last_s_ind ~= s_ind))
                
                % if index is odd
                if (mod(idx, 2) ~= 0)
                    line = plot(ax, lim_AoA_sel, aero_force(idx, :));
                    line.Color = colors(ind_c_trial, ind_c_dir);
                    line.LineStyle = "--";
                    line.LineWidth = 2;
                    line.DisplayName = "Aero Model - " + abbr_sel(i);
                end

                last_f_ind = freq_index;
                last_s_ind = s_ind;
                end

            end

            title(ax, [sub_title titles(idx)]);
            xlabel(ax, x_label);
            ylabel(ax, y_labels(idx))
            grid(ax, 'on');
            l = legend(ax, Location="best");
            ax.FontSize = 18;
        end
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