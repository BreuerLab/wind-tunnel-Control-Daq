function move_traverse(mm, step_factor)
global sT
if isempty(sT)
    initialize_traverse
end

pause(0.3);
if nargin < 2
    step_factor = 0;
end

steps = calc_steps_PK264(mm, step_factor);

fprintf(sT, steps);

pause(1); % 1 seconds
end

function steps = calc_steps_PK264(d, step_factor)
% step_PK264 will cause the PK264 motor to move 'd' mm, based on user
% input. The function assumes a lead screw with a 0.100" pitch
% (0.0002500?/step linear movement)

din = d / 10 / 2.54; % d (mm) / 10 (mm/cm) / 2.54 (cm/in)
step_res = 1 / 2^step_factor;
step_div = 0.00025 / step_res; % smallest amount one can move in inches

steps = din / step_div;

steps = steps/2; % strange factor of 2

if steps >= 0
    steps = ['+' num2str(steps)];
else
    steps = num2str(steps);
end
end