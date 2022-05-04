% TODO: Document this function.

function pitch_home(target)

pause("on");

P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
Deg2Con = 29850.74;

last_read = pitch_read;

P.P = target * Deg2Con - (last_read.POS + 52238083) / 16;
pitch_move(P);

pause(0.1)
new_read = pitch_read;

while new_read.POS ~= last_read.POS
    pause(0.1);
    last_read = new_read;
    new_read = pitch_read;
end

end