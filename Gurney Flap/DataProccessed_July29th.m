clear all;
close all;
clc; 

%load all the data we are going to analyze 
filename = 'July_29th_0ms.xlsx';
data_1 = readmatrix(filename);

filename = 'July_29th_3ms.xlsx';
data_2 = readmatrix(filename);

filename = 'July_29th_4ms.xlsx';
data_3 = readmatrix(filename);

filename = 'July_29th_6ms.xlsx';
data_4 = readmatrix(filename);

%seprate out raw voltages 
voltages_1  = data_1(:,3:8); 
voltages_2  = data_2(:,3:8); 
voltages_3  = data_3(:,3:8); 
voltages_4  = data_4(:,3:8); 


%load calibration matricies of choice

C1 = [-76429.5051128075,-62448.3086538153,0,10579.7542452395,0,0;2165.89374002351,171358.261424953,0,-299.813840961926,0,0;105663.287492413,-263126.666861929,0,-14626.4405711226,0,0;136489.231216569,-291882.148645999,0,-18893.5218311758,0,0;1308.13219993399,-62950.7439862933,0,-181.078199776026,0,0;-15318.0096944581,46789.9311609879,0,2120.39549195147,0,0];
%load('C_july21st_LP.mat','C'); %calibration matrix derived for Lift and Pitch  
C2 = [-105401.758367513,0,5900.97475602969,4743.14461476384,-304.738656512576,1120.57437661593;96293.5075273965,0,908.819655729000,10710.3950247874,105.312542166401,-851.235911957834;1578.44111285261,0,-100238.716329725,-180.218874736193,344.839632759934,-14987.3507775488;-706030.597620443,0,-454296.243268036,117283.524722722,43322.4013190641,-143283.165577023;-29776.2422766921,0,2543.95777324236,-3433.80967422287,-832.490080023640,141.312106299637;-956.237582828947,0,48353.4012335381,280.008999514464,-4383.86849338935,3000.44576931143];
%load('C_july21st_all.mat','C'); 

T1 = readtable('C1_inv_A.csv');  % calibration matrices from Aerolab
T2 = readtable('C1_inv_C2_A.csv');
%calibration matrices read from table:
C1_inv = T1{:,:};
C1_inv_C2 = T2{:,:};


Fcalc1 = (C1_inv*voltages_1' - C1_inv_C2*abs(C1_inv*voltages_1'))';
Fcalc2 = (C1_inv*voltages_2' - C1_inv_C2*abs(C1_inv*voltages_2'))';
Fcalc3 = (C1_inv*voltages_3' - C1_inv_C2*abs(C1_inv*voltages_3'))';
Fcalc4 = (C1_inv*voltages_4' - C1_inv_C2*abs(C1_inv*voltages_4'))';

gageL = 3.85; %inches  distance between gages big sting

%extracting components from calculated force 'Fcalc':
Fn1_1 = Fcalc1(:,1);   %N1 force
Fn2_1 = Fcalc1(:,2);
Fs1_1 = Fcalc1(:,3);   %S1 force
Fs2_1 = Fcalc1(:,4); 
Faf_1 = Fcalc1(:,5);   %axial force
Frm_1 = Fcalc1(:,6);   %roll moment

Lift1  = (-1)*(Fn1_1+Fn2_1)*4.48;          %lift [lbf]
Drag1  = -Faf_1*4.448;                %drag converted to N   
Side1  = (-1)*(Fs1_1+Fs2_1) * 4.448;    %side force, converted to N
Pitch1 =  (Fn2_1-Fn1_1)*(gageL/2)*0.11;   %pitch moment  [lbf*inch]
Roll1  = Frm_1 *0.11 ;                %roll moment, converted to Nm
Yaw1   = (Fs2_1-Fs1_1)*(gageL/2)*0.11;   %yaw moment, converted to Nm

F_aerolab_1 = [Lift1, Drag1, Side1, Pitch1, Roll1, Yaw1];

Fn1_2 = Fcalc2(:,1);   %N1 force
Fn2_2 = Fcalc2(:,2);
Fs1_2 = Fcalc2(:,3);   %S1 force
Fs2_2 = Fcalc2(:,4); 
Faf_2 = Fcalc2(:,5);   %axial force
Frm_2 = Fcalc2(:,6);   %roll moment

