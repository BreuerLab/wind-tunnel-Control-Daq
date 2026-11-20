%% wing_geometry_analysis.m
% Wing planform geometry from photos of each wing lying flat next to a
% ruler (face up and face down). For every photo: silhouette, chord
% distribution c(r) and summary statistics (wing_planform_geometry.m). Then
% the photos of each wing are averaged and the left and right wings
% compared.
%
% All planforms are put in the same frame (root at r = 0 on the left,
% leading edge on top), so face-up / face-down photos and left / right
% wings overlay directly. The difference between the face-up and face-down
% photos of one wing is a useful estimate of the measurement error.
%
% Outputs (in outDir):
%   <photo>_planform.png      summary figure per photo
%   <photo>_silhouette.png    binary planform (1 px = 1/pxPerMm mm)
%   wing_geometry_photos.csv  statistics per photo
%   wing_geometry_wings.csv   statistics per wing (mean of its photos,
%                             and the face-up/face-down spread)
%   wing_chord_distributions.csv  c(r) of every photo and wing mean on a
%                             common 0.25 mm grid
%   wing_geometry.mat         everything, including chord functions
%   chord_comparison.png      c(r) overlay

clear; clc; close all

%% ---------------- user settings ----------------
imageDir = "";        % folder with the photos ("" = choose with a dialog)

% file name, wing, face. Edit to match your photos.
photos = [
    "left_up.jpg",    "left",  "up"
    "left_down.jpg",  "left",  "down"
    "right_up.jpg",   "right", "up"
    "right_down.jpg", "right", "down"
];

opts = struct();
opts.rootOffset_mm = 0;       % flapping axis to wing root, for r1hat/r2hat/r3hat
opts.spanAxis = "ruler";      % or "leadingEdge"
opts.rootSide = "auto";       % "left"/"right" if auto gets it wrong
opts.leadingEdge = "auto";    % "top"/"bottom" if auto gets it wrong
opts.manualCalibration = false; % true: click the ruler yourself
% opts.pxPerMm = 11.40;       % force a scale
opts.plot = true;
opts.verbose = true;

dr = 0.25;                    % grid for the averaged chord distributions (mm)
saveOutputs = true;

%% ---------------- run ----------------
if imageDir == ""
    imageDir = string(uigetdir(pwd, "Folder with the wing photos"));
    if imageDir == "0", return, end
end
outDir = fullfile(imageDir, "wing_geometry_results");
if saveOutputs && ~isfolder(outDir), mkdir(outDir); end

nP = size(photos, 1);
geos = cell(nP, 1);
for k = 1:nP
    f = fullfile(imageDir, photos(k,1));
    geos{k} = wing_planform_geometry(f, opts);
    if saveOutputs
        [~, base] = fileparts(photos(k,1));
        if isfield(geos{k}, 'fig') && isgraphics(geos{k}.fig)
            exportgraphics(geos{k}.fig, fullfile(outDir, base + "_planform.png"), 'Resolution', 150);
        end
        imwrite(geos{k}.mask, fullfile(outDir, base + "_silhouette.png"));
    end
end

%% ---------------- per-photo table ----------------
statNames = fieldnames(geos{1}.stats);
T = table(photos(:,1), photos(:,2), photos(:,3), 'VariableNames', ["File", "Wing", "Face"]);
for s = 1:numel(statNames)
    T.(statNames{s}) = cellfun(@(g) g.stats.(statNames{s}), geos);
end
T.pxPerMm = cellfun(@(g) g.pxPerMm, geos);
T.scaleVariation_pct = cellfun(@(g) 100*g.scaleInfo.localVariation, geos);

disp(' ');
disp('Per photo:');
disp(T(:, ["Wing", "Face", "area_mm2", "span_mm", "chordMax_mm", "chordMean_mm", ...
    "chordMedian_mm", "spanMax_mm", "spanMean_mm", "spanMedian_mm", "aspectRatio", "r2hat"]));

%% ---------------- per-wing average ----------------
wings = unique(photos(:,2), 'stable');
numVars = ["area_mm2", "span_mm", "chordMax_mm", "chordMean_mm", "chordMedian_mm", ...
    "spanMax_mm", "spanMean_mm", "spanMedian_mm", "meanGeomChord_mm", "aspectRatio", ...
    "r1hat", "r2hat", "r3hat"];
TW = table(wings, 'VariableNames', "Wing");
TW.nPhotos = arrayfun(@(w) nnz(photos(:,2) == w), wings);
for v = numVars
    TW.(v)            = arrayfun(@(w) mean(T.(v)(T.Wing == w)), wings);
    TW.(v + "_spread") = arrayfun(@(w) max(T.(v)(T.Wing == w)) - min(T.(v)(T.Wing == w)), wings);
