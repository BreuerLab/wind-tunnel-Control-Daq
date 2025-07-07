% synchronised_acquisition.m
clear
clc
close all

% === Configuration ===
rate = 1000;                    % Hz pour le capteur de force
esp32_port = "COM3";            % port ESP32
esp32_baud = 115200;
duree_acquisition = 5;          % secondes
t0 = tic;

% Créer objets série
esp32 = serialport(esp32_port, esp32_baud);
flush(esp32);

% Créer objets pour capteur de force
addpath 'Calibration Files/Mini40'
calibration_filepath = "FT52906.cal";
FT_obj = ForceTransducer(rate, 10, calibration_filepath, 0);
FT_obj.start_background_acquisition(); % il faut que ton objet supporte ça

% Regex ESP32
pattern = "Frequency: ([\d\.\-eE]+) \| Pos: (-?\d+) \| Vitesse: ([\d\.\-eE]+) \| Vitesse filtree: ([\d\.\-eE]+) \| PWM: (\d+).*?\|\| Vbat: ([\d\.\-eE]+) V \| I: ([\d\.\-eE]+) mA";

% Buffers ESP32
esp_t = [];
freq = [];
pos = [];
vitesse = [];
vitesse_filtree = [];
pwm = [];
tension = [];
courant = [];

disp("Démarrage acquisition synchronisée...");

while toc(t0) < duree_acquisition
    % Lecture ESP32
    if esp32.NumBytesAvailable > 0
        line = readline(esp32);
        t = toc(t0);
        tokens = regexp(line, pattern, 'tokens');
        if ~isempty(tokens)
            vals = tokens{1};
            esp_t(end+1) = t;
            freq(end+1) = str2double(vals{1});
            pos(end+1) = str2double(vals{2});
            vitesse(end+1) = str2double(vals{3});
            vitesse_filtree(end+1) = str2double(vals{4});
            pwm(end+1) = str2double(vals{5});
            tension(end+1) = str2double(vals{6});
            courant(end+1) = str2double(vals{7});
        end
    end
    
    pause(0.001); % évite surcharge CPU
end

disp("Fin de l'acquisition.");

% Récupération données du capteur de force
FT_data = FT_obj.stop_and_get_data();  % tu dois avoir cette méthode
FT_time = FT_data(:,1) - FT_data(1,1); % si premier champ est le temps

% Sauvegarde CSV combiné (si besoin)
T_esp = table(esp_t', freq', pos', vitesse', vitesse_filtree', pwm', tension', courant', ...
    'VariableNames', {'Temps_s', 'Frequence', 'Position', 'Vitesse', ...
    'VitesseFiltree', 'PWM', 'Tension', 'Courant'});
writetable(T_esp, 'esp32_data.csv');

T_force = array2table(FT_data, 'VariableNames', ...
    {'Temps_s', 'Fx', 'Fy', 'Fz', 'Tx', 'Ty', 'Tz'});
writetable(T_force, 'force_data.csv');

% Fermer port série
clear esp32

% Tracer comparé
figure;
subplot(2,1,1)
plot(esp_t, vitesse_filtree, 'r');
ylabel('Vitesse filtrée (tr/s)');
title('ESP32');

subplot(2,1,2)
plot(FT_time, FT_data(:,2:4));
legend('Fx', 'Fy', 'Fz');
ylabel('Force (N)');
xlabel('Temps (s)');
title('Capteur de force');
