classdef daq_async_test
    properties
        forceVoltage; % 5 or 10 volts
        daq; % National Instruments Data Acquistion Object
    end

    methods
        function read_data()
        daq_ID = "Dev4";
        dq = daq("ni");
        
        % channel for voltage measurement
        ch6 = this_DAQ.addinput(daq_ID, 22, "Voltage");
        
        % channel for current measurement
        ch7 = this_DAQ.addinput(daq_ID, 21, "Voltage");
        
        % channel for Galil encoder measurement
        % ch8 = this_DAQ.addinput(daq_ID, 20, "Voltage");
        ch8 = this_DAQ.addinput(daq_ID, "port0/line24", "Digital");
        
        dq.Rate = 20000;                 % 20 kHz
        dq.ScansAvailableFcnCount = 2000; % callback every 1000 scans (0.05 s at 20 kHz)
        % Assign callback (nested function shares variables above)
        dq.ScansAvailableFcn = @(src,evt) processData(src, evt);
        
        allData = [];
        allTime = [];
        end
    end
end