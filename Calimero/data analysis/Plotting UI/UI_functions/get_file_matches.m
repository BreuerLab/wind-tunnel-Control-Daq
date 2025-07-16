function struct_matches = get_file_matches(selection_list, norm_bool, shift_bool, drift_bool, sub_bool, Flapperoo, Calimero)
    struct_matches = [];
    
    for i = 1:length(selection_list)
        flapper_name = string(extractBefore(selection_list(i), "/"));
        dir_name = string(extractAfter(selection_list(i), "/"));

        % for compareAoAUI where selection_list string has
        % different form
        if (contains(dir_name, "Hz") || contains(dir_name, "St") || contains(dir_name, "PWM"))
            dir_name = extractBefore(dir_name, "/");
        end

        cur_bird = getBirdFromName(flapper_name, Flapperoo, Calimero);

        if (sub_bool)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
        end

        if (norm_bool)
            if (shift_bool)
                if (drift_bool)
                    shortened_list = intersect(intersect([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                               [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                else
                    shortened_list = setdiff(intersect([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                             [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                end
            else
                if (drift_bool)
                    shortened_list = intersect(setdiff([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                               [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                else
                    shortened_list = setdiff(setdiff([cur_bird.norm_list.file_name], [cur_bird.shift_list.file_name]),...
                                             [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                end
            end
        else
            if (shift_bool)
                if (drift_bool)
                    shortened_list = intersect(intersect(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                    [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                else
                    shortened_list = setdiff(intersect(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                    [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                end
            else
                if (drift_bool)
                    shortened_list = intersect(setdiff(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                    [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                else
                    shortened_list = setdiff(setdiff(setdiff([cur_bird.file_list.file_name], [cur_bird.norm_list.file_name]),...
                    [cur_bird.shift_list.file_name]), [cur_bird.drift_list.file_name]);
                    name_match = shortened_list(contains(shortened_list, dir_name));
                end
            end
        end

        for j = 1:length(cur_bird.file_list)
            if (cur_bird.file_list(j).file_name == name_match)
                struct_match = cur_bird.file_list(j);
                selector = char(selection_list(i));
                struct_match.selector = string(selector);
            end
        end

        % check for repeat files to load
        try
            if (length(struct_matches) == 0 || sum(contains([struct_matches.dir_name], struct_match.dir_name)) == 0)
                struct_matches = [struct_matches struct_match];
            end
        catch ME
            error("Oops! Had trouble matching a file to your selection...")
        end
    end
end