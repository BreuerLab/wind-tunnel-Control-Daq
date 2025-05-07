path = "C:\Users\rgissler\Downloads\";

% fig1_name = "temp.fig";
% fig2_name = "temp2.fig";
% fig1_name = "scaling_data.fig";
% fig2_name = "scaling_simp_mod.fig";
fig1_name = "scaling_data_freq.fig";
fig2_name = "scaling_simp_mod_freq.fig";
fig1_name = "temp_eff.fig";
fig2_name = "temp_regular.fig";

% Load the first figure
fig1 = openfig(path + fig1_name, 'invisible');  % load without displaying
ax1 = findall(fig1, 'type', 'axes');         % find axes in figure1

% Load the second figure
fig2 = openfig(path + fig2_name, 'invisible');
ax2 = findall(fig2, 'type', 'axes');

% Create a new figure to combine plots
combined_fig = figure;
combined_fig.Position = fig1.Position;  % Match figure window size
combined_ax = axes(combined_fig);

new_colors = ["#252525", "#636363", "#969696", "#cccccc"];
new_colors = flip(new_colors);
color_index = 1;

ax_new_color = ax1;
ax_old = ax2;

% Copy objects from the second figure
for i = 1:length(ax_old)
    copyobj(allchild(ax_old(i)), combined_ax);
end

% Copy objects from the first figure
for i = 1:length(ax_new_color)
    children = allchild(ax_new_color(i));
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

% Copy labels and title from ax1(1) (or any desired axis)
xlabel(combined_ax, ax_new_color(1).XLabel.String);
ylabel(combined_ax, ax_new_color(1).YLabel.String);
title(combined_ax, ax_new_color(1).Title.String);

% Match font sizes
combined_ax.FontSize = ax_new_color(1).FontSize;

% Match grid settings
if strcmp(ax_new_color(1).XGrid, 'on')
    grid(combined_ax, 'on');
else
    grid(combined_ax, 'off');
end

legend('show');