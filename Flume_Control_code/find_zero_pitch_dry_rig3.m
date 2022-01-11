% function [dat,out,Prof_out] = find_zero_pitch_dry_rig2

time = clock;
freq2 = 1;
heave2_per_chord = 1;
pitch2 = 0;
phase13 = 0;
number_of_cycles = 40;


phi = 90;
global s last_out pitch_offset1 pitch_offset2 pitch_offset3 run_num flume_hertz Wbias Gbias chord span foil_shape Temperature foil_separation new_param pos Wall_distance_left Wall_distance_right Number_of_foils

heave2 = heave2_per_chord*chord;


[p_prof2,h_prof2] = single_cycle_rig3([freq2, pitch2, heave2],phase13,s.Rate);
% -(last_out(2)+0.888888888888889)*360/5
[p_prof_trans3,h_prof_trans3] = prof_transition_rig3([freq2,-(last_out(5)-pitch_offset3)*360/10, -(last_out(6))/.03,90],phase13,[freq2, pitch2, heave2,phi],phase13,s.Rate);
[p_prof_trans4,h_prof_trans4] = prof_transition_rig3([freq2, pitch2, heave2,phi],phase13,[freq2,0, 0,90],phase13,s.Rate);
rate = s.Rate;
prof_trans3 = [p_prof_trans3,h_prof_trans3];
prof_trans4 = [p_prof_trans4,h_prof_trans4];
prof3 = repmat([p_prof2,h_prof2],number_of_cycles,1);
Prof3 = [prof_trans3;prof3;prof_trans4];

Prof1 = zeros(numel(Prof3(:,1)),2);
Prof2 = Prof1;
Prof3(:,1) = linspace(-30,30,numel(Prof1(:,1)));

% Prof(:,2) = 90*ones(numel(Prof(:,2)),1);
Prof_out=input_conv_3rigs([Prof1 Prof2 Prof3],freq2,0,heave2, 0);
% move_new_pos(Prof(1,:));
time = clock;
figure
plot(Prof_out)
%%
move_new_pos_3rigs(Prof_out(1,:));
s.queueOutputData([Prof_out]);
[dat,t] = startForeground(s);
last_out = Prof_out(end,:);



%convert raw voltages to useful data
[out,t] = output_conv_3rigs(dat);





plot(smooth(out(:,18),300));
xlabel('data sample')
ylabel('Y Force (N)')
%%
% Find zero of envelope and set as the pitch bias.
pitch_offset3 = Prof_out(20810,5);
move_new_pos_3rigs(input_conv_3rigs([0 0 0 0 0 0],1,0,0,0));
% Find the index relative to the zero position
global ch5
ch5.ZResetValue = 0;
[dat,something] = move_new_pos_3rigs(input_conv_3rigs([0 0 0 0 130 0],1,0,0,0));
dat(dat(:,1:6)>1e6)=dat(dat(:,1:6)>1e6)-2^32;
figure
plot(dat(:,5));
% Find the y count where the index activates and divide by 4. Set as ZResetValue  
ch5.ZResetValue = 338;
% Confirm Zero is approximately zero counts.
[dat,something] = move_new_pos_3rigs(input_conv_3rigs([0 0 0 0 0 0],1,0,0,0));
dat(dat(:,1:6)>1e6)=dat(dat(:,1:6)>1e6)-2^32;
figure
plot(dat(:,5));

