% This function moves the MPS pitch axis to a commanded position in
% degrees. It waits to return until the MPS has stopped moving.

% Wind Tunnel: AFAM with MPS

% pitch_home.m
% Siyang Hao, Cameron Urban
% 05/04/2022

function pitch_home(target_degrees)

% Allow this function to pause execution.
pause("on");

% Read and save the current state of the MPS pitch axis.
mps_pitch_state = pitch_read;

% Create a structure (motion_struct) with fields (ACC, DEC, and V) that
% hold reasonable values for the motion of the MPS. The units are RPM/s,
% RPM/s, and RPS respectively.
motion_struct.ACC = 1000;
motion_struct.DEC = 1000;
motion_struct.V   = 100;

% Create conversion variables that holds the MPS pitch axis's number of
% counts per degree, and number of steps per count.
counts_per_degree = 29850.74;
steps_per_count = 16;

% Create a variable to hold the offset number steps. This is used to get
% the correct current position 
steps_offset = 52238083;

% Convert the target degrees to counts.
target_counts = target_degrees * counts_per_degree;

% Get the current position of the MPS pitch axis in steps. Then, convert
% this to counts.
current_steps = mps_pitch_state.POS + steps_offset;
current_counts = current_steps / steps_per_count;

% Record the difference in counts between the target and the current state.
motion_struct.P = target_counts - current_counts;

% Command the pitch axis to move.
pitch_move(motion_struct);

% Save the current state, wait 0.1 s, and then save the new state.
last_state = mps_pitch_state;
pause(0.1)
new_state = pitch_read;

% Continue waiting until the new state's positoin and the last state's
% position haven't changed in the last 0.1 s.
while new_state.POS ~= last_state.POS
    pause(0.1);
    last_state = new_state;
    new_state = pitch_read;
end

end