clear; clc;
% --- CONFIGURATION ---
portName = "COM32";      % Change to your ESP32 port
baudRate = 115200;
timeoutSeconds = 10;
% --- Create serialport object ---
esp32 = serialport(portName, baudRate, "Timeout", timeoutSeconds);
configureTerminator(esp32, "LF");
flush(esp32);
disp("Connected to ESP32 on " + portName);



% --- AUTOMATIC SEQUENCE ---
keepRunning = true;
sentInitialZero = false;
while keepRunning
    % Read incoming messages from ESP32
    if esp32.NumBytesAvailable > 0 &&keepRunning
        line = readline(esp32);
        disp("ESP32: " + line);
        % Detect the message asking to press a key
        if ~sentInitialZero && contains(line, "ESP32 SETUP")
            pause(1);  % Optional delay before responding
            writeline(esp32, '0');
            disp(">> Sent automatic '0' to continue initialization.");
            sentInitialZero = true;
            keepRunning =false;
        end
    end
end
disp("SETUP OK");
pause(1);


writeline(esp32,'123.');
disp("Press P");
pause(10);
writeline(esp32,'0');
pause(1);
writeline(esp32,'z');
pause(5);
% --- Clean up ---
clear esp32;
disp("Automation complete. Serial connection closed.");