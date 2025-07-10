function theta = volt_to_angle(volt_daq, offset)
    analog_voltage = volt_daq - offset;  % [0 - 3.3 V]

    Vmin = min(analog_voltage);
    Vmax = max(analog_voltage);
    
    % Linear scaling to [0, 2π]
    rad_per_turn = 2*pi;
    theta = (analog_voltage - Vmin) / (Vmax - Vmin) * rad_per_turn;
    % Vmin and Vmax used since may not be 0 and 3.3V exactly,
    % the assumption here is that Vmin corresponds to an angle of 0
end

% ------------ OLD CODE prior to 07/08/2025 -----------------
% % Infer min/max from recording
% Vmin = min(analog_voltage);
% Vmax = max(analog_voltage);
% 
% % THE LINE OF CODE BELOW DOESNT APPEAR TO DO ANYTHING
% % Clamp between Vmin and Vmax to avoid outliers
% analog_voltage = max(min(analog_voltage, Vmax), Vmin);
% 
% % Linear scaling to [0°, 360°]
% angle_per_turn = 360;  
% position_vals = (analog_voltage - Vmin) / (Vmax - Vmin) * angle_per_turn;
% % Vmin and Vmax used since may not be 0 and 3.3V exactly,
% % the assumption here is that Vmin corresponds to an angle of 0°
% 
% % === Step 2 : Unwrap to get cumulative absolute angle ===
% theta = deg2rad(position_vals);
% position_vals_absolute = rad2deg(unwrap(theta));