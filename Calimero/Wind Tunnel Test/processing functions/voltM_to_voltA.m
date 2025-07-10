function voltAdj = voltM_to_voltA(volt_daq, offset)
    % Offsets should just be zero
    volt_tare = (volt_daq - offset);

    % 7 = 14 /2, since we're using R1 = 2k and R2 = 12k
    voltAdj = volt_tare * 7;
end

% ------------ OLD CODE prior to 07/08/2025 -----------------
% % Conversion to 0-255 numeric value
% volt_esp_255 = volt_esp * (255 / 3.3);
% 
% % Conversion to actual value
% volt_reel = volt_esp_255 * (5000 / 255);  % actual voltage 0-12 V
% 
% % Apply offset correction if needed
% volt_reel_offset_corr = volt_reel;