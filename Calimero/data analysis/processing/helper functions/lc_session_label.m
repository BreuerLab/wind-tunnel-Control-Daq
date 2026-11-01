function label = lc_session_label(sess)
    % Short label for a load cell session folder, e.g.
    % "...\Force Measurements\10 deg wings\4 m.s\wings_2026_09_27"
    %   -> "10 deg wings (wings_2026_09_27)"
    sess = string(sess);
    [~, sess_name] = fileparts(sess);
    type_label = extractBefore(extractAfter(sess, "Force Measurements" + filesep), filesep + "4 m.s");
    if ismissing(type_label) || strlength(type_label) == 0
        parts = split(sess, filesep);
        parts = parts(strlength(parts) > 0);
        type_label = parts(max(1, end - 2));
    end
    label = type_label + " (" + sess_name + ")";
end
