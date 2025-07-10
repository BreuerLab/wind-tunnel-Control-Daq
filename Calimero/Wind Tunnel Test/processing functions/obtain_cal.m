% **************************************************************** %
% *****************Obtaining a Calibration Matrix***************** %
% **************************************************************** %
% This function parses an ATI .cal calibration file into a matrix in
% Matlab that can be worked with more easily.
% Inputs: calibration_filepath - The path to a .cal file
% Returns: cal_mat - A matlab matrix
function cal_mat = obtain_cal(calibration_filepath)

    % Preallocate space for calibration matrix
    cal_mat = zeros(6,6);

    file_id = fopen(calibration_filepath);
    
    % Get first line from file
    tline = convertCharsToStrings(fgetl(file_id));
    
    % Counter for each measurement axis (6 total: Fx, Fy, Fz, Mx, My, Mz)
    axis_count = 1;
    
    % Loop through each line until reaching the end of the file
    while isstring(tline)
        
        % Lines with "UserAxis Name" have the calibration values
        if contains(tline, "UserAxis Name")
            split_line = split(tline);
            
            % Counter for each calibration value (six values for each axis)
            value_count = 1;
            
            for i = 1:length(split_line)
                % Check if phrase is numeric
                [num, status] = str2num(split_line(i));
                if status
                    % add that calibration value to matrix
                    cal_mat(axis_count, value_count) = num;
                    
                    % move on to the next value
                    value_count = value_count + 1;
                end
            end
            
            % move on to the next measurement axis
            axis_count = axis_count + 1;
        end
        
        % get next line
        tline = convertCharsToStrings(fgetl(file_id));
    end
    
    fclose(file_id);

end