function offsets = initial_tare(flapper_obj, offset_duration, wing_type, speed, AoA, automatic)
    %----------------------------
    % Turn off wind tunnel
    %----------------------------
    if (speed ~= 0)
        if (automatic)
            VFD_stop; % stop wind tunnel motor
            wait_speed_reached();
        else
            % Confirm user has stopped wind before recording offset for this AoA
            wind_on_off_UI("off");
        end
    end
    
    %----------------------------
    % Move MPS to prescribed pitch angle
    %----------------------------
    move_pitch(automatic, AoA);
    
    % Get offset data before flapping at this angle with no wind
    offset_name = wing_type + "_" + speed + "m.s_" + AoA + "deg";
    offsets = flapper_obj.get_force_offsets(offset_name, offset_duration);
    offsets = offsets(1,:); % just taking means, no SDs
    disp("Offset data at this AoA has been gathered");
    beep1;
    pause(1.5)
    
    %----------------------------
    % Turn wind tunnel back on
    %----------------------------
    if (speed ~= 0)
        if (automatic)
            VFD_start; % start wind tunnel motor
            wait_speed_reached();
        else
            % Confirm user has resumed wind before recording data
            wind_on_off_UI("on");
        end
    end
end