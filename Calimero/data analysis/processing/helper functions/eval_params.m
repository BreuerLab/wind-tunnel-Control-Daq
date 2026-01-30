function [speed, wing_type, freq_vals, AoA_vals, amp] = eval_params(params_path)
    files = dir(params_path);
    
    % Find params file with latest timestamp
    latest_time = datetime(0,0,0,0,0,0);
    for i = 3:length(files)
        fileName = files(i).name;
        if contains(fileName, "params")
            time_stamp = extractBefore(extractAfter(fileName,"_params_"), ".");
            time_val = timeStr2num(time_stamp);
            if time_val > latest_time
                latest_time = time_val;
                latest_file = fileName;
            end
        end
    end
    
    vars = {"speed", "wing_type", "freq_vals", "AoA_vals", "amp"};
    load(params_path + fileName, vars{:})
    disp("Loaded " + params_path + fileName)
end