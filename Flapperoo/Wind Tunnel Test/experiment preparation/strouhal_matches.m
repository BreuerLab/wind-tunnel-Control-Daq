clear
close all
clc

% Purpose: Given a series of wingbeat frequencies and wind
% speeds, find combinations that result in the same Strouhal
% number. Note the wingbeat amplitude is not necessary since in
% all cases the wingbeat amplitude will be the same.

freq = [0.1,2,2.5,3,3.5,3.75,4,4.5,5];
speed = [3,4,5,6];

% Find all St ratios
ratios = zeros(1,length(freq)*length(speed));
for i = 1:length(freq)
    for j = 1:length(speed)
        ratios((i-1)*length(speed) + j) = freq(i) / speed(j);
    end
end

% Find unique St ratios
unique_ratios = unique(ratios);

% Find duplicate ratios and print those combinations to the
% command window
for k = 1:length(unique_ratios)
    count = 0;
    combos = [];
    for i = 1:length(freq)
        for j = 1:length(speed)
            ratio = freq(i) / speed(j);
            if (unique_ratios(k) == ratio)
                count = count + 1;
                combos(count,1) = freq(i);
                combos(count,2) = speed(j);
            end
        end
    end
    if (count > 1)
        disp("Match!")
        disp(combos)
    end
end