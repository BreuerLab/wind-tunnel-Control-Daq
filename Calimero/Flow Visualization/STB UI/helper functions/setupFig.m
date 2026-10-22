function [option_panel, plot_panel, screen_size] = setupFig(mon_num)
        % Select the monitor based on user input (1, 2, ...) and how many
        % monitors MATLAB detects.
        % NOTE: MATLAB reads the monitor layout once, when it starts. If
        % monitors change while it's running (e.g. connecting through
        % Remote Desktop with "use all my monitors" after MATLAB was
        % started), restart MATLAB so it sees the new layout.
        monitor_positions = get(0, 'MonitorPositions');
        num_monitors = size(monitor_positions, 1);
        if mon_num >= 1 && mon_num <= num_monitors
            screen_size = monitor_positions(mon_num, :);
        else
            fprintf('Monitor %d not detected (MATLAB sees %d), using monitor 1.\n', mon_num, num_monitors);
            screen_size = monitor_positions(1, :);
        end
        fprintf('Monitors seen by MATLAB [x y width height]:\n');
        disp(monitor_positions)
        fprintf('Placing figure on monitor %d: [%g %g %g %g]\n', ...
            min(max(mon_num, 1), num_monitors), screen_size);

        % Create the window hidden and move it onto the target monitor
        % before showing and maximizing it. uifigure windows are positioned
        % asynchronously, so maximizing straight away can maximize the
        % window on the monitor it was created on (usually the primary).
        % Use a box inside the monitor rather than its full area so the
        % window manager doesn't clamp it back onto the primary monitor.
        inset = round(0.1 * screen_size(3:4));
        fig = uifigure('Name', 'Dynamic Force Plotting', 'Visible', 'off');
        fig.Position = [screen_size(1:2) + inset, screen_size(3:4) - 2*inset];
        fig.Visible = 'on';
        drawnow
        fig.WindowState = 'maximized'; % or 'fullscreen'
        drawnow

        % Create a grid layout
        plot_grid = uigridlayout(fig, [1, 2]);
        plot_grid.RowHeight = {'1x'};
        plot_grid.ColumnWidth = {200, '1x'};

        % Panel for dropdowns
        option_panel = uipanel(plot_grid);
        option_panel.Layout.Row = 1;
        option_panel.Layout.Column = 1;
        option_panel.AutoResizeChildren = false;

        % Panel for plots
        plot_panel = uipanel(plot_grid);
        plot_panel.Layout.Row = 1;
        plot_panel.Layout.Column = 2;
end