Lift2  = (-1)*(Fn1_2+Fn2_2)*4.48;          %lift [lbf]
Drag2  = -Faf_2*4.448;                %drag converted to N   
Side2  = (-1)*(Fs1_2+Fs2_2) * 4.448;    %side force, converted to N
Pitch2 =  (Fn2_2-Fn1_2)*(gageL/2)*0.11;   %pitch moment  [lbf*inch]
Roll2  = Frm_2 *0.11 ;                %roll moment, converted to Nm
Yaw2   = (Fs2_2-Fs1_2)*(gageL/2)*0.11;   %yaw moment, converted to Nm

F_aerolab_2 = [Lift2, Drag2, Side2, Pitch2, Roll2, Yaw2];

Fn1_3 = Fcalc3(:,1);   %N1 force
Fn2_3 = Fcalc3(:,2);
Fs1_3 = Fcalc3(:,3);   %S1 force
Fs2_3 = Fcalc3(:,4); 
Faf_3 = Fcalc3(:,5);   %axial force
Frm_3 = Fcalc3(:,6);   %roll moment

Lift3  = (-1)*(Fn1_3+Fn2_3)*4.48;          %lift [lbf]
Drag3  = -Faf_3*4.448;                %drag converted to N   
Side3  = (-1)*(Fs1_3+Fs2_3) * 4.448;    %side force, converted to N
Pitch3 =  (Fn2_3-Fn1_3)*(gageL/2)*0.11;   %pitch moment  [lbf*inch]
Roll3  = Frm_3 *0.11 ;                %roll moment, converted to Nm
Yaw3   = (Fs2_3-Fs1_3)*(gageL/2)*0.11;   %yaw moment, converted to Nm

F_aerolab_3 = [Lift3, Drag3, Side3, Pitch3, Roll3, Yaw3];


Fn1_4 = Fcalc4(:,1);   %N1 force
Fn2_4 = Fcalc4(:,2);
Fs1_4 = Fcalc4(:,3);   %S1 force
Fs2_4 = Fcalc4(:,4); 
Faf_4 = Fcalc4(:,5);   %axial force
Frm_4 = Fcalc4(:,6);   %roll moment

Lift4  = (-1)*(Fn1_4+Fn2_4)*4.48;          %lift [lbf]
Drag4  = -Faf_4*4.48;                %drag converted to N   
Side4  = (-1)*(Fs1_4+Fs2_4) * 4.448;    %side force, converted to N
Pitch4 =  ((Fn2_4-Fn1_4)*(gageL/2))*0.11;   %pitch moment  [lbf*inch]
Roll4  = Frm_4 *0.11 ;                %roll moment, converted to Nm
Yaw4   = (Fs2_4-Fs1_4)*(gageL/2)*0.11;   %yaw moment, converted to Nm

F_aerolab_4 = [Lift4, Drag4, Side4, Pitch4, Roll4, Yaw4];

F_LP_1  = voltages_1*C1;
F_all_1 = voltages_1*C2;

F_LP_2  = voltages_2*C1;
F_all_2 = voltages_2*C2;

F_LP_3  = voltages_3*C1;
F_all_3 = voltages_3*C2;

F_LP_4  = voltages_4*C1;
F_all_4 = voltages_4*C2;

%% plot aerolab vs. in house calibration
%FOR LIFT
figure
subplot(2,2,1);
plot(F_aerolab_1(:,1), F_LP_1(:,1), '*', F_aerolab_1(:,1), F_all_1(:,1),'*');
xlabel('Aerolab Calculated Force (N)');
ylabel('Lift Force(N)');
legend('LP','All');
title('0 m/s');

subplot(2,2,2);
plot(F_aerolab_2(:,1), F_LP_2(:,1), '*', F_aerolab_2(:,1), F_all_2(:,1),'*');
xlabel('Aerolab Calculated Force (N)');
ylabel('Lift Force(N)');
legend('LP','All');
title('3.15 m/s');

subplot(2,2,3);
plot(F_aerolab_3(:,1), F_LP_3(:,1), '*', F_aerolab_3(:,1), F_all_3(:,1),'*');
xlabel('Aerolab Calculated Force (N)');
ylabel('Lift Force(N)');
legend('LP','All');
title('4.4 m/s');

subplot(2,2,4);
plot(F_aerolab_4(:,1), F_LP_4(:,1), '*', F_aerolab_4(:,1), F_all_4(:,1),'*');
xlabel('Aerolab Calculated Force (N)');
ylabel('Lift Force(N)');
legend('LP','All');
title('6.7 m/s');

%FOR PITCH
figure
subplot(2,2,1);
plot(F_aerolab_1(:,4), F_LP_1(:,4), '*', F_aerolab_1(:,4), F_all_1(:,4),'*');
xlabel('Aerolab Calculated (Nm)');
ylabel('Pitching Moment (Nm)');
legend('LP','All');
title('0 m/s');

