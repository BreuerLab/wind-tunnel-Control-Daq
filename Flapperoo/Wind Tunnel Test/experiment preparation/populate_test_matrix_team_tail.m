clear
close all

% Ronan Gissler March 2023

% --------------  Variable Ranges  -------------
AoA = [0];
freq = [0,2,4];
speed = [4];
pitch = [-22.5, -15, -7.5, 0, 7.5, 15, 22.5];
roll = [-7.5, 0, 7.5];
wing_length = 0.257; % meters
amp = wing_length*(sind(45) + sind(15)); % amplitude, meters
num_wingbeats = 180;

% -------- Find all combinations of these variable ranges -------
num_combinations = length(AoA) * length(freq) * length(speed) * length(pitch) * length(roll);
AoA_vals = zeros(num_combinations,1);
freq_vals = zeros(num_combinations,1);
speed_vals = zeros(num_combinations,1);
pitch_vals = zeros(num_combinations,1);
roll_vals = zeros(num_combinations,1);
duration_vals = zeros(num_combinations,1);
strouhal_vals = zeros(num_combinations,1);

for k = 1:length(speed)
    for i = 1:length(freq)
        for j = 1:length(AoA)
            for m=1:length(pitch)
                for n=1:length(roll)
                    curIndex = (k-1)*length(freq)*length(AoA)*length(pitch)*length(roll) ...
                    + (i-1)*length(AoA)*length(pitch)*length(roll) + (j-1)*length(pitch)*length(roll) ...
                    + (m-1)*length(roll) + n;
    
                    AoA_vals(curIndex) = AoA(j);
                    freq_vals(curIndex) = freq(i);
                    speed_vals(curIndex) = speed(k);
                    pitch_vals(curIndex) = pitch(m);
                    roll_vals(curIndex) = roll(n);
                    if (freq(i) > 0)
                        duration_vals(curIndex) = 30 + (num_wingbeats/freq(i));
                    else
                        duration_vals(curIndex) = 10 + 30;
                    end
                    if (speed(k) > 0)
                        strouhal_vals(curIndex) = (freq(i) * amp) / speed(k);
                    end
                end
            end
        end
    end
end

% --------------------  Populate table  ---------------------
filename = 'team_tail_test_matrix.xlsx';

% First clear existing data
empty_arr = zeros(1000,1);
T = table(empty_arr,empty_arr,empty_arr,empty_arr,empty_arr,empty_arr,empty_arr);
writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);

T = table(AoA_vals, freq_vals, speed_vals, pitch_vals, roll_vals, duration_vals, strouhal_vals);

writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);