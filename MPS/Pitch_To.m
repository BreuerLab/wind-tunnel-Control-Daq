function Pitch_To(target)
pause('on');
P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
Deg2Con = 29850.74;
P1 = Pitch_Read;
P.P = target* Deg2Con-(P1.POS+52238083)/16;
Pitch_Move(P);
pause(30);

end