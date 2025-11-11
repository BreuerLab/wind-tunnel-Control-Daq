clear
close all

% Initial plot of single radial gaussian distribution
% I0 = 1; % normalized units
% bw = 4; % mm
% r = linspace(-2*bw,2*bw,200);
% I = I0 * exp((-2*r.^2) / bw^2);
% 
% figure
% plot(r, I, LineWidth=2)
% xlabel("Radial distance")
% ylabel("Intensity")
% set(gca, FontSize=14)

% Plot heatmap for energy intensity in FOV
clear

color_lim = 0.25;
I0 = 1; % normalized units
% bw = 3.427; % mm, reported as 1/4 inch (6.35 mm) but effective diameter 86.5% listed in test at 3.4 mm
bw = 3.875;
% bw = 5;Is t
L = 400; % mm, vertical length of FOV
W = 400; % mm, horizontal width of FOV
L_cal = 500;
W_cal = 310;
wt_dim = 1200; % mm, wind tunnel is 1.2 x 1.2 m
% vert_off = (14 + 7)*10; % mm, vertical offset of laser mirrors above wind tunnel

vert_off = (11 + 1)*10; % mm, vertical offset of lens above wind tunnel
d = ((wt_dim - L) / 2) + vert_off; % mm, vertical distance from focal point of cylindrical
                                    % lens to top of FOV
d_cal = ((wt_dim - L_cal) / 2) + vert_off; % mm, vertical distance from focal point of cylindrical
h_off = W*0.35; % mm, horizontal offset of wind tunnel
% z = linspace(d,d+L,200);
hor_num = 1000;
vert_num = 1000;

% ----------------------------------------------------------------------
% -------------------Annular section swept by wing----------------------
% ----------------------------------------------------------------------

w_r = 39; % mm
w_L = 177; % mm
phi = 21.3; % deg

p_y = d + L/2;
p_x = h_off;
% Parameters
pivot = [p_x, p_y];            % pivot point (not on the line)
line_p1 = [p_x + w_r, p_y];          % line endpoint 1
line_p2 = [p_x + w_L, p_y];          % line endpoint 2

% Radii of the two endpoints
r1 = norm(line_p1 - pivot);
r2 = norm(line_p2 - pivot);

% Sample angles
theta = linspace(-phi, phi, 200);

% Arc coordinates
x_outer = pivot(1) - r1*cosd(theta);
y_outer = pivot(2) - r1*sind(theta);

x_inner = pivot(1) - r2*cosd(theta);
y_inner = pivot(2) - r2*sind(theta);

% Build annular sector polygon
x_ring = [x_inner, fliplr(x_outer)];
y_ring = [y_inner, fliplr(y_outer)];

% ----------------------------------------------------------------------

t = 2; % thickness of laser beam edge on plot (not physical)
% fl = 3.91; % mm, a concave lens so this number is actually negative
% bfl_vals = 100; % mm
% bfl_vals = [5.2, 5.3, 7.1, 7.7, 9.0, 11.0, 14.0, 15.0 16.3, 20.3, 21.3, 23.5, 26.2, 26.7];
bfl_vals = 8; % mm
% bfl_vals = 20.3; % mm
% back focal length (mechanical) different from effective focal length
% (optical), "A mechanical measurement given as the distance between the
% last surface of an optical lens to its image plane."
P = 10; % W, roughly

if (~isscalar(bfl_vals))
    med_int_vals = zeros(size(bfl_vals));
end

for j = 1:length(bfl_vals)
bfl = bfl_vals(j);

z = linspace(0,wt_dim + vert_off + bfl,vert_num);
theta = atan(bw / (2 * bfl));
int_grid = zeros(hor_num,length(z));
laser_grid = zeros(hor_num,length(z));
for i = 1:length(z)
    cur_w = 2 * z(i) * tan(theta);
    % r = linspace(-W/2,W/2,200);
    % radial/width array for laser beam intensity calculation
    w_r = linspace(-wt_dim/2  + h_off, wt_dim/2 + h_off,hor_num);
    % I0 = (2 * P) / (pi * (cur_w / 10)^2); % only true for cone
    A = pi * (bw / 10) * ((cur_w / 2) / 10);
    I0 = P / A;
    I = I0 * exp((-2*w_r.^2) / cur_w^2);

    % Store as a column
    int_grid(i,:) = I(:);

    if (z(i) < bfl) % preserve laser as beam before lens
        [M, ind_left] = min(abs(w_r + bw/2));
        [M, ind_right] = min(abs(w_r - bw/2));
    else % find location where beam width ends
        [M, ind_left] = min(abs(w_r + cur_w/2));
        [M, ind_right] = min(abs(w_r - cur_w/2));
    end

    try % give laser some apparent thickness on the plot so it can be seen more clearly
    laser_grid(i, ind_left-t:ind_left+t) = 1;
    laser_grid(i, ind_right-t:ind_right+t) = 1;
    catch % when thickness hits border of plot, plot original unthickened line
    laser_grid(i, ind_left) = 1;
    laser_grid(i, ind_right) = 1;
    end

    % if (mod(i,50) == 0)
    %     figure
    %     plot(r, I, LineWidth=2)
    %     xlabel("Radial distance")
    %     ylabel("Intensity")
    %     set(gca, FontSize=14)
    % end
