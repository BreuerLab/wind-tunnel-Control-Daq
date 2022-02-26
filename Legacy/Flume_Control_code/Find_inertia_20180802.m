%flap back and forth
find_bias_3rigs;


flume = run_cycle_3rigs(1,0,0,0,0,0,1,0,0,10,0);

% find mass
x = flume.foil3.heave_acc(1:end-1);
y = -flume.foil3.lift_N;
% h = h*sin(2*pi*f*t)
% ha = h*(2*pi*f)^2*sin(2*pi*f)
% F = M * ha;
% x = lowlow_pass_filtfilt(x);
% y = lowlow_pass_filtfilt(y);
a = polyfit(x,y,1)
% M(1) = a(1)
% M = 2.27;
%%


flume = run_cycle_3rigs(.2,0,0,0,0,0,1,0,0,20,0);



M = 2.1;  

%% rotate 90, flap more

global pitch_bias

V = input_conv_3rigs([0 0 0 0 90 0],0,0,0,0);

old_pb = pitch_bias;
pitch_bias(3) = V(5);

move_to_zero;


flume = run_cycle_3rigs(1,0,0,0,0,0,1,0,0,10,0);

% find mass
x = smooth(flume.foil3.heave_acc(1:end-1),50);
x = lowlow_pass_filtfilt(x);
y = -smooth(flume.foil3.drag_N,50);
y = lowlow_pass_filtfilt(y);
a = polyfit(x,y,1)
% M(2) = a(1);

% cftool

%find moment

pitch_bias = old_pb;

move_to_zero;
%%
find_bias_3rigs;

flume = run_cycle_3rigs(1,0,0,0,0,90,0,0,0,10,0);

x = flume.foil3.pitch_acc(1:end-1);
y = -flume.foil3.torque_Nm;
% x = lowlow_pass_filtfilt(x);
% y = lowlow_pass_filtfilt(y);
b  = polyfit(x,y,1)

