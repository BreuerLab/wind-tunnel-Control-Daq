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
set(gca, FontSize=18)
legend(Location="northwest")

figure
hold on
p1 = plot(rad2deg(z), b0, DisplayName="J_0(A)");
p1.LineWidth = 2;
p2 = plot(rad2deg(z), b1_term_2, DisplayName="(9J_1(A) + J_1(3A))/A");
p2.LineWidth = 2;
xlabel("Wingbeat Amplitude A (deg)")
set(gca, FontSize=18)
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
set(gca, FontSize=18)
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
z = 0.001:0.001:pi/2; % theta_m
chord = 0.1;

% f = 0:1:5;
% U = 5;
f_U = linspace(0,1,10);

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
    set(ax, FontSize=18)
    
    cmap = colormap(ax, map);
    minSt = 0;
    maxSt = max(f_U);
    zmap = linspace(minSt, maxSt, length(cmap));
    clim(ax, [minSt, maxSt])
    cb = colorbar(ax);
    ylabel(cb,'f / U (m^{-1})','FontSize',16,'Rotation',270)
    
    p.Color = interp1(zmap, cmap, f_U(i));
end

figure
y = (1 - besselj(0, z)) ./ (besselj(1, z) .* z);
plot(z,y)

% Plot flapping number for data
f = figure;
f.Position = [100 100 800 600];
hold on
ax = gca;
set(ax, FontSize=18)
grid(ax, 'on');

cmap = colormap(ax, map);
minSt = 0;
maxSt = max(f_U)*chord*pi;
zmap = linspace(minSt, maxSt, length(cmap));
clim(ax, [minSt, maxSt])
cb = colorbar(ax);
cb.Label.Interpreter = 'latex';
cb.Label.String = '$\frac{\pi fc}{U}$';
cb.Label.FontSize = 24; % Optional: make it more readable
cb.Label.Rotation = 0;

% ylabel(cb,'\frac{fc}{U}','FontSize',16,'Rotation',270,Interpreter='latex')
xlabel("Wingbeat Amplitude \theta_m")
ylabel("Flapping Number")

% Set the tick positions
xticks(0 : pi/12 : pi/3)
xlim([0 pi/3 + 0.0001])
% Set labels using LaTeX syntax
xticklabels({'$0$', '$\frac{\pi}{12}$', '$\frac{\pi}{6}$', '$\frac{\pi}{4}$', '$\frac{\pi}{3}$'})

% Tell MATLAB to use the LaTeX interpreter
set(gca, 'TickLabelInterpreter', 'latex')

bio_f_U_min = 0.2 ./ (2*R*sin(z));
bio_f_U_max = 0.4 ./ (2*R*sin(z));

St_min = 2*R*z .* bio_f_U_min;
Fl_min = besselj(0, z) + (2/3) * pi^2 * (St_min.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, z));

St_max = 2*R*z .* bio_f_U_max;
Fl_max = besselj(0, z) + (2/3) * pi^2 * (St_max.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, z));


% fill([z flip(z)], [Fl_min flip(Fl_max)], [0.2 0.6 0.8], ... % Custom RGB color
%     'FaceAlpha', 0.3, ...                   % 30% transparency
%     'EdgeColor', 'none');

p = plot(z, Fl_min);
p.LineWidth = 2;
p.Color = "black";
p = plot(z, Fl_max);
p.LineWidth = 2;
p.Color = "black";

xline(pi/6,LineWidth=2,Color="black",LineStyle="--")

[M, I] = min(abs(z - pi/6));
Fl_range = [Fl_min(I), Fl_max(I)];

for i = 1:length(f_U)
    St = 2*R*z * f_U(i);
    % Fl = besselj(0, z) + (pi^2 / 18) * (St.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (9*besselj(1, z) + besselj(1, 3*z));
    Fl = besselj(0, z) + (2/3) * pi^2 * (St.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, z));

% St = (wing_freq * amp) / wind_speed;
% St = 0.25*besselj(0,amp) + (St^2 / amp)*(0.600353*besselj(1,amp) + 0.0667059*besselj(1,3*amp));

    p = plot(z, Fl);
    p.LineWidth = 2;

    p.Color = interp1(zmap, cmap, f_U(i)*chord*pi);
end

return

% 2. Define the position of the inset [left, bottom, width, height]
% These values are fractions of the figure window (0 to 1)
insetPos = [0.15, 0.65, 0.25, 0.25]; 

% 3. Create the inset axes
axInset = axes('Position', insetPos);
hold on
grid on

% Set the tick positions
xticks([pi/8, pi/6, pi/5])
xlim([pi/8 pi/5 + 0.0001])
% Set labels using LaTeX syntax
xticklabels({'$\frac{\pi}{8}$', '$\frac{\pi}{6}$', '$\frac{\pi}{5}$'})

% Tell MATLAB to use the LaTeX interpreter
set(gca, 'TickLabelInterpreter', 'latex')

for i = 1:length(f_U)
    St = 2*R*z * f_U(i);
    Fl = besselj(0, z) + (2/3) * pi^2 * (St.^2 ./ (z*R^2)) * (l^2 - 3*l*R + 3*R^2) .* (besselj(1, z));

    % 4. Plot the data into the inset
    p = plot(z, Fl);
    p.LineWidth = 2;

    p.Color = interp1(zmap, cmap, f_U(i));

end