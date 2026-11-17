function export_3D_plot(fig, basename, resolution)
% EXPORT_3D_PLOT  Export a 3D MATLAB figure as two aligned layers for Illustrator.
%
%   export_3D_plot()                       exports gcf to 'figure_data.png' / 'figure_text.pdf'
%   export_3D_plot(fig)                    exports the given figure
%   export_3D_plot(fig, basename)          writes <basename>_data.png and <basename>_text.pdf
%   export_3D_plot(fig, basename, dpi)     sets the raster resolution (default 600)
%
% Dense 3D graphics (surfaces, patches, isosurfaces, scatter3) give huge
% vector files that Illustrator struggles to open. This function splits the
% figure into:
%   <basename>_data.png  - the plotted data only (raster, high resolution)
%   <basename>_text.pdf  - axes, ticks, labels, titles, legends, colorbars,
%                          text() and annotation() objects (vector, editable)
%
% Both are written with PRINT (not EXPORTGRAPHICS) so they cover the same
% full-figure area and line up exactly. The axis limits and camera are frozen
% during the export so text() objects stay in place when the data is hidden.
% The figure is restored to its original state afterwards.
%
% In Illustrator: open <basename>_text.pdf, File > Place <basename>_data.png,
% scale it to the artboard width, snap it to the corner and send it to the back.
%
% LaTeX text: MATLAB's LaTeX interpreter uses its own Computer Modern fonts
% (mwa_cmr10, mwa_cmmi10, ...). Illustrator only displays them correctly if
% they are installed on the system. Install every .ttf in
%   fullfile(matlabroot, 'sys', 'fonts', 'ttf', 'cm')
% then restart Illustrator.

if nargin < 1 || isempty(fig),        fig = gcf;            end
if nargin < 2 || isempty(basename),   basename = 'figure';  end
if nargin < 3 || isempty(resolution), resolution = 600;     end

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

overlay = [axs; lg; cb; txt; ann];               % hidden in the raster layer

% Remember original visibility so we restore exactly what was there
all_objs = [overlay; data];
orig_vis = get(all_objs, 'Visible');
if ~iscell(orig_vis), orig_vis = {orig_vis}; end

% ------------------------------------------- freeze limits and the 3D camera
frozen_props = {'XLim','YLim','ZLim','CameraPosition','CameraTarget', ...
                'CameraUpVector','CameraViewAngle','DataAspectRatio', ...
                'PlotBoxAspectRatio'};
orig_modes = cell(numel(axs), numel(frozen_props));
for i = 1:numel(axs)
    for j = 1:numel(frozen_props)
        orig_modes{i,j} = axs(i).([frozen_props{j} 'Mode']);
        axs(i).(frozen_props{j}) = axs(i).(frozen_props{j});  % sets *Mode = manual
    end
end

orig_paper_mode = fig.PaperPositionMode;
fig.PaperPositionMode = 'auto';   % print at on-screen size

cleanup = onCleanup(@() restore_figure());

% ---------------------------------------------------- layer 1: data (raster)
set(overlay, 'Visible', 'off')
print(fig, png_file, '-dpng', sprintf('-r%d', resolution))

% ------------------------------------------- layer 2: text and axes (vector)
restore_visibility()
set(data, 'Visible', 'off')
try
    print(fig, pdf_file, '-dpdf', '-vector')      % R2021b and later
catch
    print(fig, pdf_file, '-dpdf', '-painters')    % older releases
end

fprintf('Wrote %s\nWrote %s\n', png_file, pdf_file);

% ------------------------------------------------------------------ helpers
    function restore_visibility()
        for k = 1:numel(all_objs)
            if isvalid(all_objs(k))
                all_objs(k).Visible = orig_vis{k};
            end
        end
    end

    function restore_figure()
        if ~isvalid(fig), return, end
        restore_visibility()
        for ii = 1:numel(axs)
            if ~isvalid(axs(ii)), continue, end
            for jj = 1:numel(frozen_props)
                axs(ii).([frozen_props{jj} 'Mode']) = orig_modes{ii,jj};
            end
        end
        fig.PaperPositionMode = orig_paper_mode;
    end
end
