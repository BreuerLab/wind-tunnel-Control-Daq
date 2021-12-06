%Alex Koh-Bell, for large sting, move motor, read voltages and output forces, 
%April 18, 2021

% INSTRUCTIONS: 
% 1. 'run section' on 'take in calibration matrices'
% section below, and only do this once for each set of data
% 2. 'run section' on Motor control section to move motor
% 3. 'run section' on Reading Voltages section to read and save
%   Repeat steps 2 and 3 until have gone through all desired angles, and
%   the last 'VoltagesAndAnglesList' that gets saved (filename will have the 
% final angle in counts at the end_ will have all of the voltage data along with 
% the corresponding angle in a list
% This process should be done for both a 'control' run with the wind tunnel
% off, and then an actual run with the wind tunnel on, and voltages from
% the 'control' run should then be subtracted from the actual run voltages,
% and then these adjusted voltages should be run through a separate force
% calculation code.

%% Section 1. Take in calibration matrices, Run at beggining only once
clear all;
close all;
clc;

voltagesAndAngles = [];  %list to be filled in with voltage data and saved
angleCounter = 0;
load('C_march29.mat','C'); %calibration matrix derived for Lift and Pitch

T1 = readtable('C1_inv_A.csv');  % calibration matrices from Aerolab
T2 = readtable('C1_inv_C2_A.csv');
%calibration matrices read from table:
C1_inv = T1{:,:};
C1_inv_C2 = T2{:,:};


%% Section 2. MOTOR CONTROL   up to 450,000
% using Modbus for Kollmorgen motor control system

P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
P.P   = 30000;  % movement in counts
% P.P = 0;


disp('Load Move Commands')
Pitch_Move(P);

disp('Read Commands')
P1 = Pitch_Read;

% STORE ANGLE IN COUNTS HERE
angle = P1.POS

angleCounter = angleCounter + P.P

%% Section 3. READING VOLTAGES

format long   %needed so that voltages aren't rounded off

% Test the strain gage channels
Rate = 1600;
Total_Time = 10;
Npts = Rate*Total_Time;

s = daq("ni");
s.Rate = Rate;
[ch1 id1] = addinput(s, "cDAQ1Mod3", [0 1 2 3], "Bridge");
[ch2 id2] = addinput(s, "cDAQ1Mod4", [0 1 2 3], "Bridge");

% Set the channels for Full bridge and 350 Ohms *** NEED TO CHECK THIS ***
for i = 1:4
    ch1(i).BridgeMode = 'Full';
    ch2(i).BridgeMode = 'Full';
    
    ch1(i).NominalBridgeResistance = 350;
    ch2(i).NominalBridgeResistance = 350;
    
    ch1(i).Name = sprintf('Sting%1d', i);
    ch2(i).Name = sprintf('Sting%1d', i + 4);

end

fprintf('Reading %d seconds at %d Hz\n', Total_Time, Rate);
data = read(s, Npts);
stackedplot(data);
S = [data.Sting1, data.Sting2, data.Sting3, data.Sting4, ...
     data.Sting5, data.Sting6, data.Sting7, data.Sting8];
S_ave = mean(S);
S_std = std(S);

% Taking averages over time period of each signal, combining into Vavgs array

V1 = mean(data.Sting1);
V2 = mean(data.Sting2);
V3 = mean(data.Sting3);
V4 = mean(data.Sting4);
V5 = mean(data.Sting5);
V6 = mean(data.Sting6);
V7 = mean(data.Sting7);
V8 = mean(data.Sting8);

V3 = zeros(length(V3),1);

Vavgs = [V1;V2;V3;V4;V5;V6;V7;V8];

% ignore voltages 4 and 8, only 6 'real' voltages  %can also try ignoring 'S1', with separate 'C'
voltagesRaw = [V1;V2;V3;V5;V6;V7];


% %  adjusting voltage based on 'control'
% load('controlVoltages.mat','voltagesControl');
% voltages = voltagesRaw - voltagesControl;
voltages = voltagesRaw;   %not using 'control' in this version, calculate with control post-experiment


% CALCULATING FORCES: 
% calculating lift and pitch based on SVD regression coefficients
% give 6 voltages, or any number of sets of 6 voltages. 

% voltages = [0.2520  0.5478  0  -0.0002  0.0615  -0.0528]*10^(-3);  %example voltages

calcForces = voltages'*C;
calcLift = calcForces(:,1);   
calcPitch = calcForces(:,2);



% Calculate other forces based on calibration matrix, side force and yaw unreliable likely

% calculating forces from voltages:
Fcalc = (C1_inv*voltages-C1_inv_C2*abs(C1_inv*voltages))';

% converting forces from n1, n2, s1... into Drag, side force, roll...
gageL = 3.85; %inches  distance between gages big sting

%extracting components from calculated force 'Fcalc':
Fn1 = Fcalc(:,1);   %N1 force
Fn2 = Fcalc(:,2);
Fs1 = Fcalc(:,3);   %S1 force
Fs2 = Fcalc(:,4); 
Faf = Fcalc(:,5);   %axial force
Frm = Fcalc(:,6);   %roll moment

%converting calculated values:
% Lift = (-1)*(Fn1+Fn2);          %lift [lbf]
Drag = -Faf;   
Side = (-1)*(Fs1+Fs2);          %side force
% Pitch =  (Fn2-Fn1)*(gageL/2);   %pitch moment  [lbf*inch]
Roll = Frm;                     %roll moment
Yaw = (Fs2-Fs1)*(gageL/2);      %yaw
calculatedLoads = [calcLift, Drag, Side, calcPitch, Roll, Yaw]

if abs(calcLift) > 30
    "Near Lift Limit"
    LiftAerolab = (-1)*(Fn1+Fn2)
    LiftSVD = calcLift
end

if abs(calcPitch) > 60
    "NEAR Pitch limit"
    PitchAerolab = (Fn2-Fn1)*(gageL/2)
    PitchSVD = calcPitch
end
voltages = voltages';
voltAndAngle = [voltages angle angleCounter];
voltagesAndAngles = [voltagesAndAngles; voltAndAngle];

% SAVING DATA   %saves raw voltages, adjusted voltages, and forces (Unadjusted for angle) 
% ForcesAndVoltages = [voltagesRaw; voltages; calculatedLoads];
% filename = 'VoltagesAdjusted.mat';
% save(filename, 'voltages')
% 
% filename2 = 'VoltagesRaw.mat';
% save(filename2, 'voltagesRaw')
angleString = num2str(angle);
filename = ['Voltages'  angleString '.mat'];
save(filename, 'voltages')   %saved filename has 'angle' in counts

filename = ['VoltagesAndAnglesList'  angleString '.mat'];
save(filename, 'voltagesAndAngles')   %saved filename has last 'angle' in counts

%% read a 'control' at the beginning of measurements
%if first run through, uncomment this to save a control: 

% save('controlVoltages', 'voltagesRaw')

%load limits: 40 lbf Lift, 70 lbf-in Pitch