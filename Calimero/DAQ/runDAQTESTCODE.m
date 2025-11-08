clear
close all

durationSeconds = 5;

% Create DAQ and channels - change Dev1/ai0 etc to your device/channels.
daq_ID = "Dev4";
dq = daq("ni");
ch1 = dq.addinput(daq_ID, 1, "Voltage");
ch2 = dq.addinput(daq_ID, 2, "Voltage");
% addinput(dq, "Dev1", "ctr0", "EdgeCount"); % counter channel for OC pulses

% Sampling parameters
dq.Rate = 20000;                 % 20 kHz
dq.ScansAvailableFcnCount = 5000; % callback every 1000 scans (0.05 s at 20 kHz)

% Preallocate/initialize shared variables (parent workspace for the nested fn)
allData = [];    % adjust second dim if you change number of channels
allTime = [];
totalScans = 0;

% For debugging: enable a simple flag to print when callback runs
DEBUG = true;

% Assign callback (nested function shares variables above)
dq.ScansAvailableFcn = @(src,evt) processData(src, evt);

% Start in background so the main function continues and callback runs
start(dq, "Duration", seconds(5));

% Wait the requested duration (or you could use wait(dq, timeout) or other logic)
pause(durationSeconds);
% while dq.Running
%     pause(0.5)
%     fprintf("While loop: Scans acquired = %d\n", dq.NumScansAcquired)
% end

% Stop acquisition and cleanup
stop(dq);

% Return accumulated data
time = allTime;
data = allData;

% ---------------------------------------------------------------------
    function processData(src, evt)
        % Callback: read newly available scans and append to allData/allTime.
        % try
            % nScans = evt.ElementsAvailable;
            % if nScans == 0
            %     return;
            % end
            % Read exactly the available scans (this drains them from the device buffer)
            [newData, newTime, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
            
            % disp(size(data_t))
            plot(newTime, newData)
        %     if isempty(newData)
        %         return;
        %     end
        % 
        %     % Build timestamps (seconds) for these new scans
        %     newTime = (totalScans + (0:(size(newData,1)-1))') / src.Rate;
        % 
            % Append (grow arrays) - for long runs consider matfile or file streaming
            allData = [allData; newData];
            allTime = [allTime; newTime];

        %     % Update total scans consumed
        %     totalScans = totalScans + size(newData,1);
        % 
        %     if DEBUG
        %         fprintf("Callback: got %d scans — total %d\n", size(newData,1), totalScans);
        %     end
        % catch ME
        %     % If an error occurs inside the callback it can silently stop further callbacks.
        %     % Print it so you can see and debug.
        %     warning("Error inside processData callback:\n%s", getReport(ME));
        % end
    end