voltage = 5;

% Create DAq session and set its aquisition rate (Hz).
this_DAQ = daq("ni");
this_DAQ.Rate = rate;
daq_ID = "Dev2";
% Don't know your DAQ ID, type "daq.getDevices().ID" into the
% command window to see what devices are currently connected to
% your computer

% Add the input channels.
ch0 = this_DAQ.addinput(daq_ID, 0, "Voltage");
ch1 = this_DAQ.addinput(daq_ID, 1, "Voltage");
ch2 = this_DAQ.addinput(daq_ID, 2, "Voltage");
ch3 = this_DAQ.addinput(daq_ID, 3, "Voltage");
ch4 = this_DAQ.addinput(daq_ID, 4, "Voltage");
ch5 = this_DAQ.addinput(daq_ID, 5, "Voltage");

% Set the voltage range of the channels
ch0.Range = [-voltage, voltage];
ch1.Range = [-voltage, voltage];
ch2.Range = [-voltage, voltage];
ch3.Range = [-voltage, voltage];
ch4.Range = [-voltage, voltage];
ch5.Range = [-voltage, voltage];

% Start the DAq session.
start(obj.daq, "Duration", session_duration);

% Read the data from this DAq session.
raw_data = read(obj.daq, seconds(session_duration));

raw_data_table = timetable2table(raw_data);

raw_data_table_times = raw_data_table(:, 1);
raw_data_table_volt_vals = raw_data_table(:, 2:7);

raw_times = seconds(table2array(raw_data_table_times));
raw_volt_vals = table2array(raw_data_table_volt_vals);

results = [raw_times raw_volt_vals];

% Write the experiment data to a .csv file.
trial_name = strjoin(["experiment", datestr(now, "mmddyy")], "_");
trial_file_name = trial_name + ".csv";
writematrix(results, trial_file_name);

% Flush data from DAQ buffer and stops background operations
stop(obj.daq);
flush(obj.daq);