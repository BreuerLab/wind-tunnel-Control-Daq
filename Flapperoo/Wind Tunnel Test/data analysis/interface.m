% --------------------------------------------------------------------
% Class providing methods for creating GUI menus and dropdowns
% --------------------------------------------------------------------

classdef interface
    methods(Static)
        function selection = dropdown(options, title)
            % DROPDOWN  Create a dropdown menu to select an item from options
            screen_size = get(0, 'ScreenSize');
            fig_width = 300;
            fig_height = 150;
            fig_x = (screen_size(3) - fig_width) / 2;
            fig_y = (screen_size(4) - fig_height) / 2;
            fig = uifigure('Name', title, 'Position', [fig_x, fig_y, fig_width, fig_height], ...
                           'CloseRequestFcn', @select);
        
            % Create dropdown menu and button
            dropdown = uidropdown(fig, 'Items', options, 'Position', [50, 80, 200, 30]);
            uibutton(fig, 'Text', 'Select', 'Position', [100, 30, 100, 30], 'ButtonPushedFcn', @select);
        
            selection = '';
            uiwait(fig);
        
            % (~,~) indicates arguments of callback function
            % aren't used, called by uibutton above
            function select(~, ~)
                % SELECT  Store the selected item and close the figure
                selection = dropdown.Value;
                uiresume(fig);
                delete(fig);
            end
        end

        function dynamic_plotting(folder_path, filenames)
            % DYNAMIC_PLOTTING  Create a GUI for plotting dynamic data
            if nargin == 1
                items = dir(fullfile(folder_path, "*.mat"));
                filenames = sort({items.name});
            end
            names = Config.NAMES + " & Position Versus Time";
            options = squeeze(split(strrep(filenames, ".mat", ""), "_"));
        
            % Create a GUI figure with a grid layout
            screen_size = get(0, 'ScreenSize');
            fig = uifigure('Name', 'Dynamic Lift Force Plotting', ...
                'Position', [0 0 screen_size(3) screen_size(4)]);
        
            % Create a grid layout
            plot_grid = uigridlayout(fig, [1, 2]);
            plot_grid.RowHeight = {'1x'};
            plot_grid.ColumnWidth = {150, '1x'};
        
            % Panel for dropdowns
            option_panel = uipanel(plot_grid);
            option_panel.Layout.Row = 1;
            option_panel.Layout.Column = 1;
        
            % Panel for plots
            plot_panel = uipanel(plot_grid);
            plot_panel.Layout.Row = 1;
            plot_panel.Layout.Column = 2;

             % Initialize tiled layout for plots
            t = tiledlayout(plot_panel, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
        
            selection = [options(1, :)];
            for i = 1:size(options, 2)
                drop_y = screen_size(4) - 200 - 40 * i;
                uidropdown(option_panel, 'Position', [10 drop_y 200 30], ...
                    'Items', unique(options(:, i)), ...
                    'ValueChangedFcn', @(src, ~) select(i, src));
            end
            fplots =  true(1, 3);
            for i = 1:3
                check_y = drop_y - 35 - 25 * (i - 1);
                uicheckbox(option_panel, 'Text', Config.FORCES(i) + " Force", ...
                    'Position', [20 check_y 100 30], 'Value', true, ...
                    'ValueChangedFcn', @(src, ~) select(i, src));
            end
            update_plot();
        
            function select(i, src)
                % SELECT  Update the selection and plot
                if isa(src, 'matlab.ui.control.DropDown')
                    selection(i) = src.Value;
                else
                    fplots(i) = src.Value;
                end
                update_plot();
            end
        
            function update_plot()
                % UPDATE_PLOT  Update the plot based on selected settings
                delete(t.Children);

                % Load data or return if file does not exist
                filename = fullfile(folder_path, strjoin(selection, "_") + ".mat");
                if ~exist(filename, 'file')
                    return;
                end
                load(filename, 'time', 'forces', 'pos_encoder');
        
                for idx = 1:6
                    ax = nexttile(t, idx);
                    if idx <= 3
                        factor = Config.W;
                        yl = "Normalized Force";
                    else
                        factor = Config.W * Config.L;
                        yl = "Normalized Torque";
                    end
        
                    yyaxis(ax, 'left');
                    hold(ax, 'on');
                    for j = 1:3
                        if fplots(j)
                            fp = Config.FORCES(j);
                            plot(ax, time, forces.(fp)(:, idx) / factor, 'DisplayName', fp, 'LineWidth', 1.5);
                        end
                    end
                    ylabel(ax, yl);
            
                    yyaxis(ax, 'right');
                    plot(ax, time, pos_encoder * 100, 'DisplayName', 'Position', 'LineWidth', 1.5);
                    ylabel(ax, "Position (cm)");
            
                    title(ax, names(idx));
                    xlabel(ax, "Time (s)");
                    grid(ax, 'on');
                    legend(ax);
                end
            end
        end
    end
end