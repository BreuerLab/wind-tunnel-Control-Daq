function checkLimits(results)
    % Parameters specifc to Gamma IP65 Force Transducer
    % force_limit = 1200; % Newton
    % torque_limit = 79; % Newton*meters
    
    % Parameters specifc to Mini40 IP65 Force Transducer
    force_limit = 810; % Newton
    torque_limit = 19; % Newton*meters

    disp("Checking limits for Mini40 Load Cell")

    % Reaching torque or force limits?
    if(max(abs(results(:,2:4))) > 0.7*force_limit)
        beep3;
        msgbox("Approaching Force Limit!!!","DANGER!","error");
    end
    if (max(abs(results(:,5:7))) > 0.7*torque_limit)
        beep3;
        msgbox("Approaching Torque Limit!!!","DANGER!","error");
    end
end