clear
close all
% optics calculation

theta_i = 0.011693; % degrees
% fl_convex = 125; % mm
% fl_concave = -100; % mm
fl_convex = 100; % mm
fl_concave = -50; % mm
% Good values include: 40, -30; 125, -100; 175, -150

D_init = 3.85; % mm
% D_init = 3;
% D_init = 5;
D_fin_orig = 5.85; % mm
lens_separation = fl_convex + fl_concave;
L_tot = 5850; % mm from emission to floor of tunnel
L_i = 0:1:4000; % mm
L_f = L_tot - (lens_separation + L_i); % mm

fl_second = fl_concave;
fl_first = fl_convex;
% MP = - fl_convex / fl_concave;
MP = - fl_second / fl_first;
D_i = D_init + L_i*tand(2 * theta_i);
D_o = D_i * MP;
theta_o = theta_i / MP;

D_fin = D_o + L_f*tand(2 * theta_o);

% if (D_fin < D_fin_orig)
%     disp("Improvement by: " + (D_fin_orig - D_fin))
% end

figure
hold on
yline(D_fin_orig)
yyaxis left
plot(L_i, D_fin, LineWidth=2)
ylabel("Final beam diameter (mm)")

yyaxis right
plot(L_i, D_i, LineWidth=2)
ylabel("Pre-lens beam diameter (mm)")

xlabel("First lens placement relative to emission")
set(gca, FontSize=16)