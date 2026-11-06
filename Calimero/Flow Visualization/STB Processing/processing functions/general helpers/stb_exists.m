function tf = stb_exists(src)
% STB_EXISTS  True if a processed STB case has any of its files (case
% struct) or the .mat file exists (path).
    tf = ~isempty(stb_case_files(src));
end
