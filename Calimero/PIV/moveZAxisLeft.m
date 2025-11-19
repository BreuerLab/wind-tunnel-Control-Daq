function moveZAxisLeft(ax)
% moveZAxisLeft - Moves the Z-axis ruler to the left side of a 3D axes
%
% Syntax: moveZAxisLeft(ax)
%
% Input:
%   ax - handle to the axes (default: gca)
%
% Example:
%   figure; surf(peaks);
%   moveZAxisLeft(gca);

if nargin < 1
    ax = gca;
end

% Ensure 3D box and grid
ax.Box = 'off';
ax.XColor = 'k';
ax.YColor = 'k';
ax.ZColor = 'none'; % hide original z-axis

% Determine position for new z-axis (left side)
xmin = ax.XLim(1);        % left side
ycenter = mean(ax.YLim);  % middle of Y axis
zmin = ax.ZLim(1);
zmax = ax.ZLim(2);

% Draw new z-axis line
hold(ax,'on')
zLine = line(ax, [xmin xmin], [ycenter ycenter], [zmin zmax], ...
    'Color','k','LineWidth',1.5);

% Add tick marks and labels
ticks = ax.ZRuler.TickValues;
labels = ax.ZRuler.TickLabel;

tickLength = 0.01 * diff(ax.XLim); % relative size
for i = 1:length(ticks)
    z = ticks(i);
    % tick mark
    line(ax, [xmin xmin+tickLength], [ycenter ycenter], [z z], 'Color','k', 'LineWidth',1);
    % tick label
    text(ax, xmin - tickLength, ycenter, z, labels{i}, ...
        'HorizontalAlignment','right', 'VerticalAlignment','middle');
end
hold(ax,'off')
end