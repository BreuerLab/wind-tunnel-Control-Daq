function VFD = VFD_initialize
%% Initialize the VFD
%
% Kenny Breuer May 2022

SIMULATE = 0;

if SIMULATE
    VFD.Handle = 0;
    VFD.ServerID = 0;
    VFD.MaxRPM = 500;
    disp('Running simulated VFD  - edit VFD_initialize to change');
else
    
    % Catch the error and return -1 if the VFD is not online
    try
        VFD.Handle = modbus('tcpip', '192.168.1.1', 'Timeout', 3);
        VFD.Handle.Timeout = 3;
        VFD.ServerID = 1;
        
        % set the acceleration/decelerations to 20 seconds (from zero to max speed) 
        % There is a factor of ten in the parameter 
        write(VFD.Handle,'holdingregs', 2202, 200, 'uint16');
        write(VFD.Handle,'holdingregs', 2203, 200, 'uint16');
        
        % This is an alternate set of accelerations 
        % write(VFD.Handle,'holdingregs', 2204, 200, 'uint16');
        % write(VFD.Handle,'holdingregs', 2205, 200, 'uint16');

        % Specific variables
        VFD.MaxRPM = 500;

    catch
        beep; pause(0.5); beep;
        disp('MODBUS not responding - TIMEOUT')
        disp('**  Is the VFD switched on? **')
        VFD.Handle = -1;
        VFD.ServerID = -1;
    end
end

return;
