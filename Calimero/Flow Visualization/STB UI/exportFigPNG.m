function outFile = exportFigPNG(fig, outFile, opts)
%EXPORTFIGPNG Export a 2D MATLAB figure as a high-resolution PNG at a fixed size.
%
%   exportFigPNG()                         exports gcf, asks where to save
%   exportFigPNG(fig)                      exports fig, asks where to save
%   exportFigPNG(fig, 'name.png')          figure sized to 1000 x 600, 300 dpi
%   exportFigPNG(fig, 'name.png', 'Size', [1200 800])
%   exportFigPNG(fig, 'name.png', 'Size', [1200 800], 'DPI', 600)
%   exportFigPNG(fig, 'Preview', true)     only resize the figure, no export
%
%   Size is the figure's [width height] in MATLAB position units (pixels),
%   the same units as fig.Position. The open figure is resized to that size
%   (keeping its top-left corner in place) and stays that size after the
%   export, so what you see on screen is what gets saved. Use 'Preview' to
%   resize first, adjust the legend or labels, then export.
%
%   The PNG's pixel dimensions are Size / (screen ppi) * DPI. On Windows
%   (96 ppi), 1000 x 600 at 300 dpi gives about 3125 x 1875 px.

    arguments
        fig = gcf
        outFile {mustBeTextScalar} = ''
        opts.Size (1,2) double {mustBePositive} = [800 600]   % [width height], MATLAB position pixels
        opts.DPI  (1,1) double {mustBePositive} = 300
        opts.Preview (1,1) logical = false
    end

    % Resize the open figure to the export size and leave it that way
    resizeFigure(fig, opts.Size);

    if opts.Preview
        fprintf('Figure resized to %d x %d (preview only, nothing saved)\n', opts.Size);
        outFile = '';
        return
    end

    % Ask for a file name if none was given
    if strlength(outFile) == 0
        [f, p] = uiputfile('*.png', 'Save figure as PNG', 'figure.png');
        if isequal(f, 0)
            outFile = '';
            disp('Export cancelled (figure was still resized).');
            return
        end
        outFile = fullfile(p, f);
    end
    [p, n, ~] = fileparts(char(outFile));
    outFile = fullfile(p, [n '.png']);

    % Print settings, restored afterwards
    old.PaperPositionMode = fig.PaperPositionMode;
    old.InvertHardcopy    = fig.InvertHardcopy;
    restore = onCleanup(@() restorePrintSettings(fig, old)); %#ok<NASGU>
    fig.PaperPositionMode = 'auto';   % print at the on-screen size
    fig.InvertHardcopy    = 'on';     % white background

    print(fig, outFile, '-dpng', sprintf('-r%d', round(opts.DPI)));

    info = imfinfo(outFile);
    fprintf('Saved %s (figure %d x %d, image %d x %d px, %g dpi)\n', ...
        outFile, opts.Size(1), opts.Size(2), info.Width, info.Height, opts.DPI);
end

function resizeFigure(fig, sz)
    if strcmp(fig.WindowStyle, 'docked')
        fig.WindowStyle = 'normal';   % docked figures can't be resized
        drawnow;
    end
    oldUnits = fig.Units;
    fig.Units = 'pixels';
    pos = fig.Position;
    top = pos(2) + pos(4);                      % keep the top-left corner fixed
    fig.Position = [pos(1), top - sz(2), sz(1), sz(2)];
    fig.Units = oldUnits;
    drawnow;
end

function restorePrintSettings(fig, old)
    if ~isvalid(fig), return; end
    fig.PaperPositionMode = old.PaperPositionMode;
    fig.InvertHardcopy    = old.InvertHardcopy;
end