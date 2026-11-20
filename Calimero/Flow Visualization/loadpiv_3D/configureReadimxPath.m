function configureReadimxPath()
% CONFIGUREREADIMXPATH  Make sure LaVision's readimx MEX is on the path.
%
% The main scripts (main_processing, main_processing_batch, main_analysis)
% add it with addpath(genpath('C:\Users\rgissler\Documents\MATLAB')). If
% it still isn't found, the readimx_WIN / readimx_MAC folder is looked for
% in the current folder and in MATLAB's userpath (Documents\MATLAB by
% default) and added to the path. The current folder is not changed.
    if exist('readimx', 'file') == 3
        return
    end

    if ismac
        folder_name = 'readimx_MAC';
    elseif ispc
        folder_name = 'readimx_WIN';
    else
        error('System not identified (if using LINUX I do not know what to do).')
    end

    roots = {pwd};
    up = strtok(userpath, pathsep);
    if ~isempty(up)
        roots{end+1} = up;
    end

    for i = 1:numel(roots)
        candidate = fullfile(roots{i}, folder_name);
        if isfolder(candidate)
            addpath(genpath(candidate));
            if exist('readimx', 'file') == 3
                return
            end
        end
    end

    error('configureReadimxPath:notFound', ...
        ['readimx (LaVision MATLAB add-on) not found. Looked for %s in:\n  %s\n' ...
         'Add it with addpath(genpath(''<folder containing %s>'')) before loading .vc7 files.'], ...
        folder_name, strjoin(roots, sprintf('\n  ')), folder_name);
end
