path = "C:\Users\rgissler\Downloads\";

% Load the first figure
fig1 = openfig(path + "temp.fig", 'invisible');  % load without displaying
ax1 = findall(fig1, 'type', 'axes');         % find axes in figure1

% Load the second figure
fig2 = openfig(path + "temp2.fig", 'invisible');
ax2 = findall(fig2, 'type', 'axes');

% Create a new figure to combine plots
combined_fig = figure;
combined_fig.Position = fig1.Position;  % Match figure window size
combined_ax = axes(combined_fig);

new_colors = ["#252525", "#636363", "#969696", "#cccccc"];
new_colors = flip(new_colors);
color_index = 1;

% Copy objects from the first figure
for i = 1:length(ax1)
    children = allchild(ax1(i));
    % copyobj(allchild(ax1(i)), combined_ax);

    % Reverse order (MATLAB draws in reverse order typically)
    children = flipud(children);

    for j = 1:length(children)
    obj = copyobj(children(j), combined_ax);
    
    % Only recolor if it's a line or something with a Color property
    if isprop(obj, 'Color')
        obj.Color = new_colors(color_index);
        color_index = color_index + 1;
    end
    end
end

% Copy objects from the second figure
for i = 1:length(ax2)
    copyobj(allchild(ax2(i)), combined_ax);
end

% Copy labels and title from ax1(1) (or any desired axis)
xlabel(combined_ax, ax1(1).XLabel.String);
ylabel(combined_ax, ax1(1).YLabel.String);
title(combined_ax, ax1(1).Title.String);

% Match font sizes
combined_ax.FontSize = ax1(1).FontSize;

% Match grid settings
if strcmp(ax1(1).XGrid, 'on')
    grid(combined_ax, 'on');
else
    grid(combined_ax, 'off');
end

legend('show');