% synchronised_acquisition.m
clear
clc
close all

% === Configuration ===
rate = 1000;                    % Hz, force trandsucer measurement rate
esp32_port = "COM3";            
esp32_baud = 115200;
acquisition_time = 5;          % seconds
t0 = tic;

% Create serial objects
esp32 = serialport(esp32_port, esp32_baud);
flush(esp32);

% Create objects for the force sensor
addpath 'Calibration Files/Mini40'
calibration_filepath = "FT52906.cal";
FT_obj = ForceTransducer(rate, 10, calibration_filepath, 0);
FT_obj.start_background_acquisition(); % your object must support this

% Regex for ESP32
pattern = "Frequency: ([\d\.\-eE]+) \| Pos: (-?\d+) \| Speed: ([\d\.\-eE]+) \| Filtered Speed: ([\d\.\-eE]+) \| PWM: (\d+).*?\|\| Vbat: ([\d\.\-eE]+) V \| I: ([\d\.\-eE]+) mA";

% ESP32 data buffers
esp_t = [];
freq = [];
pos = [];
speed = [];
filtered_speed = [];
pwm = [];
voltage = [];
current = [];

disp("Starting synchronized acquisition...");

while toc(t0) < acquisition_time
    % Read from ESP32
    if esp32.NumBytesAvailable > 0
        line = readline(esp32);
        t = toc(t0);
        tokens = regexp(line, pattern, 'tokens');
        if ~isempty(tokens)
            vals = tokens{1};
            esp_t(end+1) = t;
            freq(end+1) = str2double(vals{1});
            pos(end+1) = str2double(vals{2});
            speed(end+1) = str2double(vals{3});
            filtered_speed(end+1) = str2double(vals{4});
            pwm(end+1) = str2double(vals{5});
            voltage(end+1) = str2double(vals{6});
            current(end+1) = str2double(vals{7});
        end
    end
    
    pause(0.001); % prevents CPU overload
end

disp("End of acquisition.");

% Retrieve data from force sensor
FT_data = FT_obj.stop_and_get_data();  % you must have this method
FT_time = FT_data(:,1) - FT_data(1,1); % if the first column is time

% Save combined CSV (if needed)
T_esp = table(esp_t', freq', pos', speed', filtered_speed', pwm', voltage', current', ...
    'VariableNames', {'Temps_s', 'Frequency', 'Position', 'Speed', ...
    'FilteredSpeed', 'PWM', 'Voltage', 'Current'});
writetable(T_esp, 'esp32_data.csv');

T_force = array2table(FT_data, 'VariableNames', ...
    {'Temps_s', 'Fx', 'Fy', 'Fz', 'Tx', 'Ty', 'Tz'});
writetable(T_force, 'force_data.csv');

% Close serial port
clear esp32

% Plot comparison
figure;
subplot(2,1,1)
plot(esp_t, filtered_speed, 'r');
ylabel('Filtered Speed (tr/s)');
title('ESP32');

subplot(2,1,2)
plot(FT_time, FT_data(:,2:4));
legend('Fx', 'Fy', 'Fz');
ylabel('Force (N)');
xlabel('Time (s)');
title('Force Measurements');
