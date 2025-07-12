function move_pitch(automatic, AoA)
    Pitch = Pitch_initialize;
    
    %----------------------------
    % Enable MPS pitch motor
    %----------------------------
    if (automatic)
        Pitch_enable(Pitch);
        disp("MPS Pitch Enabled")
        pause(2)
    else
        % Confirm user has enabled MPS before attempting to change AoA
        MPS_on_off_UI("on");
    end
    
    % Check current angle
    cur_ang = Pitch_Angle();
    
    % Adjust angle of attack via MPS
    Pitch_To(AoA);
    disp("Pitching to AoA: " + AoA)
    
    %----------------------------
    % Disable MPS pitch motor
    %----------------------------
    if (automatic)
        stop_time = abs(AoA - cur_ang)/4 + 1;
        pause(stop_time)
        Pitch_disable(Pitch);
        disp("MPS Pitch Disabled")
        cur_ang = Pitch_Angle();
        disp("Current Angle is: " + cur_ang)
    else
        % Confirm user has disabled MPS before attempting to record data
        MPS_on_off_UI("off");
    end
    
    clear Pitch;
end