function initialize_traverse()

% Initialize MATLAB session
global sT
sT=serial('COM9'); % Define port
sT.BaudRate=9600; % Define baud rate
sT.Terminator='CR'; % Define terminator - CR = Carriage Return, LF = Line Feed
fopen(sT); % iniate communication with driver
flushinput(sT); % keep things clean

% Initialize comunication and parameters
fprintf(sT, ' '); % Step 1 of startup procedure
fscanf(sT)
fprintf(sT, ''); % Step 2 of startup procedure
% Driver is ready to receive communication

fscanf(sT);

fprintf(sT, 'X')
fscanf(sT)
% Set up driver parameters for motor
fprintf(sT, 'I 400'); % Initial velocity: 20-20000 (Default: 400)
fprintf(sT, 'V 2000'); % Slew velocity: 20-2000 (Default: 3004)
fprintf(sT, 'D 0'); % (Micro)Step resolution (Divide factor): 0-8 (e.g. 0 gives full step, 1 gives half step, so 1/(2^D))
fprintf(sT, 'K 10 10'); % Ramp slope: Accel/Decel 0-255 /0-255 (Default: 10/10)
fprintf(sT, 'B 30 200'); % Jog speed (steps/sec): Slow*30/High*30 0-255/0-255 (Default: 30,200)
% fprintf('T'); % Trip point: Position/Vec. Address +-8388607.99/0-255
%fprintf(''); % Auto power down 
fprintf(sT, 'H 0'); % Auto variable resolution: 0-Fixed Res. Mode, 1-Auto Variable Res. Mode
fprintf(sT, 'Y 10 10'); % Hold/Run current: 0-100/0-100 % max 29 ----- just try diff values to see what works (i think)
% fprintf('l'); % Limit polarity: Invert,Softstop 0-3 --- have to find what
% the limit switches are doing
fprintf(sT, 'Z 0'); % Auto position readout 0/1

fprintf(sT, 'S'); % Save to non-volatile memory (there is a warning not to do this too often)

fscanf(sT) % Winner.

end