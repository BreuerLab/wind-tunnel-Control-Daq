clear
close all

% Ronan Gissler March 2023

% --------------  Variable Ranges  -------------
AoA = -14:2:14;
freq = [0,2,3,3.5,4,4.5,5];
speed = [0,2,4];
wing_length = 0.257; % meters
amp = wing_length*(sind(45) + sind(15)); % amplitude, meters
num_wingbeats = 180;

% -------- Find all combinations of these variable ranges -------
num_combinations = length(speed) * length(AoA) * length(freq);
AoA_vals = zeros(num_combinations,1);
freq_vals = zeros(num_combinations,1);
speed_vals = zeros(num_combinations,1);
duration_vals = zeros(num_combinations,1);
strouhal_vals = zeros(num_combinations,1);

for k = 1:length(speed)
    for i = 1:length(freq)
        for j = 1:length(AoA)
            curIndex = (k-1)*length(freq)*length(AoA) + (i-1)*length(AoA) + j;
            AoA_vals(curIndex) = AoA(j);
            freq_vals(curIndex) = freq(i);
            speed_vals(curIndex) = speed(k);
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

% --------------------  Populate table  ---------------------
filename = 'test_matrix.xlsx';

% First clear existing data
empty_arr = zeros(1000,1);
T = table(empty_arr,empty_arr,empty_arr,empty_arr,empty_arr);
writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);

T = table(AoA_vals, freq_vals, speed_vals, duration_vals, strouhal_vals);

writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);