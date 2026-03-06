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

    slider; % slider object
    
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
                      0.01, 0.1;...
                      0.01, 0.1;...
                      0.01, 0.1;...
                      0.01, 0.1;...
                      0, 0.05;...
                      0, 0.05;...
                      0, 0.05;...
                      0, 0.05];

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
        b1.Position = [30 button1_y 160 unit_height];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) playStop_change(src, event, plot_panel);

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
            obj.update_plot(plot_panel);
        end

        % User selected new desired plot type
        function type_change(src, ~, plot_panel)
            obj.plot_type = src.Value;
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
        axesToDelete = findobj(plot_panel.Children, 'Type', 'axes');

        % Delete the axes to prepare for new plotting unless
        % plot is 3D and plot_type 3D, then just adjust colors on plot
        if is2D(axesToDelete)
            delete(axesToDelete);
        else
            p = findobj(axesToDelete, 'Type', 'patch');
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
        if isempty(axesToDelete) || ~isvalid(axesToDelete)
            ax = axes(plot_panel);
        else
            ax = axesToDelete;
        end

        if obj.plot_type == "movie"
        if min(obj.clims(var_idx,:)) < -1
            zero = -1;
        elseif min(obj.clims(var_idx,:)) < 0.5
            zero = 0;
        else
            zero = 1;
        end

        % params.zero = 0;
        % params.title = "Spanwise velocity - Average";
        % params.folder = "u_avg";
        % params.clims = [-0.2 0.2];
        % make_movie(x(:,:,z_ind), y(:,:,z_ind), u_phase_avg(:,:,z_ind,:), params)

        params.zero = zero;
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
            params.clims = [-1 1];
            params.zero = 0;
            params.movie = false;
            params.L = d.L;
            params.shift = -7;
            params.isoValue = 0.05; % 0.05
            if isvalid(axesToDelete) && ~is2D(axesToDelete)
                [~,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
                p.FaceVertexCData = cData;
            else
            % stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);
            [s,cData] = stack_vortices_3D(x, y, val, Q, d.cycle_freq, params);
            plot_3D(ax, s, cData, params)
            end
        end
    end
end

end