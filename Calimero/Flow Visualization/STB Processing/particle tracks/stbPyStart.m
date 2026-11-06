function stbPyStart()
% STBPYSTART  Start MATLAB's Python (and load stb_tracks.py) before the
% particle steps need it.
%
% On Windows, starting the out-of-process Python host (MATLABPyHost.exe)
% while a parallel pool is running can fail with
%   Unable to launch Simple server ... CreateProcessW: The parameter is
%   incorrect [system:87]
% so if Python isn't running yet, an open pool is shut down first (it is
% restarted by start_pool when the next parallel step needs it). Does
% nothing if Python is already running.
    pe = pyenv;
    if pe.Status == "Loaded", return; end
    if pe.ExecutionMode == "OutOfProcess"
        pool = gcp('nocreate');
        if ~isempty(pool)
            disp("Closing the parallel pool to start Python (it restarts when needed)")
            delete(pool);
        end
    end
    stbPyModule();
end
