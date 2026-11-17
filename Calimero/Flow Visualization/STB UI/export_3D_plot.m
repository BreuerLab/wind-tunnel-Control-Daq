function export_3D_plot(varargin)
% EXPORT_3D_PLOT  Export a 3D MATLAB figure as two aligned layers for Illustrator.
%
%   export_3D_plot()                       exports gcf to 'figure_data.png' / 'figure_text.pdf'
%   export_3D_plot(fig)                    exports the given figure
%   export_3D_plot(fig, basename)          writes <basename>_data.png and <basename>_text.pdf
%   export_3D_plot(fig, basename, dpi)     sets the raster resolution (default 600)
%   export_3D_plot(..., show_axes)         show_axes = false hides the axes
%                                          (lines, ticks, tick labels, axis
%                                          labels, title) in the PDF. Legends,
%                                          colorbars, text() and annotation()
%                                          objects are still exported.
%   export_3D_plot(false)                  gcf, default names, axes hidden
%
% Dense 3D graphics (surfaces, patches, isosurfaces, scatter3) give huge
% vector files that Illustrator struggles to open. This function splits the
% figure into:
%   <basename>_data.png  - the plotted data only (raster, high resolution)
%   <basename>_text.pdf  - axes, ticks, labels, titles, legends, colorbars,
%                          text() and annotation() objects (vector, editable)
%
% Both are rendered with PRINT (not EXPORTGRAPHICS) so they cover the same
% full-figure area and line up exactly. Both have transparent backgrounds:
% the PDF has no figure or axes background, and the PNG gets an alpha channel
% computed by rendering the data on white and on black (exact, including
% anti-aliased edges). The axis limits and camera are frozen
% during the export so text() objects stay in place when the data is hidden.
% The figure is restored to its original state afterwards.
%
% In Illustrator: open <basename>_text.pdf, File > Place <basename>_data.png
% (100% scale), align it to the artboard's top-left corner and send it to the back.
%
% LaTeX text: MATLAB's LaTeX interpreter uses its own Computer Modern fonts
% (mwa_cmr10, mwa_cmmi10, ...). Illustrator only displays them correctly if
% they are installed on the system. Install every .ttf in
%   fullfile(matlabroot, 'sys', 'fonts', 'ttf', 'cm')
% then restart Illustrator.

% A trailing logical/true-false argument is show_axes; the rest is positional
show_axes = true;
args = varargin;
if ~isempty(args) && (islogical(args{end}) && isscalar(args{end}))
    show_axes = args{end};
    args(end) = [];
end
args(end+1:3) = {[]};
[fig, basename, resolution] = args{1:3};

if isempty(fig),        fig = gcf;            end
if isempty(basename),   basename = 'figure';  end
if isempty(resolution), resolution = 600;     end

% Drop any extension the user passed
[p, n] = fileparts(basename);
basename = fullfile(p, n);
png_file = [basename '_data.png'];
pdf_file = [basename '_text.pdf'];

drawnow

% ------------------------------------------------------------------ objects
axs = findall(fig, 'Type', 'axes');
lg  = findall(fig, 'Type', 'legend');
cb  = findall(fig, 'Type', 'colorbar');
ann = findall(fig, 'Type', 'annotationpane');   % annotation() overlay

kids = allchild(axs);
if iscell(kids), kids = vertcat(kids{:}); end
txt   = findall(kids, 'flat', 'Type', 'text');   % text() placed on the plot
lgt   = findall(kids, 'flat', 'Type', 'light');  % keep lights on for the raster
data  = kids(~ismember(kids, [txt; lgt]));      % everything that is plotted data

% Titles/subtitles stay visible when an axes is turned off, so handle them
% separately
titles = gobjects(0, 1);
for a = axs'
    titles(end+1, 1) = a.Title; %#ok<AGROW>
    if isprop(a, 'Subtitle'), titles(end+1, 1) = a.Subtitle; end %#ok<AGROW>
end

overlay = [axs; titles; lg; cb; txt; ann];       % hidden in the raster layer

% Remember original visibility so we restore exactly what was there
all_objs = [overlay; data];
orig_vis = get(all_objs, 'Visible');
if ~iscell(orig_vis), orig_vis = {orig_vis}; end

