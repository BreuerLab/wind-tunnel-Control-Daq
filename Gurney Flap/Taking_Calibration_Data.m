close all;
clear all;
clc; 

%% Set which measurments you are taking
prompt = '# of hanging postions testing ';
p = input(prompt);

prompt = '# of weights testing ';
w = input(prompt);

m = w * p * 3; %total number of measurments taking

%% Preallocate matricies to put data into
S_ave = zeros(3,w,p,8); %average voltages
S_std = zeros(3,w,p,8); %standard deviation of voltages
S_rms = zeros(3,w,p,8); %root mean square of voltages

Voltages_and_Forces = zeros(3,w,p,16); %average measured voltages and applied loads

%unit vectors in axis direction
u_x = [1 0 0];
u_y = [0 1 0];
u_z = [0 0 1];

g = 9.81; %in m/s^2

%% Run for loop
for ip = 1:p
    
    %get postion that force is being applied at (measurments from end of sting tip)
    prompt = 'position mass applied at (measure from tip)- [X(m) Y(m) Z(m)] \n  x-(outwards from tip) \n y-(left from rearfacing)\n z-(away from tab) \n ';
    coords = input(prompt);
    dist_electrical_center = coords + [0.098425 0 0];  %adjust so calulating moments ab electrical center, also account for angle of sting
    
    %get direction that force is being applied at
    prompt = 'count of mount \n'; 
    count = input(prompt);
    theta = count/29850.74; %(29k counts per degree)
    gamma = 90-theta; 

    direction_nonunit = [-cosd(gamma), 0, -sind(gamma)];
    %for drag measurments: take point on hanging sting, subtract the point
    %the mass is applied at
    
    %make inputed direction into unit vector
    norm_nonunit = norm(direction_nonunit);
    direction_unit = direction_nonunit/norm_nonunit;
    
    for iw = 1:w
        %% Calculate the applied forces and moments for each weight
        prompt ='mass(kg) ';
        mass = input(prompt);
%             mass = mass_wo;
      
        %mass = mass_wo + 0.75 ; %adjust for weight of hangy thing (750g)
        
        AppliedForce = mass * g * direction_unit; %Force vector = magnitude*direction
        Moment = cross(dist_electrical_center, AppliedForce); %M = r x F
    
        %Define know loads/moments (based on calibration coordinate system- from report)
        Flift = AppliedForce(3); %the sign of this one is maybe wrong
        Fdrag =-AppliedForce(1); %this should be negative right?
        Fz    = AppliedForce(2); %this one should maybe be negative?? have to check ab this
        
        %note: pretty unsure about the signs for the above, maybe ask for help w that

        %should I just index these? like Mpitch = Moment(2) etc..
        Mpitch = dot(u_y, Moment); %My
        Mroll  = dot(u_x, Moment); %Mx
        Myaw   = dot(u_z, Moment); %Mz
    
        Forces = [Flift; Fdrag; Fz; Mpitch; Mroll; Myaw;0;0];
        %still need to investigate which of these we do not need to
        %include, because I am pretty sure sting 4 and 8 don't do anything
        
        for it = 1:3
            %% Now collect three trials of volatages per weight, postion pair!
            
            %alex's code
            format long   %needed so that voltages aren't rounded off
    
            %test strain gage channels
            Rate = 1600;
            Total_Time = 10;  %can change time here if more points wanted
    
            Npts = Rate*Total_Time;
    
            s = daq("ni");
            s.Rate = Rate;
            [ch1, id1] = addinput(s, "cDAQ1Mod3", [0 1 2 3], "Bridge"); %wants me to seperate w commas, but idk how that will change
            [ch2, id2] = addinput(s, "cDAQ1Mod4", [0 1 2 3], "Bridge");
    
    
            % Set the channels for Full bridge and 350 Ohms *** NEED TO CHECK THIS
            % Something needs checking??
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
 
            S_ave(it,iw,ip,:) = mean(S);
            S_std(it,iw,ip,:) = std(S);
            S_rms(it,iw,ip,:) = rms(S); %I added a rms, also have to index these because 4D matricies

            V1 = mean(data.Sting1);
            V2 = mean(data.Sting2);
            V3 = mean(data.Sting3);
            V4 = mean(data.Sting4);  %if 4 and 8 are really not in use, I should not include/ condense data?? 
            V5 = mean(data.Sting5);
            V6 = mean(data.Sting6);
            V7 = mean(data.Sting7);
            V8 = mean(data.Sting8);

            Vavgs = [V1;V2;V3;V4;V5;V6;V7;V8];
            
            Vraw = [V1;V2;V3;V5;V6;V7];
    
            %index in forces and voltages
            Voltages_and_Forces(it,iw,ip,1:8) = Vavgs;
            Voltages_and_Forces(it,iw,ip,9:16) = Forces;
            
        end
    end
    %for each position do we want to make a plot of forces vs. voltages ?? 
  
end

%% Put data into the form for processing/viewing- 2D matrix
 %preallocate new matricies
 Voltages_and_Forces_2D = zeros(m,16);  
 S_std_2D = zeros(m,8);
 S_ave_2D = zeros(m,8);
 S_rms_2D = zeros(m,8);

 ind =1; %set counter to 1 (matlab does not like zero)
 
 %Extracting needed data
 for ii = 1:3
     for jj = 1:w
         for kk = 1:p
             
             VFs_2D = squeeze(Voltages_and_Forces(ii,jj,kk,:)); %removing uneeded dimensions
             Voltages_and_Forces_2D(ind,:) = VFs_2D'; %need to transpose
             
             %repeat for other matricies 
             Ss_2D = squeeze(S_std(ii,jj,kk,:));
             Sa_2D = squeeze(S_ave(ii,jj,kk,:));
             Sr_2D = squeeze(S_rms(ii,jj,kk,:));
             
             S_std_2D(ind,:) = Ss_2D';
             S_ave_2D(ind,:) = Sa_2D';
             S_rms_2D(ind,:) = Sr_2D';
             
             ind = ind+1; 
             
         end
     end
 end

        
            


%% Save file: MAKE SURE TO CHANGE NAME BEFORE RUNNING AGAIN

filename='Calibration_Data_july30th.mat';
save(filename);saves all varibles

