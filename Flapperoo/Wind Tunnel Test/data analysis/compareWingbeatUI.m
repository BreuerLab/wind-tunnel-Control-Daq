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

    % booleans for model
    mod_inertial;
    mod_added_mass;
    mod_aero;
    mod_total;

    % ------- Available parameters user can select from -------
    Flapperoo;
    MetaBird;

    % --------- Actively selected parameters ---------
    % full case name includes type, freq, speed, and angle
    selection;

    sel_bird;
    sel_type;
    sel_freq;
    sel_speed;
    sel_angle;

    % Curves currently displayed on plot
    plot_curves;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = compareWingbeatUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.index = 0;
        obj.axes_labels = ["All", "Drag", "Transverse Lift", "Lift",...
            "Roll Moment", "Pitch Moment", "Yaw Moment"];
        obj.norm = false;
        obj.norm_period = true;
        obj.pitch_shift = true;
        obj.sub = false;
        obj.spectrum = false;
        obj.freq_scale = false;
        obj.log_scale = false;
        obj.filt_num = 3;

        mod_inertial = false;
        mod_added_mass = false;
        mod_aero = false;
        mod_total = false;

        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");

        obj.selection = strings(0);
        obj.sel_bird = obj.Flapperoo;
        obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
        obj.sel_freq = obj.sel_bird.freqs(1);
        obj.sel_speed = obj.sel_bird.speeds(1);
        obj.sel_angle = obj.sel_bird.angles(1);

        obj.plot_curves = [];
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
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

        % Dropdown box for wingbeat frequency selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        d3.Items = obj.sel_bird.freqs(obj.sel_bird.freqs ~= "0 Hz");
        d3.ValueChangedFcn = @(src, event) freq_change(src, event);

        % Dropdown box for angle of attack selection
        drop_y4 = drop_y3 - (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [10 drop_y4 180 unit_height];
        d4.Items = obj.sel_bird.angles + " deg";
        d4.ValueChangedFcn = @(src, event) angle_change(src, event);

        % Dropdown box for wind speed selection
        drop_y5 = drop_y4 - (unit_height + unit_spacing);
        d5 = uidropdown(option_panel);
        d5.Position = [10 drop_y5 180 unit_height];
        d5.Items = obj.sel_bird.speeds + " m/s";
        d5.ValueChangedFcn = @(src, event) speed_change(src, event, d3);

        d1.ValueChangedFcn = @(src, event) flapper_change(src, event, d2, d3, d4, d5);

        % Subtraction Case Selection
        button1_y = drop_y5 - (unit_height + unit_spacing);
        b1 = uibutton(option_panel,"state");
        b1.Text = "Subtraction";
        b1.Position = [20 button1_y 160 unit_height];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) subtraction_change(src, event, plot_panel, d3);

        % Subtraction Case Selection
        % % Dropdown box for flapper type selection
        % drop_y5 = button1_y - 35;
        % d5 = uidropdown(option_panel);
        % d5.Position = [10 drop_y5 180 30];
        % d5.Items = obj.types;
        % % d5.ValueChangedFcn = @(src, event) type_change(src, event);
        % 
        % % Dropdown box for wingbeat frequency selection
        % drop_y6 = drop_y5 - 35;
        % d6 = uidropdown(option_panel);
        % d6.Position = [10 drop_y6 180 30];
        % d6.Items = obj.freqs;
        % % d6.ValueChangedFcn = @(src, event) freq_change(src, event);
        % 
        % % Dropdown box for angle of attack selection
        % drop_y7 = drop_y6 - 35;
        % d7 = uidropdown(option_panel);
        % d7.Position = [10 drop_y7 180 30];
        % d7.Items = obj.angles + " deg";
        % % d7.ValueChangedFcn = @(src, event) angle_change(src, event);
        % 
        % % Dropdown box for wind speed selection
        % drop_y8 = drop_y7 - 35;
        % d8 = uidropdown(option_panel);
        % d8.Position = [10 drop_y8 180 30];
        % d8.Items = obj.speeds + " m/s";
        % % d8.ValueChangedFcn = @(src, event) speed_change(src, event, d2);

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

        % Dropdown box for which force/moment axes to display
        drop_y9 = list_y - (unit_height + unit_spacing);
        d9 = uidropdown(option_panel);
        d9.Position = [10 drop_y9 180 unit_height];
        d9.Items = obj.axes_labels;
        d9.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        button3_y = drop_y9 - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "Normalize Y-Axis";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) norm_change(src, event, plot_panel, d3);

        button4_y = button3_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel,"state");
        b5.Text = "Normalize X-Axis";
        b5.Position = [20 button4_y 160 unit_height];
        b5.Value = true;
        b5.BackgroundColor = [0.3010 0.7450 0.9330];
        b5.ValueChangedFcn = @(src, event) norm_period_change(src, event, plot_panel);
        
        button5_y = button4_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel,"state");
        b6.Text = "Shift Pitch To LE";
        b6.Position = [20 button5_y 160 unit_height];
        b6.Value = true;
        b6.BackgroundColor = [0.3010 0.7450 0.9330];
        b6.ValueChangedFcn = @(src, event) pitch_shift_change(src, event, plot_panel);

        model_panel_height = 0.16*screen_height;
        model_panel_y = button5_y - unit_spacing - model_panel_height;
        model_panel = uipanel(option_panel);
        model_panel.Title = "Model";
        model_panel.TitlePosition = 'centertop';
        model_panel.Position = [30 model_panel_y 140 model_panel_height];

        check1_y = model_panel_height - 1.6*unit_height;
        c1 = uicheckbox(model_panel);
        c1.Text = "Inertial";
        c1.Position = [30 check1_y 120 unit_height];
        c1.ValueChangedFcn = @(src, event) model_inertial_change(src, event, plot_panel);

        check2_y = check1_y - (unit_height + unit_spacing);
        c2 = uicheckbox(model_panel);
        c2.Text = "Added Mass";
        c2.Position = [30 check2_y 120 unit_height];
        c2.ValueChangedFcn = @(src, event) model_added_mass_change(src, event, plot_panel);

        check3_y = check2_y - (unit_height + unit_spacing);
        c3 = uicheckbox(model_panel);
        c3.Text = "Thin Airfoil";
        c3.Position = [30 check3_y 120 unit_height];
        c3.ValueChangedFcn = @(src, event) model_aero_change(src, event, plot_panel);

        check4_y = check3_y - (unit_height + unit_spacing);
        c4 = uicheckbox(model_panel);
        c4.Text = "Total";
        c4.Position = [30 check4_y 120 unit_height];
        c4.ValueChangedFcn = @(src, event) model_total_change(src, event, plot_panel);

        filt_types = ["Raw", "Filtered - F_c = 50 Hz", "Filtered - F_c = 10*w_f Hz"];
        drop_y10 = model_panel_y - (unit_height + unit_spacing);
        d10 = uidropdown(option_panel);
        d10.Items = filt_types;
        d10.Value = filt_types(end);
        d10.Position = [5 drop_y10 190 unit_height];
        s = uistyle(Interpreter="tex");
        addStyle(d10,s)
        d10.ValueChangedFcn = @(src, event) filt_change(src, event, plot_panel);

        button6_y = drop_y10 - (unit_height + unit_spacing);
        b7 = uibutton(option_panel,"state");
        b7.Text = "Spectrum";
        b7.Position = [20 button6_y 160 unit_height];
        b7.BackgroundColor = [1 1 1];
        b7.ValueChangedFcn = @(src, event) spectrum_change(src, event, plot_panel, d3);

         % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button7_y = button6_y - (unit_height + unit_spacing);
        b8 = uibutton(option_panel, "state");
        b8.Position = [15 button7_y 80 unit_height];
        b8.BackgroundColor = [1 1 1];
        b8.Text = "f_w scale";
        b8.Interpreter = 'tex';
        b8.ValueChangedFcn = @(src, event) freq_scale_change(src, event, plot_panel);

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b9 = uibutton(option_panel, "state");
        b9.Position = [105 button7_y 80 unit_height];
        b9.BackgroundColor = [1 1 1];
        b9.Text = "Log scale";
        b9.Interpreter = 'tex';
        b9.ValueChangedFcn = @(src, event) log_scale_change(src, event, plot_panel);

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
            obj.sel_freq = obj.sel_bird.freqs(1);
            obj.sel_angle = obj.sel_bird.angles(1);
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
        function freq_change(src, ~)
            obj.sel_freq = src.Value;
        end

        % update angle variable with new value selected by user
        function angle_change(src, ~)
            obj.sel_angle = str2double(extractBefore(src.Value, " deg"));
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
                    St = freqToSt(obj.sel_bird.name, wing_freq, obj.sel_speed);
                    d2.Items{i} = ['St: ' num2str(St)];
                end
            end
        end

        function subtraction_change(src, ~, plot_panel, d2)
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
            if (obj.norm)
                % Extract first number after 'St: '
                St = sscanf(extractAfter(obj.sel_freq, "St: "), '%g', 1);
                abbr_freqs = str2double(extractBefore(obj.sel_bird.freqs(1:end-2), " Hz")); % remove v2 trials
                sel_freq = stToFreq(obj.sel_bird.name, St, obj.sel_speed, abbr_freqs);
                case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + sel_freq + " Hz " + obj.sel_angle + " deg";
                % disp_case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + obj.sel_freq + " " + obj.sel_angle + " deg";
            else
                case_name = obj.sel_type + " " + obj.sel_speed + " m/s " + obj.sel_freq + " " + obj.sel_angle + " deg";
                % disp_case_name = case_name;
            end

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
            obj.index = find(obj.axes_labels == src.Value) - 1;
            obj.update_plot(plot_panel);
        end

        function norm_change(src, ~, plot_panel, d2)
            if (src.Value)
                obj.norm = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                % replace freqs with strouhal numbers
                for i = 1:length(d2.Items)
                    wing_freq = str2double(extractBefore(d2.Items{i}, " Hz"));
                    St = freqToSt(obj.sel_bird.name, wing_freq, obj.sel_speed);
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

        function pitch_shift_change(src, ~, plot_panel)
            if (src.Value)
                obj.pitch_shift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.pitch_shift = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function model_inertial_change(src, ~, plot_panel)
            if (src.Value)
                obj.mod_inertial = true;
            else
                obj.mod_inertial = false;
            end
            obj.update_plot(plot_panel);
        end

        function model_added_mass_change(src, ~, plot_panel)
            if (src.Value)
                obj.mod_added_mass = true;
            else
                obj.mod_added_mass = false;
            end
            obj.update_plot(plot_panel);
        end

        function model_aero_change(src, ~, plot_panel)
            if (src.Value)
                obj.mod_aero = true;
            else
                obj.mod_aero = false;
            end
            obj.update_plot(plot_panel);
        end

        function model_total_change(src, ~, plot_panel)
            if (src.Value)
                obj.mod_total = true;
            else
                obj.mod_total = false;
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

        function spectrum_change(src, ~, plot_panel, d2)
            if (src.Value)
                obj.spectrum = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                d2.Items = obj.sel_bird.freqs;
            else
                obj.spectrum = false;
                src.BackgroundColor = [1 1 1];
                d2.Items = obj.sel_bird.freqs(obj.sel_bird.freqs ~= "0 Hz");
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

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)

    function [sel_type, sel_speed, sel_freq, sel_angle] = parseCases(case_name)
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
                        split_time_str = split(time_str);
                        h_m_s = split_time_str(2);
                        split_h_m_s = str2double(split(h_m_s, "-"));
                        if (split_h_m_s(1) < 6)
                            split_h_m_s(1) = split_h_m_s(1) + 12;
                        end
                        time_val = split_h_m_s(1)*3600 + split_h_m_s(2)*60 + split_h_m_s(3);
        
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

    function lighter_color = getLightColor(original_color)
        original_color = hex2rgb(original_color);
                
        % Amount to lighten (0 = no change, 1 = completely white)
        fade_amount = 0.7;  % Adjust this value to control how light you want the color
        
        % White color in RGB
        white = [1, 1, 1];
        
        % Linearly interpolate between the original color and white
        lighter_color = (1 - fade_amount) * original_color + fade_amount * white;
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

    % results is a 6 x N_frames matrix
    function [f, power, num_windows, f_min] = freq_spectrum(results, frame_rate)
        % min freq is 1 / ((1 / freq) * (180 wingbeats))
        % = freq / 180
        f_min = 0.2;
        window = frame_rate / f_min;
        num_windows = round(length(results) / window);
        noverlap = window/2;
    
        signal = results';
        % note mean knows to take the mean of the columns
        signal = signal - mean(signal);
        [pxx, f] = pwelch(signal, window, noverlap, window, frame_rate);
        power = 10*log10(pxx);
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

        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];
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

        [x_label, y_labels] = compareWingbeatUI.get_labels(obj.norm_period, obj.norm, obj.spectrum, obj.freq_scale);
        titles = obj.axes_labels(2:7);

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

        colors = getColors(length(uniq_types), length(uniq_speeds), length(uniq_freqs), length(obj.selection));

        uniq_counts = [length(uniq_types), length(uniq_speeds)];
        [B, I] = sort(uniq_counts);
        
        if (I(2) == 1)
            common_var = uniq_types;
        else
            common_var = string(uniq_speeds);
        end

        % Back when model lines had specific colors
        % mod_colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
        %     [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
        %     [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
        %     [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];

        end

        if (length(obj.selection) > 1)
            [abbr_sel] = compareWingbeatUI.get_abbr_names(obj.selection);
        end
    
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

            last_freq = 0;
            last_speed = 0;
            for i = 1:length(obj.selection)
            
            [sel_type, sel_speed, sel_freq, sel_angle] = compareWingbeatUI.parseCases(obj.selection(i));
            wing_freq = str2double(extractBefore(sel_freq, " Hz"));
            if (obj.sub)
                sub_type = compareWingbeatUI.getSubType(sel_type, obj.sel_bird);
            end
            
            % Get color for this case name
            sels = [sel_type, sel_speed];
            original_color = colors(find(uniq_freqs == sel_freq), find(common_var == sels(I(2)))); % hex
            lighter_color = compareWingbeatUI.getLightColor(original_color); % RGB

            % Using what all case names have in common, come up
            % with an abbreviated name
            case_name = sel_type + " " + sel_speed + " m/s " + sel_freq + " " + sel_angle + " deg";
            if (exist("abbr_sel", "var"))
                abbr_name = compareWingbeatUI.getAbbrName(case_name, abbr_sel);
            else
                abbr_name = case_name;
            end

            % Find exact filename matching this case
            [data_filename, data_folder] = compareWingbeatUI.findMatchFile(sel_type, sel_speed, sel_freq, sel_angle, obj.sel_bird.freqs, processed_data_files);
        
            if (obj.spectrum)
            [time_data, force_data, f, power, norm_factors] ...
            = compareWingbeatUI.load_spectrum_data(data_folder, data_filename, obj.filt_num, obj.norm);

            if (obj.freq_scale)
                f = f / wing_freq;
            end

            for idx = 1:6
                ax = tiles(idx);

                hold(ax, 'on');
                line = plot(ax, f, power(:,idx));
                if (obj.log_scale)
                    set(ax, 'XScale', 'log');
                end
                if (obj.freq_scale)
                    xlim(ax, [0 20])
                else
                    xlim(ax, [0 100])
                end
                line.DisplayName = abbr_name;
                line.Color = original_color;
                line.LineWidth = 2;
            end

            else

            AR = 2*obj.sel_bird.AR;

            thinAirfoil = true;
            if thinAirfoil % MAKE A BUTTON
                lift_slope = ((2*pi) / (1 + 2/AR));
                pitch_slope = -lift_slope / 4;
            else
                [lift_slope, pitch_slope] = getGlideSlopes(lim_AoA_sel, lim_avg_forces); % INPUTS UNDEFINED
            end

            % Get forces from quasi-steady model
            [time, inertial_force, added_mass_force, aero_force] = ...
                getModel(obj.data_path, obj.sel_bird.name, sel_freq, sel_angle, sel_speed, lift_slope, pitch_slope, AR);

            [center_to_LE, ~, ~, ~, ~] = getWingMeasurements(obj.sel_bird.name);

            % Load data from file
            [frames, cycle_avg_forces, cycle_std_forces, ...
                cycle_min_forces, cycle_max_forces, cycle_rmse_forces, norm_factors] ...
            = compareWingbeatUI.load_data(data_folder, data_filename, obj.filt_num, obj.pitch_shift, center_to_LE, sel_angle, obj.norm);

            % Use dynamic pressure force to scale modeled data
            if (obj.norm)
                inertial_force = [inertial_force(:,1) / norm_factors(1),...
                        inertial_force(:,2) / norm_factors(1),...
                        inertial_force(:,3) / norm_factors(2)];

                added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
                        added_mass_force(:,2) / norm_factors(1),...
                        added_mass_force(:,3) / norm_factors(2)];
            else
                aero_force = [aero_force(:,1) * norm_factors(1),...
                        aero_force(:,2) * norm_factors(1),...
                        aero_force(:,3) * norm_factors(2)];
            end
            total_drag = aero_force(:,1) + inertial_force(:,1) + added_mass_force(:,1);
            total_lift = aero_force(:,2) + inertial_force(:,2) + added_mass_force(:,2);
            total_moment = aero_force(:,3) + inertial_force(:,3) + added_mass_force(:,3);
            total_force = [total_drag, total_lift, total_moment];

            if (obj.sub)
            % Find exact filename matching this case
            try
            [sub_filename, sub_folder] = compareWingbeatUI.findMatchFile(sub_type, sel_speed, sel_freq, sel_angle, obj.sel_bird.freqs, processed_data_files);
            catch ME
            error("Are you sure that data exists?")
            end

            disp("Subtracting from: " + sub_folder + "  /  " + sub_filename)

            [center_to_LE, ~, ~, ~, ~] = getWingMeasurements(obj.sel_bird.name);

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

            if (~obj.norm_period)
                % Scale x-axis back to time domain
                frames = (frames / wing_freq);
            end

            upper_results = cycle_avg_forces + cycle_std_forces;
            lower_results = cycle_avg_forces - cycle_std_forces;

            for idx = 1:6
                ax = tiles(idx);

                hold(ax, 'on');
                xconf = [frames, frames(end:-1:1)];         
                yconf = [upper_results(idx, :), lower_results(idx, end:-1:1)];
                p = fill(ax, xconf, yconf, lighter_color);
                p.HandleVisibility = 'off';
                p.EdgeColor = 'none';
                data_l = plot(ax, frames, cycle_avg_forces(idx, :));
                data_l.DisplayName = abbr_name;
                data_l.Color = original_color;
                data_l.LineWidth = 2;

                if (last_freq ~= wing_freq || last_speed ~= sel_speed)
                obj.plot_model(idx, ax, original_color, time, inertial_force, added_mass_force, aero_force, total_force, abbr_name);
                if (idx == 5)
                    last_freq = wing_freq;
                    last_speed = sel_speed;
                end
                end

                % plot_wingbeat_patch();
                hold(ax, 'off');
            end
            end
            end

        % -----------------------------------------------------
        % ---- Plotting a single axes defined by obj.index ----
        % -----------------------------------------------------
        else
            ax = axes(plot_panel);
            idx = obj.index;

            last_freq = 0;
            last_speed = 0;
            for i = 1:length(obj.selection)
            
            [sel_type, sel_speed, sel_freq, sel_angle] = compareWingbeatUI.parseCases(obj.selection(i));
            wing_freq = str2double(extractBefore(sel_freq, " Hz"));
            if (obj.sub)
                sub_type = compareWingbeatUI.getSubType(sel_type, obj.sel_bird);
            end

            % Get color for this case name
            sels = [sel_type, sel_speed];
            original_color = colors(find(uniq_freqs == sel_freq), find(common_var == sels(I(2)))); % hex
            lighter_color = compareWingbeatUI.getLightColor(original_color); % RGB

            % Using what all case names have in common, come up
            % with an abbreviated name
            case_name = sel_type + " " + sel_speed + " m/s " + sel_freq + " " + sel_angle + " deg";
            if (exist("abbr_sel", "var"))
                abbr_name = compareWingbeatUI.getAbbrName(case_name, abbr_sel);
            else
                abbr_name = case_name;
            end

            % Find exact filename matching this case
            [data_filename, data_folder]...
                = compareWingbeatUI.findMatchFile(sel_type, sel_speed, sel_freq, sel_angle, obj.sel_bird.freqs, processed_data_files);
        
            if (obj.sub)
                % Find exact filename matching this case
                try
                [sub_filename, sub_folder]...
                    = compareWingbeatUI.findMatchFile(sub_type, sel_speed, sel_freq, sel_angle, obj.sel_bird.freqs, processed_data_files);
                catch ME
                    error("Are you sure that data exists?")
                end
            end

            if (obj.spectrum)
            [time_data, force_data, f, power, norm_factors] ...
            = compareWingbeatUI.load_spectrum_data(data_folder, data_filename, obj.filt_num, obj.norm);

            if (obj.sub)
                [sub_time, sub_force, sub_f, sub_power, ~]...
                    = compareWingbeatUI.load_spectrum_data(sub_folder, sub_filename, obj.filt_num, obj.norm);

                disp("Subtracting spectrum from: " + sub_folder + "  /  " + sub_filename)
                if (f == sub_f)
                    power = power - sub_power;
                else
                    error("Frequencies don't match!")
                end
            end

            hold(ax, 'on');
            if (obj.freq_scale)
                f = f / wing_freq;
            end
            line = plot(ax, f, power(:,idx));
            if (obj.log_scale)
                set(ax, 'XScale', 'log');
            end
            if (obj.freq_scale)
                xlim(ax, [0 20])
            else
                xlim(ax, [0 100])
            end
            line.DisplayName = abbr_name;
            line.Color = original_color;
            line.LineWidth = 2;

            else

            AR = 2*obj.sel_bird.AR;

            thinAirfoil = true;
            if thinAirfoil % MAKE A BUTTON
                lift_slope = ((2*pi) / (1 + 2/AR));
                pitch_slope = -lift_slope / 4;
            else
                [lift_slope, pitch_slope] = getGlideSlopes(lim_AoA_sel, lim_avg_forces); % INPUTS UNDEFINED
            end

            % Get forces from quasi-steady model
            [time, inertial_force, added_mass_force, aero_force] = ...
                getModel(obj.data_path, obj.sel_bird.name, sel_freq, sel_angle, sel_speed, lift_slope, pitch_slope, AR);

            [center_to_LE, ~, ~, ~, ~] = getWingMeasurements(obj.sel_bird.name);

            % Load data from file
            [frames, cycle_avg_forces, cycle_std_forces, ...
                cycle_min_forces, cycle_max_forces, cycle_rmse_forces, norm_factors] ...
            = compareWingbeatUI.load_data(data_folder, data_filename, obj.filt_num, obj.pitch_shift, center_to_LE, sel_angle, obj.norm);

            if (obj.norm)
                inertial_force = [inertial_force(:,1) / norm_factors(1),...
                        inertial_force(:,2) / norm_factors(1),...
                        inertial_force(:,3) / norm_factors(2)];

                added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
                        added_mass_force(:,2) / norm_factors(1),...
                        added_mass_force(:,3) / norm_factors(2)];
            else
                aero_force = [aero_force(:,1) * norm_factors(1),...
                        aero_force(:,2) * norm_factors(1),...
                        aero_force(:,3) * norm_factors(2)];
            end

            total_drag = aero_force(:,1) + inertial_force(:,1) + added_mass_force(:,1);
            total_lift = aero_force(:,2) + inertial_force(:,2) + added_mass_force(:,2);
            total_moment = aero_force(:,3) + inertial_force(:,3) + added_mass_force(:,3);
            total_force = [total_drag, total_lift, total_moment];

            % just for lift case. Wanted to better understand
            % when inertia is dominating over aerodynamics
            phase_ratio = max(aero_force(:,2)) / max(inertial_force(:,2) + added_mass_force(:,2));
            disp("----------------------------------------------------------------------------")
            disp("Aerodynamics are " + phase_ratio + " times the sum of inertia and added mass")
            disp("----------------------------------------------------------------------------")

            if (obj.sub)
            disp("Subtracting from: " + sub_folder + "  /  " + sub_filename)

            [center_to_LE, ~, ~, ~, ~] = getWingMeasurements(obj.sel_bird.name);

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

            %=============================================
            % ----------test freq scaling of peaks--------
            %=============================================
            % cycle_avg_forces = cycle_avg_forces / wing_freq^2;

            if (~obj.norm_period)
                % Scale x-axis back to time domain
                frames = (frames / wing_freq);
            end

            upper_results = cycle_avg_forces + cycle_std_forces;
            lower_results = cycle_avg_forces - cycle_std_forces;

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

            if (last_freq ~= wing_freq || last_speed ~= sel_speed)
            obj.plot_model(idx, ax, original_color, time, inertial_force, added_mass_force, aero_force, total_force, abbr_name);
            last_freq = wing_freq;
            last_speed = sel_speed;
            end
            hold(ax, 'off');
            end

            end

            title(ax, titles(idx));
            xlabel(ax, x_label);
            ylabel(ax, y_labels(idx))
            grid(ax, 'on');
            legend(ax, Location="northeast");
            ax.FontSize = 18;
        end
    end

    function plot_model(obj, idx, ax, original_color, time, inertial_force, added_mass_force, aero_force, total_force, abbr_name)
        % (1/2)*(x - 1) + 1 is the formula needed to convert
        % 1, 3, 5 to 1, 2, 3
        mod_idx = (1/2)*(idx - 1) + 1;

        if (floor(mod_idx) == mod_idx)
        if (obj.mod_inertial)
        inertial_l = plot(ax, time / max(time), inertial_force(:,mod_idx));
        inertial_l.Marker = "*";
        inertial_l.LineWidth = 2;
        inertial_l.Color = original_color;
        if (length(obj.selection) > 1)
            inertial_l.DisplayName = abbr_name + " - Inertial";
        else
            inertial_l.DisplayName = "Inertial";
        end
        end
        if (obj.mod_added_mass)
        added_mass_l = plot(ax,time / max(time), added_mass_force(:,mod_idx));
        added_mass_l.Marker = "o";
        added_mass_l.LineWidth = 2;
        added_mass_l.Color = original_color;
        if (length(obj.selection) > 1)
            added_mass_l.DisplayName = abbr_name + " - Added Mass";
        else
            added_mass_l.DisplayName = "Added Mass";
        end
        end
        if (obj.mod_aero)
        aero_l = plot(ax, time / max(time), aero_force(:,mod_idx));
        aero_l.Marker = "x";
        aero_l.LineWidth = 2;
        aero_l.Color = original_color;
        if (length(obj.selection) > 1)
            aero_l.DisplayName = abbr_name + " - Thin Airfoil";
        else
            aero_l.DisplayName = "Thin Airfoil";
        end
        end
        if (obj.mod_total)
        total_l = plot(ax, time / max(time), total_force(:,mod_idx));
        total_l.LineStyle = "--";
        total_l.LineWidth = 2;
        total_l.Color = original_color;
        if (length(obj.selection) > 1)
            total_l.DisplayName = abbr_name + " - Total Model";
        else
            total_l.DisplayName = "Total Model";
        end
        end
        end

    end
end

end