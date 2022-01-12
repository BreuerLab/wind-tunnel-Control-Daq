freq1 = 1;
pitch1 = 0;
heave1_per_chord = 0;
pitch3 = 0;
heave3_per_chord = 0;
pitch2 = 0;

heave2_per_chord = 1; 
phase12 = 0;
phase13 = 0;
number_of_cycles = 100;
phi = 90;


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
global s last_out pitch_offset1 pitch_offset2 pitch_offset3 run_num flume_hertz Wbias Gbias chord span foil_shape Temperature foil_separation  pos Wall_distance_left Wall_distance_right Number_of_foils pitch_bias fname 

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

Prof3(:,1) = linspace(-30,30,numel(Prof1(:,1)));
% Prof(:,2) = 90*ones(numel(Prof(:,2)),1);
Prof_out=input_conv_3rigs([Prof1  Prof2 Prof3],freq1,heave1,heave2, heave3);
 move_new_pos_3rigs([Prof1(1,:)  Prof2(1,:) Prof3(1,:)],2);

% figure
% plot(Prof_out)
% x = zeros(numel(Prof_out(:,1)),2);

s.queueOutputData([Prof_out]);
disp('output queued.  Max voltage:')
disp(max(abs(Prof_out)))
% prepare(s)
T(1,:) = clock;
[dat,t,T_start] = startForeground(s);
last_out = Prof_out(end,:);
T(2,:) = clock;
outputSingleScan(s,last_out)

%convert raw voltages to useful data
[out] = output_conv_3rigs(dat);
Length = numel(out(:,1))/1000;