end
if (~isscalar(bfl_vals))
median_intensity = median(int_grid(z > d+bfl & z < (d+bfl+L),w_r > -W/2 & w_r < W/2),"all");
med_int_vals(j) = round(median_intensity,3);
end
end

if (isscalar(bfl_vals))
bfl = bfl_vals;

% [left bottom width height]
FOV_pos = [-W/2 d + bfl W L];
Cal_pos = [-W/2 + (W - W_cal)/2 d_cal + bfl W_cal L_cal];
wind_tunnel_pos = [-wt_dim/2 + h_off bfl + vert_off wt_dim wt_dim];

% ----------------------------------------------------------------------
% ----------Laser Beam Border in Wind Tunnel Section Plot---------------
% ----------------------------------------------------------------------

figure
hold on
imagesc(w_r, z, laser_grid)
n = 256;  % number of steps
cmap = [linspace(1,0,n)', linspace(1,1,n)', linspace(1,0,n)'];  
colormap(cmap);

% Plot annular region swept by wing
fill(x_ring, y_ring, 'c', 'FaceAlpha', 0.3, 'EdgeColor', 'k');
plot(pivot(1), pivot(2), 'ko', 'MarkerFaceColor', 'k'); % pivot

xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
axis equal
xlim([-wt_dim/2 + h_off wt_dim/2 + h_off])
ylim([0 wt_dim + vert_off])
% xlim([-4 4])
% ylim([0 8])
% xlim([-4 4])
% ylim([-8 8])
title('Border of Laser Beam')

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

% Wind tunnel rectangle
rectangle('Position', wind_tunnel_pos, 'EdgeColor', 'k', 'LineWidth', 1)

% ----------------------------------------------------------------------
% ------------Field of View in Wind Tunnel Section Plot-----------------
% ----------------------------------------------------------------------

figure
hold on
imagesc(w_r, z, int_grid)
cb = colorbar;
% clim([0 color_lim])

% Define custom 2-color colormap:
% - first color: white (for values below cutoff)
% - second color: yellow (for values above cutoff)
colormap([1 1 1; 1 1 0]);
% Set color limits so that values <= cutoff map to first color,
% and values >= cutoff map to second color
clim([color_lim-0.001, color_lim+0.001]); 

datacursormode on

% Plot annular region swept by wing
fill(x_ring, y_ring, 'c', 'FaceAlpha', 0.3, 'EdgeColor', 'k');
plot(pivot(1), pivot(2), 'ko', 'MarkerFaceColor', 'k'); % pivot

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

% Calibration target rectangle
rectangle('Position', Cal_pos, 'EdgeColor', '#4f4f4f', 'LineWidth', 2)

% Wind tunnel rectangle
rectangle('Position', wind_tunnel_pos, 'EdgeColor', 'k', 'LineWidth', 1)

ylabel(cb,'W / cm^2','FontSize',16,'Rotation',270)
xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
axis equal
xlim([-wt_dim/2 + h_off wt_dim/2 + h_off])
ylim([0 wt_dim + vert_off])
title('Light Intensity in Wind Tunnel')

% ----------------------------------------------------------------------
% --------------------------Field of View Plot--------------------------
% ----------------------------------------------------------------------

figure
hold on
imagesc(w_r(w_r > -W/2 & w_r < W/2), z(z > d+bfl & z < (d+bfl+L)), int_grid(z > d+bfl & z < (d+bfl+L),w_r > -W/2 & w_r < W/2))
cb = colorbar;
clim([0 color_lim])
datacursormode on

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

ylabel(cb,'W / cm^2','FontSize',16,'Rotation',270)
xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
axis equal
xlim([-W/2 W/2])
ylim([d+bfl d+bfl+L])
title('Light Intensity in Field of View')

disp("Back focal length: " + bfl + " mm")

mean_intensity = mean(int_grid(z > d+bfl & z < (d+bfl+L),w_r > -W/2 & w_r < W/2),"all");
disp("The average intensity in the FOV is: " + round(mean_intensity,3) + " W/cm^2")

median_intensity = median(int_grid(z > d+bfl & z < (d+bfl+L),w_r > -W/2 & w_r < W/2),"all");
disp("The median intensity in the FOV is: " + round(median_intensity,3) + " W/cm^2")

min_intensity = min(int_grid(z > d+bfl & z < (d+bfl+L),w_r > -W/2 & w_r < W/2),[],"all");
disp("The minimum intensity in the FOV is: " + round(min_intensity,3) + " W/cm^2")

else
    [M, I] = max(med_int_vals);
    disp("Highest median intensity is " + M + " W/cm^2, for BFL = " + bfl_vals(I))
end