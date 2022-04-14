% ToDo: Document this function.
% This function was adapted from twoDoFPVT_v5.m by Xiaozhou Fan.

% extract_matrix.m
% Cameron Urban
% 04/14/2022

function matrix = extract_matrix(handles, num_points, matrix_name)
    
    matrix = zeros(num_points, 1);
    
    for point_num = 1:num_points
        point_index = point_num - 1;
        array_val = strcat(matrix_name,'[', num2str(point_index), ']=?');
        matrix(point_num) = str2double(handles.command(array_val));
    end

end