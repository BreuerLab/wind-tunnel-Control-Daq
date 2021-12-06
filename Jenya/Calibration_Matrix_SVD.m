%this code finds a value for C, which can be used as A*C = b, where
% A is 6 voltages, and b is lift and pitch force
%% import csv and xlsx files
clear all;
close all;
clc;


% filename = 'july_calibration_data_VF.xlsx';
 filename = 'july_calibration_data_VF.xlsx';
% filename = 'july_12th_data_2.xlsx';
 %filename = 'july_17th_data.xlsx';

alldata = readmatrix(filename);  %each row of this spreadsheet has 6 voltages and 6 known applied load components

% filename = 'july_calibration_data_std.xlsx';
% std_data = readmatrix(filename);
% 
% filename = 'july_calibration_data_avg.xlsx';
% avg_data = readmatrix(filename);

%% plot standard deviation and average channel values

% %cannot decide between rms and avg (because isn't it okay if they are just averages?
% avgV1 = avg_data(:,1);
% avgV2 = avg_data(:,2);
% avgV3 = avg_data(:,3);
% avgV4 = avg_data(:,4);
% avgV5 = avg_data(:,5);
% avgV6 = avg_data(:,6);
% 
% stdV1 = std_data(:,1);
% stdV2 = std_data(:,2);
% stdV3 = std_data(:,3);
% stdV4 = std_data(:,4);
% stdV5 = std_data(:,5);
% stdV6 = std_data(:,6);

% figure
% errorbar(avgV1, stdV1, '*');
% title('voltage 1 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')
% 
% figure
% errorbar(avgV2, stdV2, '*');
% title('voltage 2 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')
% 
% figure
% errorbar(avgV3, stdV3,'*');
% title('voltage 3 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')
% 
% figure
% errorbar(avgV4, stdV4);
% title('voltage 4 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')
% 
% figure
% errorbar(avgV5, stdV5);
% title('voltage 5 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')
% 
% figure
% errorbar(avgV6, stdV6);
% title('voltage 1 average and standard daviation');
% ylabel('Voltage(uV)')
% xlabel('measurment number')



%% assign variables

%known applied forces data
L = alldata(:,7);  %lift [lbf]
D = alldata(:,8);  %drag
Si = alldata(:,9);  %side force
P = alldata(:,10);  %pitch moment  [lbf*inch]
R = alldata(:,11);   %roll moment
Y = alldata(:,12);  %yaw
appliedLoads = [L, D, Si, P, R, Y];

%voltage readings
N1 = alldata(:,1); %should n1 and n2 be switched, no idea
N2 = alldata(:,2);
S1 = alldata(:,3);
S2 = alldata(:,4);
AF = alldata(:,5);
RM = alldata(:,6);


voltages = [N1, N2, S1, S2, AF, RM];

%% SVD, to solve Ac = b for c where A is voltages and b if known forces

[U,S,V] = svd(voltages, 'econ');

%try setting small eigenvalues to zero, check if smaller error

cLift  = V*inv(S)*U'*L;  %c for all applided loads
cDrag  = V*inv(S)*U'*D;
cSide  = V*inv(S)*U'*Si;
cPitch = V*inv(S)*U'*P;
cRoll  = V*inv(S)*U'*R;
cYaw   = V*inv(S)*U'*Y;   

%maybe try to do this so we have a full size calibration matrix 

C = [cLift, cDrag, cSide, cPitch, cRoll, cYaw];     %now A*C=b where b has six columns(?)
save('C_july30th_LP', 'C')

calcForces = voltages*C;

calcLift   = calcForces(:,1);
calcDrag   = calcForces(:,2);
calcSide   = calcForces(:,3);
calcPitch  = calcForces(:,4);
calcRoll   = calcForces(:,5);
calcYaw    = calcForces(:,6);


%% graph calculated vs applied and error

%Lift
figure
subplot(2,1,1)
plot(calcLift,L, '*')
%plot(calcLift(1:60),L(1:60),'r*',calcLift(61:120),L(61:120),'b*',calcLift(121:180),L(121:180),'g*',calcLift(181:240),L(181:240),'y*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Lift ')
lift_error = zeros(1,length(L));

for iz = 1:length(L)
    if L(iz) > 0
        lift_error(iz) = 0;
    else
        lift_error(iz) = 100*(calcLift(iz)-L(iz))./L(iz);
    end
end

% iz = find(L ~= 0);
subplot(2,1,2)
%plot(L(1:60),lift_error(1:60),'r*',L(61:120),lift_error(61:120),'b*',L(121:180),lift_error(121:180),'g*', L(181:240), lift_error(181:240),'y*')
plot(L, lift_error, '*')
% plot(100*(calcLift(iz)-L(iz))./L(iz), '*')
xlabel('Applied Load')
ylabel('Error [%]')
title('Lift Error')


% Pitch
figure
subplot(2,1,1)
%plot(calcPitch(1:60),P(1:60),'r*',calcPitch(61:120),P(61:120),'b*',calcPitch(121:180),P(121:180),'g*',calcPitch(181:240),P(181:240),'y*')
plot(calcPitch, P, '*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Pitch ')
pitch_error = zeros(1,length(P));
% ip = find(P ~= 0);

for ip = 1:length(P)
    if P(ip) == 0
        pitch_error(ip) = 0;
    else
        pitch_error(ip) = 100*(calcPitch(ip)-P(ip))./P(ip);
    end
end
        
subplot(2,1,2)
plot(P, pitch_error, '*')
%plot(P(1:60),pitch_error(1:60),'r*',P(61:120),pitch_error(61:120),'b*',P(121:180),pitch_error(121:180),'g*', P(181:240), pitch_error(181:240),'y*')
%xlabel('Calculated (N)')
xlabel('Applied Load')
ylabel('Error [%]')
title('Pitch Error')


%Drag
figure
subplot(2,1,1)
plot(calcDrag,D, '*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Drag ')

for id = 1:length(D)
    if D(id) == 0
        drag_error(id) = 0;
    else
        drag_error(id) = 100*(calcDrag(id)-D(id))./D(id);
    end
end
        
%id = find(D ~= 0);
subplot(2,1,2)
plot(D, drag_error, '*')
%plot(100*(calcDrag(id)-D(id))./D(id), '*')
title('Drag Error')
xlabel('Applied Load')
ylabel('Error [%]')

%Side Force
figure
subplot(2,1,1)
plot(calcSide,Si, '*')
%plot(calcSide(1:60),Si(1:60),'r*',calcSide(61:120),Si(61:120),'b*',calcSide(121:180),Si(121:180),'g*', calcSide(181:240),Si(181:240),'y*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Side Force ')
side_error = zeros(1,length(Si));

for isi = 1:length(Si)
    if Si(isi) == 0
        side_error(isi) = 0;
    else
        side_error(isi) = 100*(calcSide(isi)-Si(isi))./Si(isi);
    end
end

% isi = find(Si ~= 0);
% plot(100*(calcSide(isi)- Si(isi))./Si(isi), '*')
subplot(2,1,2)
plot(Si, side_error, '*')
%plot(Si(1:60),side_error(1:60),'r*',Si(61:120),side_error(61:120),'b*',Si(121:180),side_error(121:180),'g*',Si(121:180),side_error(181:240),'y*')
xlabel('Applied Load')
ylabel('Error [%]')
title('Side Force Error')


%Roll
figure
subplot(2,1,1)
plot(calcRoll,R, '*')
%plot(calcRoll(1:60),R(1:60),'r*',calcRoll(61:120),R(61:120),'b*',calcRoll(121:180),R(121:180),'g*', calcRoll(181:240),R(181:240),'y*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Roll ')
roll_error = zeros(1,length(R));

for ir = 1:length(R)
    if R(ir) == 0
        roll_error(ir) = 0;
    else
        roll_error(ir) = 100*(calcRoll(ir)-R(ir))./R(ir);
    end
end
%ir = find(R ~= 0);
subplot(2,1,2)
plot(R, roll_error, '*')
%plot(100*(calcRoll(ir)-R(ir))./R(ir), '*')
%plot(R(1:60),roll_error(1:60),'r*',R(61:120),roll_error(61:120),'b*',R(121:180),roll_error(121:180),'g*',R(121:180),roll_error(181:240),'y*')
xlabel('Applied Load')
ylabel('Error [%]')
title('Roll Error')

%Yaw
figure
subplot(2,1,1)
plot(calcYaw,Y, '*')
%plot(calcYaw(1:60),Y(1:60),'r*',calcYaw(61:120),Y(61:120),'b*',calcYaw(121:180),Y(121:180),'g*', calcYaw(181:240),Y(181:240),'y*')
xlabel('Calculated (N)')
ylabel('Applied (N)')
title('Calculated vs. Applied Yaw ')
yaw_error = zeros(1,length(Y));

for iy = 1:length(Y)
    if Y(iy) > 0
        yaw_error(iy) = 100*(calcYaw(iy)-Y(iy))./Y(iy);
    else
        yaw_error(iy) = 0;
    end
end
% iy = find(Y ~= 0);
subplot(2,1,2)
% plot(100*(calcYaw(iy)-Y(iy))./Y(iy), '*')
plot(Y,yaw_error, '*')
%plot(Y(1:60),yaw_error(1:60),'r*',Y(61:120),yaw_error(61:120),'b*',Y(121:180),yaw_error(121:180),'g*',Y(121:180),yaw_error(181:240),'y*')
xlabel('Applied Load')
ylabel('Error [%]')
title('Yaw Error')


