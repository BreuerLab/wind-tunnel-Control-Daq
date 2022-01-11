function move_new_pos(n_pos)
% n_pos is in volts, transitions position  from current to desired
global s last_out

% out = input_conv2(n_pos);
if isempty(s)
    daq_setup2;
    disp('checking daq')
end

s.IsContinuous = false;
% load('C:\Users\Control Systems\Documents\vert_foil\last_out')
% load('C:\Users\Control Systems\Documents\vert_foil\last_out','-ascii')


pprof=linspace(last_out(1),n_pos(1),s.Rate*5)';
hprof=linspace(last_out(2),n_pos(2),s.Rate*5)';

s.queueOutputData([pprof hprof]);
s.IsNotifyWhenDataAvailableExceedsAuto=true;
s.startForeground;

last_out=[pprof(end),hprof(end)];
% save('C:\Users\Control Systems\Documents\vert_foil\last_out','last_out');




end