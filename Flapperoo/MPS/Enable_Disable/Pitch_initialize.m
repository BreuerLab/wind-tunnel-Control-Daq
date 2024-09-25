function Pitch = Pitch_initialize

% Initialize the Kolmorgen pitch axis

Pitch.ACC_Conversion = 17476.3; % to RPM/sec
Pitch.DEC_Conversion = 17476.3; % to RPM/sec
Pitch.V_Conversion   = 17476.3; % to RPM
Pitch.P_Conversion   = 16.0*29850.74;    % from degress to counts
Pitch.POS_Conversion = 1.0;     % counts

Pitch.ACC_DEFAULT = 1000;       % Default acceleration
Pitch.DEC_DEFAULT = 1000;       % Default deceleration
Pitch.V_DEFAULT   = 100;        % Default top speed

Pitch.AXIS_ADDRESS = '192.168.1.202';

Pitch.Report = 0;  % Verbose mode

Pitch.IOFF = 1; % This seems to be necessary to get the addresses correct

Pitch.Initialized = 1;  % set flag

% Call Pitch_Position to get the current position of the indexer
P0 = Pitch_read_enable(Pitch);

% Set this as the intial position
Pitch.P0 = P0.POS;

return