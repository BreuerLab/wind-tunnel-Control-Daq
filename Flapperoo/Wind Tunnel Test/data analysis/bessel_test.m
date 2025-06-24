clear
close all
% get some typical values for bessel functions
z = 0:0.01:pi/2;
b0 = besselj(0, z);
b1 = besselj(1, z);

figure
hold on
p1 = plot(z, b0, DisplayName="J_0");
p1.LineWidth = 2;
p2 = plot(z, b1, DisplayName="J_1");
p2.LineWidth = 2;
legend

b1_term = z.*(9*besselj(1, z) + besselj(1, 3*z));
b1_term_2 = (9*besselj(1, z) + besselj(1, 3*z)) ./ z;

figure
hold on
p1 = plot(rad2deg(z), b0, DisplayName="J_0(A)");
p1.LineWidth = 2;
p2 = plot(rad2deg(z), b1_term, DisplayName="A(9J_1(A) + J_1(3A))");
p2.LineWidth = 2;
xlabel("Wingbeat Amplitude A (deg)")
set(gca, FontSize=14)
legend(Location="northwest")

figure
hold on
p1 = plot(rad2deg(z), b0, DisplayName="J_0(A)");
p1.LineWidth = 2;
p2 = plot(rad2deg(z), b1_term_2, DisplayName="(9J_1(A) + J_1(3A))/A");
p2.LineWidth = 2;
xlabel("Wingbeat Amplitude A (deg)")
set(gca, FontSize=14)
legend(Location="northeast")

figure
hold on
p1 = plot(z, b1_term ./ b0, DisplayName="J_0");
p1.LineWidth = 2;
legend

figure
hold on
p1 = plot(rad2deg(z), b1_term_2 ./ b0, DisplayName="(9J_1(A) + J_1(3A)) / (A J_0(A))");
p1.LineWidth = 2;
xlabel("Wingbeat Amplitude A (deg)")
set(gca, FontSize=14)
legend()

disp(mean(b1_term ./ b0))

clear

map = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
% map = ["#fef0d9"; "#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
% diverging colors
% map = ["#d7191c"; "#fdae61"; "#ffffbf"; "#abdda4"; "#2b83ba"];
map = hex2rgb(map);
xquery = linspace(0,1,128);
numColors = size(map);
numColors = numColors(1);
map = interp1(linspace(0,1,numColors), map, xquery,'pchip');

l = 0.25;
R = 0.313;
z = 0:0.01:pi/2; % theta_m

% f = 0:1:5;
% U = 5;
f_U = 0:0.1:(5/6);

% Plot flapping number for data
figure
hold on

for i = 1:length(f_U)
    St = 2*R*z * f_U(i);

    p = plot(z, St);
    xlabel("Wingbeat Amplitude \theta_m (rad)")
    ylabel("Strouhal Number")
    p.LineWidth = 2;
    ax = gca;
    set(ax, FontSize=16)
    
    cmap = colormap(ax, map);
    minSt = 0;
    maxSt = 5/6;
    zmap = linspace(minSt, maxSt, length(cmap));
    clim(ax, [minSt, maxSt])
    cb = colorbar(ax);
    ylabel(cb,'f / U (m^{-1})','FontSize',16,'Rotation',270)
    
    p.Color = interp1(zmap, cmap, f_U(i));
end

% Plot flapping number for data
figure
hold on

for i = 1:length(f_U)
    St = 2*R*z * f_U(i);
    Fl = besselj(0, z) + (pi^2 / 18) * (St.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (9*besselj(1, z) + besselj(1, 3*z));

% St = (wing_freq * amp) / wind_speed;
% St = 0.25*besselj(0,amp) + (St^2 / amp)*(0.600353*besselj(1,amp) + 0.0667059*besselj(1,3*amp));

    p = plot(z, Fl);
    xlabel("Wingbeat Amplitude \theta_m (rad)")
    ylabel("Flapping Number")
    p.LineWidth = 2;
    ax = gca;
    set(ax, FontSize=16)
    
    cmap = colormap(ax, map);
    minSt = 0;
    maxSt = 5/6;
    zmap = linspace(minSt, maxSt, length(cmap));
    clim(ax, [minSt, maxSt])
    cb = colorbar(ax);
    ylabel(cb,'f / U (m^{-1})','FontSize',16,'Rotation',270)
    
    p.Color = interp1(zmap, cmap, f_U(i));
end
