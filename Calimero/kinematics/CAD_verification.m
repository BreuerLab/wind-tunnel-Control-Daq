function CAD_verification(r, d, numRevs, numPts)

% init_theta only pertains to backwards case
% this wasn't working initially because phi should actually have had a
% negative sign to match CAD data
init_theta = atan(-3.451/6.399);
theta = linspace(init_theta, init_theta - numRevs*2*pi, numPts);

% init_theta = atan(3.451/6.399);
% theta = linspace(init_theta, init_theta + numRevs*2*pi, numPts);
time_eqt = linspace(0, numRevs, numPts);

data_path_F = "R:\ENG_Breuer_Shared\group\Ronan\Solidworks\Calimero\Data\wing_angle_data_1Hz.csv";
data_path_R = "R:\ENG_Breuer_Shared\group\Ronan\Solidworks\Calimero\Data\wing_angle_data_1Hz_rev.csv";

phi_eqt = -atand((r*sin(theta)) ./ (d + r*cos(theta)));

data_F = readmatrix(data_path_F,"NumHeaderLines",2);
time_F = data_F(:,1);
phi_F = data_F(:,2);

data_R = readmatrix(data_path_R,"NumHeaderLines",2);
time_R = data_R(:,1);
phi_R = data_R(:,2);

% --------------------------------------------------------
% Plotting angular velocity of motion from equation compared with motion
% measured from CAD, validates the equation
% --------------------------------------------------------
figure
hold on
plot(time_F, phi_F, DisplayName="SolidWorks Forward", LineWidth=2)
plot(time_R, phi_R, DisplayName="SolidWorks Reverse", LineWidth=2)
plot(time_eqt, phi_eqt, DisplayName="Equation", LineWidth=2)
xlim([0 1])
legend()

end