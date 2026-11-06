function tf = stb_has_var(src, var_name)
% STB_HAS_VAR  True if a processed STB case (case struct or .mat path)
% holds the variable. For "a.b" names, the struct a.
    var_name = string(var_name);
    if contains(var_name, "."), var_name = extractBefore(var_name, "."); end
    tf = stb_exists(src) && ismember(char(var_name), stb_who(src));
end
