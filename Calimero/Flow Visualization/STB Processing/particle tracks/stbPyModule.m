function mod = stbPyModule(required)
% STBPYMODULE  Import stb_tracks.py (next to this file) into MATLAB's Python,
% reloading it if the loaded copy predates the file on disk or lacks a
% required function. Python caches imported modules for the whole MATLAB
% session, so without this an updated stb_tracks.py is ignored until
% terminate(pyenv) or a MATLAB restart.
%
%   mod = stbPyModule()                     % import / reload if stale
%   mod = stbPyModule("block_attributes")   % also reload if it's missing

    persistent loadedStamp
    here = fileparts(mfilename('fullpath'));
    if count(py.sys.path, here) == 0
        insert(py.sys.path, int32(0), here);
    end
    mod = py.importlib.import_module('stb_tracks');

    f = dir(fullfile(here, 'stb_tracks.py'));
    stamp = f.datenum;
    % first call this MATLAB session: Python may still hold an older copy
    % from before a `clear`, so reload once; afterwards only if the file
    % changed or a required function is missing
    stale = isempty(loadedStamp) || stamp > loadedStamp;
    if nargin >= 1
        for r = string(required)
            if ~logical(py.hasattr(mod, char(r))), stale = true; end
        end
    end
    if stale
        if logical(py.hasattr(mod, 'close')), mod.close(); end   % release open sets
        mod = py.importlib.reload(mod);
    end
    loadedStamp = stamp;
end
