function [p_prof, h_prof, t] = single_cycle_rig3(new_param,phase1,pitch_bias, rate)
% param = [freq (Hz), p_amp (degs), h_amp (m), A1,B1, C1, D1]  8/27/2014
% -Michael
if numel(new_param) == 3
    new_param(4) = 0;
    new_param(5) = 0;
    new_param(6) = 0;
    new_param(7) = 0;
end
if numel(new_param) == 4
    new_param(5) = 0;
    new_param(6) = 0;
    new_param(7) = 0;
    new_param(8) = 0;
end
% global pitch_bias

T = 1/new_param(1);
dt = 1/rate;
t = [0:dt:T];
phase = .001696-.1438*new_param(1)+.04096*new_param(3)+phase1;
% phase = -new_param(1)*0.304+0.0799;
% phase = 0;

p_prof=pitch_bias*ones(length(t),1)+ new_param(2).*sin(2*pi*new_param(1).*t+pi/2+phase)'+new_param(4)*sin(3*2*pi*new_param(1)*t+phase)'+new_param(5)*cos(3*2*pi*new_param(1)*t+phase)';
h_prof=new_param(3).*sin(2*pi*new_param(1).*t+phase1)' +new_param(6)*sin(3*2*pi*new_param(1)*t+phase1)' + new_param(7)*cos(3*2*pi*new_param(1)*t+phase1)';

