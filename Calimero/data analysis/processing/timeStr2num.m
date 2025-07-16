function time_val = timeStr2num(time_str)
    time_str = convertStringsToChars(time_str);
    h_m_s = time_str(12:end); % year is always 4, month 2, day 2
    split_h_m_s = str2double(split(h_m_s, "_"));
    % IS THIS ASSUMING I'M NOT COLLECTING DATA AT 6 AM, CLOCK
    % SHOULD BE 24 HOURS
    if (split_h_m_s(1) < 6)
        split_h_m_s(1) = split_h_m_s(1) + 12;
    end
    time_val = split_h_m_s(1)*3600 + split_h_m_s(2)*60 + split_h_m_s(3);
end