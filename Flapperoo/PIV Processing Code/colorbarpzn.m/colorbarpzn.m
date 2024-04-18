function varargout = colorbarpzn(varargin)
%COLORBARPZN creates positive-zero-negative colormap and colorbar.
% Zero is in white if while color location is not specified.
% Customized colormap/colorbar options are available for:
%   - automatic/manual positive, zero, and negative color.
%   - predefined colors for different combinations of colormap spectrum.
%   - automatic/manual positive, negative, or positive-negative colormap.
%   - automatic/manual white position (at zero or specified).
%   - secondary positive and negative colors assigned to specific values.
%   - reversed default positive and negative colors.
%   - reversed colorbar direction by switching the order of input limits.
%   - number of colormap levels.
%   - LaTeX colorbar label.
%   - log scale colormap with adjustable loginess.
%   - extended white region to display small values in a uniform color.
%   - returning colorbar handle and/or colormap array.
% -------------------------------------------------------------------------
%
% Syntax:
%
% colorbarpzn(caxis1, caxis2)
% colorbarpzn(caxis1, caxis2, 'options')
% colorbarpzn(target, __)
% colorbarpzn(__, 'off')
% h = colorbarpzn(__)
% [h, cmap] = colorbarpzn(__)
% cmap = colorbarpzn(__, 'off')
% -------------------------------------------------------------------------
%
% Description:
%
% colorbarpzn(caxis1, caxis2): creates automatic colormap and colorbar
%                              based on caxis([cmin, cmax]), where
%                              cmin = min([caxis1, caxis2]) and
%                              cmax = max([caxis1, caxis2]). The colormap
%                              has a default style in which zero is in
%                              white, positive is in red, and negative is
%                              in blue. When caxis1 < caxis2, the colorbar
%                              is displayed in 'normal' direction; when
%                              caxis1 > caxis2, the colorbar is displayed
%                              in 'reversed' direction (see e.g.[3]).
%
% 'options':
% (one input/output option can be used independently or with other options)
%
% colorbarpzn(__, 'rev'): creates reversed default colormap, where positive
%                         is in blue and negative is in red. 'rev' will be
%                         overwritten if 'colorP' or 'colorN' is manually
%                         specified. See e.g.[6]
%
% colorbarpzn(__, 'dft', 'colors'): change defaul colors in the order of
%                                   positive, zero, negative with
%                                   predefined colors. 'colors' is an 1 X 3
%                                   char variable which is a combination of
%                                   any 3 characters from 'r' (red), 'b'
%                                   (blue), 'g' (green), 'p' (purple), 'y'
%                                   (yellow), 'w' (white), and 'k' (black).
%                                   E.g., 'rgb', 'ywg', 'bwp', etc. 'dft'
%                                   will be overwritten if 'colorP',
%                                   'colorN', or 'colorZ' is manually
%                                   specified. See e.g.[5].
%
% colorbarpzn(__, 'colorP', [R G B]/'color'): customizes positive color
%                                             with RGB or one of the color
%                                             code (see 'colors' in the
%                                             'dft' option). See e.g.[1].
%
% colorbarpzn(__, 'colorN', [R G B]/'color'): customizes negative color
%                                             with RGB or one of the color
%                                             code (see 'colors' in the
%                                             'dft' option). See e.g.[5].
%
% colorbarpzn(__, 'colorZ', [R G B]/'color'): customizes white/zero color
%                                             with RGB or one of the color
%                                             code (see 'colors' in the
%                                             'dft' option). See e.g.[5].
%
% colorbarpzn(__, 'colorP2', [R G B]/'color', P2value):
%                                   adds a secondary color to the positive
%                                   color spectrum with RGB or one of the
%                                   predefined color code. The parameter
%                                   P2value specifies the position of
%                                   colorP2 on the colorbar where
%                                   cmin (or Wvalue) < P2value < cmax.
%                                   P2value is at the middle of
%                                   [cmin/Wvalue, cmax] if not specified.
%                                   See e.g.[8].
%
% colorbarpzn(__, 'colorN2', [R G B]/'color', N2value):
%                                   adds a secondary color to the negative
%                                   color spectrum with RGB or one of the
%                                   predefined color code. The parameter
%                                   N2value specifies the position of
%                                   colorN2 on the colorbar where
%                                   cmin < N2value < cmax (or Wvalue).
%                                   N2value is at the middle of
%                                   [cmin, cmax/Wvalue] if not specified.
%                                   See e.g.[8]
%
% colorbarpzn(__, 'full'): enforces full positive-negative color map with
%                          white is at the middle of [cmin, cmax].
%                          See e.g.[5].
%
% colorbarpzn(__, 'full', Wvalue): enforces full positive-negative colormap
%                                  and specifies white position by Wvalue.
%                                  See e.g.[4].
%
% colorbarpzn(__, 'level', Nlevel): customizes the number of colormap
%                                   levels (see e.g.[1, 5]). An odd integer
%                                   is preferred. The default Nlevel is 127
%                                   if 'level' option is not used.
%
% colorbarpzn(__, 'label', 'LaTeXString'): creates a LaTeX colorbar label.
%                                          See e.g.[3].
%
% colorbarpzn(__, 'log'): creates log scale colormap for coarser
%                         increment near white (smaller white region) with
%                         defualt loginess = 1. (citation [1]).
%
% colorbarpzn(__, 'log', loginess): creates log scale colormap and
%                                   specifies the loginess value to make
%                                   smaller white region (loginess > 0, see
%                                   e.g.[3]) or larger white region
%                                   (loginess < 0, see e.g.[6]).
%
% colorbarpzn(__, 'wrs', WhiteRegionSize): define the white color region
%                                          size as a ratio to the total
%                                          size of the colorbar/map, so
%                                          small values are displayed in a
%                                          uniform color. See e.g.[7].
%                                          0 < WhiteRegionSize < 1.
%
% colorbarpzn(__, 'off'): set the colormap without creating a colorbar.
%
% colorbarpzn(target, __): sets the colormap for the figure, axes, or chart
%                          specified by target, instead of for the current
%                          figure and adds a colorbar to the axes or chart
%                          specified by target. Specify the target axes or
%                          chart as the first argument in any of the
%                          previous syntaxes. Similar to the combined use
%                          of colormap(target, map) and colorbar(target).
%                          See e.g.[3, 4].
%
% h = colorbarpzn(__): h returns a colorbar handle. See e.g.[4].
%
% [h, cmap] = colorbarpzn(__): h returns a colorbar handle and cmap returns
%                              the colormap array. See e.g.[5].
%
% cmap = colorbarpzn(__): cmap returns the colormap array only. See e.g.[6].
% -------------------------------------------------------------------------
%
% Examples:
%
% [1] colorbarpzn(-1, 2, 'level', 21, 'colorP', [0.6 0.4 0.3]):
%       creates a colormap and a colorbar from -1 to 2 where 0 is in white
%       color with 21 levels on one side and with customized positive color
%       [0.6 0.4 0.3].
%
% [2] colorbarpzn(-1, 2, 'dft', 'ywg'):
%       creates a colormap and a colorbar from -1 to 2 where the default
%       positive color is changed to predefined yellow 'y', the default
%       zero color remains white 'w', and the default negative color is
%       changed to predefined green 'g'.
%
% [3] colorbarpzn(ax1, 2, 1, 'log', 1.2, 'label', '$\alpha$'):
%       on axis ax1, creates a colormap and a colorbar from 1 to 2 with
%       only positive color where the white color region is shortened by a
%       loginess of 1.2; the colorbar is displayed in reversed direction
%       as 2 > 1; the colorbar label desplays $\alpha$ with LaTeX
%       interpreter.
%
% [4] h = colorbarpzn(ax2, 1, 3, 'full', 1.5):
%       on axis ax2, creates a colormap and a colorbar from 1 to 3 with
%       full default positive-negative color spectrum where white color is
%       aligned with the specified Wvalue 1.5 following the 'full' option;
%       h returns the colorbar handle.
%
% [5] [h, cmap] = colorbarpzn(-4, -2, 'full', 'colorZ', [0.8 0.8 0.8], ...
%                             'colorN', 'p', 'level', 31):
%       creates a colormap and a colorbar from -4 to -2 with full
%       positive-negative color spectrum with 31 levels on each side where
%       white color is customized with [0.8 0.8 0.8] and the negative end
%       of the spectrum is in predefined purple color 'p'; the white color
%       is aligned with the mean of caxis1 and caxis2 -3 on the colorbar as
%       no Wvalue is specifice after 'full' option; h returns the colorbar
%       handle and cmap returns the 31 X 3 colormap array generated.
%
% [6] cmap = colorbarpzn(-2, 2, 'log', -1, 'rev', 'off'):
%       returns a 127 X 3 colormap array to cmap whlie disables displaying
%       the colorbar; the colormap is with a reversed defualt color
%       spectrum and the white color region is enlarged by a loginess of -1.
%
% [7] colorbarpzn(-1, 2, 'wrs', 0.4):
%       creates a colormap and a colorbar from -1 to 2 with the default
%       positive-negative color spectrum where the values between -0.4 and
%       0.8 are displayed in White; the red and blue linear color gradients
%       tarts at 0.8 and -0.4 respectively, with a white regein in the
%       middle.
%
% [8] colorbarpzn(-1, 2, 'colorP2', 'g', 1.5, 'colorN2', [0.3 0.4 0.2]):
%       creates a colormap and a colorbar from -1 to 2 with the default
%       positive-negative color spectrum and adds a secondary positive
%       color with predefined green 'g' aligned with the value 1.5 and a
%       secondary negative color with RGB [0.3 0.4 0.2] at the middle of
%       [-1 0] as the N2value parameter is not specified.
% =========================================================================
%
% version 1.8.0
%   - Function name changed to >>colorbarpzn denoting
%     positive-zero-negative. 'colorW' option name changed to 'colorZ'
%     accordingly.
%   - Fix a bug when using the 'full' option without specifying 'Wvalue'
%     gives a false error.
% Xiaowei He
% 06/16/2023
% -------------------------------------------------------------------------
% version 1.7.2
%   - Fixed a bug where the number of levels is incorrect when using the
%     'log' option.
%   - Fixed a bug where the 'zero' color is missing when generating a
%     one-sided colorbar/colormap.
% Xiaowei He
% 05/22/2023
% -------------------------------------------------------------------------
% version 1.7.1
%   - Fixed a bug in v1.7.0 where using [R G B] and P2value/N2value
%     together in 'colorP2' or 'colorN2' can cause a fault error.
% Xiaowei He
% 04/25/2023
% -------------------------------------------------------------------------
% version 1.7.0
%   - Added options 'colorP2' and 'colorN2' for secondary colors in the
%     positive and negative color spectra, respectively.
%   - Predefined colors can now be used for 'colorP', 'colorN', 'colorZ',
%     as well as the new 'colorP2' and 'colorN2' options.
%   - Removed the warning messages when overwritting 'dft' colors with
%     'colorP', 'colorN', and 'colorZ'.
% Xiaowei He
% 04/25/2023
% -------------------------------------------------------------------------
% version 1.6.1
%   - Fixed a bug in v1.6.0 where the white color is not at zero when using
%     default cmin and cmax settings.
% Xiaowei He
% 09/01/2022
% -------------------------------------------------------------------------
% version 1.6.0
%   - Added an option 'wrs' for extending the White color region so small
%     values are displayed in the White color and the color gradient does
%     not start until a threshold. See description of
%     colormap(__, 'wrs', WhiteRegionSize).
%   - Adjusted the default red and blue color.
%   - Fixed a bug where an even number level cannot be generated, although
%     an odd Nlevel value is preferred for acurate Zero value positioning.
%   - 'off' potion can now be used without an output argument.
% Xiaowei He
% 08/25/2022
% -------------------------------------------------------------------------
% version 1.5.0
%   - Added several predefined low-saturation colors and an input argument
%     'dft' which allows for changing the default red-white-blue colormap
%     with combinations of these predefined colors. See description of
%     colormap(__, 'dft', 'colors') for details.
%   - Fixed a bug that causes errors when the colorbar label string is the
%     same as one of the input arguments.
% Xiaowei He
% 05/28/2022
% -------------------------------------------------------------------------
% version 1.4.0
%   - Added support for reversed colorbar direction by switching cmin and
%     cmax order, so the input limits became colorbarpzn(caxis1, caxis2).
%     E.g., colorbarpzn(2, -1) displays a -1 to 2 colorbar in reversed
%     direction, which is equivalent to cb.Direction = 'rev'.
%   - Removal of the caxis1 < caxis2 rule accordingly.
%   - Fixed a bug that causes an error when using 0 or 1 as the first caxis
%     limit, i.e., colorbarpzn(0, caxis2) or colorbarpzn(1, caixs2).
%   - Updates in headline description and examples.
% Xiaowei He
% 05/23/2022
% -------------------------------------------------------------------------
% version 1.3.0
%   - Added support for setting colormap and displaying colorbar on
%     specific target, e.g., colorbarpzn(ax, cmin, cmax).
%   - Updates and corrections in headline description and examples.
% Xiaowei He
% 05/07/2022
% -------------------------------------------------------------------------
% version 1.2.0
%   - Changed the function name from >>colorbarPWN to >>colorbarpwn for
%     friendlier user experience.
%   - Added an option 'off' which disables creatting the colorbar and only
%     returns the colormap array.
%   - Updates in headline description including a few examples.
% Xiaowei He
% 04/27/2022
% -------------------------------------------------------------------------
% version 1.1.1
%   - Minor code improvement.
%   - Updates in headline descriptions.
% Xiaowei He
% 04/21/2022
% -------------------------------------------------------------------------
% version 1.1.0
%   - Added an output argument for the colormap array.
%   - Added an input argument 'rev' for reversed default Positive and
%     Negative colors, where Positive is in blue and Negative is in red.
%   - Improved some logical structures.
%   - Updated some descriptions in the headlines.
% Xiaowei He
% 04/15/2022
% -------------------------------------------------------------------------
% version 1.0.1
%   - Fixed a bug when output coloarbar handle.
% Xiaowei He
% 04/07/2022
% -------------------------------------------------------------------------
% version 1.0.0
% Xiaowei He
% 03/30/2022
% =========================================================================
%
% citation [1]
% Connor Ott (2017). Non-linearly Spaced Vector Generator
% https://www.mathworks.com/matlabcentral/fileexchange/64831-non-linearly-spaced-vector-generator,
% MATLAB Central File Exchange.
% function nonLinVec = nonLinspace(mn, mx, num)
%     loginess = 1.5; % Increasing loginess will decreasing the spacing towards
%                     % the end of the vector and increase it towards the beginning.
%     nonLinVec = (mx - mn)/loginess*log10((linspace(0, 10^(loginess) - 1, num)+ 1)) + mn;
% end
% =========================================================================
    nargoutchk(0, 2)
    narginchk(2, 25)
    % check input arguments
    % determine axis handle
    if ishandle(varargin{1}) && ~isnumeric(varargin{1})
        iax = 1;
        axmsg = 'ax, ';
        ax = varargin{1};
    else
        iax = 0;
        axmsg = '';
        ax = gca;
    end
    if nargin < 2+iax
        error(['colorbarpwm(' axmsg 'caxis1, caxis2): not enough input arguments, must specify caxis1 and caxis2.'])
    end
    % assign variables
    caxis1 = varargin{1+iax};
    caxis2 = varargin{2+iax};
    if ~isscalar(caxis1) || ~isscalar(caxis2)
        error(['colorbarpzn(' axmsg 'caxis1, caxis2): caxis1 and caxis2 must be scalars.'])
    end
    if length(varargin) > 2+iax
        options = varargin(3+iax:end);
    else
        options = {};
    end
    % colorbar label
    labelflag = ~isempty(find(strcmp(options, 'label'), 1));
    if labelflag
        if length(options) > find(strcmp(options, 'label'), 1)
            labelpar = options{find(strcmp(options, 'label'), 1)+1};
            if ischar(labelpar)
                labelstr = labelpar;
                ilabel = find(strcmp(options, 'label'), 1);
                options(ilabel+1) = [];
                options(ilabel) = [];
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''label'', ''LaTeXString''): LaTeXString must be a char variable.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''label'', ''LaTeXString''): LaTeXString must be specified.'])
        end
    end
    % default color switch
    dftflag = ~isempty(find(strcmp(options, 'dft'), 1));
    if dftflag
        if length(options) > find(strcmp(options, 'dft'), 1)
            dftpar = options{find(strcmp(options, 'dft'), 1)+1};
            if ischar(dftpar) && length(dftpar) == 3
                precolor = dftpar;
                idft = find(strcmp(options, 'dft'), 1);
                options(idft+1) = [];
                options(idft) = [];
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''dft'', ''colors''): colors must be an 1 X 3 char variable as a combiation of ''r'', ''g'', ''b'',''p'', ''y'',''w'', ''k''.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''dft'', ''colors''): colors must be specified.'])
        end
    end
    % check input arguments
    if length(options) >= 1
        if isempty(find(strcmp(options{1}, {'level', 'colorP', 'colorN', 'colorP2', 'colorN2', 'colorZ', 'log', 'full', 'rev', 'wrs', 'off'}), 1))
            error(['colorbar(' axmsg 'caxis1, caxis2, ' num2str(options{1}) '): invalid input argument ' num2str(options{1}) '.'])
        else
            for i = 2 : length(options)
                if isnumeric(options{i}) && isnumeric(options{i-1}) ...
                   && isempty(find(strcmp(options{i-2}, {'colorP', 'colorN', 'colorZ', 'colorP2', 'colorN2'}), 1))
                    error(['colorbar(' axmsg 'caxis1, caxis2, ' num2str(options{i}) '): invalid input argument ' num2str(options{i}) '.'])
                 elseif ischar(options{i}) ...
                        && isempty(find(strcmp(options{i}, {'level', 'colorP', 'colorN', 'colorP2', 'colorN2', 'colorZ', 'log', 'full', 'rev', 'wrs', 'off'}), 1)) ...
                        && isempty(find(strcmp(options{i-1}, {'colorP', 'colorN', 'colorZ', 'colorP2', 'colorN2'}), 1))
                    error(['colorbar(' axmsg 'caxis1, caxis2, ''' options{i} '''): invalid input argument ''' options{i} '''.'])
                end
            end
        end
    end
    % determine colorbar direction
    if caxis1 < caxis2
        cmin = caxis1;
        cmax = caxis2;
        dirflag = false;
    elseif caxis1 > caxis2
        cmin = caxis2;
        cmax = caxis1;
        dirflag = true;
    else
        error(['colorbarpzn(' axmsg 'caxis1, caxis2): caxis1 must not equal to caxis2.'])
    end
    % full spectrum switch
    fullflag = ~isempty(find(strcmp(options, 'full'), 1));
    % W value specification switch
    if fullflag
        if length(options) > find(strcmp(options, 'full'), 1)
            fullpar = options{find(strcmp(options, 'full'), 1)+1};
            if isscalar(fullpar)
                if fullpar > cmin && fullpar < cmax
                    Wvalue = fullpar;
                else
                    error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''full'', Wvalue): Wvalue must be within cmin < Wvalue < cmax.'])
                end
            elseif ~isscalar(fullpar) && ~ischar(fullpar)
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''full'', Wvalue): Wvalue must be a scalar when specified.'])
            else
                Wvalue = (cmin + cmax)/2;
            end
        else
            Wvalue = (cmin + cmax)/2;
        end
    else
        Wvalue = 0;
    end
    % determine colormap range
    if cmin >= 0 && ~fullflag
        mapflag = 1;
    elseif cmax <= 0 && ~fullflag
        mapflag = -1;
    else
        mapflag = 0;
    end
    % colormap levels
    levelflag = ~isempty(find(strcmp(options, 'level'), 1));
    if levelflag
        if length(options) > find(strcmp(options, 'level'), 1)
            levelpar = options{find(strcmp(options, 'level'), 1)+1};
            if isscalar(levelpar) && isreal(levelpar) && levelpar > 0
                Nlevel = levelpar;
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''level'', Nlevel): Nlevel must be a real positive number.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''level'', Nlevel): Nlevel must be specified.'])
        end
    else
        Nlevel = 127;
    end
    % predefined colors
    red = [0.7, 0.15, 0.0];
    green = [0.32, 0.54, 0.42];
    blue = [0.0, 0.47, 0.72];
    purple = [0.43, 0.29, 0.47];
    yellow = [0.59, 0.42, 0.23];
    white = [1, 1, 1];
    black = [0.15, 0.15, 0.15];
    dftpwn = [red; white; blue]; % default red/positive white/zero blue/negative
    % change default colors with predefined colors
    if dftflag
        for i = 1 : 3
            switch precolor(i)
                case 'r'
                    dftpwn(i, :) = red;
                case 'g'
                    dftpwn(i, :) = green;
                case 'b'
                    dftpwn(i, :) = blue;
                case 'p'
                    dftpwn(i, :) = purple;
                case 'y'
                    dftpwn(i, :) = yellow;
                case 'w'
                    dftpwn(i, :) = white;
                case 'k'
                    dftpwn(i, :) = black;
                otherwise
                    error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''dft'', ''colors''): colors must be an 1 X 3 char variable as a combiation of ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
            end
        end
    end
    % reversed default positive and negative color switch
    revflag = ~isempty(find(strcmp(options, 'rev'), 1));
    if revflag
        if length(options) > find(strcmp(options, 'rev'), 1) ...
           && isnumeric(options{find(strcmp(options, 'rev'), 1)+1})
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ' num2str(options{find(strcmp(options, 'rev'), 1)+1}) ...
                   '): invalid input argument ' num2str(options{find(strcmp(options, 'rev'), 1)+1}) '.'])
        end
        dftP = dftpwn(3, :); % default blue
        dftW = dftpwn(2, :);
        dftN = dftpwn(1, :); % default red
    else
        dftP = dftpwn(1, :); % default red
        dftW = dftpwn(2, :);
        dftN = dftpwn(3, :); % default blue
    end
    % manual color switches
    % colorP
    Pflag = ~isempty(find(strcmp(options, 'colorP'), 1));
    if Pflag
        if length(options) > find(strcmp(options, 'colorP'), 1)
            Ppar = options{find(strcmp(options, 'colorP'), 1)+1};
            if ~ischar(Ppar) && isrow(Ppar) && length(Ppar) == 3
                colorP = Ppar;
            elseif ischar(Ppar) && length(Ppar) == 1
                switch Ppar
                    case 'r'
                        colorP = red;
                    case 'g'
                        colorP = green;
                    case 'b'
                        colorP = blue;
                    case 'p'
                        colorP = purple;
                    case 'y'
                        colorP = yellow;
                    case 'w'
                        colorP = white;
                    case 'k'
                        colorP = black;
                    otherwise
                        error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP'', [R G B]/''color''): ''color'' must be one of the color code: ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
                end
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP'', [R G B]/''color''): colorP parameter must be an 1x3 row array or one of the color code char.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP'', [R G B]/''color''): colorP parameter be specified.'])
        end
    else
        colorP = dftP; % default positive color
    end
    % colorN
    Nflag = ~isempty(find(strcmp(options, 'colorN'), 1));
    if Nflag
        if length(options) > find(strcmp(options, 'colorN'), 1)
            Npar = options{find(strcmp(options, 'colorN'), 1)+1};
            if ~ischar(Npar) && isrow(Npar) && length(Npar) == 3
                colorN = Npar;
            elseif ischar(Npar) && length(Npar) == 1
                switch Npar
                    case 'r'
                        colorN = red;
                    case 'g'
                        colorN = green;
                    case 'b'
                        colorN = blue;
                    case 'p'
                        colorN = purple;
                    case 'y'
                        colorN = yellow;
                    case 'w'
                        colorN = white;
                    case 'k'
                        colorN = black;
                    otherwise
                        error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN'', [R G B]/''color''): ''color'' must be one of the color code: ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
                end
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN'', [R G B]/''color''): colorN parameter must be an 1x3 row array or one of the color code char.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN'', [R G B]/''color''): colorN parameter must be specified.'])
        end
    else
        colorN = dftN; % default negative color
    end
    % colorZ
    Wflag = ~isempty(find(strcmp(options, 'colorZ'), 1));
    if Wflag
        if length(options) > find(strcmp(options, 'colorZ'), 1)
            Wpar = options{find(strcmp(options, 'colorZ'), 1)+1};
            if ~ischar(Wpar) && isrow(Wpar) && length(Wpar) == 3
                colorZ = Wpar;
            elseif ischar(Wpar) && length(Wpar) == 1
                switch Wpar
                    case 'r'
                        colorZ = red;
                    case 'g'
                        colorZ = green;
                    case 'b'
                        colorZ = blue;
                    case 'p'
                        colorZ = purple;
                    case 'y'
                        colorZ = yellow;
                    case 'w'
                        colorZ = white;
                    case 'k'
                        colorZ = black;
                    otherwise
                        error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorZ'', [R G B]/''color''): ''color'' must be one of the color code: ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
                end
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorZ'', [R G B]/''color''): colorZ parameter must be an 1x3 row array or one of the color code char.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorZ'', [R G B]/''color''): colorZ parameter must be specified.'])
        end
    else
        colorZ = dftW; % default white
    end
    % colorP2
    P2flag = ~isempty(find(strcmp(options, 'colorP2'), 1));
    P2ratio = 0;
    colorP2 = colorZ;
    if P2flag
        if length(options) > find(strcmp(options, 'colorP2'), 1)
            P2par = options{find(strcmp(options, 'colorP2'), 1)+1};
            if ~ischar(P2par) && isrow(P2par) && length(P2par) == 3
                colorP2 = P2par;
            elseif ischar(P2par) && length(P2par) == 1
                switch P2par
                    case 'r'
                        colorP2 = red;
                    case 'g'
                        colorP2 = green;
                    case 'b'
                        colorP2 = blue;
                    case 'p'
                        colorP2 = purple;
                    case 'y'
                        colorP2 = yellow;
                    case 'w'
                        colorP2 = white;
                    case 'k'
                        colorP2 = black;
                    otherwise
                        error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP2'', [R G B]/''color''): ''color'' must be one of the color code: ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
                end
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP2'', [R G B]/''color''): colorP parameter must be an 1x3 row array or one of the color code char.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP2'', [R G B]/''color''): colorP2 parameter be specified.'])
        end
        P2ratio = 0.5;
        if length(options) > find(strcmp(options, 'colorP2'), 1)+1
            P2parVal = options{find(strcmp(options, 'colorP2'), 1)+2};
            if ~ischar(P2parVal)
                if isscalar(P2parVal) && isreal(P2parVal) && (((P2parVal > Wvalue)&&(mapflag==0))||((P2parVal > cmin)&&(mapflag~=0))) && P2parVal < cmax
                    if mapflag == 0
                        P2ratio = (P2parVal - Wvalue)/(cmax - Wvalue);
                    else
                        P2ratio = (P2parVal - cmin)/(cmax - cmin);
                    end
                else
                    error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorP2'', [R G B]/''color'', P2value): P2value must be a real number between Wvalue (or cmin) and cmax.'])
                end
            end
        end
    end
    P2level = round(P2ratio*Nlevel);
    if P2level < 1 && P2level > 0
        P2level = 1;
    end
    % colorN2
    N2flag = ~isempty(find(strcmp(options, 'colorN2'), 1));
    N2ratio = 0;
    colorN2 = colorZ;
    if N2flag
        if length(options) > find(strcmp(options, 'colorN2'), 1)
            N2par = options{find(strcmp(options, 'colorN2'), 1)+1};
            if ~ischar(N2par) && isrow(N2par) && length(N2par) == 3
                colorN2 = N2par;
            elseif ischar(N2par) && length(N2par) == 1
                switch N2par
                    case 'r'
                        colorN2 = red;
                    case 'g'
                        colorN2 = green;
                    case 'b'
                        colorN2 = blue;
                    case 'p'
                        colorN2 = purple;
                    case 'y'
                        colorN2 = yellow;
                    case 'w'
                        colorN2 = white;
                    case 'k'
                        colorN2 = black;
                    otherwise
                        error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN2'', [R G B]/''color''): ''color'' must be one of the color code: ''r'', ''g'', ''b'', ''p'', ''y'', ''w'', ''k''.'])
                end
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN2'', [R G B]/''color''): colorP parameter must be an 1x3 row array or one of the color code char.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN2'', [R G B]/''color''): colorN2 parameter be specified.'])
        end
        N2ratio = 0.5;
        if length(options) > find(strcmp(options, 'colorN2'), 1)+1
            N2parVal = options{find(strcmp(options, 'colorN2'), 1)+2};
            if ~ischar(N2parVal)
                if isscalar(N2parVal) && isreal(N2parVal) && N2parVal > cmin && (((N2parVal < Wvalue)&&(mapflag == 0))||((N2parVal < cmax)&&(mapflag~=0)))
                    if mapflag == 0
                        N2ratio = (N2parVal - Wvalue)/(cmin - Wvalue);
                    else
                        N2ratio = (N2parVal - cmax)/(cmin - cmax);
                    end
                else
                    error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''colorN2'', [R G B]/''color'', N2value): N2value must be a real number between cmin and Wvalue (or cmax).'])
                end
            end
        end
    end
    N2level = round(N2ratio*Nlevel);
    if N2level < 1 && N2level > 0
        N2level = 1;
    end
   
    % log scale colormap switch
    logflag = ~isempty(find(strcmp(options, 'log'), 1));
    % loginess value specification switch
    if logflag
        if length(options) > find(strcmp(options, 'log'), 1)
            logpar = options{find(strcmp(options, 'log'), 1)+1};
            if isscalar(logpar)
                if logpar ~= 0
                    loginess = logpar;
                else
                    error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''log'', loginess): loginess must not be zero.'])
                end
            elseif ~isscalar(logpar) && ~ischar(logpar)
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''log'', loginess): loginess must a scalar when specified.'])
            else
                loginess = 1;
            end
        else
            loginess = 1;
        end
        nonLinspace = @(mn, mx, num) round((mx - mn)/loginess*log10((linspace(0, 10^(loginess) - 1, num)+ 1)) + mn, 4); % citation [1]
    end
    % white region size
    wrsflag = ~isempty(find(strcmp(options, 'wrs'), 1));
    if wrsflag
        if length(options) > find(strcmp(options, 'wrs'), 1)
            wrspar = options{find(strcmp(options, 'wrs'), 1)+1};
            if ~ischar(wrspar) && isscalar(wrspar) && isreal(wrspar) && wrspar > 0 && wrspar < 1
                WhiteRegionSize = wrspar;
            else
                error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''wrs'', WhiteRegionSize): WhiteRegionSize must be a real number between 0 and 1.'])
            end
        else
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ''wrs'', WhiteRegionSize): WhiteRegionSize must be specified.'])
        end
    else
        WhiteRegionSize = 1/Nlevel;
    end
    % generate colormap
    Wlevel = round(WhiteRegionSize*Nlevel);
    if Wlevel < 1
        Wlevel = 1;
    end
    Nlevel = Nlevel-Wlevel+1;
    if logflag
        switch mapflag
            case 1
                mapP2 = [nonLinspace(colorZ(1), colorP2(1), P2level)', nonLinspace(colorZ(2), colorP2(2), P2level)', nonLinspace(colorZ(3), colorP2(3), P2level)'];
                mapP1 = [nonLinspace(colorP2(1), colorP(1), Nlevel-P2level)', nonLinspace(colorP2(2), colorP(2), Nlevel-P2level)', nonLinspace(colorP2(3), colorP(3), Nlevel-P2level)'];
                cmap = [repmat(colorZ, Wlevel-1, 1); mapP2(1:end, :); mapP1];
            case -1
                mapN2 = [nonLinspace(colorZ(1), colorN2(1), N2level)', nonLinspace(colorZ(2), colorN2(2), N2level)', nonLinspace(colorZ(3), colorN2(3), N2level)'];
                mapN1 = [nonLinspace(colorN2(1), colorN(1), Nlevel-N2level)', nonLinspace(colorN2(2), colorN(2), Nlevel-N2level)', nonLinspace(colorP2(3), colorP(3), Nlevel-N2level)'];
                cmap = flip([repmat(colorZ, Wlevel-1, 1); mapN2(1:end, :); mapN1]);
            case 0
                if abs(cmax-Wvalue) >= abs(cmin-Wvalue)
                    cratio = abs((cmin-Wvalue)/(cmax-Wvalue));
                    Nfactored = ceil(floor(cratio*Nlevel/(1+cratio)));
                    Nlevel = Nlevel - Nfactored;
                    P2level = round(P2ratio*Nlevel);
                    N2level = round(N2ratio*Nfactored);
                    if P2level < 1 && P2level > 0
                        P2level = 1;
                    end
                    if N2level < 1 && N2level > 0
                        N2level = 1;
                    end
                    mapP2 = [nonLinspace(colorZ(1), colorP2(1), P2level)', nonLinspace(colorZ(2), colorP2(2), P2level)', nonLinspace(colorZ(3), colorP2(3), P2level)'];
                    mapP1 = [nonLinspace(colorP2(1), colorP(1), Nlevel-P2level)', nonLinspace(colorP2(2), colorP(2), Nlevel-P2level)', nonLinspace(colorP2(3), colorP(3), Nlevel-P2level)'];
                    mapN2 = [nonLinspace(colorZ(1), colorN2(1), N2level)', nonLinspace(colorZ(2), colorN2(2), N2level)', nonLinspace(colorZ(3), colorN2(3), N2level)'];
                    mapN1 = [nonLinspace(colorN2(1), colorN(1), Nfactored+1-N2level)', nonLinspace(colorN2(2), colorN(2), Nfactored+1-N2level)', nonLinspace(colorN2(3), colorN(3), Nfactored+1-N2level)'];
                else
                    cratio = abs((cmax-Wvalue)/(cmin-Wvalue));
                    Nfactored = ceil(floor(cratio*Nlevel/(1+cratio)));
                    Nlevel = Nlevel - Nfactored;
                    P2level = round(P2ratio*Nfactored);
                    N2level = round(N2ratio*Nlevel);
                    if P2level < 1 && P2level > 0
                        P2level = 1;
                    end
                    if N2level < 1 && N2level > 0
                        N2level = 1;
                    end
                    mapP2 = [nonLinspace(colorZ(1), colorP2(1), P2level)', nonLinspace(colorZ(2), colorP2(2), P2level)', nonLinspace(colorZ(3), colorP2(3), P2level)'];
                    mapP1 = [nonLinspace(colorP2(1), colorP(1), Nfactored+1-P2level)', nonLinspace(colorP2(2), colorP(2), Nfactored+1-P2level)', nonLinspace(colorP2(3), colorP(3), Nfactored+1-P2level)'];
                    mapN2 = [nonLinspace(colorZ(1), colorN2(1), N2level)', nonLinspace(colorZ(2), colorN2(2), N2level)', nonLinspace(colorZ(3), colorN2(3), N2level)'];
                    mapN1 = [nonLinspace(colorN2(1), colorN(1), Nlevel-N2level)', nonLinspace(colorN2(2), colorN(2), Nlevel-N2level)', nonLinspace(colorN2(3), colorN(3), Nlevel-N2level)'];
                end
                mapPN = [flip(mapN1(2:end, :)); flip(mapN2(2:end, :)); repmat(colorZ, Wlevel, 1); mapP2(2:end, :); mapP1(2:end, :)];
                cmap = mapPN;
        end
    else
        switch mapflag
            case 1
                mapP2 = [linspace(colorZ(1), colorP2(1), P2level)', linspace(colorZ(2), colorP2(2), P2level)', linspace(colorZ(3), colorP2(3), P2level)'];
                mapP1 = [linspace(colorP2(1), colorP(1), Nlevel-P2level)', linspace(colorP2(2), colorP(2), Nlevel-P2level)', linspace(colorP2(3), colorP(3), Nlevel-P2level)'];
                cmap = [repmat(colorZ, Wlevel, 1); mapP2(2:end, :); mapP1(2:end, :)];
            case -1
                mapN2 = [linspace(colorZ(1), colorN2(1), N2level)', linspace(colorZ(2), colorN2(2), N2level)', linspace(colorZ(3), colorN2(3), N2level)'];
                mapN1 = [linspace(colorN2(1), colorN(1), Nlevel-N2level)', linspace(colorN2(2), colorN(2), Nlevel-N2level)', linspace(colorN2(3), colorN(3), Nlevel-N2level)'];
                cmap = flip([repmat(colorZ, Wlevel, 1); mapN2(2:end, :); mapN1(2:end, :)]);
            case 0
                if abs(cmax-Wvalue) >= abs(cmin-Wvalue)
                    cratio = abs((cmin-Wvalue)/(cmax-Wvalue));
                    Nfactored = ceil(floor(cratio*Nlevel/(1+cratio)));
                    Nlevel = Nlevel - Nfactored;
                    P2level = round(P2ratio*Nlevel);
                    N2level = round(N2ratio*Nfactored);
                    if P2level < 1 && P2level > 0
                        P2level = 1;
                    end
                    if N2level < 1 && N2level > 0
                        N2level = 1;
                    end
                    mapP2 = [linspace(colorZ(1), colorP2(1), P2level+1)', linspace(colorZ(2), colorP2(2), P2level+1)', linspace(colorZ(3), colorP2(3), P2level+1)'];
                    mapP1 = [linspace(colorP2(1), colorP(1), Nlevel-P2level)', linspace(colorP2(2), colorP(2), Nlevel-P2level)', linspace(colorP2(3), colorP(3), Nlevel-P2level)'];
                    mapN2 = [linspace(colorZ(1), colorN2(1), N2level+1)', linspace(colorZ(2), colorN2(2), N2level+1)', linspace(colorZ(3), colorN2(3), N2level+1)'];
                    mapN1 = [linspace(colorN2(1), colorN(1), Nfactored+1-N2level)', linspace(colorN2(2), colorN(2), Nfactored+1-N2level)', linspace(colorN2(3), colorN(3), Nfactored+1-N2level)'];
                else
                    cratio = abs((cmax-Wvalue)/(cmin-Wvalue));
                    Nfactored = ceil(floor(cratio*Nlevel/(1+cratio)));
                    Nlevel = Nlevel - Nfactored;
                    P2level = round(P2ratio*Nfactored);
                    N2level = round(N2ratio*Nlevel);
                    if P2level < 1 && P2level > 0
                        P2level = 1;
                    end
                    if N2level < 1 && N2level > 0
                        N2level = 1;
                    end
                    mapP2 = [linspace(colorZ(1), colorP2(1), P2level+1)', linspace(colorZ(2), colorP2(2), P2level+1)', linspace(colorZ(3), colorP2(3), P2level+1)'];
                    mapP1 = [linspace(colorP2(1), colorP(1), Nfactored+1-P2level)', linspace(colorP2(2), colorP(2), Nfactored+1-P2level)', linspace(colorP2(3), colorP(3), Nfactored+1-P2level)'];
                    mapN2 = [linspace(colorZ(1), colorN2(1), N2level+1)', linspace(colorZ(2), colorN2(2), N2level+1)', linspace(colorZ(3), colorN2(3), N2level+1)'];
                    mapN1 = [linspace(colorN2(1), colorN(1), Nlevel-N2level)', linspace(colorN2(2), colorN(2), Nlevel-N2level)', linspace(colorN2(3), colorN(3), Nlevel-N2level)'];
                end
                mapPN = [flip(mapN1(2:end, :)); flip(mapN2(2:end, :)); repmat(colorZ, Wlevel, 1); mapP2(2:end, :); mapP1(2:end, :)];
                cmap = mapPN;
        end
    end
    % colorbar display switch
    offflag = ~isempty(find(strcmp(options, 'off'), 1));
    if offflag
        if length(options) > find(strcmp(options, 'off'), 1) ...
           && isnumeric(options{find(strcmp(options, 'off'), 1)+1})
            error(['colorbarpzn(' axmsg 'caxis1, caxis2, ' num2str(options{find(strcmp(options, 'off'), 1)+1}) ...
                   '): invalid input argument ' num2str(options{find(strcmp(options, 'off'), 1)+1}) '.'])
        end
        % output
        colormap(ax, cmap)
        caxis([cmin, cmax])
        if nargout == 2
            error(['[h, cmap] = colorbarpzn(' axmsg 'caxis1, caxis2, ''off''): cannot return colarbar handle h with input argument ''off''.'])
        elseif nargout == 1
            varargout{1} = cmap;
        end
    end
    % output
    if ~offflag
        colormap(ax, cmap)
        caxis([cmin, cmax])
        cb = colorbar(ax);
        cb.Label.Interpreter = 'latex';
        if labelflag
            cb.Label.String = labelstr;
        end
        if dirflag
            cb.Direction = 'rev';
        end
        % colorbar handle
        if nargout == 1
            varargout{1} = cb;
        elseif nargout == 2
            varargout{1} = cb;
            varargout{2} = cmap;
        end
    end
end