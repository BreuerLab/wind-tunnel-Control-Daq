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

% Ronan Gissler November 2023

function real_test(AoA, freq, speed, wing_type, debug)

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
wait_time = 4000; % 4 seconds (data collected before and after flapping)
distance = -1; % ticks to travel this trial -> calculated each trial

% Force Transducer Parameters
rate = 9000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = -1; % Measurement Time -> calculated each trial
force_limit = 1200; % Newton
torque_limit = 79; % Newton*meters

% Reminder user of setup procedure
fig = uifigure;
fig.Position = [600 500 440 180];
movegui(fig,'center')
message = ["1. Links should be fully fastened onto threaded rods during robot assembly."...
           "2. Each test should begin with the wings at the bottom of downstroke."...
           "3. Highlight each trial in the excel test matrix after completion."];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);

% Begin looping through each wingbeat frequency
i = 1;
while(i <= length(freq))
disp("Now running trial with " + freq(i) + " Hz, at " + AoA + "deg AoA");

% Set case name and wingbeat frequency for this trial
case_name = AoA + "deg_" + speed + "ms_" + freq(i) + "Hz_" + wing_type;
vel = freq(i)*rev_ticks; % ticks / sec

% Move MPS to correct angle of attack
% Pitch_To(AoA);
% pause(2);

% estimate recording length based on parameters
estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time};
[distance, session_duration, trigger_pos] = estimate_duration(estimate_params{:});

if(~debug)
%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep(dmc, "accel_placeholder", num2str(acc));
dmc = strrep(dmc, "speed_placeholder", num2str(vel));
dmc = strrep(dmc, "distance_placeholder", num2str(distance));
dmc = strrep(dmc, "wait_time_placeholder", num2str(wait_time + 3000));
dmc = strrep(dmc, "wait_ticks_placeholder", num2str(trigger_pos));
% added extra 3 seconds in galil waiting time as seen above to account
% for extra time spent executing operations

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil's address.
galil.address = galil_address;

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

%% Get offset data before flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets_before = FT_obj.get_force_offsets(case_name + "_before", rate, offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

disp("Initial offset data has been gathered");
beep2;

%% Set up the DAQ
% Command the galil to execute the program
galil.command("XQ");

results = FT_obj.measure_force(case_name, rate, session_duration, offsets_before);

disp("Experiment data has been gathered");
beep2; 

%% Get offset data after flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets_after = FT_obj.get_force_offsets(case_name + "_after", rate, offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

disp("Final offset data has been gathered");
beep2;

%% Clean up
delete(galil);

%% Display preliminary data
drift = offsets_after - offsets_before;
FT_obj.plot_results(results, case_name, drift);

disp(max(abs(results(:,2:4))));
disp(max(abs(results(:,5:7))));

% Reaching torque or force limits?
if(max(abs(results(:,2:4))) > 0.7*force_limit)
    beep3;
    msgbox("Approaching Force Limit!!!","DANGER!","error");
end
if (max(abs(results(:,5:7))) > 0.7*torque_limit)
    beep3;
    msgbox("Approaching Torque Limit!!!","DANGER!","error");
end
end

if (i < length(freq))
    i = handle_next_trial(i, length(freq));
end
i = i + 1;
end
cleanup = onCleanup(@()myCleanupFun(debug));
end

function myCleanupFun(debug)
    disp("Cleanup:")
    if (~debug)
        disp("Stopping Motors via Galil")
        galil.command("ST");
        galil.command("MO");
        galil.command("CB 1");
    end
end