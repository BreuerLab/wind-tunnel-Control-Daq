% This program is used to run the flapperoo wind tunnel tests. From
% this Matlab file, the MPS is commanded to move the robot to
% different angles of attack, the robot motor is commands to different
% flapping frequencies, and the force transducer data is recorded.

% When I ran this experiment I used the following pieces of equipment:
% Load Cell: ATI Gamma IP65
% DAQ: NI USB-6341 'Dev1'
% DMC: Galil DMC-4143 (with AMP-43547)
% Motor: Nanotec SCB5618M4204-B Stepper Motor
% Flapperoo: 1 DOF

% Ronan Gissler June 2023

function run_trials_gravity(AoA, wing_type, automatic, debug)

% Force Transducer Parameters
voltage = 5;
calibration_filepath = "../Force Transducer/Calibration Files/FT43243.cal"; 
rate = 9000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = 5; % Measurement Time
force_limit = 1200; % Newton
torque_limit = 79; % Newton*meters

% Remind user of setup procedure
procedure_UI();

if (~debug)
% Make force transducer object
FT_obj = ForceTransducer(rate, voltage, calibration_filepath, 1);
end

j = 1;
while (j <= length(AoA))

if (~debug)
    Pitch = Pitch_initialize;

    if (automatic)
        Pitch_enable(Pitch);
        disp("MPS Pitch Enabled")
        pause(4)
    else
        % Confirm user has enabled MPS before attempting to change AoA
        MPS_on_off_UI("on");
    end

    % Adjust angle of attack via MPS
    Pitch_To(AoA(j));
    disp("Pitching to AoA: " + AoA(j))

    if (automatic)
        pause(4)
        Pitch_disable(Pitch);
        disp("MPS Pitch Disabled")
    else
        % Confirm user has disabled MPS before attempting to record data
        MPS_on_off_UI("off");
    end

    clear Pitch;

    % Get offset data before flapping at this angle with no wind
    offset_name = wing_type + "_" + AoA(j) + "deg";
    offsets = FT_obj.get_force_offsets(offset_name, offset_duration);
    offsets = offsets(1,:); % just taking means, no SDs
    disp("Offset data at this AoA has been gathered");
    beep2;

    % Confirm user has tared before moving on
    tare_complete();

else
    disp("Running code to be done at beginning of each new AoA.")
end

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + AoA(j) + "deg_";

if (~debug)

% Collect experiment data
results = FT_obj.measure_force(case_name, session_duration, offsets);
disp("Experiment data has been gathered");
beep2; 

% Display preliminary data
drift = 0;
FT_obj.plot_results(results, case_name, drift);

% Reaching torque or force limits?
if (max(abs(results(:,2:4))) > 0.7*force_limit)
    beep3;
    msgbox("Approaching Force Limit!!!","DANGER!","error");
end
if (max(abs(results(:,5:7))) > 0.7*torque_limit)
    beep3;
    msgbox("Approaching Torque Limit!!!","DANGER!","error");
end
end

if (j < length(AoA) && ~automatic)
    j = handle_next_AoA(j, length(AoA));
end

j = j + 1;
end

if (~debug)
    % Clean up
    delete(FT_obj);
end

end