subplot(2,2,2);
plot(F_aerolab_2(:,4), F_LP_2(:,4), '*', F_aerolab_2(:,4), F_all_2(:,4),'*');
xlabel('Aerolab Calculated (Nm)');
ylabel('Pitching Moment (Nm)');
legend('LP','All');
title('3.15 m/s');

subplot(2,2,3);
plot(F_aerolab_3(:,4), F_LP_3(:,4), '*', F_aerolab_3(:,4), F_all_3(:,4),'*');
xlabel('Aerolab Calculated (Nm)');
ylabel('Pitching Moment (Nm)');
legend('LP','All');
title('4.4 m/s');

subplot(2,2,4);
plot(F_aerolab_4(:,4), F_LP_4(:,4), '*', F_aerolab_4(:,4), F_all_4(:,4),'*');
xlabel('Aerolab Calculated (Nm)');
ylabel('Pitching Moment (Nm)');
legend('LP','All');
title('6.7 m/s');

%% plot changes in lift and pitch with differnt speeds

figure
subplot(2,1,1);
plot(data_1(:,2),data_1(:,9), '*r', data_2(:,2),data_2(:,9), '*g',...
    data_3(:,2),data_3(:,9), '*b', data_4(:,2),data_4(:,9), '*y' ); 
xlabel('Angle of Attack(degrees)')
ylabel('Lift Force(N)');
legend('0 m/s', '3.15 m/s', '4.4 m/s', '6.7 m/s')

subplot(2,1,2);
plot(data_1(:,2),data_1(:,12), '*r', data_2(:,2),data_2(:,12), '*g',...
    data_3(:,2),data_3(:,12), '*b', data_4(:,2),data_4(:,12), '*y' ); 
xlabel('Angle of Attack(degrees)');
ylabel('Pitching Moment(Nm)');
legend('0 m/s', '3.15 m/s', '4.4 m/s', '6.7 m/s')

%% Plot all forces dependant on angle

figure;
subplot(2,2,1);
plot(data_1(:,2), data_1(:,9), data_1(:,2), data_1(:,10), data_1(:,2), data_1(:,11),...
    data_1(:,2), data_1(:,12),data_1(:,2), data_1(:,13), data_1(:,2), data_1(:,14));
xlabel('Angle of Attack(degrees)');
ylabel('Force-N/Moment-Nm');
legend('Lift', 'Drag', 'Side', 'Pitch', 'Roll', 'Yaw');

subplot(2,2,2);
plot(data_2(:,2), data_2(:,9), data_2(:,2), data_2(:,10), data_2(:,2), data_2(:,11),...
    data_2(:,2), data_2(:,12),data_2(:,2), data_2(:,13), data_2(:,2), data_2(:,14));
xlabel('Angle of Attack(degrees)');
ylabel('Force-N/Moment-Nm');
legend('Lift', 'Drag', 'Side', 'Pitch', 'Roll', 'Yaw');

subplot(2,2,3);
plot(data_3(:,2), data_3(:,9), data_3(:,2), data_3(:,10), data_3(:,2), data_3(:,11),...
    data_3(:,2), data_3(:,12),data_3(:,2), data_3(:,13), data_3(:,2), data_3(:,14));
xlabel('Angle of Attack(degrees)');
ylabel('Force-N/Moment-Nm');
legend('Lift', 'Drag', 'Side', 'Pitch', 'Roll', 'Yaw');

subplot(2,2,4);
plot(data_4(:,2), data_4(:,9), data_4(:,2), data_4(:,10), data_4(:,2), data_4(:,11),...
    data_4(:,2), data_4(:,12),data_4(:,2), data_4(:,13), data_4(:,2), data_4(:,14));
xlabel('Angle of Attack(degrees)');
ylabel('Force-N/Moment-Nm');
legend('Lift', 'Drag', 'Side', 'Pitch', 'Roll', 'Yaw');


%% Calculate and plot lift coefficent

CL_2 = F_LP_2(:,1)/(0.5*998.2*(3.15^2));
CL_3 = F_LP_3(:,1)/(0.5*998.2*(4.4^2));
CL_4 = F_LP_4(:,1)/(0.5*998.2*(6.7^2));

figure
plot(data_2(:,2), CL_2,'-*', data_3(:,2), CL_3, '-*', data_4(:,2), CL_4, '-*');
title('Lift Coefficent vs. Attack Angle');
xlabel('Angle of Attack(degrees)');
ylabel('Coefficent of Lift');
legend('3.15 m/s','4.4 m/s','6.7 m/s');




















