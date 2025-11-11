classdef daq_async_test < handle
    properties
        data;
        time;
    end

    methods(Static)
        function read_data()
        daq_ID = "Dev4";
        dq = daq("ni");
        
        % channel for voltage measurement
        ch6 = dq.addinput(daq_ID, 22, "Voltage");
        
        % channel for current measurement
        ch7 = dq.addinput(daq_ID, 21, "Voltage");
        
        % channel for Galil encoder measurement
        % ch8 = this_DAQ.addinput(daq_ID, 20, "Voltage");
        ch8 = dq.addinput(daq_ID, "port0/line24", "Digital");
        
        dq.Rate = 4000;                 % 20 kHz
        dq.ScansAvailableFcnCount = 2000; % callback every 1000 scans (0.05 s at 20 kHz)
        % Assign callback (nested function shares variables above)
        dq.ScansAvailableFcn = @(src,evt) processData(src, evt, daq_async_test);
        duration = 2;
        
        start(dq, "Duration", seconds(duration));

        % Wait the requested duration (or you could use wait(dq, timeout) or other logic)
        pause(duration);
        % while dq.Running
        %     pause(0.5)
        %     fprintf("While loop: Scans acquired = %d\n", dq.NumScansAcquired)
        % end
        
        % Stop acquisition and cleanup
        stop(dq);

        function processData(src, evt, obj)
            disp("Saving Data")
            [newData, newTime, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
            
            obj.data = [obj.data; newData];
            obj.time = [obj.time; newTime];

        end
        end
    end
    methods
        function obj = daq_async_test()
            obj.data = [];
            obj.time = [];
        end
    end
end