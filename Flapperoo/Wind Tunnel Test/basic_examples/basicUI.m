classdef basicUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    % integer, 0-6, defines which force/moment axes to display
    index;
    % force and moment axes labels used in dropdown box
    axes_labels;

    % boolean, whether data is normalized/non-dimensionalized
    norm;

    % frequencies selected by user
    sel_freqs;
end

methods
    % Constructor Function
    % Defines constants and default values for parameters
    function obj = basicUI(mon_num)
        obj.mon_num = mon_num;
        obj.index = 0;
        obj.axes_labels = ["All", "Drag", "Transverse Lift", "Lift",...
            "Roll Moment", "Pitch Moment", "Yaw Moment"];
        obj.norm = false;
        obj.sel_freqs = [];
    end

    % Builds figure with all UI elements and defines all callback
    % functions to be used when user clicks on UI elements
    function dynamic_plotting(obj)
        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);

        tree_y = screen_size(4) - 600;
        t = uitree(option_panel,'checkbox');
        t.Position = [10 tree_y 180 500];
        % Assign callback in response to node selection
        t.CheckedNodesChangedFcn = @(src, event) select_curve(src, event, plot_panel);
        data_freqs = [2, 3, 4];
        for i = 1:length(data_freqs)
            name = "sin(" + data_freqs(i) + "\pit)";
            uitreenode(t, 'Text', name);
        end
        s = uistyle(Interpreter="tex");
        addStyle(t,s)

        % Dropdown box for which force/moment axes to display
        drop_y = tree_y - 35;
        d = uidropdown(option_panel);
        d.Position = [10 drop_y 180 30];
        d.Items = obj.axes_labels;
        d.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        button1_y = drop_y - 35;
        b1 = uibutton(option_panel,"state");
        b1.Text = "Normalize";
        b1.Position = [20 button1_y 160 30];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) norm_change(src, event, plot_panel);

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

        % User selected new curve in checkbox group
        function select_curve(~, event, plot_panel)
            % Get the selected nodes
            selectedNodes = event.CheckedNodes;

            obj.sel_freqs = [];

            for i = 1:length(selectedNodes)
                % Find first number after 'sin(',
                % that's the frequency
                cur_sel_freq = sscanf(extractAfter(selectedNodes(i).Text, "sin("), '%g', 1);
                obj.sel_freqs = [obj.sel_freqs cur_sel_freq];
            end

            obj.update_plot(plot_panel);
        end

        % User selected new desired force/moment axes
        function index_change(src, ~, plot_panel)
            obj.index = find(obj.axes_labels == src.Value) - 1;
            obj.update_plot(plot_panel);
        end

        % User pressed normalization button
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

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

% The only function contained in this section is update_plot
methods (Access = private)
    % update plot after user changes selected variables
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)

        % Variables for plotting later
        x_label = "Wingbeat Period (t/T)";
        if (obj.norm)
            y_label_F = "Cycle Average Force Coefficient";
            y_label_M = "Cycle Average Moment Coefficient";
        else
            y_label_F = "Cycle Average Force (N)";
            y_label_M = "Cycle Average Moment (N*m)";
        end
        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];
        titles = obj.axes_labels(2:7);

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

            x = 0:0.001:1;
            for i = 1:length(obj.sel_freqs)
            for idx = 1:6
                y = rand()*sin(obj.sel_freqs(i)*pi*x) + 0.3*rand()*sin(20*pi*x);
                hold(tiles(idx), 'on');
                line = plot(tiles(idx), x, y);
                line.DisplayName = "sin(" + obj.sel_freqs(i) + "\pit)";
                hold(tiles(idx), 'off');
            end
            end

        % -----------------------------------------------------
        % ---- Plotting a single axes defined by obj.index ----
        % -----------------------------------------------------
        else
            ax = axes(plot_panel);
            idx = obj.index;

            x = 0:0.001:1;
            for i = 1:length(obj.sel_freqs)
            y = rand()*sin(obj.sel_freqs(i)*pi*x) + 0.3*rand()*sin(20*pi*x);
            hold(ax, 'on');
            line = plot(ax, x, y);
            line.DisplayName = "sin(" + obj.sel_freqs(i) + "\pit)";
            hold(ax, 'off');

            title(ax, titles(idx));
            xlabel(ax, x_label);
            ylabel(ax, y_labels(idx))
            grid(ax, 'on');
            legend(ax, Location="best");
            ax.FontSize = 18;
            end
        end
    end
end

end