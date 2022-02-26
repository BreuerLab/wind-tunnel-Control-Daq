function initialize_driver
% intialize MATLAB session
s=serial('COM24'); % Define port
s.BaudRate=9600; % Define baud rate
s.Terminator='CR'; % Define terminator - CR = Carriage Return, LF = Line Feed
fopen(s); % iniate communication with driver
flushinput(s); % keep things clean

fprintf(s, ' '); % Step 1 of startup procedure
fprintf(s, ''); % Step 2 of startup procedure
% Driver is ready to receive communication



end