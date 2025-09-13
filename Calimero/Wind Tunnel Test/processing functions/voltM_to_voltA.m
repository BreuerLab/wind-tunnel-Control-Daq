function voltAdj = voltM_to_voltA(volt_daq, offset)
    % Offsets should just be zero
    % volt_tare = (volt_daq - offset);

    % 7 = 14 /2, since we're using R1 = 2k and R2 = 12k
    voltAdj = volt_daq * 7;
end