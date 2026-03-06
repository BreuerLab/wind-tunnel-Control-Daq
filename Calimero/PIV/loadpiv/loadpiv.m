function varargout = loadpiv(folderPIV, varargin)
% This MATLAB function extracts data from LaVision DaVis PIV files.
% Extracts and formats data from "vc7" files contained in "folderPIV".
% 
% **IMPORTANT: For this function to work, the user must download the [MATLAB add-on provided by LaVision](https://www.lavision.de/en/downloads/software/matlab_add_ons.php) (i.e., the *readimx_WIN* or *readimx_MAC* folder).
% Make sure the add-on corresponds to the correct Operating System.**
% 
%  **IMPORTANT NOTES:**
%  - For this function to work, the *readimx* folder **MUST** be in your PATH.
%  - Whenever new updates are made, PLEASE UPDATE THE DOCUMENTATION AND ADD A
%    VERSION DESCRIPTION IN THE FORMAT SPECIFIED.
%  -------------------------------------------------------------------------
%  ## Sintax:
% 
%  `D = loadpiv(folderPIV)`
% 
%  `D = loadpiv(folderPIV, params, "nondim")`
% 
%  `D = loadpiv(folderPIV, "extractAllVariables")`
% 
%  `D = loadpiv(folderPIV, "numCamFields", 2)`
% 
%  `D = loadpiv(folderPIV, "frameRange", [1:2:100])`
% 
%  `D = loadpiv(folderPIV, "fovCenter", [-0.2, 3.1])`
% 
%  `D = loadpiv(folderPIV, "fovRot", 0.23)`
% 
%  `D = loadpiv(folderPIV, "Validate", 0.4)`
% 
%  -------------------------------------------------------------------------
%  ### Mandatory inputs:
% 
%  `D = loadpiv(folderPIV)` : Extracts PIV data from directory "`folderPIV`" and stores it in the structure `D`.
%            The directory must contain the ".vc7" files. Only extracts
%            coordinates, velocity components, and z-vorticity. Depending on
%            the dataset, the extracted variables might include the
%            following: <br />
% - `D.x` : x-coordinates matrix <br />
% - `D.y` : y-coordinates matrix <br />
% - `D.u` : x-velocity component <br />
% - `D.v` : y-velocity component <br />
% - `D.w` : z-velocity component <br />
% - `D.vort` : z-vorticity component
% 
%  -------------------------------------------------------------------------
%  ### Optional inputs:
% 
%  `D = loadpiv(__, params, "nondim")` : Extracts and non-dimensionalizes
%            data using parameters contained in the structure "`params`".
%            "`params`" must have the form: <br />
% - `params.L` = characteristic_length <br />
% - `params.U` = characteristic_velocity <br />
% 
%  `D = loadpiv(__, params, "extractAllVariables")` : Extracts all data
%            found in the ".vc7" files. Depending on the dataset, the extract
%            ed variables might include the following: <br />
% - `D.x` : x-coordinates matrix <br />
% - `D.y` : y-coordinates matrix <br />
% - `D.u` : x-velocity component <br />
% - `D.v` : y-velocity component <br />
% - `D.w` : z-velocity component <br />
% - `D.vort` : z-vorticity component <br />
% - `D.corr` : correlation values <br />
% - `D.uncU` : x-velocity uncertainty <br />
% - `D.uncV` : y-velocity uncertainty <br />
% - `D.uncW` : z-velocity uncertainty <br />
% 
%  -------------------------------------------------------------------------
%  ### Name-value arguments:
% 
%  `D = loadpiv(__, "numCamFields", numCamera)` : Number of independent fields
%                from different cameras. Used for processing.
% 
%  `D = loadpiv(__, "frameRange", frames)` : Specifies specific frames to
%                be extracted instead of the full dataset. Must be followed
%                by a 1D array containing the frame numbers.
% 
%  `D = loadpiv(__, "fovCenter", [xcntr, ycntr])` : Specifies the location
%                of the desired origin of the coordinate axis. Must be
%                followed by a `[xcntr, ycntr]` array specified in meters.
% 
%  `D = loadpiv(__, "fovRot", rotAngle)` : Specifies the rotation of the
%                fov with respect to the origin. Must be followed by the
%                angle's value in radians.
% 
%  `D = loadpiv(__, "Validate", minCorrelationValue)` : Sets a minimum
%                correlation value, otherwise passes NaN-values.
% 
%  -------------------------------------------------------------------------
%  ### Output arguments
% 
%  `D = loadpiv(__)` : outputs flow data in structure `D`.
% 
%  `[D,A] = loadpiv(__)` : outputs flow data in structure `D`, and recording
%                attributes in structure `A`. Currently only outputs 
%                **total acquisition time** in seconds.
% 
%  -------------------------------------------------------------------------
%  ### Output flow data - data structure "D":
% 
% `x` : array containing x-coordinates with size `[n, m]`.
% 
% `y` : array containing y-coordinates with size `[n, m]`.
% 
% `u` : array containing x-component of flow velocity with size `[n, m, N]`.
% 
% `v` : array containing y-component of flow velocity with size `[n, m, N]`.
% 
% `w` : array containing z-component of flow velocity with size `[n, m, N]`.
% 
% `vort` : array containing z-component of vorticity with size `[n, m, N]`.
% 
% `corr` : array containing correlation values with size `[n, m, N]`.
% 
% `uncU` : array containing u-velocity uncertainty with size `[n, m, N]`.
% 
% `uncV` : array containing v-velocity uncertainty with size `[n, m, N]`.
% 
% `uncW` : array containing z-velocity uncertainty with size `[n, m, N]`.
% 
%  -------------------------------------------------------------------------
%  ### Output recording attributes - structure "A":
% 
% `totalAcquisitionTime` : total PIV acquisition time in seconds.
% 
%  -------------------------------------------------------------------------
%  ## UPDATES:
% 
%  #### Version 1.0.0
%  2024/10/31 - Eric Handy (with snippets from Alex, Siyang, and Kenny)
% 
%  #### Version 1.1.0
%  2024/11/06 - Eric Handy
%  - Bug fixes.
%  - Changed vorticity calculation from MATLAB's "curl()" function to the
%    algorithm specified by Raffel's PIV Handbook.
% 
%  #### Version 1.1.1
%  2025/05/12 - Eric Handy
%  - Fixed bug that immediately identified any second parameter as "params".
%  - Fixed a bug that did not assign all output variables specified when
%    using the "extractAllVariables" option.
%  NOTE: These issues have not been robustly tested.
% 
%  #### Version 2.0.0
%  2025/08/06 - Kenny Breuer
%  - Added a "validate" option that returns data only if it meets a correlation
%    threshold.
%  - Output data is NaN if there is no value (instead of 0).
%  - Returns results in a structure - solves several problems with ordering
%    output results.
%  - Doesn't return "isvalid" - that doesn't seem to be present in all the PIV
%    data.
% 
%  #### Version 2.1.0
%  2025/09/30 - Pedro C Ormonde
%  - Fixed hard-coded indices for field names ('U0','V0','TS:Correlation
%    value', etc). Now the function reads from available field names.
%  - Added optional input "n_camField" if data contains multiple monoPIV 
%    fields from multiple cameras. Default: n_camField = 1.
% 
% #### Version 2.1.1
%  2025/10/01 - Eric Handy
%  - Bug fixes.
% 
% #### Version 2.2.0
%  2025/10/15 - Eric Handy
%  - Added option to output a recording attributes structure `A`.
%  - Bug fixes.
% --------------------------------------------------------------------------
%  **SINTAX FOR UPDATES:**
%  #### Version N1.N2.N3
%  YYYY/MM/DD - Name Last
%  - N1 for large structural overhauls to the function (new data structure,
%    new input/output format, new algorithm, etc.).
%  - N2 for small additions to fn (new arguments, new outputs, etc.).
%  - N3 for bug fixes and compatibility updates.
% --------------------------------------------------------------------------


%% Check input parameters

% Check number of outputs
nargoutchk(1,2);

% Check if folderPIV is passed and put into char format
if isempty(folderPIV) || ~exist('folderPIV','Var')
    error('Missing input argument: "folderPIV".');
elseif ~ischar(folderPIV)
    folderPIV = convertStringsToChars(folderPIV);
end

% Default parameters:
CorrelationThreshold = 0;

% Parse inputs:
skip_next = 0;
for optionNum = 1:length(varargin)
    if skip_next == 1 % skip to next in case a name-value argument was just evaluated
        skip_next = 0;
        continue;
    else
        var_option = varargin{optionNum};
    
        % Name-value arguments:
        if ~isnumeric(var_option) && ~isstruct(var_option)
            switch var_option
                case 'frameRange' % to extract specific frames
                    frameRange = varargin{optionNum+1};
                    if ~isnumeric(frameRange)
                        error('Value of "frameRange" must be a numerical integer array.');
                    end
                    skip_next = 1;

                case 'frameSelect' % to extract specific frames
                    sel_frames = varargin{optionNum+1};
                    if ~isnumeric(sel_frames)
                        error('Value of "frameRange" must be a numerical integer array.');
                    end
                    skip_next = 1;
    
                case 'nondim' % non-dimensionalize data option
                    nondim = 1;
    
                case 'extractAllVariables' % extract all optional variables
                    eav = 1;
    
                case 'fovCenter' % specify coordinate center
                    fovCenter = varargin{optionNum+1};
                    if ~isvector(fovCenter) || ~isnumeric(fovCenter)
                        error('"fovCenter" coordinates invalid, must be a numeric vector [x, y].')
                    end
                    skip_next = 1;
    
                case 'fovRot' % specify coordinate rotation
                    fovRot = varargin{optionNum+1};
                    if ~isnumeric(fovRot)
                        error('"fovRot" value invalid, must be a numeric value in radians.')
                    end
                    skip_next = 1;
    
                case 'Validate' % specify minimum vector correlation
                    CorrelationThreshold = varargin{optionNum+1};
                    fprintf('Minimium correlation: %6.2f\n', CorrelationThreshold);
                    skip_next = 1;
                    
                case 'numCamFields' % specify which camera to extract data from
                    n_camField = varargin{optionNum+1};
                    fprintf('Extracting fields for camera: %1.0d\n',n_camField);
                    skip_next = 1;
    
                otherwise
                    if isempty(var_option)
                        error('Empty argument "[]" not valid sintax.');
                    else
                        error(['Invalid argument: "',var_option,'" for input "options."']);
                    end
            end
        % Params structure:
        elseif isstruct(var_option)
            params = var_option;
        else
            if isempty(var_option)
                error('Empty argument "[]" not valid sintax.');
            else
                error(['Input not recognized:',newline,var_option]);
            end
        end
    end
end


% Check for PIV parameters variable
if ~exist('params','Var') || isempty(params)
    params = struct;
end

% Check for "eav" (Extract All Variables) flag
if ~exist('eav','Var')
    eav = 0;
end

% Check for Field of View characteristics
if ~exist('fovCenter','Var')
    % disp('WARNING: "fovCenter" not specified.')
    fovCenter = [0,0];
end

if ~exist('fovRot','Var')
    % disp('WARNING: "fovRot" not specified.')
    fovRot = 0;
end

% Check for n_camFields variable
if ~exist('n_camField','Var')
    % warning('"numCamField" not specified. Default to numCamField = 1.')
    n_camField = 1;
end

% Check for characteristic parameters and extract
if ~exist('nondim','Var')
    L = 1; U = 1;
elseif nondim == 1
    if ~isfield(params,'L') || ~isfield(params,'U')
        warning('"L" (length) and "U" (velocity) fields in struct "params" not passed. Output will be dimensional.')
        L = 1; U = 1;
    elseif ~isnumeric(params.L) || ~isnumeric(params.U)
        warning('Values for "params.L" and/or "params.U" invalid, values must be numeric and in SI units. Output will be dimensional.')
        L = 1; U = 1;
    else
        L = params.L; U = params.U;
    end
end

%% Load data

% locate current directory
folderMain = cd();

% Locate ".vc7" files in PIV directory
files = dir(fullfile(folderPIV,'*.vc7'));
if isempty(files)
    error('No ".vc7" files found in specified directory "folderPIV". Check path.')
end

% Determine range of frames to be processed
if ~exist('frameRange','Var') || isempty(frameRange)
    frameRange = 1:length(files);
end

% Determine range of frames to be processed
if ~exist('sel_frames','Var') || isempty(sel_frames)
    sel_frames = 1:length(files);
end

%% Add path of IMX executable
if exist('readimx', 'file') ~= 3  % check if function is not yet defined
    if ismac
        % addpath(genpath('readimx_MAC'));
        cd('readimx_MAC');
    elseif ispc
        % addpath(genpath('readimx_WIN'));
        cd('readimx_WIN');
    else
        error('System not identified (if using LINUX I do not know what to do).')
    end
end

%% Read in the files
counter = 0;
N = length(frameRange);

% Loop through each file
for ii = 1:length(sel_frames)
    file_ind = sel_frames(ii);
    counter = counter + 1;
    % fnum = fnum + 1;
    % get frame number from filename
    fnum = str2double(regexp(files(file_ind).name, '\d+', 'match','once'));

    % Read DaVis file
    fname = readimx(fullfile(folderPIV,files(file_ind).name));
    
    % Extract attributes --------------------------------------------------
    if nargout  == 2
        Attr = fname.Frames{1}.Attributes;
        % find desired attribute
        for i = 1:length(Attr)
            attr_name = Attr{i}.Name;
            switch attr_name
                case 'AcqTimeSeries'
                    if fnum == 1
                        acqTime_strt = str2double(Attr{i}.Value(1:end-3))*10^-6;
                    elseif fnum == N
                        acqTime_fnsh = str2double(Attr{i}.Value(1:end-3))*10^-6;
                    end
                    % break
                otherwise
                    continue;
            end
        end
    end
    % -----------------------------------------------------------------

    % Extract data from file - returns data structure from one PIV frame
    out1 = extractData(fname, CorrelationThreshold,n_camField);

    % Initialize variables
    if counter == 1
        if out1.dimNum > 3
            error('Data structure constains unrecognized data structure, number of dimensions exceeds 3D data structure. Review data structure');
        end
        % disp([num2str(out1.dimNum),'-dimensional data available.'])

        %% Rotate coordinate system if needed
        D.x = ( (out1.xRaw-fovCenter(1)).*cos(fovRot) - (out1.yRaw-fovCenter(2)).*sin(fovRot) );
        D.y = ( (out1.xRaw-fovCenter(1)).*sin(fovRot) + (out1.yRaw-fovCenter(2)).*cos(fovRot) );
        D.z = out1.zRaw;

        D.u    = nan(size(out1.uRaw));
        D.v    = nan(size(out1.vRaw));
        if out1.dimNum == 3
           D.w = nan(size(out1.wRaw));
        end

        D.vortZ(:,:,:,counter) = nan(size(out1.uRaw));
        D.vortX(:,:,:,counter) = nan(size(out1.uRaw));
        D.vortY(:,:,:,counter) = nan(size(out1.uRaw));

        if eav == 1
            % D.corr = nan([size(D.x),N]);
            D.uncU = nan(size(out1.uncURaw));
            D.uncV = nan(size(out1.uncVRaw));
            if out1.dimNum == 3
               D.uncW = nan(size(out1.uncWRaw));
            end
        end
    end

    % Store data into arrays with rotation
    D.u(:,:,:,counter) = ( out1.uRaw.*cos(fovRot) - out1.vRaw.*sin(fovRot) );
    D.v(:,:,:,counter) = ( out1.uRaw.*sin(fovRot) + out1.vRaw.*cos(fovRot) );

    D.vortZ(:,:,:,counter) = out1.vortZRaw;
    D.vortX(:,:,:,counter) = out1.vortXRaw;
    D.vortY(:,:,:,counter) = out1.vortYRaw;

    if eav == 1
        % D.corr(:,:,fnum) = out1.corrRaw;
        tmp = out1.uncURaw;
        tmp(tmp == 0) = NaN;
        D.uncU(:,:,:,counter) = tmp;

        tmp = out1.uncVRaw;
        tmp(tmp == 0) = NaN;
        D.uncV(:,:,:,counter) = tmp;
    end

    % For 3-dimensional data
    if out1.dimNum == 3
        D.w(:,:,:,counter) = out1.wRaw;
        if eav == 1
            tmp = out1.uncWRaw;
            tmp(tmp == 0) = NaN;
            D.uncW(:,:,:,counter) = tmp;
        end
    end

    % Progress update
    if mod(counter,100) == 0
        disp(['processed ',num2str(counter),'/',num2str(length(sel_frames))])
    end
end

%% Non-dimesionalize
D.u = D.u/U;
D.v = D.v/U;

D.vortZ = D.vortZ * L/U;
D.vortX = D.vortX * L/U;
D.vortY = D.vortY * L/U;

D.x = D.x/L;
D.y = D.y/L;

if eav == 1
    D.uncU = D.uncU/U;
    D.uncV = D.uncV/U;
end

if out1.dimNum == 3
    D.w = D.w/U;
    if eav == 1
        D.uncW = D.uncW/U;
    end
end

% Set output variables
switch nargout
    case 1
        varargout{1} = D;
    case 2
        % Store in attributes structure
        A.totalAcquisitionTime = acqTime_fnsh - acqTime_strt;
        % Output variables
        varargout{1} = D;
        varargout{2} = A;
end

% Return to main folder
cd(folderMain)
if length(sel_frames) > 100
    disp('Done')
end

end


%% Subroutines

% Extract data from DaVis data structure ----------------------------------
function out1 = extractData(dataStructure, CorrelationThreshold,n_camField)

% Components
C = dataStructure.Frames{n_camField, 1}.Components;

% Scales
S = dataStructure.Frames{n_camField, 1}.Scales;

% Grids
G = dataStructure.Frames{n_camField, 1}.Grids;

% Find field names by search (not hard-coded)
field_names = cell(1,length(C));
for i=1:length(C)
    field_names{i} = C{i,1}.Name;
end
% Assign variable names from indices for each field_name
idu = find(strcmp(field_names, 'U0'),1); % First (and only) index where matches occur
idv = find(strcmp(field_names, 'V0'),1);
idw = find(strcmp(field_names, 'W0'),1);
% idcorr = find(strcmp(field_names, 'TS:Correlation value'),1);
% idParticle_Size = find(strcmp(field_names, 'TS:Particle size'),1);
% idPeak_Ratio = find(strcmp(field_names, 'TS:Peak ratio'),1);
iduncU = find(strcmp(field_names, 'TS:Uncertainty Vx'),1);
iduncV = find(strcmp(field_names, 'TS:Uncertainty Vy'),1);
iduncW = find(strcmp(field_names, 'TS:Uncertainty Vz'),1);

% Create 'out1.dimNum'variable
if isempty(idw)
    out1.dimNum = 2;
else
    out1.dimNum = 3;
end

% Check for ISVALID flag
if length(dataStructure.Frames{n_camField, 1}.ComponentNames) > 12
    %out1.dimNum = 3;
    if  length(dataStructure.Frames{n_camField, 1}.ComponentNames) < 16
        % isvalid does not exist
        isvalid_exists = 0;
    else
        isvalid_exists = 1;
    end
else
    %out1.dimNum = 2;
    if  length(dataStructure.Frames{n_camField, 1}.ComponentNames) < 12
        % isvalid does not exist
        isvalid_exists = 0;
    else
        isvalid_exists = 1;
    end
end

% define size of u, v, w matrices
numPlanes = length(C{1, 1}.Planes);
sizeXY = size(C{1, 1}.Planes{1, 1});

trim_bool = true;
if trim_bool
    planesList = 2:numPlanes-1;
    numPlanesTr = numPlanes - 2;
else
    planesList = 1:numPlanes;
    numPlanesTr = numPlanes;
end

out1.uRaw = nan([sizeXY numPlanesTr]);
out1.vRaw = nan(size(out1.uRaw));
out1.wRaw = nan(size(out1.uRaw));

count = 0;
for i = planesList
    count = count + 1;
    % Extract vector data
    out1.uRaw(:,:,count) = C{idu, 1}.Planes{i, 1} * S.I.Slope + C{idu, 1}.Scale.Offset;
    out1.vRaw(:,:,count) = C{idv, 1}.Planes{i, 1} * S.I.Slope + C{idv, 1}.Scale.Offset;
    if out1.dimNum == 3
        out1.wRaw(:,:,count) = C{idw, 1}.Planes{i, 1} * S.I.Slope + C{idw, 1}.Scale.Offset;
    end
end

% out1.corrRaw = C{idcorr, 1}.Planes{1, 1};
% 
% % Replace invalid vectors with NaN
% if isvalid_exists
%     isValid = C{end, 1}.Planes{1, 1};
%     invalid_vectors = find((out1.corrRaw < CorrelationThreshold) | isnan(out1.corrRaw) | (isValid == 0) );
% else
%     invalid_vectors = find((out1.corrRaw < CorrelationThreshold) | isnan(out1.corrRaw));
% end

% % Mask out the invalid pixels
% out1.uRaw(invalid_vectors) = NaN;
% out1.vRaw(invalid_vectors) = NaN;
% out1.corrRaw(invalid_vectors) = NaN;
% if out1.dimNum == 3
%     out1.wRaw(invalid_vectors) = NaN;
% end

% Generate grids
xr = ( (1:size(out1.uRaw,1)) - 0.5 );
yr = ( (1:size(out1.uRaw,2)) - 0.5 );
zr = ( (1:numPlanes) - 0.5 );

if trim_bool
    zr = zr(2:end-1);
end

[out1.xRaw, out1.yRaw, out1.zRaw] = ndgrid((xr * G.X * S.X.Slope + S.X.Offset)/1000,...
    (yr * G.Y * S.Y.Slope + S.Y.Offset)/1000,...
    (zr * G.Z * S.Z.Slope + S.Z.Offset)/1000);

% Reorient to compute vorticity
% x - negative to positive (left to right)
% y - negative to positive (bottom to top)
% out1.xRaw =  flip(out1.xRaw');
% out1.xRaw =  flip(-out1.xRaw,2); % NEW
% % out1.yRaw =  flip(out1.yRaw');
% out1.yRaw =  out1.yRaw;
% out1.zRaw =  flip(-out1.zRaw,3); % NEW
% % out1.uRaw =  flip(out1.uRaw');
% % out1.uRaw =  flip(out1.uRaw',2); % NEW
% out1.uRaw = flip(flip(-out1.uRaw, 2),3); % NEW NEW
% % out1.vRaw = -flip(out1.vRaw');
% % out1.vRaw = flip(-out1.vRaw',2); % NEW
% out1.vRaw = flip(flip(out1.vRaw, 2),3); % NEW NEW
% if out1.dimNum == 3
%     % out1.wRaw = flip(out1.wRaw');
%     out1.wRaw = flip(flip(-out1.wRaw, 2),3);
% end

rot180 = @(data) flip(flip(flip(data, 2), 3),1); % just removed flip(xxx,1)

% Apply to all components
out1.xRaw = rot180(-out1.xRaw);
out1.yRaw = rot180(out1.yRaw);
out1.zRaw = rot180(-out1.zRaw);

out1.uRaw = rot180(-out1.uRaw);
out1.vRaw = rot180(-out1.vRaw); % just removed negative sign
out1.wRaw = rot180(-out1.wRaw);

% Compute vorticity
[out1.vortXRaw, out1.vortYRaw, out1.vortZRaw] = ...
    calculateVorticity(out1.xRaw, out1.yRaw, out1.zRaw, out1.uRaw, out1.vRaw, out1.wRaw);

% Save data
if isvalid_exists
    out1.isValidRaw = single(flip(isValid'));
end

% out1.corrRaw = flip(out1.corrRaw');

out1.uncURaw = nan([sizeXY numPlanesTr]);
out1.uncVRaw = nan(size(out1.uncURaw));
out1.uncWRaw = nan(size(out1.uncURaw));
count = 0;
for i = planesList
    count = count + 1;
    % Uncertainties
    out1.uncURaw(:,:,count) = C{iduncU, 1}.Planes{i, 1};
    out1.uncVRaw(:,:,count) = C{iduncV, 1}.Planes{i, 1};
    if out1.dimNum == 3
        out1.uncWRaw(:,:,count) = C{iduncW, 1}.Planes{i, 1};
    end
end

out1.uncURaw = rot180(out1.uncURaw);
out1.uncVRaw = rot180(out1.uncVRaw);
if out1.dimNum == 3
    out1.uncWRaw = rot180(out1.uncWRaw);
end

end

% Compute vorticity -------------------------------------------------------
function [omega_x, omega_y, omega_z] = calculateVorticity(xRaw,yRaw,zRaw,uRaw,vRaw,wRaw)

% A: ALGORITHM TAKEN FROM RAFFEL'S PIV HANDBOOK
% 6.4 Estimation of Differential Quantities, page 195
omega_x = nan(size(uRaw));
omega_y = nan(size(uRaw));
omega_z = nan(size(uRaw));

dx = abs(xRaw(2,1,1) - xRaw(1,1,1));
dy = abs(yRaw(1,2,1) - yRaw(1,1,1));
dz = abs(zRaw(1,1,2) - zRaw(1,1,1));

%     C = 1 / (8 * dx * dy);
% 
%     i = 2:size(xRaw,1)-1; 
%     j = 2:size(xRaw,2)-1;
%     k = 1:size(xRaw,3);
% 
%     omega_z(i,j,k) = C * (...
%     -dx * (vRaw(i-1,j-1,k) + 2*vRaw(i,j-1,k) + vRaw(i+1,j-1,k)) ...
%     -dy * (uRaw(i+1,j-1,k) + 2*uRaw(i+1,j,k) + uRaw(i+1,j+1,k)) ...
%     +dx * (vRaw(i+1,j+1,k) + 2*vRaw(i,j+1,k) + vRaw(i-1,j+1,k)) ...
%     +dy * (uRaw(i-1,j+1,k) + 2*uRaw(i-1,j,k) + uRaw(i-1,j-1,k)) ...
% );

% 1. Define the Kernels
% Note: In MATLAB convolution, the kernel is effectively "flipped" 
% during the operation, but for symmetric stencils like this, 
% we just map the coefficients directly.

Ku = [ -1,   0,  1;
       -2,  0, 2;
       -1,   0,  1 ] * dx;

Kv = [ 1, 2, 1;
        0,    0,    0;
        -1,  -2,  -1 ] * dy;

% kernels flipped since convn flips them again before applying them

% 2. Apply Convolution
% 'same' keeps the output the same size as input.
% convn handles the 3rd dimension (k) automatically by applying 
% the 2D kernel to every slice.
C = 1 / (8 * dx * dy);
omega_z = C * (convn(uRaw, Ku, 'same') + convn(vRaw, Kv, 'same'));

% C = 1 / (8 * dx * dy);
% 
% i = 2:size(xRaw,1)-1; 
% j = 2:size(xRaw,2)-1;
% k = 1:size(xRaw,3);
% 
% omega_z(i,j,k) = C * (...
%             dx*(uRaw(i-1,j-1,k) + 2*uRaw(i,j-1,k) + uRaw(i+1,j-1,k)) ...
%             + dy*(vRaw(i+1,j-1,k) + 2*vRaw(i+1,j,k) + vRaw(i+1,j+1,k)) ...
%             - dx*(uRaw(i+1,j+1,k) + 2*uRaw(i,j+1,k) + uRaw(i-1,j+1,k)) ...
%             - dy*(vRaw(i-1,j+1,k) + 2*vRaw(i-1,j,k) + vRaw(i-1,j-1,k)) ...
% );
% Dont compute the edge vorticity
% C = 1 / (8 * dx * dy);
% for k = 1:size(xRaw,3)
%     for i = 2:size(xRaw,1)-1
%         for j = 2:size(xRaw,2)-1
%             omega_z(i,j,k) = ...
%                 C * ( ...
%                 + dx*(uRaw(i-1,j-1,k) + 2*uRaw(i,j-1,k) + uRaw(i+1,j-1,k)) ...
%                 + dy*(vRaw(i+1,j-1,k) + 2*vRaw(i+1,j,k) + vRaw(i+1,j+1,k)) ...
%                 - dx*(uRaw(i+1,j+1,k) + 2*uRaw(i,j+1,k) + uRaw(i-1,j+1,k)) ...
%                 - dy*(vRaw(i-1,j+1,k) + 2*vRaw(i-1,j,k) + vRaw(i-1,j-1,k)) ...
%                 );
% 
%             % - (1/2)*dx*(vRaw(i-1,j-1,k) + 2*vRaw(i,j-1,k) + vRaw(i+1,j-1,k)) ...
%             %     - (1/2)*dy*(uRaw(i+1,j-1,k) + 2*uRaw(i+1,j,k) + uRaw(i+1,j+1,k)) ...
%             %     + (1/2)*dx*(vRaw(i+1,j+1,k) + 2*vRaw(i,j+1,k) + vRaw(i-1,j+1,k)) ...
%             %     + (1/2)*dy*(uRaw(i-1,j+1,k) + 2*uRaw(i-1,j,k) + uRaw(i-1,j-1,k)) ...
% 
%             % omega_z(i,j) = ((1/2) / (4*dx*dy))*...
%             %     ( ...
%             %     dx*(uRaw(i-1,j-1) + 2*uRaw(i,j-1) + uRaw(i+1,j-1)) ...
%             %     + dy*(vRaw(i+1,j-1) + 2*vRaw(i+1,j) + vRaw(i+1,j+1)) ...
%             %     - dx*(uRaw(i+1,j+1) + 2*uRaw(i,j+1) + uRaw(i-1,j+1)) ...
%             %     - dy*(vRaw(i-1,j+1) + 2*vRaw(i-1,j) + vRaw(i-1,j-1)) ...
%             %     );
%         end
%     end
% end

% We define this as a 3D array: [Rows x Cols x Slices]
% Since k (Cols) doesn't change, the second dimension size is 1.
Kw = zeros(3, 1, 3);
Kw(1, 1, :) = [ -1,  -2,  -1]; % i-1 terms
Kw(2, 1, :) = [0,  0,  0]; % i terms
Kw(3, 1, :) = [ 1,  2, 1]; % i+1 terms
Kw = Kw * dz;

% Kernel for uRaw: Operations on Dim 1 (j) and Dim 3 (i)
Ku = zeros(3, 1, 3);
Ku(:, 1, 3) = [-1, -2,  -1]; % j-1 terms
Ku(:, 1, 2) = [0, 0, 0]; % j terms (middle)
Ku(:, 1, 1) = [1, 2,  1]; % j+1 terms
Ku = Ku * dx;

C = 1 / (8 * dx * dz);
omega_y = C * (convn(wRaw, Kw, 'same') + convn(uRaw, Ku, 'same'));

% C = 1 / (8 * dx * dz);
% 
% i = 2:size(xRaw,3)-1; 
% j = 2:size(xRaw,1)-1;
% k = 1:size(xRaw,2);
% 
% omega_y(j,k,i) = C * (...
%             dz*(wRaw(j-1,k,i-1) + 2*wRaw(j-1,k,i) + wRaw(j-1,k,i+1)) ...
%             + dx*(uRaw(j-1,k,i+1) + 2*uRaw(j,k,i+1) + uRaw(j+1,k,i+1)) ...
%             - dz*(wRaw(j+1,k,i+1) + 2*wRaw(j+1,k,i) + wRaw(j+1,k,i-1)) ...
%             - dx*(uRaw(j+1,k,i-1) + 2*uRaw(j,k,i-1) + uRaw(j-1,k,i-1)) ...
% );

% for k = 1:size(xRaw,2)
%     for i = 2:size(xRaw,1)-1
%         for j = 2:size(xRaw,3)-1
%             omega_z(i,k,j) = ...
%                 ( ...
%                 - (1/2)*dz*(uRaw(i-1,k,j-1) + 2*uRaw(i-1,k,j) + uRaw(i-1,k,j+1)) ...
%                 - (1/2)*dx*(wRaw(i-1,k,j+1) + 2*wRaw(i,k,j+1) + wRaw(i+1,k,j+1)) ...
%                 + (1/2)*dz*(uRaw(i+1,k,j+1) + 2*uRaw(i+1,k,j) + uRaw(i+1,k,j-1)) ...
%                 + (1/2)*dx*(wRaw(i+1,k,j-1) + 2*wRaw(i,k,j-1) + wRaw(i-1,k,j-1)) ...
%                 ) ...
%                 / (4*dx*dy);
%             % - (1/2)*dz*(uRaw(i-1,k,j-1) + 2*uRaw(i,k,j-1) + uRaw(i+1,k,j-1)) ...
%             %     - (1/2)*dx*(wRaw(i+1,k,j-1) + 2*wRaw(i+1,k,j) + wRaw(i+1,k,j+1)) ...
%             %     + (1/2)*dz*(uRaw(i+1,k,j+1) + 2*uRaw(i,k,j+1) + uRaw(i-1,k,j+1)) ...
%             %     + (1/2)*dx*(wRaw(i-1,k,j+1) + 2*wRaw(i-1,k,j) + wRaw(i-1,k,j-1)) ...
%         end
%     end
% end
% elseif (dim == 1)
Kv = zeros(1, 3, 3);
Kv(1, :, 1) = [ -1,  -2,  -1]; % i-1 terms
Kv(1, :, 2) = [0,  0,  0]; % i terms
Kv(1, :, 3) = [ 1,  2, 1]; % i+1 terms
Kv = Kv * dy;

% Kernel for uRaw: Operations on Dim 1 (j) and Dim 3 (i)
Kw = zeros(1, 3, 3);
Kw(1, 3, :) = [-1, -2,  -1]; % j-1 terms
Kw(1, 2, :) = [0, 0, 0]; % j terms (middle)
Kw(1, 1, :) = [1, 2,  1]; % j+1 terms
Kw = Kw * dz;

C = 1 / (8 * dy * dz);
omega_x = C * (convn(vRaw, Kv, 'same') + convn(wRaw, Kw, 'same'));

% C = 1 / (8 * dy * dz);
% 
% i = 2:size(xRaw,2)-1; 
% j = 2:size(xRaw,3)-1;
% k = 1:size(xRaw,1);
% 
% omega_x(k,i,j) = C * (...
%             dy*(vRaw(k,i-1,j-1) + 2*vRaw(k,i,j-1) + vRaw(k,i+1,j-1)) ...
%             + dz*(wRaw(k,i+1,j-1) + 2*wRaw(k,i+1,j) + wRaw(k,i+1,j+1)) ...
%             - dy*(vRaw(k,i+1,j+1) + 2*vRaw(k,i,j+1) + vRaw(k,i-1,j+1)) ...
%             - dz*(wRaw(k,i-1,j+1) + 2*wRaw(k,i-1,j) + wRaw(k,i-1,j-1)) ...
% );

% for k = 1:size(xRaw,1)
%     for i = 2:size(xRaw,2)-1
%         for j = 2:size(xRaw,3)-1
%             omega_z(k,i,j) = ...
%                 ( ...
%                 - (1/2)*dy*(wRaw(k,i-1,j-1) + 2*wRaw(k,i,j-1) + wRaw(k,i+1,j-1)) ...
%                 - (1/2)*dz*(vRaw(k,i+1,j-1) + 2*vRaw(k,i+1,j) + vRaw(k,i+1,j+1)) ...
%                 + (1/2)*dy*(wRaw(k,i+1,j+1) + 2*wRaw(k,i,j+1) + wRaw(k,i-1,j+1)) ...
%                 + (1/2)*dz*(vRaw(k,i-1,j+1) + 2*vRaw(k,i-1,j) + vRaw(k,i-1,j-1)) ...
%                 ) ...
%                 / (4*dy*dz);
%         end
%     end
% end

% NOTE: ADD COMPUTATION OF EDGES (USE MATLAB'S IMPLEMENTATION IN "curl")

% B: Using Matlab's curl function:
% [omega_z, ~] = curl(xRaw, yRaw, uRaw, vRaw);

end
