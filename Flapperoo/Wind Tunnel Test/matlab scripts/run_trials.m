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

function run_trials(AoA, freq, speed, wing_type, automatic, debug)

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "real_test_commented.dmc";
microsteps = 256; % fixed parameter of Galil amplifier
steps_per_rev = 200; % fixed parameter of motor
rev_ticks = microsteps*steps_per_rev; % ticks per rev
vel = 0*rev_ticks; % ticks / sec -> calculated each trial
acc = 3*rev_ticks; % ticks / sec^2
measure_revs = 180; % we want 180 wingbeats of data
padding_revs = 1; % dropped from front and back during data processing
wait_time = 3000; % 3 seconds (data collected before and after flapping)
distance = -1; % ticks to travel this trial -> calculated each trial

% Force Transducer Parameters
voltage = 5;
calibration_filepath = "../Force Transducer/Calibration Files/FT43243.cal"; 
rate = 9000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = -1; % Measurement Time -> calculated each trial
force_limit = 1200; % Newton
torque_limit = 79; % Newton*meters

% Remind user of setup procedure
procedure_UI();

if (~debug)
% Connect to the Galil device.
galil = actxserver("galil");
% Set the Galil's address.
galil.address = galil_address;
% Ensure Galil stops motor when the run_trial function completes
% (either on its own or termination by user)
cleanup = onCleanup(@()myCleanupFun(galil));

% Make force transducer object
FT_obj = ForceTransducer(rate, voltage, calibration_filepath, 1);
end

j = 1;
while (j <= length(AoA))

if (~debug)
% Adjust anlge of attack via MPS
Pitch_To(AoA(j));
disp("Pitching to AoA: " + AoA(j))

% Confirm user has stopped wind before recording offset for this AoA
wind_on_off_UI("off");

% Get offset data before flapping at this angle with no wind
offset_name = wing_type + "_" + speed + "m.s_" + AoA(j) + "deg";
offsets = FT_obj.get_force_offsets(offset_name, offset_duration);
offsets = offsets(1,:); % just taking means, no SDs
disp("Offset data at this AoA has been gathered");
beep2;

% Confirm user has resumed wind before recording data
wind_on_off_UI("on");

else
    disp("Running code to be done at beginning of each new AoA.")
end

% Begin looping through each wingbeat frequency
i = 1;
while (i <= length(freq))
disp("Now running trial with " + freq(i) + " Hz, at " + AoA(j) + "deg AoA");

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + speed + "m.s_" + AoA(j) + "deg_" + freq(i) + "Hz";
vel = freq(i)*rev_ticks; % ticks / sec

% estimate recording length based on parameters
estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time};
[distance, session_duration, trigger_pos] = estimate_duration(estimate_params{:});

if (~debug)
%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep(dmc, "accel_placeholder", num2str(acc));
dmc = strrep(dmc, "speed_placeholder", num2str(vel));
dmc = strrep(dmc, "distance_placeholder", num2str(distance));
dmc = strrep(dmc, "wait_time_placeholder", num2str(wait_time - 2000));
dmc = strrep(dmc, "wait_ticks_placeholder", num2str(trigger_pos));
% added extra 3 seconds in galil waiting time as seen above to account
% for extra time spent executing operations

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

% Get offset data before flapping at this angle and windspeed
offsets_before = FT_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs
disp("Initial offset data has been gathered");
beep2;

% Command the galil to execute the program
galil.command("XQ");

% Collect experiment data during flapping
results = FT_obj.measure_force(case_name, session_duration, offsets);
disp("Experiment data has been gathered");
beep2; 

% Get offset data after flapping at this angle and windspeed
offsets_after = FT_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs
disp("Final offset data has been gathered");
beep2;

% Display preliminary data
drift = offsets_after - offsets_before;
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

if (i < length(freq) && ~automatic)
    i = handle_next_trial(i, length(freq));
end

% Save wind tunnel struct variable so that we know the air properties
% for this trial
trial_name = strjoin([case_name, "wind_tunnel", datestr(now, "mmddyy")], "_");
trial_file_name = "data\wind tunnel data\" + trial_name;
struct_file_name = trial_file_name + ".mat";
struct_file_name = "'" + struct_file_name + "'";
evalin('base',"save(" + struct_file_name + ", 'AFAM_Tunnel');");

% Take a screenshot of the wind tunnel GUI so that we can also see the
% history of the temperature and speed. This takes a screenshot of the
% top right corner of the horizontal wind tunnel monitor.
screenshot(trial_file_name + ".jpg")

i = i + 1;
end

if (j < length(AoA) && ~automatic)
    j = handle_next_AoA(j, length(AoA));
end

j = j + 1;
end

if (~debug)
    % Clean up
    delete(cleanup);
    delete(galil);
    delete(FT_obj);
end

end