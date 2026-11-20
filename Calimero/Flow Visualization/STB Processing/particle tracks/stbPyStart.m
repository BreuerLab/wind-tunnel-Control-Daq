function stbPyStart()
% STBPYSTART  Start MATLAB's Python (and load stb_tracks.py) for the
% particle steps, with a clear message if it can't be started.
%
% process_case calls it before the binned phase average: started after
% the binned processing, MATLAB's out-of-process Python host
% (MATLABPyHost.exe) failed to launch with
%   Unable to launch Simple server ... CreateProcessW: The parameter is
%   incorrect [system:87]
% although it starts fine in a fresh MATLAB. Does nothing if Python is
% already running.
    pe = pyenv;
    if pe.Status == "Loaded", return; end
    try
        stbPyModule();
    catch err
        error("stbPyStart:launch", ['Could not start Python (%s).\n' ...
            'Try it in a fresh MATLAB: py.list({1}). If that works, start Python before ' ...
            'anything else in the session (process_case does this for the particle steps).'], ...
            strtrim(err.message))
    end
end