end
disp('Per wing (mean of its photos; *_spread = max - min between photos):');
disp(TW(:, ["Wing", "nPhotos", "area_mm2", "area_mm2_spread", "span_mm", "span_mm_spread", ...
    "chordMax_mm", "chordMean_mm", "chordMedian_mm", "spanMax_mm", "spanMean_mm", ...
    "spanMedian_mm", "aspectRatio", "r2hat"]));

% chord distributions on a common grid
Rmax = max(T.span_mm);
rGrid = (0:dr:ceil(Rmax/dr)*dr).';
C = zeros(numel(rGrid), nP);
for k = 1:nP
    C(:,k) = geos{k}.chordFun(rGrid);
end
Cw = zeros(numel(rGrid), numel(wings));
for w = 1:numel(wings)
    Cw(:,w) = mean(C(:, photos(:,2) == wings(w)), 2);
end
% chord function of each wing (mean of its photos)
wingChordFun = cell(numel(wings), 1);
for w = 1:numel(wings)
    cw = Cw(:,w);
    wingChordFun{w} = @(r) interp1(rGrid, cw, r, 'linear', 0);
end

%% ---------------- plots ----------------
cols = lines(nP);
faceStyles = ["-", "--"];   % face up: solid, face down: dashed
figC = figure('Name', 'Chord comparison', 'Color', 'w', 'Position', [100 100 1100 750]);
tlC = tiledlayout(figC, 2, 1, 'TileSpacing', 'compact');

ax = nexttile(tlC); hold(ax, 'on'); grid(ax, 'on')
for k = 1:nP
    ls = faceStyles(1 + (photos(k,3) == "down"));
    plot(ax, geos{k}.r_mm, geos{k}.chordSmooth_mm, ls, 'Color', cols(k,:), 'LineWidth', 1.2, ...
        'DisplayName', photos(k,2) + " / " + photos(k,3));
end
xlabel(ax, 'spanwise r from root (mm)'); ylabel(ax, 'chord c(r) (mm)');
title(ax, 'Chord distribution, every photo'); legend(ax, 'Location', 'northeast');

ax = nexttile(tlC); hold(ax, 'on'); grid(ax, 'on')
wc = lines(numel(wings));
for w = 1:numel(wings)
    sel = find(photos(:,2) == wings(w));
    lo = min(C(:,sel), [], 2); hi = max(C(:,sel), [], 2);
    fill(ax, [rGrid; flipud(rGrid)], [lo; flipud(hi)], wc(w,:), 'FaceAlpha', 0.2, ...
        'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(ax, rGrid, Cw(:,w), 'Color', wc(w,:), 'LineWidth', 1.8, 'DisplayName', wings(w) + " wing (mean)");
end
xlabel(ax, 'spanwise r from root (mm)'); ylabel(ax, 'chord c(r) (mm)');
title(ax, 'Mean chord per wing (band = spread between photos)'); legend(ax, 'Location', 'northeast');

% silhouettes overlaid (canonical frame)
figS = figure('Name', 'Silhouette overlay', 'Color', 'w', 'Position', [150 150 1100 450]);
axS = axes(figS); hold(axS, 'on'); axis(axS, 'equal'); grid(axS, 'on'); set(axS, 'YDir', 'reverse')
for k = 1:nP
    g = geos{k};
    B = bwboundaries(g.mask, 'noholes');
    [~, kb] = max(cellfun(@(b) size(b,1), B));
    b = B{kb};
    ls = faceStyles(1 + (photos(k,3) == "down"));
    plot(axS, (b(:,2) - 0.5)/g.pxPerMm, (b(:,1) - 0.5)/g.pxPerMm, ls, 'Color', cols(k,:), ...
        'LineWidth', 1.2, 'DisplayName', photos(k,2) + " / " + photos(k,3));
end
xlabel(axS, 'spanwise r from root (mm)'); ylabel(axS, 'chordwise x from LE (mm)');
title(axS, 'Planforms (root left, leading edge up)'); legend(axS, 'Location', 'southwest');

%% ---------------- save ----------------
if saveOutputs
    writetable(T, fullfile(outDir, "wing_geometry_photos.csv"));
    writetable(TW, fullfile(outDir, "wing_geometry_wings.csv"));
    TC = array2table([rGrid C Cw], 'VariableNames', ...
        ["r_mm", photos(:,2).' + "_" + photos(:,3).', wings.' + "_mean"]);
    writetable(TC, fullfile(outDir, "wing_chord_distributions.csv"));
    exportgraphics(figC, fullfile(outDir, "chord_comparison.png"), 'Resolution', 150);
    exportgraphics(figS, fullfile(outDir, "silhouette_overlay.png"), 'Resolution', 150);
    geosNoFig = cellfun(@(g) rmfield(g, intersect(fieldnames(g), {'fig'})), geos, 'UniformOutput', false);
    save(fullfile(outDir, "wing_geometry.mat"), 'geosNoFig', 'T', 'TW', 'rGrid', 'C', 'Cw', ...
        'wings', 'photos', 'wingChordFun', 'opts');
    fprintf('\nResults saved to %s\n', outDir);
end
