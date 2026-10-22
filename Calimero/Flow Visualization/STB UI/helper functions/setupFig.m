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

        % Show the window, then move it onto the target monitor and only
        % maximize once it has actually arrived there. uifigure windows
        % are positioned asynchronously, and maximizing a window that
        % hasn't moved yet maximizes it on the primary monitor. Use a box
        % inside the monitor rather than its full area so the window
        % manager doesn't clamp it back onto the primary monitor.
        inset = round(0.1 * screen_size(3:4));
        target = [screen_size(1:2) + inset, screen_size(3:4) - 2*inset];
        fig = uifigure('Name', 'Dynamic Force Plotting');
        drawnow
        landed = false;
        for attempt = 1:10
            fig.Position = target;
            drawnow
            pause(0.1)
            pos = fig.Position;
            % the move itself has to have happened, not just the window
            % already sitting on that monitor at its default position
            landed = all(abs(pos - target) <= 2) && on_monitor(pos, screen_size);
            if landed
                break
            end
        end
        fprintf('  window at [%g %g %g %g] after %d attempt(s)\n', pos, attempt);

        if landed && on_monitor(screen_size, monitor_positions(1, :))
            % primary monitor: maximizing works
            fig.WindowState = 'maximized'; % or 'fullscreen'
            drawnow
        elseif landed
            % Other monitors: don't maximize. Over Remote Desktop, MATLAB
            % maximizes the window onto the primary monitor, and resizing
            % it while moving between monitors with different display
            % scaling doubles its size and position. The window is already
            % on the target monitor here, so resizing it now stays on that
            % monitor's scaling. OuterPosition includes the title bar, so
            % the whole window stays on screen.
            fig.OuterPosition = screen_size;
            drawnow
            pause(0.2)
            outer = fig.OuterPosition;
            if ~on_monitor(fig.Position, screen_size) || any(abs(outer(3:4) - screen_size(3:4)) > 0.1 * screen_size(3:4))
                % resize went wrong: put it back where it was visible
                fprintf('  could not fill the monitor, leaving the window at [%g %g %g %g]\n', target);
                fig.Position = target;
                drawnow
            end
            fprintf('  window at [%g %g %g %g]\n', fig.Position);
        else
            fprintf('  window did not move to the requested monitor\n');
        end
        
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

% Whether the centre of a window [x y w h] is inside a monitor [x y w h]
function tf = on_monitor(pos, monitor)
    c = pos(1:2) + pos(3:4) / 2;
    tf = all(c >= monitor(1:2) & c <= monitor(1:2) + monitor(3:4));
end
