function [ Pitch, Heave, t ] = prof_transition_aoa(f,aoa1,h1,U,On)
%TRANSITION takes in the transition length, and the function parameters to
%transition states
% param = [freq (Hz), p_amp, h_amp (m), A1, B1, C1, D1]  8/27/2014
global chord
rate = 1000;
T1 = 1/f;
T2 = 1/f;
dt = 1/rate;
cycles_trans = 2;
x = [-cycles_trans/2*T1:dt:cycles_trans*T2/2];

[Pitch_initial, Heave_initial] = single_cycle_wallace([f,0,0,90],0,0,1000);
Heave_initial = repmat(Heave_initial,10,1);
Pitch_initial = repmat(Pitch_initial,10,1);
Heave_initial = Heave_initial(1:length(x))';
Pitch_initial = Pitch_initial(1:length(x))';

[~,Pitch_final, Heave_final] = single_cycle_aoa(f*chord/U,aoa1,h1,U);
Heave_final = repmat(Heave_final,10,1);
Pitch_final = repmat(Pitch_final,10,1);
Heave_final = Heave_final(end-length(x)+1:end)';
Pitch_final = Pitch_final(end-length(x)+1:end)';

switch On
    case 0

Heave = ((1-tanh(10*x/cycles_trans/T2))/2).*Heave_initial+(1+tanh(10*x/cycles_trans/T2))/2.*Heave_final;
Pitch = ((1-tanh(10*x/cycles_trans/T2))/2).*Pitch_initial+(1+tanh(10*x/cycles_trans/T2))/2.*Pitch_final;
Pitch = Pitch';
Heave = Heave';
t = x- cycles_trans*T2/2;
    case 1
    Heave = ((1-tanh(10*x/cycles_trans/T2))/2).*Heave_final+(1+tanh(10*x/cycles_trans/T2))/2.*Heave_initial;
    Pitch = ((1-tanh(10*x/cycles_trans/T2))/2).*Pitch_final+(1+tanh(10*x/cycles_trans/T2))/2.*Pitch_initial;
    Pitch = Pitch';
    Heave = Heave';
    t = x- cycles_trans*T2/2;
end

end

