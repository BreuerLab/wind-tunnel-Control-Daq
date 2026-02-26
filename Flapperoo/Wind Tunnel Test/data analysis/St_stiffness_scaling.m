clear
close all

x = [0.2, 0.4];
% x = 0:0.01:1;
y = (x.^2) ./ (x.^2 + (1/4.25));

fig_width = 800;
fig_height = 600;
f = figure;
f.Position(3:4) = [fig_width, fig_height];

plot(x, y, LineWidth=2)
xlabel("Strouhal Number")
ylabel("Flapping Contribution to Pitch Stiffness")
set(gca,FontSize=16)
grid("on")
ylim([0 1])
xline(0.2, LineWidth=2, LineStyle="--")
xline(0.4, LineWidth=2, LineStyle="--")