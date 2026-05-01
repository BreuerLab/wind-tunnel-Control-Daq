% "< handle" used to pass by reference instead of a copy. I did
% this on 10/10/24 after having some issue with the file save
% functionality. The property was update in obj.update_plot but
% not in the callback function. I guess I always thought it was
% pass by reference, but default is to pass a copy
classdef compareWingbeatUI < handle

    properties (Constant)
        COLOR_ACTIVE = [0.3010 0.7450 0.9330];
        COLOR_INACTIVE = [1 1 1];
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

    force_bool;
    vort_bool; % 1 - velocity, 2 - vorticity
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
        obj.root_path = data_path;
        obj.PIV_path = obj.root_path + "Processed Results\";
        obj.force_path = obj.root_path + "Force Measurements\";

        obj.inds = [];
        % obj.axes_labels = ["Lift", "Drag", "Speed", "Voltage", "Current", "Power"];
        obj.axes_labels = ["Lift - Vorticity", "y*\omega_x", "x*\omega_y", "u*w",...
            "Drag - Vorticity", "z*\omega_y", "y*\omega_z", "(u-U)*u", "Speed", "Voltage", "Current", "Power"];
        obj.var_names = ["lift.tot", "lift.vortX", "lift.vortY", "lift_vel",...
                    "drag.tot", "drag.vortY", "drag.vortZ", "drag_vel",...
                    "phase_avg_speed", "phase_avg_volt", "phase_avg_cur", "phase_avg_volt"];
        obj.y_labels = ["Lift (N)","Lift (N)","Lift (N)","Lift (N)",...
            "Drag (N)", "Drag (N)", "Drag (N)", "Drag (N)",...
            "Speed (Hz)", "Voltage (V)", "Current (mA)", "Power (mW)"];
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
        obj.vort_bool = true;

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
        cur_types = unique(string(obj.available_selections(:, 1)));
        d1.Items = cur_types;
        d1.ValueChangedFcn = @(src, event) type_change(src, event);

        % Dropdown box for wingbeat frequency selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 unit_height];
        cur_freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),3);
        d2.Items = string(cur_freqs) + " Hz";

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
        % drop_y9 = list_y - (unit_height + unit_spacing);
        % d9 = uidropdown(option_panel);
        % d9.Position = [10 drop_y9 180 unit_height];
        % d9.Items = obj.axes_labels;
        % d9.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        param_panel_height = 300;
        param_panel_width = 180;
        param_panel_y = list_y - unit_spacing - param_panel_height;
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
                'Position', [20 (param_panel_height - 50 - (i-1)*20) 150 22], ...
                'ValueChangedFcn', @(src, event) updateLogic(src, event, plot_panel));
        end

        button4_y = param_panel_y - (unit_height + unit_spacing);
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
            obj.sel_type = src.Value;
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~, d)
            obj.sel_freq = str2double(regexp(src.Value, '\d+', 'match'));
            
            % Change amplitude list to only show those available at this
            % wingbeat frequency
            amps = obj.available_selections(cell2mat(obj.available_selections(:,3)) == obj.sel_freq ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),2);
            d.Items = string(amps) + " deg";
        end

        % update speed variable with new value selected by user
        function amp_change(src, ~, d)
            obj.sel_amp = str2double(regexp(src.Value, '\d+', 'match'));

            % Change frequency list to only show those available at this
            % wingbeat amplitude
            freqs = obj.available_selections(cell2mat(obj.available_selections(:,2)) == obj.sel_amp ...
            & strcmp(string(obj.available_selections(:,1)), obj.sel_type),3);
            d.Items = string(freqs) + " Hz";
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

            % removing value from list used for plotting
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
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

        function method_change(src, ~, plot_panel)
            if (src.Value)
                obj.vort_bool = false;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                src.Text = "Use Vorticity";
            else
                obj.vort_bool = true;
                src.BackgroundColor = [1 1 1];
                src.Text = "Use Velocity";
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
        delete(plot_panel.Children)
        disp("-------------")

        uniq_types = unique(string(obj.available_selections(:,1)));
        uniq_amps = unique(cell2mat(obj.available_selections(:,2)));
        uniq_freqs = unique(cell2mat(obj.available_selections(:,3)));

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

        dual_plot = false;
        if ~isempty(obj.inds)
            if length(obj.inds) > 1
                for n = 2:length(obj.inds)
                    if ~strcmp(obj.y_labels(obj.inds(n-1)), obj.y_labels(obj.inds(n)))
                        dual_plot = true;
                        ylabel_one = obj.y_labels(obj.inds(n-1));
                        ylabel_two = obj.y_labels(obj.inds(n));
                    end
                end
            end
        end

        ax = axes(plot_panel);
        hold(ax, 'on');
        for j = 1:length(obj.inds)
            index = obj.inds(j);
        for i = 1:length(obj.selection)
            cur_sel = obj.selection(i);

            [amp, type, freq] = parse_name(cur_sel);

            filename = cur_sel + "_phase_avg.mat";

            if ismember(index,[1,2])
                vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
            end

            % switch index
            %     case 1
            %         if obj.vort_bool
            %             var_name = "lift";
            %         else
            %             var_name = "lift_vel";
            %         end
            %     case 2
            %         if obj.vort_bool
            %             var_name = "drag";
            %         else
            %             var_name = "drag_vel";
            %         end
            %     case 3
            %         var_name = "phase_avg_speed";
            %     case 4
            %         var_name = "phase_avg_volt";
            %     case 5
            %         var_name = "phase_avg_cur";
            %     case 6
            %         vars = {"phase_avg_volt", "phase_avg_cur"};
            % end
            var_name = obj.var_names(index);

            calc_force = true;
            if ismember(index,[1,2,3,4,5,6,7,8]) && calc_force
                % Compute Lift force
                avg_type = 1;
    
                norm_bool = false;
                file_path = obj.PIV_path + filename;
                [var, err] = get_PIV_force(file_path, cur_sel, var_name, avg_type, norm_bool, obj.y_cen);
            elseif index == 6
                d = load(obj.PIV_path + filename, vars{:});
                var = d.(vars{1}) .* d.(vars{2});
            else
                d = load(obj.PIV_path + filename, var_name);
                var = d.(var_name);
            end
            
            % vars_kin = {"phase_avg_pos", "phase_avg_speed", "phase_avg_acc"};
            vars_kin = {"phase_avg_speed", "phase_avg_wing_pos", "phase_avg_wing_speed", "phase_avg_wing_acc"};
            load(obj.PIV_path + filename, vars_kin{:})
            freq_cor = mean(phase_avg_speed);
            % added_mass = get_added_mass(phase_avg_pos, phase_avg_speed, phase_avg_acc);
            added_mass = get_added_mass(phase_avg_wing_pos, phase_avg_wing_speed, phase_avg_wing_acc);

            if ismember(index,[1,2,3,4,5,6,7,8]) && obj.PIV_sub
                % filename = "body_phase_avg.mat";
                filename = "ring_time_avg.mat";

                if ~strcmp(var_name, "lift.vortY")
                if calc_force
                    % Compute aerodynamic forces
                    norm_bool = false;
                    file_path = obj.PIV_path + "time_avg/" + filename;
                    [bod_var, bod_err] = get_PIV_force(file_path, "", var_name, 0, norm_bool, obj.y_cen);
                    var = var - bod_var;
                else
                    d = load(obj.PIV_path + "time_avg/" + filename, var_name);
                    var = var - d.(var_name);
                end
                end
            end

            % Shift data given convection time downstream to target
            if ismember(index,[1,2,3,4,5,6,7,8])
            dist = 0.9;
            if contains(type, "UP_two")
                dist = dist + 0.76;
            elseif contains(type, "UP_one")
                dist = dist + 0.37;
            end
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

            if amp == 10
                var = circshift(var, round(0.44*length(var)));
                disp("Shifted STB curve for " + cur_sel)
            end

            norm_bool = false;
            if norm_bool
                var = var / mean(var);
            end

            time = 1:length(var);
            time = time / length(var);

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

            % Get color for this case name
            sels = [type, amp];
            original_color = colors(find(uniq_freqs == freq), find(common_var == sels(I(2)))); % hex

            if dual_plot
                if strcmp(ylabel_one, obj.y_labels(index))
                    yyaxis(ax, 'left')
                    line = plot(ax, time, var);
                elseif strcmp(ylabel_two, obj.y_labels(index))
                    yyaxis(ax, 'right')
                    line = plot(ax, time, var);
                end
            else
                line = plot(ax, time, var);
            end
            linestyles = ["-", "--", ":", "-."];

            if isscalar(obj.inds)
                legend_entry = strrep(cur_sel,"_"," ");
            else
                legend_entry = obj.axes_labels(index);
                line.LineStyle = linestyles(find(obj.inds == index));
            end

            disp(legend_entry + ": " + mean(var))
            line.DisplayName = legend_entry;
            line.Color = original_color;
            line.LineWidth = 2;
            % if contains(type, "UP")
            %     line.LineStyle = "--";
            % end

            if obj.force_bool && ~contains(type, "UP")
                line = plot(ax, time_F, force);
                F_legend = strrep(cur_sel,"_"," ") + " F";
                line.DisplayName = F_legend;
                disp(F_legend + ": " + mean(force))
                line.Color = original_color;
                line.LineWidth = 2;
                line.LineStyle = ":";
            end
        end
        end
        hold(ax, 'off');

        grid(ax, 'on');
        l = legend(ax, Location="best");
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
                ylabel(ax, ylabel_one)
                ax.YAxis(1).Color = 'k';
                yyaxis(ax, 'right')
                ylabel(ax, ylabel_two)
                ax.YAxis(2).Color = 'k';
            else
                ylabel(ax, obj.y_labels(obj.inds(1)))
            end
            
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
            set(fignew,'CreateFcn','set(gcf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

      
    end
end
end