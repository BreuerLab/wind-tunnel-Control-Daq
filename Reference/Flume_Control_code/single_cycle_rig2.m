function [p_prof, h_prof, t] = single_cycle_rig2(new_param,phase1,pitch_bias, rate)
% param = [freq (Hz), p_amp (degs), h_amp (m), A1,B1, C1, D1]  8/27/2014
% -Michael
if numel(new_param) == 3
    new_param(4) = 90;
    new_param(5) = 0;
    new_param(6) = 0;
    new_param(7) = 0;
    new_param(8) = 0;
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
phase_h = 0;%   Heave phase
phase_p = .001696-.1438*new_param(1)+.04096*new_param(3)+phase1;
% phase_p = 0;% Pitch phase% phase = -new_param(1)*0.304+0.0799;
% phase = 0;

p_prof=pitch_bias*ones(length(t),1)+ new_param(2).*sin(2*pi*new_param(1).*t+pi*new_param(4)/180+phase_p+0)'+new_param(5)*sin(3*2*pi*new_param(1)*t+phase_p)'+new_param(6)*cos(3*2*pi*new_param(1)*t+phase_p)';
h_prof=new_param(3).*sin(2*pi*new_param(1).*t+phase1+phase_h)' +new_param(7)*sin(3*2*pi*new_param(1)*t+phase1+phase_h)' + new_param(8)*cos(3*2*pi*new_param(1)*t+phase1+phase_h)';

