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

I0 = 1; % normalized units
bw = 3.427; % mm, reported as 1/4 inch (6.35 mm) but effective diameter 86.5% listed in test at 3.4 mm
L = 500; % mm, vertical length of FOV
W = 350; % mm, horizontal width of FOV
wt_dim = 1200; % mm, wind tunnel is 1.2 x 1.2 m
d = (wt_dim - L) / 2; % mm, vertical distance from focal point of cylindrical
                    % lens to top of FOV
% z = linspace(d,d+L,200);
hor_num = 1000;
vert_num = 1000;
t = 2; % thickness of laser beam edge on plot (not physical)
% fl = 3.91; % mm, a concave lens so this number is actually negative
bfl = 7.1; % mm
% bfl = 7.1; % mm
% back focal length (mechanical) different from effective focal length
% (optical), "A mechanical measurement given as the distance between the
% last surface of an optical lens to its image plane."
P = 10; % W, roughly
FOV_pos = [-W/2 d + bfl W L];
wind_tunnel_pos = [-wt_dim/2 + W/2 bfl wt_dim wt_dim];

z = linspace(0,wt_dim,vert_num);

theta = atan(bw / (2 * bfl));
int_grid = zeros(hor_num,length(z));
laser_grid = zeros(hor_num,length(z));
for i = 1:length(z)
    cur_w = 2 * z(i) * tan(theta);
    % r = linspace(-W/2,W/2,200);
    r = linspace(-wt_dim/2  + W/2, wt_dim/2 + W/2,hor_num);
    % I0 = (2 * P) / (pi * (cur_w / 10)^2); % only true for cone
    A = pi * (bw / 10) * ((cur_w / 2) / 10);
    I0 = P / A;
    I = I0 * exp((-2*r.^2) / cur_w^2);

    % Store as a column
    int_grid(i,:) = I(:);

    if (z(i) < bfl)
        [M, ind_left] = min(abs(r + bw/2));
        [M, ind_right] = min(abs(r - bw/2));
    else
        [M, ind_left] = min(abs(r + cur_w/2));
        [M, ind_right] = min(abs(r - cur_w/2));
    end

    try
    laser_grid(i, ind_left-t:ind_left+t) = 1;
    laser_grid(i, ind_right-t:ind_right+t) = 1;
    catch
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

figure
imagesc(r, z, laser_grid)
n = 256;  % number of steps
cmap = [linspace(1,0,n)', linspace(1,1,n)', linspace(1,0,n)'];  
colormap(cmap);
xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
xlim([-wt_dim/2 + W/2 wt_dim/2 + W/2])
ylim([0 wt_dim])
% xlim([-4 4])
% ylim([0 8])
% xlim([-4 4])
% ylim([-8 8])
title('Border of Laser Beam')

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

% Wind tunnel rectangle
rectangle('Position', wind_tunnel_pos, 'EdgeColor', 'k', 'LineWidth', 1)

% --------------------------------------------------------------

figure
hold on
imagesc(r, z, int_grid)
cb = colorbar;
clim([0 0.5])
datacursormode on

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

% Wind tunnel rectangle
rectangle('Position', wind_tunnel_pos, 'EdgeColor', 'k', 'LineWidth', 1)

ylabel(cb,'W / cm^2','FontSize',16,'Rotation',270)
xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
xlim([-wt_dim/2 + W/2 wt_dim/2 + W/2])
ylim([0 wt_dim])
title('Light Intensity in Wind Tunnel')

disp("Back focal length: " + bfl + " mm")

mean_intensity = mean(int_grid(z > d+bfl & z < (d+bfl+L),r > -W/2 & r < W/2),"all");
disp("The average intensity in the FOV is: " + round(mean_intensity,3) + " W/cm^2")

min_intensity = min(int_grid(z > d+bfl & z < (d+bfl+L),r > -W/2 & r < W/2),[],"all");
disp("The minimum intensity in the FOV is: " + round(min_intensity,3) + " W/cm^2")

% --------------------------------------------------------------

figure
hold on
imagesc(r(r > -W/2 & r < W/2), z(z > d+bfl & z < (d+bfl+L)), int_grid(z > d+bfl & z < (d+bfl+L),r > -W/2 & r < W/2))
cb = colorbar;
clim([0 0.5])
datacursormode on

% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

ylabel(cb,'W / cm^2','FontSize',16,'Rotation',270)
xlabel('Horizontal Position (mm)')
ylabel('Vertical Position (mm)')
set(gca, FontSize=14)
set(gca,'YDir','reverse')
xlim([-W/2 W/2])
ylim([d+bfl d+bfl+L])
title('Light Intensity in Field of View')