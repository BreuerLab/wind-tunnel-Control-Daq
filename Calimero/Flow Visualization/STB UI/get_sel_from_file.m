function available_selections = get_sel_from_file(files)
    available_selections = cell(length(files),3);

    for i = 1:length(files)
        name = files(i).name;
        name = extractBefore(name, "_phase_avg");

        if ~contains(name, "Hz") % body or ring only case
            continue
        end
        
        [amp, type, freq] = parse_name(name);

        % Add to list of amplitudes and frequencies
        available_selections{i,1} = type;
        available_selections{i,2} = amp;
        available_selections{i,3} = freq;
    end

    % Deletes rows where all elements are 0 - body/ring case
    % available_selections(~any(available_selections, 2), :) = [];
    available_selections(all(cellfun(@isempty, available_selections), 2), :) = [];
end