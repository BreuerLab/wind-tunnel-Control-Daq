function P = loadSTBParticles(setPath, blocks, lvpyioPath, frame)
% LOADSTBPARTICLES  Read 2-pulse STB tracks from a DaVis particle set via lvpyio.
%
%   P = loadSTBParticles(setPath)                    % metadata only
%   P = loadSTBParticles(setPath, blocks)            % blocks are 1-based, like DaVis
%   P = loadSTBParticles(setPath, blocks, lvpyioPath)
%   P = loadSTBParticles(setPath, blocks, lvpyioPath, frame)
%
%   setPath    : DaVis particle-field set, i.e. the folder next to the .set
%                file, without extension, e.g. 'F:\...\x2_..._8Hz\SavedTracks'
%   blocks     : vector of 1-based block indices ([] for metadata only)
%   lvpyioPath : optional folder that CONTAINS the lvpyio package folder
%                (only needed if lvpyio was not pip-installed; [] otherwise)
%   frame      : "analysis" (default) or "davis"
%                "analysis" = the frame loadpiv.m produces for binned STB
%                data: x = -z_DaVis (slab normal, pointing UPSTREAM so the
%                freestream is u ~ -U), y = -x_DaVis,
%                z = y_DaVis, and the same rotation for (u,v,w). Positions
%                stay in mm (loadpiv uses m). "davis" = DaVis physical axes
%                (slab normal = z).
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
%   1) Use a 64-bit python.org Python that both lvpyio and your MATLAB
%      release support. lvpyio 1.5.0 needs 3.10-3.14 (and numpy >= 2.0);
%      MATLAB R2023b-R2024a support up to 3.11, R2024b-R2025b up to 3.12,
%      R2026a up to 3.13. Python 3.11 works with all of R2023b onward.
%   2) Install the matching LaVision wheel, e.g. for Python 3.11 on Windows:
%        python -m pip install lvpyio-1.5.0-cp311-cp311-win_amd64.whl
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
    P.frame = "";
    if nargin < 2 || isempty(blocks), return; end

    if P.info.pulses_per_block ~= 2
        error('loadSTBParticles:type', 'Expected a 2-pulse field, got %d pulses.', ...
              P.info.pulses_per_block);
    end

    % Python indices are 0-based
    pyBlocks = py.numpy.array(int64(blocks(:)' - 1));
    M = double(mod.read_blocks(setPath, pyBlocks));
    M(:, 10) = M(:, 10) + 1;   % back to 1-based block numbers

    if nargin < 4 || isempty(frame), frame = "analysis"; end
    frame = lower(string(frame));
    switch frame
        case "analysis"
            % proper rotation, matches loadpiv.m (which flips signs on the raw
            % readimx components; lvpyio positions here are already physical)
            M(:, 1:6) = [-M(:,3), -M(:,1), M(:,2), -M(:,6), -M(:,4), M(:,5)];
            % analysis-frame x points UPSTREAM, so the freestream is u ~ -U
            % (as in import_STB_data / flowField_UI)
            if median(M(:, 4)) > 0
                warning('loadSTBParticles:frame', ...
                    ['Median streamwise velocity u is positive (%.2f m/s) in the ' ...
                     'analysis frame, where x points upstream and u ~ -U is ' ...
                     'expected. Check the axis mapping against binned data.'], median(M(:,4)));
            end
        case "davis"
        otherwise
            error('loadSTBParticles:frame', 'frame must be "analysis" or "davis".');
    end
    P.frame = frame;
    P.data  = M;
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
