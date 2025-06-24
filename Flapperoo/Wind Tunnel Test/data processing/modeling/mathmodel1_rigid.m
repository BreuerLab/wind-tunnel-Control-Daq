% code for rigid wing
clear
close all

%Make the font size bigger than 14
%titles--- 'FontSize', 22, 'FontWeight', 'bold')
%labels----'FontSize', 18)
%legends----'FontSize', 14)


%%
%This extracts info from the experimental data
data_path = "../processed data/";
%pick a file from the processed data folder
[file,path] = uigetfile(data_path + '*.mat');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);
load(path + file)



%Insert the data from the chosen file
%% define physical constants

f=5;%Hz Adjust this to be the same frequency as the chosen file.

period_length=1;
A=pi/6;%rad
m=.013;%kg
l=.05;%m center of mass
%phi= 0; %angle to shift (to align with collected data)
t=frames/f; %0:0.01:1;
g = 10; % negative or positive?
%% Math Model 1

%Ry = Fcsin(theta) centripetal + Fgravity + Finertial
theta = A.*cos(2*pi*f.*t);
dtheta = -2*pi*f*A.*sin(2*pi*f.*t);
ddtheta = -4* pi^2 * f^2 * A .* cos(2*pi*f.*t);
ycom = l.*sin(theta);


% syms t
% dycom = diff(ycom);
% ddycom = diff(dycom)
%dycom = -2*pi*A*l*f*sin(2*pi*f*t)*cos(A*cos(2*pi*f*t));

ddycom = -4*pi^2*A^2*l*f^2.*(sin(2*pi*f.*t)).^2 .* sin(A*cos(2*pi*f.*t)) - ...
    4*pi^2*A*l*f^2.*cos(2*pi*f.*t) .* cos(A*cos(2*pi*f.*t));


forcec = 2*(m*l*(dtheta.^2)); 
forceg = 2*m*g*l.*sin(theta); %this value is really small
forceI = 2*m.*ddycom;
Forcing = forcec+forceg+forceI;


%% Plotting

figure(1)
plot(frames, wingbeat_avg_forces(:,3), "LineWidth", 2)
hold on

plot(frames, Forcing, "LineWidth", 3); % this is plotting too many periods of the forcing

title('Theroetical Force versus Time for Rigid Inertial Wing','FontSize', 22, 'FontWeight','bold');
xlabel('Fraction of the Period','FontSize',  18)
ylabel('Force (N)', 'FontSize',  18)

hold on
plot(frames, (wingbeat_avg_forces(:,3)-Forcing), "-", "LineWidth", 2)

legend('Experimental Wingbeat avg F', 'Math Model One Sum of Forces', 'Subtraction','FontSize', 14);


hold off
figure(2)
%insert a yyaxis here with radians on the right force on the left.
yyaxis right
plot(frames,theta, 'LineWidth', 2)
hold on
ylabel('Wing Position (Radians)','Fontsize', 18)
yyaxis left
plot(frames, Forcing, 'LineWidth', 2)
hold on
plot(frames, forcec, 'LineWidth', 2)
hold on
plot(frames, forceg, 'LineWidth', 2)
hold on
plot(frames, forceI, 'LineWidth', 2)

title('Force Components','FontSize', 22, 'FontWeight','bold')
ylabel('Force (N)','FontSize', 18)
xlabel('Wingbeat Period (t/T)','FontSize', 18) 
legend('Sum of Forces', 'Centripetal Forcing', 'Force of Gravity', 'Inertial Force','Wing Angle (Radians)','FontSize', 14)



