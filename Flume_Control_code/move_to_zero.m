function move_to_zero
% n_pos is in volts, transitions position  from current to desired
global s last_out pitch_bias

% out = input_conv2(n_pos);
if isempty(s)
    daq_setup_3rigs;
    disp('checking daq')
    find_bias_3rigs
end

s.IsContinuous = false;
% load('C:\Users\Control Systems\Documents\vert_foil\last_out')
% load('C:\Users\Control Systems\Documents\vert_foil\last_out','-ascii')


pprof1=linspace(last_out(1),pitch_bias(1),s.Rate*2)';
hprof1=linspace(last_out(2),0,s.Rate*2)';
pprof2=linspace(last_out(3),pitch_bias(2),s.Rate*2)';
hprof2=linspace(last_out(4),0,s.Rate*2)';
pprof3=linspace(last_out(5),pitch_bias(3),s.Rate*2)';
hprof3=linspace(last_out(6),0,s.Rate*2)';

output_prof = [pprof1 hprof1  pprof2 hprof2 pprof3 hprof3];
s.queueOutputData(output_prof);
s.IsNotifyWhenDataAvailableExceedsAuto=true;
dat = s.startForeground;

last_out=[pprof1(end) hprof1(end) pprof2(end),hprof2(end) pprof3(end),hprof3(end)];
% save('C:\Users\Control Systems\Documents\vert_foil\last_out','last_out');




end