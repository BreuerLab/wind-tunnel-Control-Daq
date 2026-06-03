function current = volt_to_cur(volt_daq, offset)
    % Offsets should just be zero
    % volt_tare = (volt_daq - offset);

    % current = volt_daq * ((1000 / 1.9) / 5);
    current = volt_daq * 1000 / 5;
    % current = volt_daq * (1000 / 2.2);
    % current = volt_daq * (1000 / 0.1);
end