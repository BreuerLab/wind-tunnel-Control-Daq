function save_STB_struct(save_path, S, bools)
% Save the fields of S as variables in save_path.
%
% By default the file is written uncompressed (-v7.3 -nocompression):
% MATLAB's default compression runs on a single core and was most of the
% save time for phase-averaged files. Uncompressed files are larger but
% faster to write and to load. Set bools.compress_save = true to use
% MATLAB's default (compressed) format instead.

compress = isfield(bools, 'compress_save') && bools.compress_save;
if compress
    save(save_path, '-struct', 'S');
else
    save(save_path, '-struct', 'S', '-v7.3', '-nocompression');
end
end
