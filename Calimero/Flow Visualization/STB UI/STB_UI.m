classdef STB_UI < handle
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    % boolean, whether data is normalized/non-dimensionalized
    norm;

    % cases/files selected by user
    file_path;
    case_name;
    case_name_list;

    num_bins;
    frame_ind;
    play;

    plot_type;
    plot_types;

    variable_name;
    var_name_list;
    movie_3D_vars;
    hist_vars;
    freq_vars

    variable_name_dict;
    label_dict;

    hist_var_name_dict;
    hist_label_dict;

    freq_var_name_dict;
    freq_label_dict;

    clims; % color limits for each variable

    param_panel; % panel of 3D plot parameters
    var_dropdown; % drop down box object for variable selection
    clim_slider; % slider for color limits on plots
    slider; % slider object
    play_button;
    
    % properties related to 3D plot

    plot_hold_bool;
    Q_iso;
    iso_var;
    iso_var_list;
    mirror_bool;
    filter_bool;
    num_cycles;
    cam;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = STB_UI(mon_num, file_path)
        obj.mon_num = mon_num;
        obj.norm = false;
        obj.case_name = "";
        obj.variable_name = "";
        obj.file_path = file_path;

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;

        obj.plot_types = ["time avg","phase avg: movie","phase avg: 3D plot","image wingbeat phase", "wingbeat frequency"];
        obj.plot_hold_bool = false;
        obj.iso_var_list = ["Q","Qx","Qy","Qz"];
        obj.Q_iso = 0.05;
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.num_cycles = 1;

        files = dir(obj.file_path + "*.mat");

        obj.case_name_list = extractBefore(string({files.name}),".mat");

        obj.movie_3D_vars = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|"];
        movie_3D_values = ["u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
        "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg",...
        "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg","uncTot_phase_avg"];

        obj.hist_vars = ["bin counts","bin SD","distribution"];
        hist_vals = ["bin_count", "bin_std","tick_frame_pos"];
        hist_labels = ["Number of frames per bin", "Phase variability per bin (% cycle)","Number of frames per tick"];

        obj.freq_vars = ["frequency","bin counts", "bin SD"];
        freq_vals = ["phase_avg_speed", "bin_count_speed", "bin_std_speed"];
        freq_labels = ["Wingbeat Frequency (Hz)", "Number of samples per bin", "Phase variability per bin (% cycle)"];

        obj.var_name_list = obj.movie_3D_vars;
        obj.clims = [-0.2, 0.2;...
                     -0.2, 0.2;...
                      -1.1, -0.9;...
                      -1.1, -0.9;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02];
        movie_3D_labels = ["\boldmath$\frac{u c}{U_{\infty}}$",...
                            "\boldmath$\frac{v c}{U_{\infty}}$",...
                            "\boldmath$\frac{w c}{U_{\infty}}$",...
                            "\boldmath$\frac{U c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_x c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_y c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega_z c}{U_{\infty}}$",...
                            "\boldmath$\frac{\omega c}{U_{\infty}}$",...
                            "","","","",...
                            "\boldmath$\frac{u c}{U_{\infty}}$",...
                            "\boldmath$\frac{v c}{U_{\infty}}$",...
                            "\boldmath$\frac{w c}{U_{\infty}}$",...
                            "\boldmath$\frac{U c}{U_{\infty}}$"];

        keys = cellstr([obj.movie_3D_vars obj.hist_vars]);
        values = [movie_3D_values hist_vals];
        labels = [movie_3D_labels hist_labels];
        obj.variable_name_dict = containers.Map(keys, values);
        obj.label_dict = containers.Map(keys, labels);

        hist_keys = cellstr(obj.hist_vars);
        obj.hist_var_name_dict = containers.Map(hist_keys, hist_vals);
        obj.hist_label_dict = containers.Map(hist_keys, hist_labels);

        freq_keys = cellstr(obj.freq_vars);
        obj.freq_var_name_dict = containers.Map(freq_keys, freq_vals);
        obj.freq_label_dict = containers.Map(freq_keys, freq_labels);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
        pause(1.5) % wait until GUI opened

        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        % Dropdown box for which cases axes to display
        drop_y1 = screen_height*0.85 - 30;
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.Items = obj.case_name_list;
        obj.case_name = d1.Value; % use current value in box
        d1.ValueChangedFcn = @(src, event) case_change(src, event, plot_panel);

        drop_y2 = drop_y1 - 35;
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 30];
        d2.Items = obj.plot_types;
        obj.plot_type = d2.Value; % use current value in box
        d2.ValueChangedFcn = @(src, event) type_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        drop_y3 = drop_y2 - 35;
        obj.var_dropdown = uidropdown(option_panel);
        obj.var_dropdown.Position = [10 drop_y3 180 30];
        obj.var_dropdown.Items = obj.var_name_list;
        obj.variable_name = obj.var_dropdown.Value; % use current value in box
        obj.var_dropdown.ValueChangedFcn = @(src, event) variable_change(src, event, plot_panel);

        clim_y = drop_y3 - 35;
        obj.clim_slider = uislider(option_panel,"range");
        obj.clim_slider.Position = [10 clim_y 180 3];
        obj.clim_slider.Limits = obj.clims(1,:);
        obj.clim_slider.Value = obj.clims(1,:);
        % s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        % s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        obj.clim_slider.ValueChangedFcn = @(src, event) clim_change(src, event, plot_panel);

        panel_width = plot_panel.Position(3);
        s_w = panel_width * (3/4);
        s_x = (panel_width - s_w)/2; % end of right monitor around 1690
        s_y = 0.05*screen_height;
        obj.slider = uislider(plot_panel);
        obj.slider.Position = [s_x s_y s_w 3];
        obj.slider.Limits = [1 obj.num_bins];
        obj.slider.Value = obj.frame_ind;
        obj.slider.MajorTicks = 1:5:obj.num_bins;
        obj.slider.MinorTicks = 1:obj.num_bins;
        obj.slider.ValueChangedFcn = @(src, event) frame_change(src, event, plot_panel);

        button1_y = s_y + 50;
        obj.play_button = uibutton(plot_panel,"state");
        obj.play_button.Text = "Play";
        obj.play_button.FontSize = 18;
        obj.play_button.Position = [30 button1_y 120 unit_height];
        obj.play_button.BackgroundColor = [1 1 1];
        obj.play_button.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_panel);

        param_panel_height = 380;
        param_panel_width = 180;
        param_panel_y = drop_y3 - 150 - param_panel_height;
        obj.param_panel = uipanel(option_panel);
        obj.param_panel.Visible = "off";
        obj.param_panel.Title = "3D Plot Parameters";
        obj.param_panel.TitlePosition = 'centertop';
        obj.param_panel.Position = [10 param_panel_y param_panel_width param_panel_height];

        % l1_y = drop_y3 - 150;
        l1_y = param_panel_height - 50;
        l1_x = 55;
        l1_w = 70;
        l1 = uilabel(obj.param_panel);
        l1.HorizontalAlignment = 'center';
        l1.Position = [l1_x l1_y l1_w unit_height];
        l1.Text = 'Q isovalue:';

        s2_y = l1_y - 5;
        s2_w = param_panel_width - 2*10;
        s2 = uislider(obj.param_panel);
        s2.Position = [5 s2_y s2_w 3];
        s2.Limits = [0.005 0.1];
        s2.Value = obj.Q_iso;
        s2.MajorTicks = 0:0.025:0.1; % 0:0.05:0.5
        s2.MinorTicks = 0.005:0.005:0.1; % 0.01:0.01:0.5
        s2.ValueChangedFcn = @(src, event) Q_iso_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        drop_y4 = s2_y - 70;
        d4 = uidropdown(obj.param_panel);
        d4.Position = [30 drop_y4 120 30];
        d4.Items = obj.iso_var_list;
        obj.iso_var = d4.Value; % use current value in box
        d4.ValueChangedFcn = @(src, event) iso_var_change(src, event, plot_panel);

        button2_y = drop_y4 - 40;
        b2 = uibutton(obj.param_panel,"state");
        b2.Text = "Mirror";
        % b2.FontSize = 14;
        b2.Position = [30 button2_y 120 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.ValueChangedFcn = @(src, event) mirror_change(src, event, plot_panel);

        button3_y = button2_y - 35;
        b3 = uibutton(obj.param_panel,"state");
        b3.Text = "Filter";
        % b2.FontSize = 14;
        b3.Position = [30 button3_y 120 unit_height];
        b3.BackgroundColor = [1 1 1];
        b3.ValueChangedFcn = @(src, event) filter_change(src, event, plot_panel);

        l2_y = button3_y - 35;
        l2 = uilabel(obj.param_panel);
        l2.HorizontalAlignment = 'center';
        l2.Position = [30 l2_y 120 unit_height];
        l2.Text = 'Number of Wingbeats';

        s3_y = l2_y - 10;
        s3 = uislider(obj.param_panel);
        s3.Position = [30 s3_y 120 3];
        s3.Limits = [1 5];
        s3.Value = obj.num_cycles;
        s3.MajorTicks = 1:5;
        s3.MinorTicks = [];
        s3.ValueChangedFcn = @(src, event) num_cycles_change(src, event, plot_panel);

        button4_y = s3_y - 120;
        % 1. Create the Button Group (the container)
        bg_2 = uibuttongroup(obj.param_panel, ...
            'Position', [30 button4_y 124 2*(unit_height+5)], ...
            'BorderType', 'none', ...
            'BackgroundColor', option_panel.BackgroundColor, ...
            'SelectionChangedFcn', @(bg, event) view_change_handler(event, plot_panel));
        
        % Dimensions for buttons relative to the group
        b_w = 32;
        b_s = (120 - 3*b_w)/2;
        pad = 2;
        v_sep = (unit_height+5);

        % 2. Add Toggle Buttons to the group
        % Note: Position is now relative to the 'bg' container [Left Bottom Width Height]
        b4_1 = uitogglebutton(bg_2, 'Text', '+xy', 'Position', [pad pad+v_sep b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4_2 = uitogglebutton(bg_2, 'Text', '+yz', 'Position', [pad + b_w + b_s pad+v_sep b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4_3 = uitogglebutton(bg_2, 'Text', '+xz', 'Position', [pad + 2*(b_w + b_s) pad+v_sep b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4_4 = uitogglebutton(bg_2, 'Text', '-xy', 'Position', [pad pad b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4_5 = uitogglebutton(bg_2, 'Text', '-yz', 'Position', [pad + b_w + b_s pad b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4_6 = uitogglebutton(bg_2, 'Text', '-xz', 'Position', [pad + 2*(b_w + b_s) pad b_w unit_height], 'BackgroundColor', [1 1 1]);

        button5_y = 0.05*screen_height;
        b9 = uibutton(option_panel,"state");
        b9.Text = "Save Figure";
        b9.FontSize = 18;
        b9.Position = [30 button5_y 120 unit_height];
        b9.BackgroundColor = [1 1 1];
        b9.ValueChangedFcn = @(src, event) save_figure(src, event, plot_panel);

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

        % ~ indicates input argument that's ignored

        % User selected new desired force/moment axes
        function case_change(src, ~, plot_panel)
            obj.case_name = src.Value;
            % obj.plot_hold_bool = false;
            obj.update_plot(plot_panel);
        end

        % User selected new desired plot type
        function type_change(src, ~, plot_panel)
            tmp = obj.plot_type;
            obj.plot_type = src.Value;
            obj.plot_hold_bool = false;

            % not changing from movie to 3D plot or vice versa
            if ~((strcmp(tmp,obj.plot_types(2)) || strcmp(tmp,obj.plot_types(3))) &&...
               (strcmp(src.Value,obj.plot_types(2)) || strcmp(src.Value,obj.plot_types(3))))
            if strcmp(obj.plot_type, obj.plot_types(4))
                obj.var_name_list = obj.hist_vars;
            elseif strcmp(obj.plot_type, obj.plot_types(5))
                obj.var_name_list = obj.freq_vars;
            else
                obj.var_name_list = obj.movie_3D_vars;
            end
            obj.var_dropdown.Items = obj.var_name_list;
            obj.variable_name = obj.var_dropdown.Value;
            end

            % update color limit slider
            var_idx = find(obj.variable_name == obj.var_name_list);
            obj.clim_slider.Limits = obj.clims(var_idx,:);
            obj.clim_slider.Value = obj.clims(var_idx,:);

            if strcmp(src.Value,obj.plot_types(3)) % 3D plot, show params
                obj.param_panel.Visible = "on";
            else
                obj.param_panel.Visible = "off";
            end

            obj.update_plot(plot_panel);
        end

        % User selected new desired force/moment axes
        function variable_change(src, ~, plot_panel)
            obj.variable_name = src.Value;
            
            % update color limit slider
            var_idx = find(obj.variable_name == obj.var_name_list);
            obj.clim_slider.Limits = obj.clims(var_idx,:);
            obj.clim_slider.Value = obj.clims(var_idx,:);

            obj.update_plot(plot_panel);
        end

        function clim_change(src, ~, plot_panel)
            ticks = obj.clim_slider.MinorTicks;

            % ensure that slider snapped to minor tick value
            newMin = interp1(ticks, ticks, src.Value(1), 'nearest', 'extrap');
            newMax = interp1(ticks, ticks, src.Value(2), 'nearest', 'extrap');
            
            % Update the slider to the snapped positions
            src.Value = [newMin, newMax];
    
            var_idx = find(obj.variable_name == obj.var_name_list);

            % update color limits
            obj.clims(var_idx,:) = [src.Value(1) src.Value(2)];
    
            obj.update_plot(plot_panel);
        end

        % User pressed normalization button
        function playStop_change(src, ~, plot_panel)
            if (src.Value)
                obj.play = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                src.Text = "Stop";
            else
                obj.play = false;
                src.BackgroundColor = [1 1 1];
                src.Text = "Play";
            end

            obj.update_plot(plot_panel);
        end

        function Q_iso_change(src, ~, plot_panel)
            precision = 0.005;
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value / precision) * precision;

            obj.Q_iso = src.Value;
            obj.clims(9:12,2) = obj.Q_iso;
            obj.update_plot(plot_panel);
        end

        % User selected new desired isosurface variable for 3D plot
        function iso_var_change(src, ~, plot_panel)
            obj.iso_var = src.Value;
            obj.update_plot(plot_panel);
        end

        % User pressed mirror button to mirror 3D wake to reconstruct left
        % wing
        function mirror_change(src, ~, plot_panel)
            if (src.Value)
                obj.mirror_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.mirror_bool = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function filter_change(src, ~, plot_panel)
            if (src.Value)
                obj.filter_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.filter_bool = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        % 3. The Single Callback Handler
        function view_change_handler(event, plot_panel)
            % event.NewValue is the handle of the button that was just selected
            selected_text = event.NewValue.Text;

            % Find only children that are of type 'axes'
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            
            switch selected_text
                case "+xz"
                    view(ax, [0 0 1])
                case "+xy"
                    view(ax, [1 0 0])
                case "+yz"
                    view(ax, [0 1 0])
                case "-xz"
                    view(ax, [0 0 -1])
                case "-xy"
                    view(ax, [-1 0 0])
                case "-yz"
                    view(ax, [0 -1 0])
            end
            fprintf('View changed to: %s\n', selected_text);
        end

        function save_figure(~, ~, plot_panel)
            ax = findobj(plot_panel.Children, 'Type', 'axes');
            cb = findobj(plot_panel.Children, 'Type', 'colorbar');

            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            % if (exist("l", "var"))
            %     copyobj([l ax], fignew); % Copy the appropriate axes
            % elseif (exist("cb", "var"))
                copyobj([ax cb], fignew); % Copy the appropriate axes
            % else
            %     copyobj(ax, fignew); % Copy the appropriate axes
            % end

            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end

        function num_cycles_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.num_cycles = src.Value;
            obj.update_plot(plot_panel);
        end

        function frame_change(src, ~, plot_panel)
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value);

            obj.frame_ind = src.Value;
            obj.update_plot(plot_panel);
        end

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

% The only function contained in this section is update_plot
methods (Access = private)
    % update plot after user changes selected variables
    function update_plot(obj, plot_panel)
        % Find only children that are of type 'axes'
        ax = findobj(plot_panel.Children, 'Type', 'axes');

        % Delete the axes to prepare for new plotting unless
        % plot is 3D and plot_type 3D, then just adjust colors on plot
        if obj.plot_hold_bool
            p = findobj(ax, 'Type', 'patch');
        else
            delete(ax);
        end

        plot_idx = find(obj.plot_types == obj.plot_type);

        % movie or 3D plot
        if ismember(plot_idx, [1, 2, 3])
            % load in variables to plot
            var_name = obj.variable_name_dict(obj.variable_name);
            var_idx = find(obj.variable_name == obj.var_name_list);

            vars = {"L","num_bins","cycle_freq","x","y",var_name};
        end
        
        if plot_idx == 3 % 3D plot
            vars{end+1} = obj.iso_var;
        elseif plot_idx == 4
            % load in variables to plot
            var_name = obj.hist_var_name_dict(obj.variable_name);

            vars = {var_name};
            if (obj.variable_name == obj.hist_vars(3))
                x_var_name = "full_cycle";
                vars{end+1} = x_var_name;
            end
        elseif plot_idx == 5
            var_name = obj.freq_var_name_dict(obj.variable_name);

            vars = {var_name};
            if obj.variable_name == obj.freq_vars(1)
                x_var_name = "norm_time_speed";
                vars{end+1} = x_var_name;
                std_name = "phase_std_speed";
                vars{end+1} = std_name;
            end
        end
        d = load(obj.file_path + obj.case_name, vars{:});

        if plot_idx == 2
            obj.slider.Visible = "on";
            obj.play_button.Visible = "on";
            % Adjust slider for number of bins
            if d.num_bins ~= obj.num_bins
                obj.num_bins = d.num_bins;
                obj.slider.Limits = [1 d.num_bins];
                obj.slider.MajorTicks = 1:5:d.num_bins;
                obj.slider.MinorTicks = 1:d.num_bins;
            end
        else
            obj.slider.Visible = "off";
            obj.play_button.Visible = "off";
        end

        val = d.(var_name);

        % movie or 3D plot
        if ismember(plot_idx, [1, 2, 3])
            x = d.x(:,:,3);
            y = d.y(:,:,3);
            val = squeeze(val(:,:,3,:));

            if min(obj.clims(var_idx,:)) < -1
                params.zero = -1;
            elseif min(obj.clims(var_idx,:)) < 0.5
                params.zero = 0;
            else
                params.zero = 1;
            end
    
            params.cb_lab = obj.label_dict(obj.variable_name);
        end

        if plot_idx == 3
            Q = d.(obj.iso_var);
            Q = squeeze(Q(:,:,3,:));
        end
        
        % Make axes for plot
        % empty - first run, not valid - empty (no values)
        if ~obj.plot_hold_bool
            ax = axes(plot_panel);
        end

        if plot_idx == 1
            params.clims = obj.clims(var_idx,:);

            mean_val = mean(val,3);
            h = PIV_plot(x, y, mean_val, params, ax);
        elseif plot_idx == 2

        % params.title = "Spanwise velocity - Average";
        params.clims = obj.clims(var_idx,:);

        val_tr = val(:,:,obj.frame_ind);
        h = PIV_plot(x, y, val_tr, params, ax);
        t = title(ax, ["Bin number: " + obj.frame_ind], FontSize=18);

        while(obj.play)
            while (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;

                % 1. Cap the data so it doesn't exceed clims
                tmp_data = val(:,:,obj.frame_ind);
                tmp_data(tmp_data < params.clims(1)) = params.clims(1);
                tmp_data(tmp_data > params.clims(2)) = params.clims(2);
        
                % UPDATE the existing objects instead of recreating them
                set(h, 'ZData', tmp_data); 
                set(t, 'String', ["Bin number: " + obj.frame_ind]);
        
                drawnow;

                pause(0.05);
            end
            obj.frame_ind = 1;
        end
        elseif plot_idx == 3
            params.num_bins = d.num_bins;
            params.clims = obj.clims(var_idx,:);
            params.movie = false;
            params.L = d.L;
            params.shift = -7;
            params.isoValue = obj.Q_iso; % 0.05
            params.mirror = obj.mirror_bool;
            params.num_cycles = obj.num_cycles;

            if any(contains(["u","ω_y","ω_z"],obj.variable_name))
                params.cFlip = true;
            else
                params.cFlip = false;
            end

            if obj.filter_bool
                % median filter approach
                Q = medfilt3(Q);
                val = medfilt3(val);

                % % 1. Create a binary mask of where the data exceeds your threshold
                % % This defines the "solid" parts of your volume
                % BW = Q >= params.isoValue;
                % 
                % % 2. Remove "islands" smaller than P voxels
                % % Adjust P (e.g., 50, 100, 500) based on the size of the noise you want to kill
                % P = 300; 
                % BW_clean = bwareaopen(BW, P);
                % 
                % % 3. Mask the original Q_fin data
                % % Set noisy regions to a value below the isoValue so they aren't rendered
                % Q(~BW_clean) = 0;
            end

            [s,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
            setColorBar(ax, params)

            if obj.plot_hold_bool
                p.Vertices = s.vertices;
                p.Faces = s.faces;
                p.FaceVertexCData = cData;
            else
                plot_3D(ax, s, cData, params)
                obj.plot_hold_bool = true;
            end
        elseif plot_idx == 4
            if (obj.variable_name == obj.hist_vars(3))
                histogram(ax, val, d.(x_var_name))
                xlabel(ax, "Tick number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
            else
                bar(ax, val)
                xlabel(ax, "Bin number", FontSize=16)
                ylabel(ax, obj.hist_label_dict(obj.variable_name), FontSize=16)
            end
        elseif plot_idx == 5
            if (obj.variable_name == obj.freq_vars(1))
                phase_avg_speed = val;
                phase_std_speed = d.(std_name);
                norm_time_speed = d.(x_var_name);

                lower_results = phase_avg_speed - phase_std_speed;
                upper_results = phase_avg_speed + phase_std_speed;
                
                original_color = "#7f2704"; % hex, some dark red
                lighter_color = getLightColor(original_color); % RGB
                
                xconf = [norm_time_speed, norm_time_speed(end:-1:1)];
                yconf = [upper_results, lower_results(end:-1:1)];
                
                hold(ax,'on')

                p = fill(ax, xconf, yconf, lighter_color);
                p.HandleVisibility = 'off';
                p.EdgeColor = 'none';
                
                l = plot(ax, norm_time_speed, phase_avg_speed);
                l.Color = original_color;
                l.LineWidth = 2;

                xlabel(ax, "Wingbeat phase", FontSize=16)
                ylabel(ax, obj.freq_label_dict(obj.variable_name), FontSize=16)
            else
                bar(ax, val)
                xlabel(ax, "Bin number", FontSize=16)
                ylabel(ax, obj.freq_label_dict(obj.variable_name), FontSize=16)
            end
        end
    end
end

end