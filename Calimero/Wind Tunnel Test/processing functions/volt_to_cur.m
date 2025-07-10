function current = volt_to_cur(volt_daq, offset)
    % Offsets should just be zero
    volt_tare = (volt_daq - offset);

    current = volt_tare;
end