clear
close all

% Ronan Gissler March 2023

% --------------  Variable Ranges  -------------
% AoA = -16:1:16;
AoA = [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16];
freq = [0,0.1,2,2.5,3,3.5,3.75,4,4.5,5];
speed = [0,3,4,5,6];
wing_length = 0.257; % meters
amp = wing_length*(sind(30) + sind(30)); % amplitude, meters
num_wingbeats = 180;
num_wingbeats_slow = 12;

% -------- Find all combinations of these variable ranges -------
num_combinations = length(speed) * length(AoA) * length(freq);
AoA_vals = zeros(num_combinations,1);
freq_vals = zeros(num_combinations,1);
speed_vals = zeros(num_combinations,1);
duration_vals = zeros(num_combinations,1);
strouhal_vals = zeros(num_combinations,1);

curIndex = 1;

% for i = 1:length(freq)
%         for j = 1:length(AoA)
% %             curIndex = (k-1)*length(freq)*length(AoA) + (i-1)*length(AoA) + j;
%             strouhal_vals(curIndex) = 0;
%             AoA_vals(curIndex) = AoA(j);
%             freq_vals(curIndex) = freq(i);
%             speed_vals(curIndex) = 0;
%             if (freq(i) > 0.5)
%                 duration_vals(curIndex) = 30 + (num_wingbeats/freq(i));
%             elseif (freq(i) > 0)
%                 duration_vals(curIndex) = 30 + (num_wingbeats_slow/freq(i));
%             else
%                 duration_vals(curIndex) = 10 + 30;
%             end
% 
%             curIndex = curIndex + 1;
%         end
% end

for k = 1:length(speed)
    for i = 1:length(freq)
        for j = 1:length(AoA)
%             curIndex = (k-1)*length(freq)*length(AoA) + (i-1)*length(AoA) + j;
                
            if (speed(k) > 0)
                strouhal = (freq(i) * amp) / speed(k);
            else
                strouhal = 0;
            end

            % only add values with realistic strouhal numbers
            % and obtainable wind speed and wingbeat freq
            if (speed(k) == 0 || ((strouhal > 0.1 && strouhal < 0.5) && (speed(k) < 6 || freq(i) < 5)))
                strouhal_vals(curIndex) = strouhal;
                AoA_vals(curIndex) = AoA(j);
                freq_vals(curIndex) = freq(i);
                speed_vals(curIndex) = speed(k);
                if (freq(i) > 0.5)
                    duration_vals(curIndex) = 25 + (num_wingbeats/freq(i));
                elseif (freq(i) > 0)
                    duration_vals(curIndex) = 25 + (num_wingbeats_slow/freq(i));
                else
                    duration_vals(curIndex) = 10 + 25;
                end
                
                curIndex = curIndex + 1;
            end
        end
    end
end

% --------------------  Populate table  ---------------------
filename = 'test_matrix.xlsx';

% First clear existing data
empty_arr = zeros(1500,1);
T = table(empty_arr,empty_arr,empty_arr,empty_arr,empty_arr);
writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);

T = table(AoA_vals, freq_vals, speed_vals, duration_vals, strouhal_vals);

writetable(T,filename,'Sheet',1,'Range','A13','AutoFitWidth',false,'WriteVariableNames',false);