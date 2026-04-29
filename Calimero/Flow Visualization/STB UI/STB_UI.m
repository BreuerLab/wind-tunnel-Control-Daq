classdef STB_UI < handle
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    % boolean, whether data is normalized/non-dimensionalized
    norm;

    % cases/files selected by user
    file_path;
    case_name;
    file_suffix;
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
    force_vars;

    variable_name_dict;
    label_dict;

    hist_var_name_dict;
    hist_label_dict;

    freq_var_name_dict;
    freq_label_dict;

    force_var_name_dict;
    force_label_dict;

    clims; % color limits for each variable
    clim_scale;

    param_panel; % panel of 3D plot parameters
    var_dropdown; % drop down box object for variable selection
    clim_slider; % slider for color limits on plots
    slider; % slider object
    play_button;
    iso_slider;
    
    % properties related to 3D plot

    plot_hold_bool;
    iso_val;
    iso_var;
    iso_var_list;
    mirror_bool;
    filter_bool;
    trim_bool;
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

        obj.plot_types = ["time avg","phase avg: movie","phase avg: 3D plot",...
            "image wingbeat phase", "wingbeat frequency","wake forces","phase avg: planar avg"];
        obj.plot_hold_bool = false;
        obj.iso_var_list = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                            "Q_x","Q_y","Q_z","|Q|", "helicity"];
        obj.iso_var = "|Q|";
        obj.iso_val = 0.05;
        obj.mirror_bool = false;
        obj.filter_bool = false;
        obj.num_cycles = 1;
        obj.trim_bool = true;

        files = dir(obj.file_path + "*.mat");

        obj.file_suffix = "_phase_avg.mat";

        % Convert file names to a string array
        fileNames = string({files.name});
        
        % Create a logical mask: true where the suffix exists
        hasSuffix = contains(fileNames, obj.file_suffix);
        
        % Only apply extractBefore to the matching files
        fileNames(hasSuffix) = extractBefore(fileNames(hasSuffix), obj.file_suffix);

        obj.case_name_list = fileNames;

        obj.movie_3D_vars = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|","helicity"];
        movie_3D_values = ["u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
        "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg",...
        "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg","uncTot_phase_avg","hel_phase_avg"];

        obj.hist_vars = ["bin counts","bin SD","distribution"];
        hist_vals = ["bin_count", "bin_std","tick_frame_pos"];
        hist_labels = ["Number of frames per bin", "Phase variability per bin (% cycle)","Number of frames per tick"];

        obj.freq_vars = ["frequency","bin counts", "bin SD"];
        freq_vals = ["phase_avg_speed", "bin_count_speed", "bin_std_speed"];
        freq_labels = ["Wingbeat Frequency (Hz)", "Number of samples per bin", "Phase variability per bin (% cycle)"];

        obj.force_vars = ["lift_vort", "lift_vel", "drag_vort", "drag_vel"];
        force_vals = ["lift", "lift_vel", "drag", "drag_vel"];
        force_labels = ["Lift (N)", "Lift (N)", "Drag (N)", "Drag (N)"];

        obj.var_name_list = obj.movie_3D_vars;
        % obj.clims = [-0.2, 0.2;...
        %              -0.2, 0.2;...
        %               -1.1, -0.9;...
        %               -1.1, -0.9;...
        %               -1, 1;...
        %               -1, 1;...
        %               -1, 1;...
        %               -1, 1;...
        %               0, 0.1;...
        %               0, 0.1;...
        %               0, 0.1;...
        %               0, 0.1;...
        %               0, 0.02;...
        %               0, 0.02;...
        %               0, 0.02;...
        %               0, 0.02];
        obj.clims = [-1.1, -0.9;...
                     -0.2, 0.2;...
                      -0.2, 0.2;...
                      -1.1, -0.9;...
                      -1, 1;...
                      -1, 1;...
                      -1, 1;...
                      0, 2;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.1;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      0, 0.02;...
                      -1, 1];
        % obj.iso_vals = [];
        obj.clim_scale = 2;
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
                            "\boldmath$\frac{U c}{U_{\infty}}$",...
                            ""];

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

        force_keys = cellstr(obj.force_vars);
        obj.force_var_name_dict = containers.Map(force_keys, force_vals);
        obj.force_label_dict = containers.Map(force_keys, force_labels);
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
        pause(1.8) % wait until GUI opened

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
        clim_center = mean(obj.clims(1,:));
        clim_range = (obj.clim_scale/2)*diff(obj.clims(1,:));
        obj.clim_slider.Limits = [clim_center - clim_range, clim_center + clim_range];
        obj.clim_slider.Value = obj.clims(1,:);
        % s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        % s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        obj.clim_slider.ValueChangedFcn = @(src, event) clim_change(src, event, plot_panel);

        button11_y = clim_y - 70;
        b11 = uibutton(option_panel,"state");
        b11.Value = true;
        b11.Text = "Trim";
        b11.FontSize = 18;
        b11.Position = [30 button11_y 120 unit_height];
        b11.BackgroundColor = [0.3010 0.7450 0.9330];
        b11.ValueChangedFcn = @(src, event) trim_change(src, event, plot_panel);

        button2_y = button11_y - 40;
        b2 = uibutton(option_panel,"state");
        b2.Text = "Mirror";
        b2.FontSize = 18;
        b2.Position = [30 button2_y 120 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.ValueChangedFcn = @(src, event) mirror_change(src, event, plot_panel);

        button3_y = button2_y - 35;
        b3 = uibutton(option_panel,"state");
        b3.Text = "Filter";
        b3.FontSize = 18;
        b3.Position = [30 button3_y 120 unit_height];
        b3.BackgroundColor = [1 1 1];
        b3.ValueChangedFcn = @(src, event) filter_change(src, event, plot_panel);

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
        param_panel_y = button11_y - 150 - param_panel_height;
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

        iso_slider_y = l1_y - 5;
        iso_slider_w = param_panel_width - 2*10;
        obj.iso_slider = uislider(obj.param_panel);
        obj.iso_slider.Position = [5 iso_slider_y iso_slider_w 3];
        obj.iso_slider.Limits = [0.005 0.1];
        obj.iso_slider.Value = obj.iso_val;
        obj.iso_slider.MajorTicks = 0:0.025:0.1; % 0:0.05:0.5
        obj.iso_slider.MinorTicks = 0.005:0.005:0.1; % 0.01:0.01:0.5
        obj.iso_slider.ValueChangedFcn = @(src, event) iso_change(src, event, plot_panel);

        % Dropdown box for which variables to display
        drop_y4 = iso_slider_y - 70;
        d4 = uidropdown(obj.param_panel);
        d4.Position = [30 drop_y4 120 30];
        d4.Items = obj.iso_var_list;
        d4.Value = obj.iso_var;
        d4.ValueChangedFcn = @(src, event) iso_var_change(src, event, plot_panel);

        l2_y = drop_y4 - 35;
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
            if ~((strcmp(tmp,obj.plot_types(1)) || strcmp(tmp,obj.plot_types(2)) ...
                    || strcmp(tmp,obj.plot_types(3)) || strcmp(tmp,obj.plot_types(7))) &&...
               (strcmp(src.Value,obj.plot_types(1)) || strcmp(src.Value,obj.plot_types(2)) ...
               || strcmp(src.Value,obj.plot_types(3)) || strcmp(src.Value,obj.plot_types(7))))
            if strcmp(obj.plot_type, obj.plot_types(4))
                obj.var_name_list = obj.hist_vars;
            elseif strcmp(obj.plot_type, obj.plot_types(5))
                obj.var_name_list = obj.freq_vars;
            elseif strcmp(obj.plot_type, obj.plot_types(6)) % wake forces
                obj.var_name_list = obj.force_vars;
            else
                obj.var_name_list = obj.movie_3D_vars;
            end
            obj.var_dropdown.Items = obj.var_name_list;
            obj.variable_name = obj.var_dropdown.Value;
            end

            % update color limit slider
            var_idx = find(obj.variable_name == obj.var_name_list);
            center = mean(obj.clims(var_idx,:));
            range = (obj.clim_scale/2)*diff(obj.clims(var_idx,:));
            obj.clim_slider.Limits = [center - range, center + range];
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
            center = mean(obj.clims(var_idx,:));
            range = (obj.clim_scale/2)*diff(obj.clims(var_idx,:));
            obj.clim_slider.Limits = [center - range, center + range];
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

        % User pressed normalization button
        function trim_change(src, ~, plot_panel)
            if (src.Value)
                obj.trim_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.trim_bool = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function iso_change(src, ~, plot_panel)
            precision = 0.005;
            % Force the slider value to the nearest integer immediately
            src.Value = round(src.Value / precision) * precision;

            obj.iso_val = src.Value;
            % obj.clims(9:12,2) = obj.iso_val;
            obj.update_plot(plot_panel);
        end

        % User selected new desired isosurface variable for 3D plot
        function iso_var_change(src, ~, plot_panel)
            obj.iso_var = src.Value;

            var_idx = find(obj.iso_var == obj.var_name_list);

            % obj.iso_slider.Limits = obj.clims(var_idx,:);
            % obj.iso_val = mean(obj.clims(var_idx,:));
            % obj.iso_slider.Value = obj.iso_val;
            % obj.iso_slider.MajorTicks = 0:0.025:0.1; % 0:0.05:0.5
            % obj.iso_slider.MinorTicks = 0.005:0.005:0.1; % 0.01:0.01:0.5

            % 1. Set the basic properties
            new_limits = obj.clims(var_idx, :);
            range_width = new_limits(2) - new_limits(1);

            obj.iso_slider.Limits = new_limits;
            obj.iso_val = mean(new_limits) + range_width/4;
            obj.iso_slider.Value = obj.iso_val;
            
            % Aim for roughly 5 to 10 major ticks
            % We use 'round' and 'log10' to find a nice power-of-ten interval
            raw_step = range_width / 5;
            magnitude = 10^floor(log10(raw_step));
            clean_step = round(raw_step / magnitude) * magnitude;
            
            % 3. Apply the Ticks
            % Ensure the ticks start at a multiple of the step
            first_tick = ceil(new_limits(1) / clean_step) * clean_step;
            obj.iso_slider.MajorTicks = first_tick : clean_step : new_limits(2);
            
            % Optional: Set Minor Ticks to be 1/5th or 1/2 of Major Ticks
            obj.iso_slider.MinorTicks = first_tick : (clean_step / 5) : new_limits(2);

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
            % fprintf('View changed to: %s\n', selected_text);
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
        if ismember(plot_idx, [1, 2, 3, 7])
            % load in variables to plot
            var_name = obj.variable_name_dict(obj.variable_name);
            var_idx = find(obj.variable_name == obj.var_name_list);

            % vars = {"L","U","num_bins","cycle_freq","x","y",var_name};
            vars = {"L","U","num_bins","cycle_freq","z","y",var_name};
        end
        
        if plot_idx == 3 || plot_idx == 7 % 3D plot
            iso_var_name = obj.variable_name_dict(obj.iso_var);
            vars{end+1} = iso_var_name;
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
        elseif plot_idx == 6
            var_name = obj.force_var_name_dict(obj.variable_name);
            vars = {"L","U","y","z","u_phase_avg","w_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg"};
        end
        full_file_path = obj.file_path + obj.case_name + obj.file_suffix;
        d = load(full_file_path, vars{:});

        if plot_idx == 2 || plot_idx == 3
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

        if plot_idx ~= 6
            val = d.(var_name);
        end

        % movie or 3D plot
        if ismember(plot_idx, [1, 2, 3, 7])
            y = squeeze(d.y(3,:,:));
            z = squeeze(d.z(3,:,:));
            val = squeeze(val(3,:,:,:));

            % Add values to params

            params.U = d.U;

            if min(obj.clims(var_idx,:)) < -1
                params.zero = -1;
            elseif min(obj.clims(var_idx,:)) < 0.5
                params.zero = 0;
            else
                params.zero = 1;
            end
    
            params.cb_lab = obj.label_dict(obj.variable_name);

            if any(contains(["v","ω_z","ω_x"],obj.variable_name))
                cFlip = true;
            else
                cFlip = false;
            end

            % Trim data
            if obj.trim_bool
                ybounds = [-2.26 2.45]; % roughly -0.15 to 0.15 meters
                zbounds = [-2.36 2.55]; % roughly -0.2 to 0.2 meters
                
                y_idx = find(y(:,1) > ybounds(1) & y(:,1) < ybounds(2));  % columns
                z_idx = find(z(1,:) > zbounds(1) & z(1,:) < zbounds(2));  % rows
                
                y = y(y_idx, z_idx);
                z = z(y_idx, z_idx);
                val = val(y_idx,z_idx,:);
            end
            % Mirror data
            if obj.mirror_bool
                % Mirror in x-direction across y-axis at centerpoint of robot/ellipse

                % First trim data about center point 
                y_cen = -2.26; % -2.16, 2.55
                
                y_idx_m = find(y(:,1) > y_cen);  % columns
                
                y = y(y_idx_m, :);
                z = z(y_idx_m, :);
                val = val(y_idx_m,:,:);
                
                % shift axis so that min point is now considered as origin
                y = y - min(y, [], "all");
                
                % Now reflect data
                % x goes from positive to negative from left to right
                y_add = flip(-y(2:end,:),1);
                z_add = flip(z(2:end,:),1);
                % flip only if C_phase_avg is streamwise vorticity
                if cFlip
                    val_add = flip(-val(2:end,:,:),1);
                else
                    val_add = flip(val(2:end,:,:),1);
                end
                
                % trimming 2:end to exclude double counting of zero
                y = [y_add; y];
                z = [z_add; z];
                val = [val_add; val]; 
            end

            if obj.filter_bool
                % median filter approach
                val = medfilt3(val);

                % % 1. Create a binary mask of where the data exceeds your threshold
                % % This defines the "solid" parts of your volume
                % BW = Q >= params.isoValue;
                % 
                % % 2. Remove "islands" smaller than P voxels
                % % Adjust P (e.g., 50, 100, 500) based on the size of the noise you want to kill
                % P = 100; 
                % BW_clean = bwareaopen(BW, P);
                % 
                % % 3. Mask the original Q_fin data
                % % Set noisy regions to a value below the isoValue so they aren't rendered
                % Q(~BW_clean) = 0;
            end
        end

        if plot_idx == 3 || plot_idx == 7 % == 7 is TEMP
            Q = d.(iso_var_name);
            Q = squeeze(Q(3,:,:,:));

            if obj.trim_bool
                Q = Q(y_idx,z_idx,:);
            end
            if obj.mirror_bool
                Q = Q(y_idx_m,:,:);
                Q_add = flip(Q(2:end,:,:),1);
                Q = [Q_add; Q];
            end
            if obj.filter_bool
                Q = medfilt3(Q);
            end
        end
        
        % Make axes for plot
        % empty - first run, not valid - empty (no values)
        if ~obj.plot_hold_bool
            ax = axes(plot_panel);
        end

        if plot_idx == 1
            params.clims = obj.clims(var_idx,:);

            mean_val = mean(val,3);
            PIV_plot(y, z, mean_val, params, ax);
        elseif plot_idx == 2

        % params.title = "Spanwise velocity - Average";
        params.clims = obj.clims(var_idx,:);

        val_tr = val(:,:,obj.frame_ind);
        h = PIV_plot(y, z, val_tr, params, ax);
        t = title(ax, ["Bin number: " + obj.frame_ind], FontSize=18);

        while obj.play && (obj.frame_ind < obj.num_bins)
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

            if obj.frame_ind == obj.num_bins
            obj.frame_ind = 0; % reset for next loop iteration
            end
        end
        elseif plot_idx == 3
            params.num_bins = d.num_bins;
            params.clims = obj.clims(var_idx,:);
            params.movie = false;
            params.L = d.L;
            params.shift = obj.frame_ind - 1;
            params.isoValue = obj.iso_val; % 0.05
            params.num_cycles = obj.num_cycles;

            [xlims,s,cData] = stack_vortices_3D(y, z, val, Q, d.cycle_freq, params);
            setColorBar(ax, params)
            xlim(ax,xlims) % otherwise when plotting multiple wingbeats awkward extra space added

            while obj.play && (obj.frame_ind < obj.num_bins)
                obj.frame_ind = obj.frame_ind + 1;
                obj.slider.Value = obj.frame_ind;
                params.shift = obj.frame_ind;
        
                [~,s,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
                p.Vertices = s.vertices;
                p.Faces = s.faces;
                p.FaceVertexCData = cData;
        
                pause(0.1);

                if obj.frame_ind == obj.num_bins
                    obj.frame_ind = 0; % reset for next loop iteration
                end
            end

            if obj.plot_hold_bool
                p.Vertices = s.vertices;
                p.Faces = s.faces;
                p.FaceVertexCData = cData;
            else
                plot_3D(ax, s, cData, params);
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
        elseif plot_idx == 6
            % Compute lift/drag force
            avg_type = 1;
            y_cen = -0.142 / d.L;
            z_cen = -0.03 / d.L;

            norm_bool = false;
            [val, err] = get_PIV_force(full_file_path, obj.case_name, var_name, avg_type, norm_bool);

            %

            plot(ax, val)
            hold(ax, "on")
            yline(ax, mean(val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.force_label_dict(obj.variable_name), FontSize=16)
        elseif plot_idx == 7
            % y = squeeze(d.y(3,:,:));
            % z = squeeze(d.z(3,:,:));
            % val = squeeze(val(3,:,:,:));

            % val(Q <= 0.001) = NaN;

            mean_val = squeeze(mean(val, [1 2], "omitnan"));

            plot(ax, mean_val)
            hold(ax, "on")
            yline(ax, mean(mean_val))
            xlabel(ax, "Time", FontSize=16)
            ylabel(ax, obj.label_dict(obj.variable_name), FontSize=16, Interpreter="latex")
        end
    end
end

end