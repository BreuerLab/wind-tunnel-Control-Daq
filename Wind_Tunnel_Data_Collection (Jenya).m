%% Section 1. Take in calibration matrices, Run at beginning only once.
clear all;
close all;
clc;

angleCounter = 0;              %start angle at zero
load('C_july21st_LP.mat','C'); %calibration matrix of choice

T1 = readtable('C1_inv_A.csv');  % calibration matrices from Aerolab
T2 = readtable('C1_inv_C2_A.csv');
%calibration matrices read from table:
C1_inv = T1{:,:};
C1_inv_C2 = T2{:,:};


%% Section 2. Collect data from wind tunnel testing

prompt = '# of wind speeds testing? ';
wind_speeds = input(prompt);

prompt = '# of pitch angles testing per speed? ';
pitch_angles = input(prompt);

m = wind_speeds * pitch_angles * 3; %total number of measurments taking


%preallocate matricies for data 
data_to_save = zeros(3, pitch_angles, wind_speeds, 8);
S_ave_4D = zeros(3,pitch_angles,wind_speeds,8); 
S_std_4D = zeros(3,pitch_angles,wind_speeds,8);
S_rms_4D = zeros(3,pitch_angles,wind_speeds,8);

for ws = 1: wind_speeds
    prompt = 'wind speed (m/s) ? ';
    speed = input(prompt);
    
    
    for pa = 1: pitch_angles
        
        P.ACC = 1000;   % rpm/s
        P.DEC = 1000;   % rpm/s
        P.V   = 100;    % rpm
        prompt = 'angle desired (degrees) ? \n ~15º limit! \n ';
        test_angle = input(prompt);
        total_count = test_angle * 29850.74/2; %conversion to count 
        
        P.P = total_count - angleCounter ; %amount of counts to move in order achieve desired angle
        
        disp('Load Move Commands')
        Pitch_Move(P);

        disp('Read Commands')
        P1 = Pitch_Read;

        disp('Load Move Commands')
        Pitch_Move(P);

        disp('Read Commands')
        P1 = Pitch_Read;

        angleCounter = angleCounter + P.P; %update angle counter
        
        %wait till steady (wing not bouncing to proceed)
        prompt = 'ready to collect? ';
        gogo = input(prompt);
        
        
        for it = 1: 3
            format long   %needed so that voltages aren't rounded off

            % Test the strain gage channels
            Rate = 1600;  %can experiment with changing this rate
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
            S_rms = rms(S);
            

            % Taking averages over time period of each signal, combining into Vavgs array

            V1 = mean(data.Sting1);
            V2 = mean(data.Sting2);
            V3 = mean(data.Sting3);
            V4 = mean(data.Sting4);
            V5 = mean(data.Sting5);
            V6 = mean(data.Sting6);
            V7 = mean(data.Sting7);
            V8 = mean(data.Sting8);


            % ignore voltages 4 and 8, only 6 'real' voltages  
            voltagesRaw = [V1;V2;V3;V5;V6;V7];

            voltages = voltagesRaw;   


            % CALCULATING FORCES: 

            calcForces = voltages'*C;
            calcLift   = calcForces(:,1);   
            calcPitch  = calcForces(:,4);
            calcDrag   = calcForces(:,2);

%             % Calculate other forces based on calibration matrix, side force and yaw unreliable likely
%             % calculating forces from voltages:
%             Fcalc = (C1_inv*voltages-C1_inv_C2*abs(C1_inv*voltages))';
% 
%             % converting forces from n1, n2, s1... into Drag, side force, roll...
%             gageL = 3.85; %inches  distance between gages big sting
% 
%             %extracting components from calculated force 'Fcalc':
%             Fn1 = Fcalc(:,1);   %N1 force
%             Fn2 = Fcalc(:,2);
%             Fs1 = Fcalc(:,3);   %S1 force
%             Fs2 = Fcalc(:,4); 
%             Faf = Fcalc(:,5);   %axial force
%             Frm = Fcalc(:,6);   %roll moment
% 
%             %converting calculated values:
%             % Lift = (-1)*(Fn1+Fn2);          %lift [lbf]
%             Drag = -Faf*4.448;                %drag converted to N   
%             Side = (-1)*(Fs1+Fs2) * 4.448;    %side force, converted to N
%             % Pitch =  (Fn2-Fn1)*(gageL/2);   %pitch moment  [lbf*inch]
%             Roll = Frm *0.11 ;                %roll moment, converted to Nm
%             Yaw = (Fs2-Fs1)*(gageL/2)*0.11;   %yaw moment, converted to Nm
            
           
            %checks to see where we are in comparison to sting load limits
            if abs(calcLift) > 177.929   my calibration matrix has it in
                "Past Lift Limit"
                disp(calcLift)
%                 LiftAerolab = (-1)*(Fn1+Fn2)*4.448; % convert to N
%                 LiftSVD = calcLift;
            end

            if abs(calcPitch) > 7.7 
                "Past Pitch limit"
                disp(calcPitch)
%                 PitchAerolab = (Fn2-Fn1)*(gageL/2)*0.11; %convert to Nm
%                 PitchSVD = calcPitch;
            end
             
            if abs(calcDrag) > 53.376
                "Past Drag Limit"
                disp(calcDrag) 
            end
            
            
            
            data_to_save(it,pa,ws,1) = speed;
            data_to_save(it,pa,ws,2) = test_angle;
            data_to_save(it,pa,ws,3:8) = voltagesRaw';
       
            S_ave_4D(it,pa,ws,:) = mean(S);
            S_std_4D(it,pa,ws,:) = std(S);
            S_rms_4D(it,pa,ws,:)= rms(S); 
          
        end
    end
end

%convert data into a nice 2D format

 data_to_save_2D = zeros(m,8);  
 S_std_2D = zeros(m,8);
 S_ave_2D = zeros(m,8);
 S_rms_2D = zeros(m,8);

 ind =1; %set counter to 1 (matlab does not like zero)
 
 for ii = 1:3
     for jj = 1:pa
         for kk = 1:ws
             
             data_2D = squeeze(data_to_save(ii,jj,kk,:)); %removing uneeded dimensions
             data_to_save_2D(ind,:) = data_2D'; %need to transpose
             
             %repeat for other matricies 
             Ss_2D = squeeze(S_std_4D(ii,jj,kk,:));
             Sa_2D = squeeze(S_ave_4D(ii,jj,kk,:));
             Sr_2D = squeeze(S_rms_4D(ii,jj,kk,:));
             
             S_std_2D(ind,:) = Ss_2D';
             S_ave_2D(ind,:) = Sa_2D';
             S_rms_2D(ind,:) = Sr_2D';
       
             ind = ind+1; 
             
         end
     end
 end

 
 
 
 % Save file: MAKE SURE TO CHANGE NAME BEFORE RUNNING AGAIN

filename='Wind_Tunnel_Data_july29th_5.mat';
save(filename); %saves all varibles

%MAKE SURE TO SAVE DENSITY DATA!

       
        






