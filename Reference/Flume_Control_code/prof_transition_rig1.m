function [ Pitch, Heave, t ] = prof_transition_rig1(param1, phase1,pitch_bias1,param2,phase2,pitch_bias2,rate)
%TRANSITION takes in the transition length, and the function parameters to
%transition states
% param = [freq (Hz), p_amp, h_amp (m), A1, B1, C1, D1]  8/27/2014

% rate = 1000;
T1 = 1/param1(1);
T2 = 1/param2(1);
dt = 1/rate;
cycles_trans = 2;
x = [-cycles_trans/2*T1:dt:cycles_trans*T2/2];

[Pitch_initial, Heave_initial, t] = single_cycle_rig1(param1,phase1,pitch_bias1,rate);
Heave_initial = repmat(Heave_initial,10,1);
Pitch_initial = repmat(Pitch_initial,10,1);
Heave_initial = Heave_initial(1:length(x))';
Pitch_initial = Pitch_initial(1:length(x))';

[Pitch_final, Heave_final] = single_cycle_rig1(param2,phase2,pitch_bias2, rate);
Heave_final = repmat(Heave_final,10,1);
Pitch_final = repmat(Pitch_final,10,1);
Heave_final = Heave_final(end-length(x)+1:end)';
Pitch_final = Pitch_final(end-length(x)+1:end)';

Heave = ((1-tanh(10*x/cycles_trans/T2))/2).*Heave_initial+(1+tanh(10*x/cycles_trans/T2))/2.*Heave_final;
Pitch = ((1-tanh(10*x/cycles_trans/T2))/2).*Pitch_initial+(1+tanh(10*x/cycles_trans/T2))/2.*Pitch_final;
Pitch = Pitch';
Heave = Heave';
t = x- cycles_trans*T2/2;
end

