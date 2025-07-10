function wait_speed_reached()
    disp("Waiting for speed to reach setting")
    lastSpeed = -1;
    curSpeed = evalin('base',"AFAM_Tunnel.Speed");
    while (abs(lastSpeed - curSpeed) > 0.01 || isnan(curSpeed))
        pause(2)
        lastSpeed = curSpeed;
        curSpeed = evalin('base',"AFAM_Tunnel.Speed");
        % disp(abs(lastSpeed - curSpeed)) % for debugging
    end
    pause(2)
    curSpeed = evalin('base',"AFAM_Tunnel.Speed");
    disp("Speed at " + curSpeed)
end