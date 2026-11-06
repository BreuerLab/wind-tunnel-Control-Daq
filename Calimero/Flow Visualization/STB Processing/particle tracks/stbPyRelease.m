function stbPyRelease(terminate_python)
% STBPYRELEASE  Free the memory Python holds after reading particle tracks.
%
%   stbPyRelease()        close the DaVis particle sets stb_tracks.py keeps
%                         open (its _open cache)
%   stbPyRelease(true)    also stop MATLAB's Python process (OutOfProcess
%                         mode only), which returns all of Python's memory
%                         to the system; it restarts on the next py. call
%
% Does nothing if Python isn't loaded, so it never starts Python.
    if nargin < 1, terminate_python = false; end
    pe = pyenv;
    if pe.Status ~= "Loaded", return; end
    try
        mod = py.sys.modules.get('stb_tracks');
        if ~isa(mod, 'py.NoneType') && logical(py.hasattr(mod, 'close'))
            mod.close();
        end
    catch err
        warning("stbPyRelease:close", "Could not close the particle sets: %s", err.message)
    end
    if terminate_python && pe.ExecutionMode == "OutOfProcess"
        terminate(pe);
    end
end
