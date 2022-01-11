function [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(freq1,pitch1,heave1_per_chord,pitch3,heave3_per_chord,pitch2,heave2_per_chord, phase12,phase13, number_of_cycles,phi)
% Given frequency (Hertz), Pitch amplitude (degrees) and heave amplitude
% pitch1 and heave1 ---shawn
% pitch2 and heave2 --- Wallace
% pitch3 and heave3 --- Gromit
% phi - phase between heave and pitch
% (chords), this function will run 3 rigs for number_of_cycles
time = clock;
freq2 = freq1;
freq3 = freq1;
phase12d = phase12;
phase13d = phase13;
phase12 = phase12*pi/180;
phase13 = phase13*pi/180;
smooth_factor = 90;
if number_of_cycles < 10
    number_of_cycles = 10;
    disp('minimum of 10 cycles for accurate data collection')
end



% phi = 90;
global s last_out run_num flume_hertz Wbias Gbias chord span foil_shape Temperature foil_separation  pos Wall_distance_left Wall_distance_right Number_of_foils pitch_bias fname 

if isempty(s)
    error('Run daq_setup_3rigs')
end
outputSingleScan(s,last_out)
heave3 = heave3_per_chord*chord;
heave1 = heave1_per_chord*chord;
heave2 = heave2_per_chord*chord;
params = [freq1,pitch1,heave1,phase12, phase13,90; %SHawn (first)
        freq1, pitch2,heave2,phase12, phase13,phi; %Wallace (last)
        freq1,pitch3,heave3, phase12, phase13,90]; %Gromit (mid)
new_param = [freq1, pitch2, heave2];
run_num = run_num+1;
last_pos = conv_last_out(last_out);
% Shawn (Foil 1, no load cell) 05/18/2017 (rig 1)
[p_prof1,h_prof1] = single_cycle_shawn([freq1, pitch1, heave1],0,0,s.Rate);
% -(last_out(2)+0.888888888888889)*360/5
[p_prof_trans1,h_prof_trans1] = prof_transition_rig1([freq1, last_pos(1:2)],0,0,[freq1, pitch1, heave1],0,0,s.Rate);
[p_prof_trans2,h_prof_trans2] = prof_transition_rig1([freq1, pitch1, heave1],0,pitch_bias(1),[freq1,0, 0],0,0,s.Rate);
rate = s.Rate;
prof_trans = [p_prof_trans1,h_prof_trans1];
prof_trans2 = [p_prof_trans2,h_prof_trans2];
prof = repmat([p_prof1,h_prof1],number_of_cycles,1);
Prof1 = [prof_trans;prof;prof_trans2];
          

% 
[p_prof2,h_prof2] = single_cycle_gromit([freq3, pitch3, heave3],phase12,0,s.Rate);
% -(last_out(2)+0.888888888888889)*360/5
[p_prof_trans5,h_prof_trans5] = prof_transition_rig3([freq3,last_pos(3:4)],phase12,0,[freq3, pitch3, heave3],phase12,0,s.Rate);
[p_prof_trans6,h_prof_trans6] = prof_transition_rig3([freq3, pitch3, heave3],phase12,0,[freq3,0, 0],phase12,0,s.Rate);
rate = s.Rate;
prof_trans5 = [p_prof_trans5,h_prof_trans5];
prof_trans6 = [p_prof_trans6,h_prof_trans6];
prof2 = repmat([p_prof2,h_prof2],number_of_cycles,1);

Prof2 = [prof_trans5;prof2;prof_trans6];


% Wallace

[p_prof3,h_prof3] = single_cycle_wallace([freq2, pitch2, heave2,phi],phase13,0,s.Rate);
% -(last_out(2)+0.888888888888889)*360/5
[p_prof_trans3,h_prof_trans3] = prof_transition_rig2([freq2,last_pos(5:6)], phase13,0,[freq2, pitch2, heave2,phi],phase13,0,s.Rate);
[p_prof_trans4,h_prof_trans4] = prof_transition_rig2([freq2, pitch2, heave2,phi],phase13,0,[freq2,0, 0,90],phase13,0,s.Rate);
rate = s.Rate;
prof_trans3 = [-p_prof_trans3,h_prof_trans3];
prof_trans4 = [-p_prof_trans4,h_prof_trans4];
prof3 = repmat([-p_prof3,h_prof3],number_of_cycles,1);
Prof3 = [prof_trans3;prof3;prof_trans4];

% Prof(:,2) = 90*ones(numel(Prof(:,2)),1);
Prof_out=input_conv_3rigs([Prof1  Prof2 Prof3],freq1,heave1,heave3, heave2);
% move_new_pos(Prof(1,:));

% figure
% plot(Prof_out)
% x = zeros(numel(Prof_out(:,1)),2);

s.queueOutputData([Prof_out]);
% disp('output queued.  Max voltage:')
% disp(max(abs(Prof_out)))
% prepare(s)
T(1,:) = clock;
[dat,t,T_start] = startForeground(s);
last_out = Prof_out(end,:);
T(2,:) = clock;
outputSingleScan(s,last_out)

%convert raw voltages to useful data
[out] = output_conv_3rigs(dat);
Length = numel(out(:,1))/1000;
flume = 0;

% figure;
% plot(Prof2);
% hold on;
% plot(Prof3+0.05);
%% vectrino section (uncomment here)
% 
% % vector_files = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\');
% % vectrino_files = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\');
% % N_vec = numel(vector_files);
% % N_trino = numel(vectrino_files);
% % tick = 0;
% % while (numel(dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\')) == N_vec)
% %     pause(0.5)
% % %     disp(tick)
% % 
% %     tick = tick +1;
% %     if tick >= 20 
% %         N_vec = N_vec+1;
% %         N_trino = N_trino+1;
% %     end
% % end
% % 
% % while (numel(dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\')) == N_trino)
% %     pause(0.5)
% % %     disp('tick')
% % end
% % 
% % if tick == 20
% %     disp('vector file timeout. Please turn on vector data recording.')
% % end
% % try
% % [flume.Vector(:,1),flume.Vector(:,2),flume.Vector(:,3),flume.Vector(:,4)] = vector_2_mat(T_start,Length);
% % catch
% %     flume.Vector = [ (1:5)' .485*ones(5,1) zeros(5,2)];
% %     disp('erroneous Vector data')
% % end
% % try
% % [flume.Vectrino(:,1),flume.Vectrino(:,2),flume.Vectrino(:,3),flume.Vectrino(:,4)] = vectrino_2_mat(T_start,Length);
% % catch
% %     flume.Vectrino = [];
% %     disp('erroneous Vectrino data')
% % end
% % 
% % avg_vel(1) = abs(trimmean(flume.Vector(:,2),5));%*1.0868;
% % avg_vel(2) = std(flume.Vector(:,2));
% %%
% % avg_vel(1) = 0.466;
% % avg_vel(2) = 0.016;
% [avg_vel(1), avg_vel(2)] = find_latest_vel;
% 
% %append null data for first foil force data
% dat(:,23:28) = zeros(numel(dat(:,1)),6);
% out(:,23:28) = zeros(numel(dat(:,1)),6);
% 
% %define path
% % path_name = ['C:\Users\Control Systems\Documents\vert_foil\Data\',num2str(Number_of_foils),'_foil\large_sweep','\'];
% % path_name = ['C:\Users\Control Systems\Documents\vert_foil\Data\',num2str(Number_of_foils),'_foil','\NEW_DATA\2017\'];
% % path_name = ['C:\Users\Control Systems\Documents\vert_foil\Turbulence Study\foil12_free\'];
% path_name = [fname,'\data\'];
% 
% %Calculate all foil parameters/efficiencies.
% 
% %Shawn
% if pitch1 ~=0 & heave1 ~=0 % Don't save data if foil is not actuated
%    disp('recording foil1') 
% flume.foil1 = calc_single_foil(params(1,:),number_of_cycles,dat(:,[1,2,23:28,13:16]),out(:,[1,2,23:28,13:16]),path_name, avg_vel); 
% end
% 
% %Foil 2 has x and y exchanged to match the experimental setup
% foil2_out = [out(:,[3,4,18]), -out(:,17),out(:,[19:22,13:16])];
% %Gromit
% if heave3 ~=0 & pitch3 ~=0  % Don't save data if foil is not actuated
%     disp('recording foil2')
% flume.foil2 = calc_single_foil(params(3,:),number_of_cycles,dat(:,[3,4,17:22,13:16]),foil2_out,path_name);
% end
% 
% %Wallace
% flume.foil3 = calc_single_foil(params(2,:),number_of_cycles,dat(:,[5,6,7:12,13:16]),out(:,[5,6,7:12,13:16]),path_name, avg_vel);
% flume.data = dat;
% flume.out = out;
% flume.volt_out = Prof_out;
% flume.command = [Prof1 Prof2 Prof3]; 
% flume.run_time = T;
% flume.T_start = T_start;
% 
% % Put all runs without flow or bad vectrino data in separate folder
% % if ~flume.foil3.U_inf || flume.foil3.U_inf_std > .1
% %         path_name = [path_name,'no_flow\'];        
% % end
% % %Check to see if pitch have chenged
% % if abs(flume.foil3.pitch_pos(1)-flume.foil3.pitch_pos(end))*180/pi>3
% %     path_name = [path_name,'questionable\'];
% % end
% if abs(flume.out(1,3)-flume.out(end,3))*180/pi>2
%     path_name = [path_name,'questionable\'];
% %     disp('Pitch is off. Press any key to zero pitch.')
% % %     find_zero_pitch_3rigs;
% end
% %Check directory path
% if ~exist(path_name,'dir')
%     mkdir(path_name)
% end
% f_disp = round(1000*flume.foil3.freq);
% %Create unique file name and save
% % save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(phase12d),'phase12_',num2str(phase13d),'phase13_1.mat');
% 
% save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_1');
% ii =1;
% while exist([path_name save_name '.mat'],'file')
% %     disp(ii)
%     ii = ii+1;
% %         save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(phase12d),'phase12_',num2str(phase13d),'phase13_',num2str(ii),'.mat');
%     save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(ii),'');
% end
% save([path_name save_name '.mat'],'flume');
%    
% 
% % plot data
% % close all
% % plot_single_foil_data(flume)
% % plot_single_foil_data(flume.foil1)
% 
% % if isfield(flume,'foil2')
% % fig1 = figure(1);
% % set(fig1,'Name','Foil 2 Gromit')
% % plot_single_foil_data(flume.foil2)
% % 
% % end
% fig2 = figure(2);
% set(fig2,'Name', 'Foil 3 Wallace (now gromit)')
% plot_single_foil_data(flume.foil3)

% print([path_name save_name],'-dpng')
% savefig([path_name save_name])


% 
% M(:,1) = 1.398;
%     I(1,1) = 6.67e-04;%0.000786;
% 
%     v = out(:,11:14);
%     for ii = 1:4
%         V(ii) = mean(v((abs(v(:,ii)-mean(v(:,ii)))<2*std(v(:,ii))),ii));
%         S(ii) = std(v((abs(v(:,ii)-mean(v(:,ii)))<2*std(v(:,ii))),ii));
%     end
%     fs_vel =sqrt(V(1)^2+V(2)^2+V(3)^2+V(4)^2); %Velocity magnitude
%     fs_std = sqrt(S(1)^2+S(2)^2+S(3)^2+S(4)^2); %Velocity standard deviation
% 
%     smooth_fac = rate/100*4/4;
% 
% 
%     p(:,1) = out(:,1);
%     pv(:,1) = diff([out(1,1);out(:,1)])*rate;
%     pa(:,1) = smooth(diff([out(1,1);smooth(out(:,1),100);out(end,1)],2).*rate^2,smooth_fac);
% 
% 
%     h(:,1) = out(:,2);
%     hv(:,1) = diff([out(1,2);out(:,2)],1).*rate;
%     ha(:,1) = smooth(diff([out(1,2);smooth(out(:,2),50);out(end,2)],2).*rate^2,smooth_fac);
% 
% 
%     Lift(:,1) = out(:,17).*cos(out(:,1))-out(:,18).*sin(out(:,1))-M(:,1)*smooth(ha(:,1),20);%1.11*[0;-smooth(diff(smooth(out(:,1),1000),2)*10000^2,50);0];
%     Drag(:,1) = out(:,17).*sin(out(:,1))+out(:,18).*cos(out(:,1));
%     CL(:,1) = Lift(:,1)/(.5*1000*fs_vel.^2*chord*span);
%     CD(:,1) = Drag(:,1)/(.5*1000*fs_vel.^2*chord*span);
% 
%     Torque(:,1) = smooth(out(:,22),20)+smooth(I(1,1)*pa(:,1),20);
% %     close 
%     figure(1)
%     
%     subplot(3,3,1)
%     hold off
%     % smooth_factor = 1;
%     y= smooth(Lift(:,1),smooth_factor);
%     plot(t(100:end),y(100:end))
%     hold on
%     y= smooth(Drag(:,1),smooth_factor);
%     % y= smooth(Drag,300);
%     plot(t(100:end),y(100:end))
% 
%     % y= smooth(out(1:end,5),smooth_factor);
%     % plot(t(1000:end),y(1000:end))
% 
% 
%     % plot(t,smooth(out(:,ii),300))
%     xlabel('Time (s)')
%     ylabel('Force (N)')
%     legend('Lift','Drag')
%     title('Rig1')
%     grid
%     ylim([-15 15])
%     hold off
%     subplot(3,3,4)
%     % figure(2)
%     hold off
% 
% 
%     % for ii = 6:8
%     y= smooth(Torque(1:end,1),smooth_factor);
%     % y= smooth(Torque(1:end),600);
%     plot(t(100:end),y(100:end))
% 
%     % hold on
%     % plot(t,smooth(out(:,ii),300))
%     % end
%     grid
%     xlabel('Time (s)');
%     ylabel('Torque (N-m)')
%     % legend('X','Y','Z')
%     hold off
%     subplot(3,3,7)
%     % figure(3)
%     [P,h1,h2] = plotyy(t(100:end),h(100:end,1),t(100:end),p(100:end,1)*180/pi);
%     xlabel('Time (s)');
%     ylabel(P(1),'Heave Position (m)')
%     ylabel(P(2),'Pitch Position (degrees)')
%     %%
%     % M = 1.104; %kg carbon fiber ellipse
%     % I = 0.0007; %carbon fiber ellipse
%     M(:,2) = 1.3584;
%     I(1,2) = 0.000764;
% 
%     p(:,2) = out(:,3);
%     pv(:,2) = diff([out(1,3);out(:,3)])*rate;
%     pa(:,2) = smooth(diff([out(1,3);smooth(out(:,3),100);out(end,3)],2).*rate^2,smooth_fac);
% 
% 
%     h(:,2) = out(:,4);
%     hv(:,2) = diff([out(1,4);out(:,4)],1).*rate;
%     ha(:,2) = smooth(diff([out(1,4);smooth(out(:,4),50);out(end,4)],2).*rate^2,smooth_fac);
% 
%     Lift(:,2) = out(:,7).*cos(out(:,3))-out(:,6).*sin(out(:,3))-M(:,2)*smooth(ha(:,2),20);%1.11*[0;-smooth(diff(smooth(out(:,1),1000),2)*10000^2,50);0];
%     Drag(:,2) = out(:,7).*sin(out(:,3))+out(:,6).*cos(out(:,3));
%     CL(:,2) = Lift(:,2)/(.5*1000*fs_vel.^2*chord*span);
%     CD(:,2) = Drag(:,2)/(.5*1000*fs_vel.^2*chord*span);
% 
%     Torque(:,2) = smooth(out(:,12),20)+smooth(I(1,2)*pa(:,2),20);
% 
%     % figure(1)
%     
%     subplot(3,3,2)
%     hold off
% 
%     y= smooth(Lift(:,2),smooth_factor);
%     plot(t(100:end),y(100:end))
%     hold on
%     y= smooth(Drag(:,2),smooth_factor);
%     % y= smooth(Drag,300);
%     plot(t(100:end),y(100:end))
% 
%     % y= smooth(out(1:end,5),smooth_factor);
%     % plot(t(1000:end),y(1000:end))
% 
% 
%     % plot(t,smooth(out(:,ii),300))
%     title('Rig2')
%     xlabel('Time (s)')
%     ylabel('Force (N)')
%     legend('Lift','Drag')
%     ylim([-15 15])
%     grid
%     hold off
%     subplot(3,3,5)
%     % figure(2)
%     hold off
% 
% 
%     % for ii = 6:8
%     y= smooth(Torque(1:end,2),smooth_factor);
%     % y= smooth(Torque(1:end),600);
%     plot(t(100:end),y(100:end))
% 
%     % hold on
%     % plot(t,smooth(out(:,ii),300))
%     % end
%     grid
%     xlabel('Time (s)');
%     ylabel('Torque (N-m)')
%     % legend('X','Y','Z')
%     hold off
%     subplot(3,3,8)
%     % figure(3)
%     [P,h1,h2] = plotyy(t(100:end),h(100:end,2),t(100:end),p(100:end,2)*180/pi);
%     xlabel('Time (s)');
%     ylabel(P(1),'Heave Position (m)')
%     ylabel(P(2),'Pitch Position (degrees)')
% 
%     p(:,3) = out(:,5);
%     pv(:,3) = diff([out(1,5);out(:,5)])*rate;
%     pa(:,3) = smooth(diff([out(1,5);smooth(out(:,5),100);out(end,5)],2).*rate^2,smooth_fac);
% 
% 
%     h(:,3) = out(:,6);
%     hv(:,3) = diff([out(1,6);out(:,6)],1).*rate;
%     ha(:,3) = smooth(diff([out(1,6);smooth(out(:,6),50);out(end,6)],2).*rate^2,smooth_fac);
% 
%     subplot(3,3,9)
%     % figure(3)
%     [P,h1,h2] = plotyy(t(100:end),h(100:end,3),t(100:end),p(100:end,3)*180/pi);
%     xlabel('Time (s)');
%     ylabel(P(1),'Heave Position (m)')
%     ylabel(P(2),'Pitch Position (degrees)')
%     
%     freq = [freq1 freq2 freq3];
%     pitch = [pitch1 pitch2 freq3];
%     heave = [heave1 heave2 heave3];
% 
% %     %for velocity profile
% %     subplot(3,2,6)
% %     plot(smooth(out(:,11),100))
% %     grid on
% %     ylabel('Ux [m/s]')
%     disp(fs_vel)
%     
% %     [cp,eff,eff_p,eff_h] = calc_tandem(out,new_param);
%     d=datevec(date);
%     run_date = date;
%     fname=sprintf('C:\\Users\\Control Systems\\Documents\\vert_foil\\Data\\3rigs\\%02i_%02i\\run_%04i',d(2),d(3),run_num);
%     save(fname,'dat','out','t','freq','heave','pitch','Lift','Drag','Torque','fs_vel','fs_std','CL','CD','time','flume_hertz','rate','Wbias','Gbias','number_of_cycles','chord','span','foil_shape','foil_separation','phase','Temperature','pos','run_date','Wall_distance_left','Wall_distance_right');
% 
