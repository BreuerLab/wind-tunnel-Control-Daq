function stamp = stb_file_stamp(src)
% STB_FILE_STAMP  Modification times of a case's files as one string, for
% cache keys (changes when the case is reprocessed).
    stamp = "";
    for f = stb_case_files(src).'
        info = dir(char(f));
        stamp = stamp + sprintf("%.10f;", info(1).datenum);
    end
end
