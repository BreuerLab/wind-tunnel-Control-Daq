function [option_panel, plot_panel, screen_size] = setupFig(mon_num)
        % Select the monitor based on user input (1, 2, ...) and the
        % monitors currently connected.
        monitor_positions = get_monitor_positions();
        num_monitors = size(monitor_positions, 1);
        if mon_num >= 1 && mon_num <= num_monitors
            screen_size = monitor_positions(mon_num, :);
        else
            fprintf('Monitor %d not detected (%d found), using monitor 1.\n', mon_num, num_monitors);
            screen_size = monitor_positions(1, :);
        end
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

% Monitor positions in MATLAB's figure coordinates, one row per monitor
% [x y width height], primary first (same layout as MonitorPositions).
%
% MATLAB reads MonitorPositions once, at startup, so it goes stale if the
% monitors change while MATLAB is running, e.g. connecting through Remote
% Desktop with "use all my monitors". On Windows the current layout is
% read from .NET instead; MonitorPositions is the fallback.
function positions = get_monitor_positions()
    matlab_positions = get(0, 'MonitorPositions');
    positions = matlab_positions;

    if ~ispc
        return
    end
    try
        NET.addAssembly('System.Windows.Forms');
        screens = System.Windows.Forms.Screen.AllScreens;
        n = screens.Length;
        bounds = zeros(n, 4); % [X Y W H], origin top-left of primary, y down
        is_primary = false(n, 1);
        for i = 1:n
            b = screens(i).Bounds;
            bounds(i,:) = double([b.X, b.Y, b.Width, b.Height]);
            is_primary(i) = screens(i).Primary;
        end
    catch err
        fprintf('Could not read the monitor layout from Windows (%s), using MATLAB''s.\n', err.message);
        return
    end

    % primary first, the rest left to right
    primary = find(is_primary, 1);
    if isempty(primary)
        primary = 1;
    end
    others = setdiff(1:n, primary);
    [~, order] = sort(bounds(others, 1));
    bounds = bounds([primary, others(order)], :);

    % Windows reports physical pixels; MATLAB uses scaled pixels when
    % display scaling isn't 100%. Scale by the primary monitor's width.
    scale = matlab_positions(1, 3) / bounds(1, 3);
    bounds = bounds * scale;

    % convert to MATLAB coordinates: 1-based, origin bottom-left of the
    % primary monitor, y up
    primary_height = bounds(1, 4);
    positions = round([bounds(:,1) + 1, primary_height - (bounds(:,2) + bounds(:,4)) + 1, ...
        bounds(:,3), bounds(:,4)]);

    if ~isequal(size(positions), size(matlab_positions)) || any(abs(positions - matlab_positions) > 1, 'all')
        fprintf('MATLAB''s monitor layout is out of date (it is read at startup), using the current one from Windows.\n');
        fprintf('MATLAB [x y width height]:\n');
        disp(matlab_positions)
        fprintf('Windows [x y width height]:\n');
        disp(positions)
    end
end