% ------------------------------------------- freeze limits and the 3D camera
% Only the limits are frozen. With the limits fixed, the automatic camera and
% aspect ratio no longer change when the data is hidden. Setting the camera or
% aspect-ratio properties manually would switch off MATLAB's stretch-to-fill
% and change the shape of the plot relative to what is on screen.
frozen_props = {'XLim','YLim','ZLim'};
orig_modes = cell(numel(axs), numel(frozen_props));
for i = 1:numel(axs)
    for j = 1:numel(frozen_props)
        orig_modes{i,j} = axs(i).([frozen_props{j} 'Mode']);
        axs(i).(frozen_props{j}) = axs(i).(frozen_props{j});  % sets *Mode = manual
    end
end

% ------------------------------------------------- remember figure settings
S.fig          = fig;
S.all_objs     = all_objs;
S.orig_vis     = orig_vis;
S.axs          = axs;
S.frozen_props = frozen_props;
S.orig_modes   = orig_modes;
S.paper_mode   = fig.PaperPositionMode;
S.paper_units  = fig.PaperUnits;
S.paper_size   = fig.PaperSize;
S.paper_pos    = fig.PaperPosition;
S.fig_color    = fig.Color;
S.invert_hc    = fig.InvertHardcopy;
S.ax_color     = get(axs, 'Color');
if ~iscell(S.ax_color), S.ax_color = {S.ax_color}; end

% Restore the figure on exit, including after an error. The anonymous
% function captures S by value, because the main function's workspace is
% already gone when onCleanup runs.
cleanup = onCleanup(@() restore_figure(S));

% Make the PDF page exactly the figure size (print otherwise puts the figure
% on a full letter/A4 page) and render the PNG at the same physical size.
fig_units  = fig.Units;
fig.Units  = 'inches';
fig_in     = fig.Position(3:4);
fig.Units  = fig_units;
fig.PaperUnits        = 'inches';
fig.PaperPositionMode = 'manual';
fig.PaperSize         = fig_in;
fig.PaperPosition     = [0 0 fig_in];
fig.InvertHardcopy    = 'off';    % keep the colours we set below

% ---------------------------------------------------- layer 1: data (raster)
% Render twice, on white and on black, and recover colour + alpha:
%   W = a*C + (1-a)*1,  B = a*C   =>   a = 1 - (W - B),  C = B / a
set(overlay, 'Visible', 'off')
res = sprintf('-r%d', resolution);

fig.Color = 'w';
W = double(print(fig, '-RGBImage', res)) / 255;
fig.Color = 'k';
B = double(print(fig, '-RGBImage', res)) / 255;

alpha = 1 - mean(W - B, 3);
alpha = min(max(alpha, 0), 1);
C = B ./ max(alpha, eps);
C = min(max(C, 0), 1);
% Tag the PNG with its resolution so Illustrator places it at the same
% physical size as the PDF (without this it assumes 72 ppi).
ppm = resolution / 0.0254;        % pixels per metre
imwrite(C, png_file, 'Alpha', alpha, 'ResolutionUnit', 'meter', ...
        'XResolution', ppm, 'YResolution', ppm);

% ------------------------------------------- layer 2: text and axes (vector)
restore_visibility(all_objs, orig_vis)
set(data, 'Visible', 'off')
if ~show_axes
    set([axs; titles], 'Visible', 'off')
end
fig.Color = 'none';               % no figure background rectangle
set(axs, 'Color', 'none')         % no axes background box
try
    print(fig, pdf_file, '-dpdf', '-vector')      % R2021b and later
catch
    print(fig, pdf_file, '-dpdf', '-painters')    % older releases
end

fprintf('Wrote %s\nWrote %s\n', png_file, pdf_file);
end

% ------------------------------------------------------------ local functions
function restore_visibility(all_objs, orig_vis)
for k = 1:numel(all_objs)
    if isvalid(all_objs(k))
        all_objs(k).Visible = orig_vis{k};
    end
end
end

function restore_figure(S)
if ~isvalid(S.fig), return, end
restore_visibility(S.all_objs, S.orig_vis)
for ii = 1:numel(S.axs)
    if ~isvalid(S.axs(ii)), continue, end
    S.axs(ii).Color = S.ax_color{ii};
    for jj = 1:numel(S.frozen_props)
        S.axs(ii).([S.frozen_props{jj} 'Mode']) = S.orig_modes{ii,jj};
    end
end
S.fig.Color             = S.fig_color;
S.fig.InvertHardcopy    = S.invert_hc;
S.fig.PaperUnits        = S.paper_units;
S.fig.PaperSize         = S.paper_size;
S.fig.PaperPosition     = S.paper_pos;
S.fig.PaperPositionMode = S.paper_mode;
end
