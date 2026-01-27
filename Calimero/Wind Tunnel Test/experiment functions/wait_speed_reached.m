function wait_speed_reached(desSpeed)
    disp("Waiting for speed to reach setting")
    lastSpeed = -1;
    AFAM_Tunnel = load_afam_data;
    curSpeed = AFAM_Tunnel.Speed;
    while (abs(lastSpeed - curSpeed) > 0.05 || isnan(curSpeed) || lastSpeed == curSpeed)
        pause(2)
        lastSpeed = curSpeed;
        AFAM_Tunnel = load_afam_data;
        curSpeed = AFAM_Tunnel.Speed;
        % disp(abs(lastSpeed - curSpeed)) % for debugging
    end
    pause(2)
    AFAM_Tunnel = load_afam_data;
    curSpeed = AFAM_Tunnel.Speed;
    disp("Speed at " + curSpeed)

    err = abs(curSpeed - desSpeed);
    if (err > 0.4)
        disp("Oops, speed not reached, trying again...")
        wait_speed_reached(desSpeed)
    end
end