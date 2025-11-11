classdef daq_async_test < handle
    properties
        data;
        time;
        DAQ;
    end

    methods
        function obj = daq_async_test()
            obj.data = [];
            obj.time = [];
            dq = daq("ni");
            obj.DAQ = dq;
        end

        function read_data(obj)
            daq_ID = "Dev4";
            
            % channel for voltage measurement
            ch6 = obj.DAQ.addinput(daq_ID, 22, "Voltage");
            
            % channel for current measurement
            ch7 = obj.DAQ.addinput(daq_ID, 21, "Voltage");
            
            % channel for Galil encoder measurement - low resolution
            ch8 = obj.DAQ.addinput(daq_ID, "port0/line24", "Digital");

            % channel for Galil encoder measurement - high resolution
            obj.DAQ.addinput(daq_ID,"ctr0","EdgeCount")
            
            obj.DAQ.Rate = 20000;
            obj.DAQ.ScansAvailableFcnCount = 2000;
            
            % Pass the object handle (by reference)
            obj.DAQ.ScansAvailableFcn = @(src, evt) processData(src, evt, obj);
            
            duration = 2;
            start(obj.DAQ, "Duration", seconds(duration));
            % pause(duration + 1);
            % stop(obj.DAQ);

            function processData(src, evt, obj)
                [newData, newTime, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
                obj.data = [obj.data; newData];
                obj.time = [obj.time; newTime];
            end
        end
    end
end
