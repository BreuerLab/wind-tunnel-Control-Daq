function VFD_set_RPM(RPM)
%
% Set the RPM
%
% Kenny Breuer May 2022
%
%

% Put in some error checkking for high RPM:

VFD = VFD_initialize;

if RPM > VFD.MaxRPM
    beep; pause(0.5); beep;
    fprintf('[WARNING:VFD_set_RPM] Are you sure you want to set the RPM to %d? [hit any key to confirm]', round(RPM))
    pause;
end
    
if VFD.ServerID > 0
    % Im not sure where the 16.8 factor comes from, but it works.
    write(VFD.Handle,'holdingregs', 2, round(RPM*16.8), 'uint16');
else
    fprintf('Simulating seting RPM to %d\n', round(RPM))
end

return
