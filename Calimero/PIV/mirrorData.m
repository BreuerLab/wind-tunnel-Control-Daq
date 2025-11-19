function new_data = mirrorData(data, split_idx)
    % x-axis starts positive in arrays and gets smaller moving right
    data_R = data(:, 1:split_idx, :);
    data_R_M = flip(data_R, 2);
    new_data = [data_R_M data_R];
end