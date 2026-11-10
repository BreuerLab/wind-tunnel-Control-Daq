function voltAdj = voltM_to_voltA(volt_daq, offset)
    % Offsets should just be zero
    % volt_tare = (volt_daq - offset);

    % 11 = 100.001 /9.091, since we're using R1 = 9.091k and R2 = 90.91k
    voltAdj = volt_daq * 11;
end