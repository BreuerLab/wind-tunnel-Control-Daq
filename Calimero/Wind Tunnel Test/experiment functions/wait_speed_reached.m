function wait_speed_reached(desSpeed)
    disp("Waiting for speed to reach setting")
    lastSpeed = -1;
    load("R:\ENG_Breuer_Shared\group\AFAM_state.mat")
    curSpeed = evalin('base', 'AFAM_Tunnel.Speed');
    while (abs(lastSpeed - curSpeed) > 0.05 || isnan(curSpeed) || lastSpeed == curSpeed)
        pause(2)
        lastSpeed = curSpeed;
        curSpeed = evalin('base',"AFAM_Tunnel.Speed");
        % disp(abs(lastSpeed - curSpeed)) % for debugging
    end
    pause(2)
    curSpeed = evalin('base',"AFAM_Tunnel.Speed");
    disp("Speed at " + curSpeed)

    err = abs(curSpeed - desSpeed);
    if (err > 0.4)
        disp("Oops, speed not reached, trying again...")
        wait_speed_reached(desSpeed)
    end
end