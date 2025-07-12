function [f, tiles] = compare_AoA_fig()

% Setup figure for plotting cycle average values live
f = figure;
f.Position = [-1084,-414,1090,800]; % bottom of vertical AFAM monitor
tiledlayout(2,3);
tiles = {nexttile, nexttile, nexttile, nexttile, nexttile, nexttile};
titles = ["Drag", "Transverse Lift", "Lift", "Roll Moment", "Pitch Moment", "Yaw Moment"];
x_label = "Angle of Attack (deg)";
y_label_F = "Cycle Average Force (N)";
y_label_M = "Cycle Average Moment (N*m)";
y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];

% Create a subplot for each force/moment axis
for k = 1:6
    axes(tiles{k})
    title(["\textbf{" + titles(k) + "}"], Interpreter='latex');
    xlabel(x_label, Interpreter='latex');
    ylabel(y_labels(k), Interpreter='latex');
end

% Label the whole figure.
sgtitle(["Force and Moment Means vs. Angle of Attack"]);
hL = legend();
hL.Layout.Tile = 'East';

end