function [out,output_prof] = move_new_pos_3rigs(position,t)
% n_pos is in volts, transitions position  from current to desired
global s last_out

% out = input_conv2(n_pos);
if isempty(s)
    daq_setup_3rigs;
    disp('checking daq')
    find_bias_3rigs
end
n_pos = input_conv_3rigs(position,0,0,0,0);
s.IsContinuous = false;
% load('C:\Users\Control Systems\Documents\vert_foil\last_out')
% load('C:\Users\Control Systems\Documents\vert_foil\last_out','-ascii')


pprof1=linspace(last_out(1),n_pos(1),s.Rate*t)';
hprof1=linspace(last_out(2),n_pos(2),s.Rate*t)';
pprof2=linspace(last_out(3),n_pos(3),s.Rate*t)';
hprof2=linspace(last_out(4),n_pos(4),s.Rate*t)';
pprof3=linspace(last_out(5),n_pos(5),s.Rate*t)';
hprof3=linspace(last_out(6),n_pos(6),s.Rate*t)';

output_prof = [pprof1 hprof1 pprof2 hprof2 pprof3 hprof3];
s.queueOutputData(output_prof);
s.IsNotifyWhenDataAvailableExceedsAuto=true;
dat = s.startForeground;

last_out=[pprof1(end) hprof1(end) pprof2(end),hprof2(end) pprof3(end),hprof3(end)];
% save('C:\Users\Control Systems\Documents\vert_foil\last_out','last_out');

out = output_conv_3rigs(dat);




end