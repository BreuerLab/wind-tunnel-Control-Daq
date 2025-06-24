classdef compareKinematicsSlopesFreqUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    data_path;

    selection;

    Flapperoo;
    MetaBird;
    sel_bird;

    sel_speed;
    sel_amp;
    freq_range;
    range;

    % booleans
    st;

    plot_id;

    saveFig;
    logScale;
end

methods
    function obj = compareKinematicsSlopesFreqUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.selection = strings(0);
        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");
        
        obj.sel_bird = obj.Flapperoo;
        obj.sel_speed = obj.sel_bird.speeds(1);
        obj.sel_amp = pi/10;
        obj.freq_range = [0 5];
        obj.range = [-16 16];

        obj.st = false;

        obj.plot_id = "Effective AoA";

        obj.saveFig;
        obj.logScale = false;
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

        % Dropdown box for amplitude selection
        drop_y3 = drop_y1 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 30];
        d3.Items = [pi/10,pi/8,pi/6,pi/5,pi/4] + " rad";
        d3.ValueChangedFcn = @(src, event) amp_change(src, event);

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
        d6.Items = ["Effective AoA", "Effective AoA Sine", "Effective AoA Sine^2"];
        d6.ValueChangedFcn = @(src, event) plot_type_change(src, event, plot_panel);

        button3_y = drop_y6 - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "St Scaling";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) st_change(src, event, plot_panel);

        button4_y = button3_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel,"state");
        b5.Text = "Log Scaling";
        b5.Position = [20 button4_y 160 unit_height];
        b5.BackgroundColor = [1 1 1];
        b5.ValueChangedFcn = @(src, event) log_scaling(src, event, plot_panel);

        AoA_y = 0.05*screen_height;
        s = uislider(option_panel,"range");
        s.Position = [10 AoA_y 180 3];
        s.Limits = obj.range;
        s.Value = obj.range;
        s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        s.ValueChangedFcn = @(src, event) AoA_change(src, event, plot_panel);

        button5_y = AoA_y + (unit_height + unit_spacing);
        b6 = uibutton(option_panel);
        b6.Text = "Save Fig";
        b6.Position = [20 button5_y 160 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ButtonPushedFcn = @(src, event) save_figure(src, event, plot_panel);

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

        % update amplitude variable with new value selected by user
        function amp_change(src, ~)
            obj.sel_amp = str2double(extractBefore(src.Value, " rad"));
        end

        % update speed variable with new value selected by user
        function speed_change(src, ~)
            speed = str2double(extractBefore(src.Value, " m/s"));
            obj.sel_speed = speed;
        end
    
        function addToList(~, ~, plot_panel, lbox)
            case_name = obj.sel_bird.name + "/" + obj.sel_speed + " m/s " + obj.sel_amp + " rad";

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

        function plot_type_change(src, ~, plot_panel)
            obj.plot_id = convertCharsToStrings(src.Value);
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
    function [flapper_name, sel_speed, sel_amp] = parseSelection(sel)
        flapper_name = string(extractBefore(sel, "/"));
        dir_name = string(extractAfter(sel, "/"));

        dir_parts = split(dir_name, ' ');
        for k = 1:length(dir_parts)
            if (contains(dir_parts(k), "m/s"))
                sel_speed = str2double(dir_parts(k-1));
            elseif (contains(dir_parts(k), "rad"))
                sel_amp = str2double(dir_parts(k-1));
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

        if (obj.st)
            x_label = "Strouhal Number";
        else
            x_label = "Wingbeat Frequency (Hz)";
        end
        y_label = "d/da of effective angle of attack";
        sub_title = "";

        if (~isempty(obj.selection))
        uniq_speeds = [];
        uniq_angles = [];
        uniq_amps = [];
        for j = 1:length(obj.selection)
            [flapper_name, cur_speed, cur_amp] = compareKinematicsSlopesFreqUI.parseSelection(obj.selection(j));

            if (sum(uniq_speeds == cur_speed) == 0)
                uniq_speeds = [uniq_speeds cur_speed];
            end
            if (sum(strcmp(uniq_amps, cur_amp)) == 0)
                uniq_amps = [uniq_amps cur_amp];
            end
        end

        abbr_sel = compareKinematicsSlopesFreqUI.get_abbr_names(obj.selection);
        colors = getColors(1, length(uniq_angles), length(uniq_speeds), length(obj.selection));
        end

        % -----------------------------------------------------
        % -------------------- Plotting -----------------------
        % -----------------------------------------------------
        ax = axes(plot_panel);
        hold(ax, 'on');

        n = 20;
        freq_vals = linspace(obj.freq_range(1), obj.freq_range(2), n);
        x_var = freq_vals;

        AoA_vals = linspace(obj.range(1), obj.range(2), 30);

        x_vals_tot = [];
        y_vals_tot = [];
        ind_tot = [];
        for i = 1:length(obj.selection)
            [flapper_name, cur_speed, cur_amp] = compareKinematicsSlopesFreqUI.parseSelection(obj.selection(i));

            [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements(flapper_name);

            mean_eff_AoA = zeros(length(freq_vals),length(AoA_vals));
            slopes = zeros(size(freq_vals));
            mean_eff_AoA_sin = zeros(length(freq_vals),length(AoA_vals));
            slopes_sin = zeros(size(freq_vals));
            mean_eff_AoA_sin2 = zeros(length(freq_vals),length(AoA_vals));
            slopes_sin2 = zeros(size(freq_vals));
            for j = 1:length(freq_vals)
                cur_freq = freq_vals(j);
                for k = 1:length(AoA_vals)
                cur_angle = AoA_vals(k);

                [time, ang_disp, ang_vel, ang_acc] = get_kinematics(obj.data_path, cur_freq, cur_amp);
                
                full_length = wing_length + arm_length;
                r = arm_length:0.001:full_length;
                % removed the +0.2 from full_length+0.2
                % linear displacements taken only in the vertical
                % direction, excluding left-right motion

                % lin_disp = cosd(ang_disp) * r;
                lin_vel = (deg2rad(ang_vel) .* cosd(ang_disp)) * r;
                % lin_acc = (deg2rad(ang_acc) .* cosd(ang_disp)) * r;
                % lin_vel = deg2rad(ang_vel) * r;
                
                [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, cur_angle, cur_speed);

                eff_AoA_span_mean = mean(eff_AoA, 2);
                u_rel_span_mean = mean(u_rel, 2);
                eff_AoA_span_mean_r = mean(eff_AoA .* r, 2);
                eff_AoA_span_mean_r2 = mean(eff_AoA .* r.^2, 2);

                mean_eff_AoA(k) = mean(eff_AoA_span_mean.* (cos(ang_disp)));
                mean_u_rel(k) = mean(u_rel_span_mean);
                mean_eff_AoA_sin(k) = mean(eff_AoA_span_mean_r.*sin(2*pi*cur_freq*time).*sin(cur_angle).* (cos(ang_disp)));
                mean_eff_AoA_sin2(k) = mean(eff_AoA_span_mean_r2.*(sin(2*pi*cur_freq*time)).^2 .* (cos(ang_disp)));

                % Not equivalent since cos changes eff_AoA before this
                % point
                % mean_eff_AoA(j,k) = mean(eff_AoA_span_mean);
                % mean_u_rel(j,k) = mean(u_rel_span_mean);
                % mean_eff_AoA_sin(j,k) = mean(eff_AoA_span_mean_r.*sin(2*pi*cur_freq*time) *sin(cur_angle).* (cos(ang_disp)));
                % mean_eff_AoA_sin2(j,k) = mean(eff_AoA_span_mean_r2.*(sin(2*pi*cur_freq*time)).^2 .* (cos(ang_disp)).^2);

                % mean_eff_AoA(j,k) = mean(eff_AoA_span_mean);
                % mean_u_rel(j,k) = mean(u_rel_span_mean);
                % mean_eff_AoA_sin(j,k) = mean(eff_AoA_span_mean_r.*sin(2*pi*cur_freq*time).*sin(cur_angle));
                % mean_eff_AoA_sin2(j,k) = mean(eff_AoA_span_mean_r2.*(sin(2*pi*cur_freq*time)).^2);
                end

                x = [ones(size(AoA_vals')), AoA_vals'];
                y = mean_eff_AoA';
                b = x\y;
                slopes(j) = b(2);

                y = mean_eff_AoA_sin';
                b = x\y;
                slopes_sin(j) = b(2);

                y = mean_eff_AoA_sin2';
                b = x\y;
                slopes_sin2(j) = b(2);
            end

            if (obj.plot_id == "Effective AoA")
                y_var = slopes;
            elseif (obj.plot_id == "Effective AoA Sine")
                y_var = slopes_sin;
            elseif (obj.plot_id == "Effective AoA Sine^2")
                y_var = slopes_sin2;
            end

            % normalize effective wind speeds by freestream
            speed_norm = true;
            if (speed_norm)
                mean_u_rel = mean_u_rel / cur_speed;
            end

            if (obj.st)
                for k = 1:length(freq_vals)
                    x_var(k) = freqToSt(flapper_name, freq_vals(k), cur_speed, obj.data_path, cur_amp);
                end
            end

            x_vals_tot = [x_vals_tot x_var];
            y_vals_tot = [y_vals_tot y_var];
            ind_tot = [ind_tot i*ones(size(x_var))];

            % Plotting
            if ~obj.logScale
                p = plot(ax, x_var, y_var);
                p.LineWidth = 2;
                p.DisplayName = abbr_sel(i);
            end

            % fit power law
            x_var_mod = x_var(2:end);
            y_var_mod = y_var(2:end);

            % logX = log(x_var);
            % logY = log(y_var);
            % 
            % p = polyfit(logX, logY, 1);
            % disp(p(1))

            % y_mod = exp(p(2)) * x_var.^(p(1));

            % test_fit = fit(x_var_mod', y_var_mod', 'power2');
            % y_mod = test_fit.a * x_var_mod.^(test_fit.b) + test_fit.c;

            % plot(ax, x_var, y_mod, LineStyle="--",Color="black")

        end

        if (obj.logScale)
            y_vals_tot = y_vals_tot - min(y_vals_tot);

            bad_ind = [];
            for n = 1:length(x_vals_tot)
                if y_vals_tot(n) == 0
                   bad_ind = [bad_ind n]; 
                end
            end
            x_vals_tot(bad_ind) = [];
            y_vals_tot(bad_ind) = [];
            ind_tot(bad_ind) = [];

            x_vals_reg = log(x_vals_tot);
            y_vals_reg = log(y_vals_tot);
            x = [ones(size(x_vals_reg')), x_vals_reg'];
            y = y_vals_reg';
            b = x\y;
            model = x*b;
            Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
            % label = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
            label = "y = " + round(exp(b(1)),3) + "*x^{" + round(b(2),3) + "}, R^2 = " + round(Rsq,3);

            for i = 1:length(obj.selection)
                p = plot(ax, x_vals_tot(ind_tot == i), y_vals_tot(ind_tot == i));
                p.LineWidth = 2;
                p.DisplayName = abbr_sel(i);
            end

            [x_vals_tot_s, sortIndices] = sort(x_vals_tot);
            model_s = model(sortIndices);

            p = plot(ax, x_vals_tot_s, exp(model_s));
            p.Color = 'black';
            p.DisplayName = label;
            p.LineWidth = 2;

            % len = length(x_vals_tot_s);
            % p = plot(ax, x_vals_tot_s, 0.04*x_vals_tot_s);
            % % p = plot(ax, x_vals_tot_s(round(len*(1/4)):round(len*(3/4))), 0.04*x_vals_tot_s(round(len*(1/4)):round(len*(3/4))));
            % p.Color = 'black';
            % p.DisplayName = "Linear";
            % p.LineWidth = 2;
            % p.LineStyle = '--';
        else
            if (sum(x_vals_tot == 0) > 0)
            % Power law for amplitude plot, only necessary for mult amp
            x_vals_tot = reshape(x_vals_tot(:,2:end), [], 1);
            y_vals_tot = reshape(y_vals_tot(:,2:end), [], 1);

            bad_ind = [];
            for n = 1:length(x_vals_tot)
                if (x_vals_tot(n) < 0.01 || y_vals_tot(n) == 0)
                   bad_ind = [bad_ind n]; 
                end
            end
            x_vals_tot(bad_ind) = [];
            y_vals_tot(bad_ind) = [];

            [x_mod_sort, sortIndices] = sort(x_vals_tot);
            % y_mod_sort = y_vals_tot(sortIndices);
            % test_fit = fit(x_vals_tot, y_vals_tot, 'power2')
            % y_mod = test_fit.a * x_mod_sort.^(test_fit.b) + test_fit.c;

            % plot(ax, x_mod_sort, y_mod, LineStyle="--",Color="black")
            end
        end

        title(ax, sub_title);
        xlabel(ax, x_label);
        ylabel(ax, y_label)
        grid(ax, 'on');
        ax.FontSize = 18;
        l = legend(ax);
        if (obj.logScale)
            set(ax, 'XScale', 'log');
            set(ax, 'YScale', 'log');
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