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
    variable_name_list;
    variable_name_dict;
    clims; % color limits for each variable
    legend_entries;

    slider; % slider object
    
    % properties related to 3D plot

    plot_hold_bool;
    Q_iso;
    old_Q_iso;
    mirror_bool;
    num_cycles;
    cam;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = STB_UI(mon_num)
        obj.mon_num = mon_num;
        obj.norm = false;
        obj.case_name = "";
        obj.variable_name = "";
        obj.file_path = "Y:\Processed Results\";

        obj.num_bins = 5;
        obj.frame_ind = 1;
        obj.play = false;

        obj.plot_types = ["movie","3D","histogram","2D"];
        obj.plot_hold_bool = false;
        obj.Q_iso = 0.05;
        obj.old_Q_iso = obj.Q_iso;
        obj.mirror_bool = false;
        obj.num_cycles = 1;

        obj.case_name_list = ["flexible_20deg_2Hz","flexible_20deg_6Hz","UP_one_flexible_20deg_6Hz"];
        obj.variable_name_list = ["u","v","w","|U|","ω_x","ω_y","ω_z","|ω|",...
                    "Q_x","Q_y","Q_z","|Q|","u_unc","v_unc","w_unc","|unc|"];
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
                      0, 0.05;...
                      0, 0.05;...
                      0, 0.05;...
                      0, 0.05];
        obj.legend_entries = ["\boldmath$\frac{u c}{U_{\infty}}$",...
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

        keys = cellstr(obj.variable_name_list);
        values = ["u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
                "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg",...
                "Qx","Qy","Qz","Q","uncU_phase_avg","uncV_phase_avg","uncW_phase_avg","uncTot_phase_avg"];
        obj.variable_name_dict = containers.Map(keys, values);
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
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 30];
        d3.Items = obj.variable_name_list;
        obj.variable_name = d3.Value; % use current value in box
        d3.ValueChangedFcn = @(src, event) variable_change(src, event, plot_panel);

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
        b1 = uibutton(plot_panel,"state");
        b1.Text = "Play";
        b1.FontSize = 18;
        b1.Position = [30 button1_y 120 unit_height];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_panel);

        editField_y = drop_y3 - 70;
        l1_x = 30;
        l1_w = 70;
        l1 = uilabel(option_panel);
        l1.HorizontalAlignment = 'right';
        l1.Position = [l1_x editField_y l1_w unit_height];
        l1.Text = 'Q isovalue:';

        f1 = uieditfield(option_panel, 'numeric');
        f1.Position = [l1_x+l1_w+5 editField_y 50 unit_height];
        f1.Value = obj.Q_iso;
        f1.Limits = [0, 1];
        f1.LowerLimitInclusive = 'on';
        f1.ValueChangedFcn = @(src, event) Q_iso_change(src, event, plot_panel);

        button2_y = editField_y - 35;
        b2 = uibutton(option_panel,"state");
        b2.Text = "Mirror";
        % b2.FontSize = 14;
        b2.Position = [30 button2_y 120 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.ValueChangedFcn = @(src, event) mirror_change(src, event, plot_panel);

        button3_y = button2_y - 40;
        % 1. Create the Button Group (the container)
        bg = uibuttongroup(option_panel, ...
            'Position', [30 button3_y 124 unit_height+5], ...
            'BorderType', 'none', ...
            'BackgroundColor', option_panel.BackgroundColor, ...
            'SelectionChangedFcn', @(bg, event) view_change_handler(event, plot_panel));
        
        % Dimensions for buttons relative to the group
        b_w = 32;
        b_s = (120 - 3*b_w)/2;
        pad = 2;

        % 2. Add Toggle Buttons to the group
        % Note: Position is now relative to the 'bg' container [Left Bottom Width Height]
        b3 = uitogglebutton(bg, 'Text', 'xy', 'Position', [pad pad b_w unit_height], 'BackgroundColor', [1 1 1]);
        b4 = uitogglebutton(bg, 'Text', 'yz', 'Position', [pad + b_w + b_s pad b_w unit_height], 'BackgroundColor', [1 1 1]);
        b5 = uitogglebutton(bg, 'Text', 'xz', 'Position', [pad + 2*(b_w + b_s) pad b_w unit_height], 'BackgroundColor', [1 1 1]);

        % panel_width = plot_panel.Position(3);
        % s_w = panel_width * (3/4);
        % s_x = (panel_width - s_w)/2; % end of right monitor around 1690
        % s_y = 0.05*screen_height;

        l_y = button3_y - 35;
        l2 = uilabel(option_panel);
        l2.HorizontalAlignment = 'center';
        l2.Position = [l1_x l_y 120 unit_height];
        l2.Text = 'Number of Wingbeats';

        s_y = l_y - 10;
        s2 = uislider(option_panel);
        s2.Position = [30 s_y 120 3];
        s2.Limits = [1 5];
        s2.Value = obj.num_cycles;
        s2.MajorTicks = 1:5;
        s2.MinorTicks = [];
        s2.ValueChangedFcn = @(src, event) num_cycles_change(src, event, plot_panel);

        button4_y = 0.05*screen_height;
        b6 = uibutton(option_panel,"state");
        b6.Text = "Save Figure";
        b6.FontSize = 18;
        b6.Position = [30 button4_y 120 unit_height];
        b6.BackgroundColor = [1 1 1];
        b6.ValueChangedFcn = @(src, event) save_figure(src, event, plot_panel);

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
            obj.plot_hold_bool = false;
            obj.update_plot(plot_panel);
        end

        % User selected new desired plot type
        function type_change(src, ~, plot_panel)
            obj.plot_type = src.Value;
            obj.plot_hold_bool = false;
            obj.update_plot(plot_panel);
        end

        % User selected new desired force/moment axes
        function variable_change(src, ~, plot_panel)
            obj.variable_name = src.Value;
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
            obj.old_Q_iso = obj.Q_iso;
            obj.Q_iso = src.Value;
            % obj.plot_hold_bool = false;
            obj.clims(9:12,2) = obj.Q_iso;
            obj.update_plot(plot_panel);
        end

        % User pressed mirror button to mirror 3D wake to reconstruct left
        % wing
        function mirror_change(src, ~, plot_panel)
            obj.plot_hold_bool = false;
            if (src.Value)
                obj.mirror_bool = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.mirror_bool = false;
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
                case "xz"
                    view(ax, [0 0 1])
                case "xy"
                    view(ax, [1 0 0])
                case "yz"
                    view(ax, [0 1 0])
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
            obj.plot_hold_bool = false;
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

        % Grab the exact 3D coordinates of the camera
        obj.cam.savedPos = get(ax, 'CameraPosition');
        obj.cam.savedTarget = get(ax, 'CameraTarget');
        obj.cam.savedUp = get(ax, 'CameraUpVector');

        % Delete the axes to prepare for new plotting unless
        % plot is 3D and plot_type 3D, then just adjust colors on plot
        if obj.plot_hold_bool
            p = findobj(ax, 'Type', 'patch');
        else
            delete(ax);
        end

        % load in variables to plot
        var_name = obj.variable_name_dict(obj.variable_name);
        var_idx = find(obj.variable_name == obj.variable_name_list);
        
        vars = {"L","num_bins","cycle_freq","x","y",var_name};
        if obj.plot_type == "3D"
            full_Q_bool = true;
            if full_Q_bool
                Q_var_name = "Q";
                vars{end+1} = Q_var_name;
            else
                % get corresponding Q value
                Q_var_name = obj.variable_name_dict(obj.variable_name_list(var_idx+4));
                vars{end+1} = Q_var_name;
            end
        end
        d = load(obj.file_path + obj.case_name, vars{:});

        % Adjust slider for number of bins
        if d.num_bins ~= obj.num_bins
            obj.num_bins = d.num_bins;
            obj.slider.Limits = [1 d.num_bins];
            obj.slider.MajorTicks = 1:5:d.num_bins;
            obj.slider.MinorTicks = 1:d.num_bins;
        end

        x = d.x(:,:,3);
        y = d.y(:,:,3);
        val = d.(var_name);
        val = squeeze(val(:,:,3,:));
        if obj.plot_type == "3D"
            Q = d.(Q_var_name);
            Q = squeeze(Q(:,:,3,:));
        end
        
        % Make axes for plot
        % empty - first run, not valid - empty (no values)
        if ~obj.plot_hold_bool
            ax = axes(plot_panel);
        end

        if min(obj.clims(var_idx,:)) < -1
            params.zero = -1;
        elseif min(obj.clims(var_idx,:)) < 0.5
            params.zero = 0;
        else
            params.zero = 1;
        end

        params.cb_lab = obj.legend_entries(var_idx);

        if obj.plot_type == "movie"

        % params.zero = 0;
        % params.title = "Spanwise velocity - Average";
        % params.folder = "u_avg";
        % params.clims = [-0.2 0.2];
        % make_movie(x(:,:,z_ind), y(:,:,z_ind), u_phase_avg(:,:,z_ind,:), params)

        params.title = "Spanwise velocity - Average";
        params.clims = obj.clims(var_idx,:);

        [h,t] = phase_avg_plot(x, y, val, params, ax, obj.frame_ind);

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
                set(t, 'String', [params.title "Bin number: " + obj.frame_ind]);
        
                drawnow;

                pause(0.05);
            end
            obj.frame_ind = 1;
        end
        elseif obj.plot_type == "3D"
            params.num_bins = d.num_bins;
            params.clims = obj.clims(var_idx,:);
            params.movie = false;
            params.L = d.L;
            params.shift = -7;
            params.isoValue = obj.Q_iso; % 0.05
            params.mirror = obj.mirror_bool;
            params.num_cycles = obj.num_cycles;
            if obj.plot_hold_bool
                [s,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
                setColorBar(ax, params)
                if obj.old_Q_iso ~= obj.Q_iso
                    % plot_3D(ax, s, cData, params)
                    % % Restore view
                    % set(ax, 'CameraPosition', obj.cam.savedPos, 'CameraTarget',...
                    % obj.cam.savedTarget, 'CameraUpVector', obj.cam.savedUp);
                    p.Vertices = s.vertices;
                    p.Faces = s.faces;
                    p.FaceVertexCData = cData;
                else
                    p.FaceVertexCData = cData;
                end
            else
            [s,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
            setColorBar(ax, params)
            plot_3D(ax, s, cData, params)
            obj.plot_hold_bool = true;
            end
        end
    end
end

end