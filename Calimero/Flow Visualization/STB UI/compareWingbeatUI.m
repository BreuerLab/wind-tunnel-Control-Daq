% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef compareWingbeatUI < handle

    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];

        cur_types = ["flexible";"UP_one_flexible";"UP_two_flexible"];
    end

properties
    mon_num; % 1 or 2, monitor to display plot on

    root_path; % file path to data
    PIV_path;
    force_path;

    % integer, 0-6, defines which force/moment axes to display
    inds;
    % force and moment axes labels used in dropdown box
    axes_labels;
    var_names;
    y_labels;

    % boolean, normalization/non-dimensionalization on or off
    norm;
    % boolean, normalization for x-axis (divided by period)
    norm_period;
    % boolean, move pitch moment from center of transducer to LE
    pitch_shift;
    % boolean, subtraction on or off
    PIV_sub;
    force_sub;
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
    y_cen;

    calc_bool;
    align_bool;
    force_bool;
    % used to calculate forces from vector field data

    % ------- Available parameters user can select from -------
    available_selections;

    selection; % list of selected cases
    sel_type;
    sel_freq;
    sel_amp;

    % Curves currently displayed on plot
    plot_curves;

    distance_labels;
    distance_type_dict;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = compareWingbeatUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.root_path = data_path;
        obj.PIV_path = obj.root_path + "Processed Results\";
        obj.force_path = obj.root_path + "Force Measurements\";

        obj.inds = [];
        % obj.axes_labels = ["Lift", "Drag", "Speed", "Voltage", "Current", "Power"];
        obj.axes_labels = ["Lift - Vorticity", "y*\omega_x", "x*\omega_y", "u*w",...
            "Drag - Vorticity", "z*\omega_y", "y*\omega_z", "(u-U)*u",...
            "Speed", "Acceleration", "Wing Position", "Wing Speed", "Wing Acceleration",...
            "Voltage", "Current", "Power"];
        obj.var_names = ["lift.tot", "lift.vortX", "lift.vortY", "lift_vel",...
                    "drag.tot", "drag.vortY", "drag.vortZ", "drag_vel",...
                    "phase_avg_speed", "phase_avg_acc", "phase_avg_wing_pos",...
                    "phase_avg_wing_speed", "phase_avg_wing_acc",...
                    "phase_avg_volt", "phase_avg_cur", "phase_avg_volt"];
        obj.y_labels = ["Lift (N)","Lift (N)","Lift (N)","Lift (N)",...
            "Drag (N)", "Drag (N)", "Drag (N)", "Drag (N)",...
            "Speed (Hz)", "Acceleration (Hz^2)", ...
            "Position (rad)", "Speed (rad/s)", "Acceleration (rad/s^2)",...
            "Voltage (V)", "Current (mA)", "Power (mW)"];
        obj.norm = false;
        obj.norm_period = true;
        obj.PIV_sub = false;
        obj.force_sub = false;
        obj.freq_scale = false;
        obj.log_scale = false;
        obj.filt_num = 3;
        obj.saveFig = false;
        obj.y_cen = -2.26; % -2.16, 2.55, -0.142 / d.L;

        obj.force_bool = false;
        obj.calc_bool = false;
        obj.align_bool = false;

        % Search through files in path to get types and speeds

        contents = dir(obj.PIV_path);
        files = contents(~[contents.isdir]);

        % Get amps, freqs, types from file names
        obj.available_selections = get_sel_from_file(files);

        obj.sel_type = obj.available_selections{1,1};
        obj.sel_amp = obj.available_selections{1,2};
        obj.sel_freq = obj.available_selections{1,3};

        obj.plot_curves = [];
        % attachFileListsToBird(path, cur_bird);

        obj.sel_type = obj.cur_types(1);
        if ~isequal(sort(obj.cur_types), sort(unique(string(obj.available_selections(:, 1)))))
            error("Downstream type mismatch. Check types...")
        end

        obj.distance_labels = ["x = 0.9m","x = 1.3m","x = 1.7m"];
        obj.distance_type_dict = containers.Map(obj.distance_labels, obj.cur_types);
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
        drop_y1 = screen_height*0.875 - unit_spacing;
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.ValueChangedFcn = @(src, event) type_change(src, event);
        d1.Items = [obj.distance_labels, "all"];

        % Dropdown box for wingbeat frequency selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 unit_height];
        cur_freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),3);
        freqs_string = string(cur_freqs) + " Hz";
        d2.Items = [freqs_string; "all"];

        % Dropdown box for wingbeat amplitude selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        cur_amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == obj.sel_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),2);
        d3.Items = string(cur_amps) + " deg";

        d2.ValueChangedFcn = @(src, event) freq_change(src, event, d3);
        d3.ValueChangedFcn = @(src, event) amp_change(src, event, d2);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = drop_y3 - (unit_height + unit_spacing);
        b2 = uibutton(option_panel);
        b2.Position = [15 button2_y 80 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.Text = "Add entry";

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b3 = uibutton(option_panel);
        b3.Position = [105 button2_y 80 unit_height];
        b3.BackgroundColor = [1 1 1];
        b3.Text = "Delete entry";

        % List of cases currently displayed on the plots
        list_y = button2_y - (3*(unit_height + unit_spacing) + unit_spacing);
        lbox = uilistbox(option_panel);
        lbox.Items = strings(0);
        lbox.Position = [10 list_y 180 3*(unit_height + unit_spacing)];

        b2.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
        b3.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

        button33_y = list_y - (unit_height + unit_spacing);
        b33 = uibutton(option_panel);
        b33.Text = "Clear Entries";
        b33.FontSize = 18;
        b33.Position = [20 button33_y 160 unit_height];
        b33.BackgroundColor = [1 1 1];
        b33.ButtonPushedFcn = @(src, event) clearList(src, event, plot_panel, lbox);

        % Dropdown box for which force/moment axes to display
        % drop_y9 = list_y - (unit_height + unit_spacing);
        % d9 = uidropdown(option_panel);
        % d9.Position = [10 drop_y9 180 unit_height];
        % d9.Items = obj.axes_labels;
        % d9.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        param_panel_height = 300;
        param_panel_width = 180;
        param_panel_y = button33_y - unit_spacing - param_panel_height;
        param_panel = uipanel(option_panel);
        param_panel.Title = "Plot Parameters";
        param_panel.TitlePosition = 'centertop';
        param_panel.Position = [10 param_panel_y param_panel_width param_panel_height];

        % Add Multiple Checkboxes using a loop
        options = obj.axes_labels;
        checkboxes = [];

        for i = 1:length(options)
            checkboxes(i) = uicheckbox(param_panel, ...
                'Text', options(i), ...
                'Position', [20 (param_panel_height - 50 - (i-1)*15) 150 22], ...
                'ValueChangedFcn', @(src, event) updateLogic(src, event, plot_panel));
        end

        button4_y = param_panel_y - (unit_height + unit_spacing);
        b4 = uibutton(option_panel, "state");
        b4.Text = "Show Force";
        b4.FontSize = 18;
        b4.Position = [20 button4_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) force_change(src, event, plot_panel);

        button6_y = button4_y - (unit_height + unit_spacing);
        b6 = uibutton(option_panel, "state");
        b6.Text = "PIV Body Sub";
        b6.FontSize = 18;
        b6.Position = [20 button6_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) PIV_sub_change(src, event, plot_panel);

        button7_y = button6_y - (unit_height + unit_spacing);
        b7 = uibutton(option_panel, "state");
        b7.Text = "Force Body Sub";
        b7.FontSize = 18;
        b7.Position = [20 button7_y 160 unit_height];
        b7.BackgroundColor = [1 1 1];
        b7.ValueChangedFcn = @(src, event) force_sub_change(src, event, plot_panel);

        button77_y = button7_y - (unit_height + unit_spacing);
        b77 = uibutton(option_panel, "state");
        b77.Text = "Live Calculate";
        b77.FontSize = 18;
        b77.Position = [20 button77_y 160 unit_height];
        b77.BackgroundColor = [1 1 1];
        b77.ValueChangedFcn = @(src, event) calc_change(src, event, plot_panel);

        button88_y = button77_y - (unit_height + unit_spacing);
        b88 = uibutton(option_panel, "state");
        b88.Text = "Align";
        b88.FontSize = 18;
        b88.Position = [20 button88_y 160 unit_height];
        b88.BackgroundColor = [1 1 1];
        b88.ValueChangedFcn = @(src, event) align_change(src, event, plot_panel);


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
        b4.FontSize = 18;
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
        function type_change(src, ~)
            if src.Value == "all"
            obj.sel_type = src.Value;
            else
            obj.sel_type = obj.distance_type_dict(src.Value);
            end
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~, d)
            if strcmp(src.Value, "all")
            obj.sel_freq = -1;
            else
            obj.sel_freq = str2double(regexp(src.Value, '\d+', 'match'));
            end
            
            % Change amplitude list to only show those available at this
            % wingbeat frequency
            if obj.sel_freq == -1
                cur_avail_freqs = cell2mat(obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),3));

                max_freq = max(cur_avail_freqs);

                amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == max_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),2);
            else
            amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == obj.sel_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),2);
            end
            d.Items = string(amps) + " deg";
        end

        % update speed variable with new value selected by user
        function amp_change(src, ~, d)
            obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));

            % Change frequency list to only show those available at this
            % wingbeat amplitude
            freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.cur_types(1)),3);
            d.Items = [string(freqs) + " Hz"; "all"];
        end

        function PIV_sub_change(src, ~, plot_panel)
            obj.PIV_sub = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.PIV_sub);
            obj.update_plot(plot_panel);
        end

        function force_sub_change(src, ~, plot_panel)
            obj.force_sub = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.force_sub);
            obj.update_plot(plot_panel);
        end

        function calc_change(src, ~, plot_panel)
            obj.calc_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.calc_bool);
            obj.update_plot(plot_panel);
        end

        function align_change(src, ~, plot_panel)
            obj.align_bool = src.Value;
            src.BackgroundColor = obj.get_button_color(obj.align_bool);
            obj.update_plot(plot_panel);
        end

        function addToList(~, ~, plot_panel, lbox)

            if obj.sel_freq == -1 % "all" case selected
               cur_avail_freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),3);
               for n = 1:length(cur_avail_freqs)
               cur_freq = cur_avail_freqs(n);
                case_name = obj.sel_type + "_" + obj.sel_amp +...
                "deg_" + cur_freq + "Hz";

                if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                    lbox.Items = [lbox.Items, case_name];
                    obj.selection = [obj.selection, case_name];
                end
               end
            elseif obj.sel_type == "all"
               for n = 1:length(obj.cur_types)
               cur_type = obj.cur_types(n);
               case_name = cur_type + "_" + obj.sel_amp +...
                "deg_" + obj.sel_freq + "Hz";

                if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                    lbox.Items = [lbox.Items, case_name];
                    obj.selection = [obj.selection, case_name];
                end
               end
            else
                case_name = obj.sel_type + "_" + obj.sel_amp +...
                "deg_" + obj.sel_freq + "Hz";

                if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                    lbox.Items = [lbox.Items, case_name];
                    obj.selection = [obj.selection, case_name];
                end
            end

            obj.update_plot(plot_panel);
        end

        function removeFromList(~, ~, plot_panel, lbox)
            case_name = lbox.Value;
            % removing value from list that's displayed
            new_list_indices = string(lbox.Items) ~= case_name;
            lbox.Items = lbox.Items(new_list_indices);

            % removing value from list used for plotting
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function clearList(~, ~, plot_panel, lbox)
            % removing value from list that's displayed
            new_list_indices = [];
            lbox.Items = lbox.Items(new_list_indices);

            % removing value from list used for plotting
            obj.selection = [];
            obj.update_plot(plot_panel);
        end

        function updateLogic(src, ~, plot_panel)
            cur_ind = find(obj.axes_labels == src.Text);
            if src.Value
                obj.inds = [obj.inds cur_ind];
            else
                obj.inds(obj.inds == cur_ind) = [];
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
    % Helper function to get button text based on state
    function text = get_button_text(is_active, label)
        if is_active
            text = "Hide " + label;
        else
            text = "Show " + label;
        end
    end

