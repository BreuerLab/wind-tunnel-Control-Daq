   % setup daq 
    rate = 1000;
    this_daq = daq("ni");
    this_daq.Rate = rate;
    offset_duration = 5;
    session_duration = 20;
    % Add the input channels.
    this_daq.addinput("Dev1", 0, "Voltage");
    this_daq.addinput("Dev1", 1, "Voltage");
    this_daq.addinput("Dev1", 2, "Voltage");
    this_daq.addinput("Dev1", 3, "Voltage");
    this_daq.addinput("Dev1", 4, "Voltage");
    this_daq.addinput("Dev1", 5, "Voltage");
    this_daq.addinput("Dev1", 6, "Voltage");
    this_daq.addinput("Dev1", 7, "Voltage");
    
    
    % get offset
    these_offsets = get_offsets( rate, offset_duration, []);
    these_offsets = these_offsets(1,:);
    beep;

    uiwait(warndlg("offset done! " + ...
    " Click OK to proceed", "Information"));
    % get readings
    start(this_daq, "Duration", session_duration);
    these_raw_data = read(this_daq, seconds(session_duration));
    %% preprocessing 
 
        
        these_raw_data_table = timetable2table(these_raw_data);
        
        these_raw_data_table_times = these_raw_data_table(:, 1);
        these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
        these_raw_data_table_TTL_vals = these_raw_data_table(:, 8:9);
        
        these_raw_times = seconds(table2array(these_raw_data_table_times));
        these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
        these_raw_TTL_vals = table2array(these_raw_data_table_TTL_vals);
        

    %% post processing 
    load FT39744_cal;
        volt_vals = these_raw_volt_vals(:, 1:6)-ones(session_duration*rate,1)*these_offsets;
        force_vals = (matrixVals * volt_vals')';
figure 
plot(these_raw_times ,force_vals);

legend
xlabel('time,s')
ylabel('N/Nm')
meanlift = mean(force_vals)
stdLift = std(force_vals)
beep;   