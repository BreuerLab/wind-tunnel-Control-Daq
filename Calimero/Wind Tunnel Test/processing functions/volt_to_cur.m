function current = volt_to_cur(volt_daq, offset)
    % Offsets should just be zero
    % volt_tare = (volt_daq - offset);

    % 1000 for A to mA and 5 for amplification of hardware filter/amp
    current = volt_daq * 1000 / 5;
end