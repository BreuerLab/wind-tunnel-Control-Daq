function [names, sub_title] = get_labels(names, selected_vars, wing_freq_ind, wing_freq, wind_speed, type, Re, St, sub_string, nondimensional, body_subtraction)

wing_freq_sel = selected_vars.freq;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;

if (nondimensional)
        if (isscalar(wing_freq_sel) && isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wing_freq_sel) && isscalar(wind_speed_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wing_freq_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) + " St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) =  " St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) +  " Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
            end
        % elseif (length(wing_freq_sel) == 1)
        %     names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
        %     sub_title = " St: " + num2str(round(St,2,"significant"));
        elseif (isscalar(wind_speed_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant"));
            end
        elseif (isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type);
            end
        else
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = "{\color{red}{SUBTRACTION}}: " + sub_string;
            else
                sub_title = "";
            end
        end
        
        else
            
        if (isscalar(wing_freq_sel) && isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wing_freq_sel) && isscalar(wind_speed_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wing_freq_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = num2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wind_speed) + " m/s";
            end
        elseif (isscalar(wing_freq_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wind_speed_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [num2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wind_speed) + " m/s";
            end
        elseif (isscalar(type_sel))
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type);
            end
        else
            names(wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = "{\color{red}{SUBTRACTION}}: " + sub_string;
            else
                sub_title = "";
            end
        end
end
end

function name = type2name(type)
    name = type;
    if (type == "blue wings")
        name = "Wings";
    elseif (type == "blue wings with tail")
        name = "Wings with Tail";
    elseif (type == "no wings with tail")
        name = "No Wings with Tail";
    elseif (type == "no wings")
        name = "No Wings";
    elseif (type == "inertial")
        name = "Skeleton Wings";
    end
end