clearvars -except offsets
close all

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer. 
% Then run the taring function with no mass on the force transducer.
% Then add the mass and run the measure function.
% Taring should be performed before each measurement.
% Author: Ronan Gissler
% Date: 10/30/2022

% Test parameters:
rate = 1000; % measurement rate of NI DAQ, in Hz
tare_duration = 5; % in seconds
session_duration = 1; % in seconds
tare = false;
measure = not(tare); % so that both aren't done simultaneously
output_filename = '1000g_mass.xlsx';

% Load the load cell's calibration matrix into the Matlab workspace
load cal_FT43243_5V;

voltage = 5; % 5 or 10 volts

%%

% **************************************************************** %
% *******************Taring the Force Transducer****************** %
% **************************************************************** %
if tare
    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;

    % Add the input channels.
    ch0 = this_daq.addinput("Dev1", 0, "Voltage");
    ch1 = this_daq.addinput("Dev1", 1, "Voltage");
    ch2 = this_daq.addinput("Dev1", 2, "Voltage");
    ch3 = this_daq.addinput("Dev1", 3, "Voltage");
    ch4 = this_daq.addinput("Dev1", 4, "Voltage");
    ch5 = this_daq.addinput("Dev1", 5, "Voltage");
    ch6 = this_daq.addinput("Dev1", 6, "Voltage");

    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];
    ch6.Range = [-voltage, voltage];

    % Get the offsets for current trial.
    start(this_daq, "Duration", tare_duration);
    [bias_timetable, ~] = read(this_daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    bias_array = table2array(bias_table(:,2:7));
    
    % Preallocate an array to hold the offsets.
    offsets = zeros(2, 6);

    for i = 1:6
        offsets(1, i) = mean(bias_array(:, i));
        offsets(2, i) = std(bias_array(:, i)) / sqrt(rate * tare_duration);
    end
    
    % Clear the DAq object.
    clear this_daq;
    
    save("offsets.mat", 'offsets');
end

%%

% **************************************************************** %
% ***********************Taking Measurements********************** %
% **************************************************************** %
if measure
    % Load offsets from taring
    load offsets

    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;

    % Add the input channels.
    ch0 = this_daq.addinput("Dev1", 0, "Voltage");
    ch1 = this_daq.addinput("Dev1", 1, "Voltage");
    ch2 = this_daq.addinput("Dev1", 2, "Voltage");
    ch3 = this_daq.addinput("Dev1", 3, "Voltage");
    ch4 = this_daq.addinput("Dev1", 4, "Voltage");
    ch5 = this_daq.addinput("Dev1", 5, "Voltage");
    ch6 = this_daq.addinput("Dev1", 6, "Voltage");

    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];
    ch6.Range = [-voltage, voltage];
    
    % Start the DAq session.
    start(this_daq, "Duration", session_duration);

    % Read the data from this DAq session.
    these_raw_data = read(this_daq, seconds(session_duration));

    these_raw_data_table = timetable2table(these_raw_data);

    these_raw_data_table_times = these_raw_data_table(:, 1);
    these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
    these_raw_data_table_trigger_vals = these_raw_data_table(:, 8);

    these_raw_times = seconds(table2array(these_raw_data_table_times));
    these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
    these_raw_trigger_vals = table2array(these_raw_data_table_trigger_vals);

    % Offset the data and multiply by the calibration matrix.
    volt_vals = these_raw_volt_vals(:, 1:6) - offsets(1,:);
    force_vals = cal_matrix * volt_vals';
    force_vals = force_vals';

    % Clear the DAq object.
    clear this_daq;

    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];

    % Create three subplots to show the force time histories. 
    subplot(2, 3, 1);
    plot(these_raw_times, force_vals(:, 1));
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 2);
    plot(these_raw_times, force_vals(:, 2));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 3);
    plot(these_raw_times, force_vals(:, 3));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    subplot(2, 3, 4);
    plot(these_raw_times, force_vals(:, 4));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 5);
    plot(these_raw_times, force_vals(:, 5));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 6);
    plot(these_raw_times, force_vals(:, 6));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    % Label the whole figure.
    sgtitle("Time Series of Loads for benchtop");

    % Save offsets and timestamped force values to excel file
    xlswrite(output_filename,[cat(2, offsets, zeros(2,1)); 
    cat(2,zeros(1,6),zeros (1,1)); 
    cat(2,force_vals,these_raw_times);]) 
end