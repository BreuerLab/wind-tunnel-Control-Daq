function [cur_pos, home_pos] = get_home_pos(hall_effect, tick_ctr)
    % Calculate the difference
    d = diff(hall_effect);
    
    % Identify the rising and falling indices
    % We add 1 because diff() makes the array one element shorter, 
    % so the edge actually lands on the next index.
    rising_edges = find(d == 1) + 1;
    falling_edges = find(d == -1) + 1;

    mid_indices = [];
    
    % Match each falling edge to the next rising edge
    for i = 1:length(falling_edges)
        
        current_falling = falling_edges(i);
        
        % Find all rising edges that happen AFTER this falling edge
        valid_rising = rising_edges(rising_edges > current_falling);
        
        % If a subsequent rising edge exists, calculate the midpoint
        if ~isempty(valid_rising)
            
            % Grab the very first rising edge after the drop
            next_rising = valid_rising(1); 
            
            % Calculate the average and round to the nearest integer index
            mid_idx = round((current_falling + next_rising) / 2);
            
            % Store the result
            mid_indices = [mid_indices, mid_idx];
        end
    end

    % the rising edge lines up the magnet with the hall effect sensor
    % home_pos = tick_ctr(mid_indices(end));
    home_pos = tick_ctr(rising_edges(end));
    % home_pos = tick_ctr(falling_edges(end));
    cur_pos = tick_ctr(end);
end