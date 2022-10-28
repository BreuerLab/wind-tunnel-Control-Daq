DataPath =  'G:\Shared drives\Gurney Flap\Data\Round3\Dryrun1025_DATA';
cd(DataPath);
load('0_2_results_102522.mat')
%% avg and std reading 
angles = min_alpha:step_alpha:max_alpha;

for i=1:length(angles)
 AOArad = deg2rad(angles(i));
 FT = results{i,1};
 force = FT(:,2:4);
 torque = FT(:,5:7);
 dcm = angle2dcm(0,0,0);%
 F_aero = (dcm*(force'))';
 T_aero = (dcm*(torque'))';
 F_aero_avg(i,1:3) = mean(F_aero);
 F_aero_std(i,1:3) = std(F_aero);
 T_aero_avg(i,1:3) = mean(T_aero);
 T_aero_std(i,1:3) = std(T_aero);
end
for ch =1:3
    figure
    errorbar(angles,F_aero_avg(:,ch),F_aero_std(:,ch))
    figurename = append('componet',num2str(ch));
    title(figurename)
    xlabel('AOA,[deg]')
    ylabel('force[N]')
    figure
    errorbar(angles,T_aero_avg(:,ch),T_aero_std(:,ch))
    figurename = append('componet',num2str(ch));
    title(figurename)
    xlabel('AOA,[deg]')
    ylabel('torque[Nm]')   
end
%% within 1 case, sync
TTL = raw_data{1,3};
figure
FTT = results{i,1};
subplot(2,1,1)
plot(FTT(:,1),FTT(:,2:7))
xlabel('time[s]')
ylabel('force/torque readings,[N]/[Nm]')
subplot(2,1,2)
plot(FTT(:,1),TTL(:,1))
xlabel('time[s]')
ylabel('TTL readings,[V]')
%% noise background 
    SP = FTT(:,4);
    
    Fs=1000;
    f_min = 1;
    
    window =size(SP,1)/50;
    noverlap = round(0.75*window);
    nfft = 2^12;
    %[pxx, f, ave1, rms1 rms2] = kb_spectrum(Fz, f_min, Fs);
    [pxx, f] = pwelch(SP,window,noverlap,nfft,Fs);
%     figure
%     plot(t,Fz)
%     ylabel('Force,N');
%     xlabel('time,[s]');
    
    semilogy(f, pxx,'+-');
    hold on

xlim([0 100])
% ylim([0 2.5])
ylabel('Power [V^2/Hz]');
xlabel('f');