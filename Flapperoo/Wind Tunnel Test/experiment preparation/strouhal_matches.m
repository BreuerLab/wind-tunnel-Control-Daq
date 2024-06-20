clear
close all
clc

freq = [0.1,2,2.5,3,3.5,3.75,4,4.5,5];
speed = [3,4,5,6];

ratios = zeros(1,length(freq)*length(speed));

for i = 1:length(freq)
    for j = 1:length(speed)
        ratios((i-1)*length(speed) + j) = freq(i) / speed(j);
    end
end

unique_ratios = unique(ratios);

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