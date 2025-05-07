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