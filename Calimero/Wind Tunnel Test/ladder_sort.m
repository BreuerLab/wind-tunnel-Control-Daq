function sorted_values = ladder_sort(values)
    sorted_values = values;
    for i = 2:2:(length(values)-1)
        sorted_values(i) = values(i+1);
        sorted_values(i+1) = values(i);
    end
end

% -16, -14, -15, -12, -13, -10, -11
% 1, 1+2, 1+1, 1+4, 1+3, 1+6, 1+5
% diff: 2, 1, 3, 1, 3, 1
% i, i+1, i-1, i+1, i-1, i+1, i-1