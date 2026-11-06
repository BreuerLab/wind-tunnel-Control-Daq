function vars = stb_who(src)
% STB_WHO  Variable names of a processed STB case (cellstr column), like
% who('-file', ...). src: case struct (names in any of its files, see
% stb_case_files) or a plain .mat path.
    if ~isstruct(src)
        vars = stb_who_cached(src);
        return
    end
    vars = {};
    for f = stb_case_files(src).'
        vars = [vars; stb_who_cached(f)]; %#ok<AGROW>
    end
    vars = unique(vars, 'stable');
end
