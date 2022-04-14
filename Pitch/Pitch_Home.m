function pitch_home(target)
pause('on');
P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
Deg2Con = 29850.74;
P1 = pitch_read;
P.P = target* Deg2Con-(P1.POS+52238083)/16;
pitch_move(P);
pause(5);
end