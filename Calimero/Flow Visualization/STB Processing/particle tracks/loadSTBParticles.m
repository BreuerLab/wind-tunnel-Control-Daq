function P = loadSTBParticles(setPath, blocks, lvpyioPath)
% LOADSTBPARTICLES  Read 2-pulse STB tracks from a DaVis particle set via lvpyio.
%
%   P = loadSTBParticles(setPath)                    % metadata only
%   P = loadSTBParticles(setPath, blocks)            % blocks are 1-based, like DaVis
%   P = loadSTBParticles(setPath, blocks, lvpyioPath)
%
%   setPath    : DaVis particle-field set, i.e. the folder next to the .set
%                file, without extension, e.g. 'F:\...\x2_..._8Hz\SavedTracks'
%   blocks     : vector of 1-based block indices ([] for metadata only)
%   lvpyioPath : optional folder that CONTAINS the lvpyio package folder
%                (only needed if lvpyio was not pip-installed)
%
%   P.data : N x 10 [x y z u v w I1 I2 trackID block]
%            x,y,z   midpoint of the two pulses (mm)
%            u,v,w   (pos2 - pos1)/dt (m/s)
%            I1,I2   particle intensity in pulse 1 / pulse 2 (raw DaVis units;
%                    P.info.intensity_scale = [slope offset] converts them)
%            trackID DaVis track id (0-based), block 1-based
%   P.info : n_blocks, pulses_per_block, track_count, times (n_blocks x 2, s),
%            units, intensity_scale
%
% ONE-TIME SETUP (before the first call in a MATLAB session):
%   1) Use a Python version that both lvpyio (3.7-3.11) and your MATLAB
%      release support, e.g. 3.10 or 3.11.
%   2) Install lvpyio into it, either from PyPI:   python -m pip install lvpyio
%      or from a wheel shipped with DaVis:         python -m pip install <file>.whl
%   3) In MATLAB:
%        pyenv('Version','C:\Path\To\Python311\python.exe', ...
%              'ExecutionMode','InProcess');   % try 'OutOfProcess' if MATLAB crashes
%   stb_tracks.py must stay in the same folder as this file.

    here = fileparts(mfilename('fullpath'));
    addPyPath(here);
    if nargin >= 3 && ~isempty(lvpyioPath)
        checkLvpyioFolder(lvpyioPath);
        addPyPath(lvpyioPath);
    end
    mod = py.importlib.import_module('stb_tracks');

    setPath = strrep(char(setPath), '\', '/');   % avoid backslash-escape issues

    % metadata
    S = struct(mod.info(setPath));
    P.info.n_blocks         = double(S.n_blocks);
    P.info.pulses_per_block = double(S.pulses_per_block);
    P.info.track_count      = double(S.track_count);
    P.info.times            = double(S.times);
    P.info.units            = string(S.units);
    P.info.intensity_scale  = double(S.intensity_scale);
    P.data = zeros(0, 10);
    if nargin < 2 || isempty(blocks), return; end

    if P.info.pulses_per_block ~= 2
        error('loadSTBParticles:type', 'Expected a 2-pulse field, got %d pulses.', ...
              P.info.pulses_per_block);
    end

    % Python indices are 0-based
    pyBlocks = py.numpy.array(int64(blocks(:)' - 1));
    M = double(mod.read_blocks(setPath, pyBlocks));
    M(:, 10) = M(:, 10) + 1;   % back to 1-based block numbers
    P.data = M;
end

function addPyPath(p)
    p = char(p);
    if count(py.sys.path, p) == 0
        insert(py.sys.path, int32(0), p);
    end
end

function checkLvpyioFolder(p)
% lvpyio contains compiled code, so a .whl must be pip-installed, not added
% to the path. A plain package folder (lvpyio\__init__.py) can be added.
    if isfolder(fullfile(p, 'lvpyio')), return; end
    whl = dir(fullfile(p, '**', 'lvpyio*.whl'));
    if ~isempty(whl)
        error('loadSTBParticles:wheel', ...
            ['Found %s but no lvpyio package folder. Install the wheel once with\n' ...
             '  python -m pip install "%s"\nusing the Python selected in pyenv, ' ...
             'then call without lvpyioPath.'], whl(1).name, fullfile(whl(1).folder, whl(1).name));
    end
    warning('loadSTBParticles:noPackage', ...
        'No lvpyio package folder or wheel found under %s.', p);
end
