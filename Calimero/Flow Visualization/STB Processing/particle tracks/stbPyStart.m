function stbPyStart()
% STBPYSTART  Start MATLAB's Python (and load stb_tracks.py) at the start
% of the particle steps, with a clear message if it can't be started.
%
% If MATLAB's out-of-process Python host (MATLABPyHost.exe) died during a
% session, e.g. when the PC ran out of memory, MATLAB can fail to start a
% new one for the rest of that session with
%   Unable to launch Simple server ... CreateProcessW: The parameter is
%   incorrect [system:87]
% Restarting MATLAB fixes it. Does nothing if Python is already running.
    pe = pyenv;
    if pe.Status == "Loaded", return; end
    try
        stbPyModule();
    catch err
        error("stbPyStart:launch", ['Could not start Python (%s).\n' ...
            'If MATLAB''s Python process crashed earlier in this session (e.g. out of memory), ' ...
            'close MATLAB, end any MATLABPyHost.exe left in Task Manager, and start MATLAB again.'], ...
            strtrim(err.message))
    end
end
