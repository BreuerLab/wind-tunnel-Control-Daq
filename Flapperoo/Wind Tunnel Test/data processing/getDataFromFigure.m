x_vals = zeros(length(AoA_sel),length(wing_freq_sel),2);
y_vals = zeros(length(AoA_sel),length(wing_freq_sel),2);

fig = gcf;
scatter_obj = findobj(gcf,'Type','scatter');
line_obj = findobj(gcf,'Type','line');

x_vals(:,j,1) = scatter_obj(1).XData;
y_vals(:,j,1) = scatter_obj(1).YData;

x_vals(:,j,2) = line_obj(1).XData;
y_vals(:,j,2) = line_obj(1).YData;

% figure
% hold on
% for i = 1:3
%     scatter(x_vals(:,i,1),y_vals(:,i,1))
%     plot(x_vals(:,i,2),y_vals(:,i,2))
% end