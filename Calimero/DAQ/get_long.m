function var_data_conv = get_long(startIdx, endIdx, galil_data)
    var_data = galil_data(startIdx:endIdx,:);
    
    var_data_conv = zeros(1, size(var_data,2), 'int32');
    for i = 1:size(var_data,2)
        var_data_conv(i) = typecast(uint8(var_data(:,i)), 'int32');
    end

    var_data_conv = double(var_data_conv); % int32 to double
end