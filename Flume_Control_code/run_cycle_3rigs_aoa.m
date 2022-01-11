function [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_aoa(freq1,aoa,heave2_per_chord, number_of_cycles,U)
% Given frequency (Hertz), Pitch amplitude (degrees) and heave amplitude
% (chords), this function will run 3 rigs for number_of_cycles
pitch1 = 0;
heave1_per_chord = 0;
pitch3 = 0;
heave3_per_chord = 0;
phase12 = 0;
phase13 = 0;
pitch2 = 0;

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

% U = 0.485;

phi = 90;
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

[~,p_prof3,h_prof3] = single_cycle_aoa(freq2*chord/U, aoa, heave2, U);
% -(last_out(2)+0.888888888888889)*360/5
[p_prof_trans3,h_prof_trans3] = prof_transition_aoa(freq2,aoa,heave2,U,0);
[p_prof_trans4,h_prof_trans4] = prof_transition_aoa(freq2,aoa,heave2,U,1);
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
%%
vector_files = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\');
vectrino_files = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\');
N_vec = numel(vector_files);
N_trino = numel(vectrino_files);
tick = 0;
while (numel(dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\')) == N_vec)
    pause(0.5)
%     disp(tick)

    tick = tick +1;
    if tick >= 20 
        N_vec = N_vec+1;
        N_trino = N_trino+1;
    end
end

while (numel(dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\')) == N_trino)
    pause(0.5)
%     disp('tick')
end

if tick == 20
    disp('vector file timeout. Please turn on vector data recording.')
end
try
[flume.Vector(:,1),flume.Vector(:,2),flume.Vector(:,3),flume.Vector(:,4)] = vector_2_mat(T_start,Length);
catch
    flume.Vector = [ (1:5)' .485*ones(5,1) zeros(5,2)];
    disp('erroneous Vector data')
end
try
[flume.Vectrino(:,1),flume.Vectrino(:,2),flume.Vectrino(:,3),flume.Vectrino(:,4)] = vectrino_2_mat(T_start,Length);
catch
    flume.Vectrino = [];
    disp('erroneous Vectrino data')
end

avg_vel(1) = abs(trimmean(flume.Vector(:,2),5));
avg_vel(2) = std(flume.Vector(:,2));



%append null data for first foil force data
dat(:,23:28) = zeros(numel(dat(:,1)),6);
out(:,23:28) = zeros(numel(dat(:,1)),6);

%define path
% path_name = ['C:\Users\Control Systems\Documents\vert_foil\Data\',num2str(Number_of_foils),'_foil\large_sweep','\'];
% path_name = ['C:\Users\Control Systems\Documents\vert_foil\Data\',num2str(Number_of_foils),'_foil','\NEW_DATA\2017\'];
% path_name = ['C:\Users\Control Systems\Documents\vert_foil\Turbulence Study\foil12_free\'];
path_name = [fname,'\data\'];

%Calculate all foil parameters/efficiencies.

%Shawn
if pitch1 ~=0 & heave1 ~=0 % Don't save data if foil is not actuated
   disp('recording foil1') 
flume.foil1 = calc_single_foil(params(1,:),number_of_cycles,dat(:,[1,2,23:28,13:16]),out(:,[1,2,23:28,13:16]),path_name, avg_vel); 
end

%Foil 2 has x and y exchanged to match the experimental setup
foil2_out = [out(:,[3,4,18]), -out(:,17),out(:,[19:22,13:16])];
%Gromit
if heave3 ~=0 & pitch3 ~=0  % Don't save data if foil is not actuated
    disp('recording foil2')
flume.foil2 = calc_single_foil(params(3,:),number_of_cycles,dat(:,[3,4,17:22,13:16]),foil2_out,path_name);
end

%Wallace
flume.foil3 = calc_single_foil(params(2,:),number_of_cycles,dat(:,[5,6,7:12,13:16]),out(:,[5,6,7:12,13:16]),path_name, avg_vel);
flume.data = dat;
flume.out = out;
flume.volt_out = Prof_out;
flume.command = [Prof1 Prof2 Prof3]; 
flume.run_time = T;
flume.T_start = T_start;

% Put all runs without flow or bad vectrino data in separate folder
% if ~flume.foil3.U_inf || flume.foil3.U_inf_std > .1
%         path_name = [path_name,'no_flow\'];        
% end
% %Check to see if pitch have chenged
% if abs(flume.foil3.pitch_pos(1)-flume.foil3.pitch_pos(end))*180/pi>3
%     path_name = [path_name,'questionable\'];
% end
if abs(flume.out(1,3)-flume.out(end,3))*180/pi>2
    path_name = [path_name,'questionable\'];
%     disp('Pitch is off. Press any key to zero pitch.')
% %     find_zero_pitch_3rigs;
end
%Check directory path
if ~exist(path_name,'dir')
    mkdir(path_name)
end
f_disp = round(1000*flume.foil3.freq);
%Create unique file name and save
% save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(phase12d),'phase12_',num2str(phase13d),'phase13_1.mat');

save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_1');
ii =1;
while exist([path_name save_name '.mat'],'file')
%     disp(ii)
    ii = ii+1;
%         save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(phase12d),'phase12_',num2str(phase13d),'phase13_',num2str(ii),'.mat');
    save_name = strcat('flume_3Rigs_',num2str(round(heave2(1)/chord*100)),'Heave_',num2str(round(pitch2(1))),'Pitch_',num2str(f_disp),'f_',num2str(ii),'');
end
save([path_name save_name '.mat'],'flume');
   

% plot data
% close all
% plot_single_foil_data(flume)
% plot_single_foil_data(flume.foil1)

% if isfield(flume,'foil2')
% fig1 = figure(1);
% set(fig1,'Name','Foil 2 Gromit')
% plot_single_foil_data(flume.foil2)
% 
% end
% fig2 = figure(2);
% set(fig2,'Name', 'Foil 3 Wallace')
% plot_single_foil_data(flume.foil3)