end

%% --------------------------------------------------------------
%---------------------------------------------------------------%
%---------------------------------------------------------------%
% The only function contained in this section is update_plot
methods (Access = private)
    % Helper function to get button color based on state
    function color = get_button_color(obj, is_active)
        if is_active
            color = obj.COLOR_ACTIVE;
        else
            color = obj.COLOR_INACTIVE;
        end
    end

    % update plot after user changes selected variables
    function update_plot(obj, plot_panel)
        fignew = figure('Visible', 'off');
        ax_target = axes('Parent', fignew);
        delete(plot_panel.Children)
        disp("-------------")

        % ----------------------------------------
        % ------------- Color Setup --------------
        % ----------------------------------------
        cur_selections = cell(length(obj.selection),3);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);
            [amp, type, freq] = parse_name(cur_sel);
    
            % Add to list of amplitudes and frequencies
            cur_selections{i,1} = type;
            cur_selections{i,2} = amp;
            cur_selections{i,3} = freq;
        end

        try
        uniq_types = unique(string(cur_selections(:,1)));
        uniq_amps = unique(cell2mat(cur_selections(:,2)));
        uniq_freqs = unique(cell2mat(cur_selections(:,3)));

        colors = getColors(length(uniq_types),...
                           length(uniq_amps),...
                           length(uniq_freqs),...
                           length(obj.selection));
        catch
        uniq_types = unique(string(obj.available_selections(:,1)));
        uniq_amps = unique(cell2mat(obj.available_selections(:,2)));
        uniq_freqs = unique(cell2mat(obj.available_selections(:,3)));

        colors = getColors(length(uniq_types),...
                           length(uniq_amps),...
                           length(uniq_freqs),...
                           length(obj.selection));
        end

        % whether 3 plots of the same case at different downstream distance
        % exist and the align bool is active. If so 3 plots will be aligned
        three_type_bool = obj.align_bool &&...
                          ~isempty(obj.inds) &&...
                          ~isempty(obj.selection);
        % length(uniq_types) == 3 &&...
                          % isscalar(uniq_amps) &&...
                          % isscalar(uniq_freqs) &&...

        colors = flip(colors,1);

        uniq_counts = [length(uniq_types), length(uniq_amps)];
        [B, I] = sort(uniq_counts);

        if (I(2) == 1)
            common_var = uniq_types;
        else
            common_var = string(uniq_amps);
        end

        % ----------------------------------------

        dual_plot = false;
        ylabs = strings(1,2);
        if ~isempty(obj.inds)
            if length(obj.inds) > 1
                for n = 2:length(obj.inds)
                    dual_plot = true;
                    ylabs(1) = obj.y_labels(obj.inds(n-1));
                    ylabs(2) = obj.y_labels(obj.inds(n));

                    % only make two plots if they are using units
                    % if ~strcmp(obj.y_labels(obj.inds(n-1)), obj.y_labels(obj.inds(n)))
                    %     dual_plot = true;
                    %     ylabel_one = obj.y_labels(obj.inds(n-1));
                    %     ylabel_two = obj.y_labels(obj.inds(n));
                    % end
                end
            end
        end

        if three_type_bool
            if length(obj.selection) > 1
                data_list(length(obj.selection)) = struct('val', []);
                get_idx = @(i, j) i; % Function returns i
            elseif length(obj.inds) > 1
               data_list(length(obj.inds)) = struct('val', []);
               get_idx = @(i, j) j; % Function returns j
            elseif obj.force_bool
                data_list(2*length(obj.selection)) = struct('val', []);
                get_idx = @(i, j) i; % Function returns i
            else
                error("Not enough selections for alignment")
            end
        end

        ax = axes(plot_panel);
        hold(ax, 'on');
        hold(ax_target, 'on');
        for j = 1:length(obj.inds)
            index = obj.inds(j);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);

            [amp, type, freq] = parse_name(cur_sel);

            filename = cur_sel + "_phase_avg";
            file_path = obj.PIV_path + filename + ".mat";
            secondary_file_path = obj.PIV_path + filename + "_integral.mat";

            if ismember(index,[1,2])
                vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
            end

            var_name = obj.var_names(index);

            if ismember(index,[1,2,3,4,5,6,7,8]) && obj.calc_bool
                % Compute Lift force
                avg_type = 1;
    
                norm_bool = false;
                [var, err] = get_PIV_force(file_path, cur_sel, var_name, avg_type, norm_bool, obj.y_cen);
            else
                if contains(var_name, ".")
                    abbrv_name = extractBefore(var_name, ".");
                    d1 = load(secondary_file_path, abbrv_name);
                else
                    d1 = load(secondary_file_path, var_name);
                end

                var = eval("d1." + var_name);
                vars = {"L","U"};
                d2 = load(file_path, vars{:});
        
                % Combine by converting to cell arrays of names/values and back to struct
                d = cell2struct([struct2cell(d1); struct2cell(d2)], [fieldnames(d1); fieldnames(d2)], 1);

                % TEMP CODE TO NORMALIZE SPEEDS
                % var = var / mean(var);
            end
            
            % vars_kin = {"phase_avg_pos", "phase_avg_speed", "phase_avg_acc"};
            vars_kin = {"phase_avg_speed", "phase_avg_wing_pos",...
                "phase_avg_wing_speed", "phase_avg_wing_acc", "u_avg"};
            load(secondary_file_path, vars_kin{:})
            freq_cor = mean(phase_avg_speed);
            % added_mass = get_added_mass(phase_avg_pos, phase_avg_speed, phase_avg_acc);
            added_mass = get_added_mass(phase_avg_wing_pos, phase_avg_wing_speed, phase_avg_wing_acc);

            if ismember(index,[1,2,3,4,5,6,7,8]) && obj.PIV_sub
                % filename = "body_phase_avg.mat";
                filename = "ring_time_avg";
                file_path_t = obj.PIV_path + "time_avg/" + filename + ".mat";
                secondary_file_path_t = obj.PIV_path + "time_avg/" + filename + "_integral.mat";

                if ~strcmp(var_name, "lift.vortY")
                if obj.calc_bool
                    % Compute aerodynamic forces
                    norm_bool = false;
                    [bod_var, bod_err] = get_PIV_force(file_path_t, "", var_name, 0, norm_bool, obj.y_cen);
                    var = var - bod_var;
                else
                    if contains(var_name, ".")
                        abbrv_name = extractBefore(var_name, ".");
                        d2 = load(secondary_file_path_t, abbrv_name);
                    else
                        d2 = load(secondary_file_path_t, var_name);
                    end

                    body_var = eval("d2." + var_name);
                    var = var - body_var;
                end
                end
            end

            % Shift data given convection time downstream to target
            % for curves using imaging plane data only
            if ismember(index,[1,2,3,4,5,6,7,8])
            dist = 0.9;
            sep_dist = 0.37;
            if contains(type, "UP_two")
                dist = dist + sep_dist*2;
            elseif contains(type, "UP_one")
                dist = dist + sep_dist;
            end
            speed = 4;
            % speed = mean(-squeeze(u_avg)) * d.U;
            conv_time = dist / speed; % 0.9 m downstream, 4 m/s
            % shift = conv_time * freq;
            shift = conv_time * freq_cor; % get shift as a portion of a cycle
            var = circshift(var, round(shift*length(var)));
            disp("Shifted by: " + round(shift*length(var)) + " / " + length(var))
            % disp("Shifted by: " + mod(round(shift*length(var)), length(var)) + " / " + length(var))

            end

            % If first value less than mean value, shift array since we
            % must have started on the other midstroke position
            % if var(1) < min(var) + range(var)/3
            %     var = circshift(var, 0.4*length(var));
            %     disp("Shifted STB curve for " + cur_sel)
            % end

            % 10 amp flexible case accidentally started at mid-downstroke
            % rather than mid-upstroke used for the rest
            if amp == 10 && ~contains(type, "UP")
                % var = circshift(var, round(0.44*length(var)));
                var = circshift(var, round(0.5*length(var)));
                disp("Shifted STB curve for " + cur_sel)
            end

            norm_bool = false;
            if norm_bool
                var = var / max(var);
            end

            if three_type_bool
                ind = get_idx(i, j);
                data_list(2*ind-1).val = var;
            end

            time = 1:length(var);
            time = time / length(var);

            time_F = [];
            force = [];
            if obj.force_bool && ~contains(type, "UP")
            
            if (ismember(index, [1,2,3,4]))
                    idx = 3;
            elseif (ismember(index, [5,6,7,8]))
                    idx = 1;
            end

            % var_name_F = "wingbeat_avg_forces_raw";
            % var_name_F = "wingbeat_avg_forces";
            var_name_F = "wingbeat_avg_forces_smoothest";
            force = get_force(obj.force_path, type, amp, freq, idx, var_name_F);

            if obj.force_sub
                body_amp = amp;
                if body_amp == 30
                    body_amp = 20;
                end
                body_force = get_force(obj.force_path, "body", body_amp, freq, idx, var_name_F);
                force = force - body_force;
            end

            time_F = 1:length(force);
            time_F = time_F / length(force);

            % THIS NEEDS SOME FIXING HERE, NOT ALWAYS SHIFTING AT THE
            % CORRECT TIME
            if force(1) < mean(force)
                force = circshift(force, round(0.4*length(force)));
                disp("Shifted force curve for " + cur_sel)
            end
            end

            if three_type_bool
                ind = get_idx(i, j);
                data_list(2*ind).val = force;
            end
            color_params.uniq_freqs = uniq_freqs;
            color_params.common_var = common_var;
            color_params.I = I;
            color_params.colors = colors;
            if ~three_type_bool
            obj.plot_data(ax, ax_target, time, var, time_F, force, index, dual_plot, j, cur_sel, color_params, ylabs); % ylabel_one, ylabel_two
            end
        end
        end

        if three_type_bool
        lengths = arrayfun(@(s) length(s.val), data_list, 'UniformOutput', true);
        maxLength = max(lengths);

        % resample data points to have the same number of bins
        for i = 1:length(data_list)
            var = data_list(i).val;

            time = 1:length(var);
            time = time / length(time);
            
            time_interp = 1:maxLength;
            time_interp = time_interp / length(time_interp);

            data_list(i).val = interp1(time, var, time_interp, 'pchip');
        end

        lags = zeros(1,length(data_list)-1);
        for i = 2:length(data_list)
        [data_list(i).val, lags(i-1)] = align_signals(data_list(1).val, data_list(i).val);
        end

        disp(lags)
        % if lags(1) < lags(2) && lags(1) < 0
        %     lags(2) = lags(2) - length(time_interp);
        % end
        % disp(lags)
        % disp(lags / length(time_interp))
        % disp(lags(2) / lags(1))


        for i = 1:length(data_list)
            var = data_list(i).val;
            % cur_sel = obj.selection(i);
            cur_sel = "";
            obj.plot_data(ax, ax_target, time_interp, var, time_F, force, index, dual_plot, 1, cur_sel, color_params, ylabs); % ylabel_one, ylabel_two
        end
        end

        hold(ax, 'off');
        hold(ax_target, 'off');
        if (obj.saveFig)
            filename = "saved_figure.fig";
            % fignew = figure('Visible','off'); % Invisible figure
            % fignew.Position = [500,491,800,600];
            % if (exist("l", "var"))
            %     copyobj([l ax], fignew); % Copy the appropriate axes
            % elseif (exist("cb", "var"))
            %     copyobj([ax cb], fignew); % Copy the appropriate axes
            % else
            %     copyobj(ax, fignew); % Copy the appropriate axes
            % end

            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

      
    end

    function plot_data(obj, ax, ax_target, time, var, time_F, force, index, dual_plot, plot_idx, cur_sel, color_params, ylabs)
        [amp, type, freq] = parse_name(cur_sel);
        % Get color for this case name
        sels = [type, amp];
        original_color = color_params.colors(find(color_params.uniq_freqs == freq), find(color_params.common_var == sels(color_params.I(2)))); % hex

        if dual_plot
            if plot_idx == 1
                yyaxis(ax, 'left')
                line = plot(ax, time, var);
                % for hidden figure for saving
                yyaxis(ax_target, 'left')
                line_h = plot(ax_target, time, var);
            else
                yyaxis(ax, 'right')
                line = plot(ax, time, var);
                % for hidden figure for saving
                yyaxis(ax_target, 'right')
                line_h = plot(ax_target, time, var);
            end
            % Code below is for when force axes have different
            % units/legends
            % if strcmp(ylabel_one, obj.y_labels(index))
            %     yyaxis(ax, 'left')
            %     line = plot(ax, time, var);
            % elseif strcmp(ylabel_two, obj.y_labels(index))
            %     yyaxis(ax, 'right')
            %     line = plot(ax, time, var);
            % end
        else
            line = plot(ax, time, var);
            % for hidden figure for saving
            line_h = plot(ax_target, time, var);
        end
            
            linestyles = ["-", "--", ":", "-."];
            if isscalar(obj.inds)
                legend_entry = strrep(cur_sel,"_"," ");
            else
                legend_entry = obj.axes_labels(index);
                line.LineStyle = linestyles(find(obj.inds == index));
                line_h.LineStyle = linestyles(find(obj.inds == index));
            end

            disp(legend_entry + ", mean: " + mean(var))
            disp(legend_entry + ", range: " + range(var))
            line.DisplayName = legend_entry;
            % line.Color = original_color;
            line.LineWidth = 2;

            line_h.DisplayName = legend_entry;
            % line_h.Color = original_color;
            line_h.LineWidth = 2;
            % if contains(type, "UP")
            %     line.LineStyle = "--";
            % end

            if obj.force_bool && ~contains(type, "UP")
                line = plot(ax, time_F, force);
                F_legend = strrep(cur_sel,"_"," ") + " F";
                line.DisplayName = F_legend;
                disp(F_legend + ": " + mean(force))
                % line.Color = original_color;
                line.LineWidth = 2;
                line.LineStyle = ":";

                % for hidden figure for saving
                line_h = plot(ax_target, time_F, force);
                line_h.DisplayName = F_legend;
                % line_h.Color = original_color;
                line_h.LineWidth = 2;
                line_h.LineStyle = ":";
            end

            grid(ax, 'on');
            legend(ax, Location="best");
            % for hidden figure for saving
            grid(ax_target, 'on');
            legend(ax_target, Location="best");
            % if ~isempty(obj.inds)
            %     if length(obj.inds) > 1
            %         for n = 2:length(obj.inds)
            %             if ~strcmp(obj.y_labels(obj.inds(n-1)), obj.y_labels(obj.inds(n)))
            %                 dual_plot = true;
            %                 ylabel_one = obj.y_labels(obj.inds(n-1));
            %                 ylabel_two = obj.y_labels(obj.inds(n));
            %             end
            %         end
            %     end
            % end

            if dual_plot
                yyaxis(ax, 'left')
                ylabel(ax, ylabs(1))
                ax.YAxis(1).Color = 'k';
                yyaxis(ax, 'right')
                ylabel(ax, ylabs(2))
                ax.YAxis(2).Color = 'k';

                % for hidden figure for saving
                yyaxis(ax_target, 'left')
                ylabel(ax_target, ylabs(1))
                ax_target.YAxis(1).Color = 'k';
                yyaxis(ax_target, 'right')
                ylabel(ax_target, ylabs(2))
                ax_target.YAxis(2).Color = 'k';
            elseif ~isempty(obj.inds)
                ylabel(ax, obj.y_labels(obj.inds(1)))
                % for hidden figure for saving
                ylabel(ax_target, obj.y_labels(obj.inds(1)))
            end
            
        ax.FontSize = 18;
        ax_target.FontSize = 18;
    end
end
end