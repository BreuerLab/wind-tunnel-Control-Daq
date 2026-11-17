function outFile = exportFigPNG(fig, outFile, opts)
%EXPORTFIGPNG Export a 2D MATLAB figure as a high-resolution PNG at a fixed size.
%
%   exportFigPNG()                         exports gcf, asks where to save
%   exportFigPNG(fig)                      exports fig, asks where to save
%   exportFigPNG(fig, 'name.png')          figure sized to 800 x 600, 300 dpi
%   exportFigPNG(fig, 'name.png', 'Size', [1200 800])
%   exportFigPNG(fig, 'name.png', 'Size', [1200 800], 'DPI', 600)
%   exportFigPNG(fig, 'Preview', true)     only resize the figure, no export
%   exportFigPNG(fig, 'name.png', 'Margin', 20)   keep a 20 px white border
%
%   Size is the figure's [width height] in MATLAB position units (pixels),
%   the same units as fig.Position. The open figure is resized to that size
%   (keeping its top-left corner in place) and stays that size after the
%   export, so what you see on screen is what gets saved. Use 'Preview' to
%   resize first, adjust the legend or labels, then export.
%
%   The saved image is cropped tightly to the plotted content (axes, tick
%   labels, title, legend, colorbar), so empty figure margins are left out.
%   Its pixel dimensions are therefore at most Size / (screen ppi) * DPI;
%   on Windows (96 ppi), 800 x 600 at 300 dpi gives at most 2500 x 1875 px.

    arguments
        fig = gcf
        outFile {mustBeTextScalar} = ''
        opts.Size (1,2) double {mustBePositive} = [800 600]   % [width height], MATLAB position pixels
        opts.DPI  (1,1) double {mustBePositive} = 300
        opts.Preview (1,1) logical = false
        opts.Margin (1,1) double {mustBeNonnegative, mustBeInteger} = 0  % white border kept around content, image pixels
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

    % exportgraphics crops tightly around the plotted content (axes, labels,
    % legend, colorbar), so empty figure margins are not saved
    exportgraphics(fig, outFile, ...
        'Resolution', opts.DPI, ...
        'BackgroundColor', 'white');

    % exportgraphics' bounding box can still include empty space, e.g. from
    % invisible objects spanning the figure, so trim any white border left
    % in the saved image as well
    trimWhiteBorder(outFile, opts.Margin, opts.DPI);

    info = imfinfo(outFile);
    fprintf('Saved %s (figure %d x %d, image %d x %d px, %g dpi)\n', ...
        outFile, opts.Size(1), opts.Size(2), info.Width, info.Height, opts.DPI);
end

function trimWhiteBorder(file, margin, dpi)
    img = imread(file);
    % A pixel counts as content if any channel is noticeably darker than white
    content = any(img < 250, 3);
    rows = find(any(content, 2));
    cols = find(any(content, 1));
    if isempty(rows), return; end   % blank image, leave as is

    [h, w, ~] = size(img);
    r1 = max(rows(1)   - margin, 1);  r2 = min(rows(end) + margin, h);
    c1 = max(cols(1)   - margin, 1);  c2 = min(cols(end) + margin, w);
    if r1 == 1 && c1 == 1 && r2 == h && c2 == w, return; end   % nothing to trim

    ppm = round(dpi / 0.0254);      % keep the dpi tag in the PNG
    imwrite(img(r1:r2, c1:c2, :), file, ...
        'ResolutionUnit', 'meter', 'XResolution', ppm, 'YResolution', ppm);
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
