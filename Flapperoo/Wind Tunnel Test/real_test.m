clear
close all
% This program runs the motor and collects data from the force transducer
% for a single benchtop test.

% Load Cell: ATI Gamma IP65
% DAQ: NI USB-6341
% DMC: Galil DMC-4143
% Motor: VEXTA PH266-E1.2 stepper motor

% Modified by: Ronan Gissler November 2022
% Original by: Cameron Urban July 2022

%% Initalize the experiment
clc;
clear variables;
close all;

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% Parameter Space - What variable ranges are you testing?
% AoA = -14:2:14;
AoA = 0;
% freq = [2, 3, 3.5, 4, 4.5, 5];
freq = [2, 3, 3.5, 4, 4.5, 5];
speed = 3;
wing_type = "elastosil";

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "real_test_commented.dmc";
microsteps = 256; % fixed parameter of AMP-43547
steps_per_rev = 200; % fixed parameter of PH266-E1.2
rev_ticks = microsteps*steps_per_rev; % ticks per rev
vel = 0*rev_ticks; % ticks / sec -> calculated each trial
acc = 3*rev_ticks; % ticks / sec^2
measure_revs = 180; % we want 180 wingbeats of data
padding_revs = 1; % dropped from front and back during data processing
wait_time = 4000; % 4 seconds (data collected before and after flapping)
distance = -1; % ticks to travel this trial -> calculated each trial

% Force Transducer Parameters
rate = 6000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = -1; % Measurement Time -> calculated each trial
force_limit = 1200; % Newton
torque_limit = 79; % Newton*meters

for i = 1:length(freq)
disp("Now running trial with " + freq(i) + " Hz, at " + AoA + "deg  AoA");

% Set trial specfic case name and wingbeat frequency
case_name = AoA + "deg_" + speed + "ms_" + freq(i) + "Hz_" + wing_type;
vel = freq(i)*rev_ticks; % ticks / sec

% Move MPS to correct angle of attack
% Pitch_To(AoA);
% pause(2);

if(vel > 0)
% estimate recording length based on parameters
estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time};
[distance, session_duration, trigger_pos] = estimate_duration(estimate_params{:});

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

else
% set session_duration for stationary test
session_duration = 30;
end

%% Get offset data before flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets_before = FT_obj.get_force_offsets(case_name + "_before", rate, offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

disp("Initial offset data has been gathered");
beep2;

%% Set up the DAQ
if (vel > 0)
% Command the galil to execute the program
galil.command("XQ");
end

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
if (vel > 0)
delete(galil);
end

%% Display preliminary data
FT_obj.plot_results(results, case_name);

drift = offsets_after - offsets_before;
disp("Over the course of the experiment, the force transducer drifted ");
disp('     F_x       F_y       F_z       M_x       M_y       M_z');
disp(drift);

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

% Wait for user input before continuing
txt = "";
while (~ strcmp(txt, "Y"))
    txt = input("Continue? Y or N:   ","s");
    pause(1);
    if (strcmp(txt, "N"))
        return;
    end
end
close all
end