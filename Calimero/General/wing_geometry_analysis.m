%% wing_geometry_analysis.m
% MAIN SCRIPT: wing planform geometry from photos and from the CAD file.
%
%   photos  -> wing_planform_geometry.m  (photo of each wing next to a
%              ruler, face up and face down)
%   CAD     -> cad_planform_geometry.m   (DXF of the laser-cut outline,
%              with the material beyond the fold lines cut off)
% Both use wing_mask_geometry.m for the measurements, so the definitions
% (root edge on r = 0, chord parallel to the root, statistics) are identical
% and the numbers can be compared one to one.
%
% For every photo: silhouette, chord distribution c(r) and summary
% statistics. The photos of each wing are averaged (the face-up/face-down
% spread is an estimate of the photo measurement error) and then compared
% with the CAD geometry: the difference shows how folding along the LE and
% tip, and scrunching of the membrane, change the real wing.
%
% Outputs (in outDir):
%   <photo>_planform.png      summary figure per photo
%   <photo>_silhouette.png    binary planform (1 px = 1/pxPerMm mm)
%   cad_planform.png          summary figure of the CAD outline
%   wing_geometry_photos.csv  statistics per photo
%   wing_geometry_wings.csv   statistics per wing (mean of its photos,
%                             and the face-up/face-down spread)
%   wing_geometry_vs_cad.csv  CAD vs each wing, with % differences
%   wing_chord_distributions.csv  c(r) of every photo, wing means and CAD
%                             on a common grid
%   wing_geometry.mat         everything, including chord functions
%   chord_comparison.png, silhouette_overlay.png

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

% CAD outline: DXF (recommended) of the planform after folding, i.e. cut at
% the fold-line notches. A file name is looked up in imageDir if it is not
% found as given. "" = no CAD comparison.
cadFile = "wing_planform.dxf";

opts = struct();
opts.rootOffset_mm = 0;       % flapping axis to wing root, for r1hat/r2hat/r3hat
opts.spanAxis = "rootNormal"; % r = 0 along the root edge; or "ruler" / "leadingEdge"
opts.rootSide = "auto";       % "left"/"right" if auto gets it wrong
opts.leadingEdge = "auto";    % "top"/"bottom" if auto gets it wrong
opts.manualCalibration = false; % true: click the ruler yourself
% opts.pxPerMm = 11.40;       % force a scale
opts.plot = true;
opts.verbose = true;

cadOpts = opts;               % same measurement settings for the CAD
cadOpts.units = "auto";       % from the DXF header; "mm"/"in" to override
cadOpts.layers = [];          % e.g. "CUT" to use only that layer
cadOpts.resolution = 10;      % px/mm of the raster the CAD outline is measured on
cadOpts.rotation_deg = [];    % [] = auto (longest straight edge = LE along x)

dr = 0.25;                    % grid for the averaged chord distributions (mm)
saveOutputs = true;

%% ---------------- photos ----------------
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

%% ---------------- CAD ----------------
haveCad = strlength(cadFile) > 0;
geoCAD = [];
if haveCad
    if ~isfile(cadFile) && isfile(fullfile(imageDir, cadFile))
        cadFile = fullfile(imageDir, cadFile);
    end
    if ~isfile(cadFile)
        warning("CAD file '%s' not found; skipping the CAD comparison.", cadFile);
        haveCad = false;
    else
        geoCAD = cad_planform_geometry(cadFile, cadOpts);
        if saveOutputs && isfield(geoCAD, 'fig') && isgraphics(geoCAD.fig)
            exportgraphics(geoCAD.fig, fullfile(outDir, "cad_planform.png"), 'Resolution', 150);
        end
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
disp(T(:, ["Wing", "Face", "area_mm2", "span_mm", "rootChord_mm", "chordMax_mm", "chordMean_mm", ...
    "chordMedian_mm", "spanMax_mm", "spanMean_mm", "spanMedian_mm", "aspectRatio", "r2hat"]));

%% ---------------- per-wing average ----------------
wings = unique(photos(:,2), 'stable');
numVars = ["area_mm2", "span_mm", "rootChord_mm", "chordMax_mm", "chordMean_mm", "chordMedian_mm", ...
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
    "rootChord_mm", "chordMax_mm", "chordMean_mm", "chordMedian_mm", "spanMax_mm", "spanMean_mm", ...
    "spanMedian_mm", "aspectRatio", "r2hat"]));

%% ---------------- photos vs CAD ----------------
TCad = table();
if haveCad
    TCad = table(numVars.', 'VariableNames', "Quantity");
    TCad.CAD = arrayfun(@(v) geoCAD.stats.(v), numVars.');
    for w = 1:numel(wings)
        wv = arrayfun(@(v) TW.(v)(w), numVars.');
        TCad.(wings(w)) = wv;
        TCad.(wings(w) + "_spread") = arrayfun(@(v) TW.(v + "_spread")(w), numVars.');
        TCad.(wings(w) + "_vs_CAD_pct") = 100*(wv - TCad.CAD)./TCad.CAD;
    end
    disp('Photos vs CAD (wing = mean of its photos; % = (wing - CAD)/CAD):');
    disp(TCad);
    fprintf('CAD polygon area (exact) %.1f mm^2; raster %.1f mm^2\n', ...
        geoCAD.stats.areaPolygon_mm2, geoCAD.stats.area_mm2);
end

%% ---------------- chord distributions on a common grid ----------------
Rmax = max(T.span_mm);
if haveCad, Rmax = max(Rmax, geoCAD.stats.span_mm); end
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
if haveCad
    Ccad = geoCAD.chordFun(rGrid);
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
if haveCad
    plot(ax, rGrid, Ccad, 'k-', 'LineWidth', 1.8, 'DisplayName', 'CAD');
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
if haveCad
    plot(ax, rGrid, Ccad, 'k--', 'LineWidth', 1.8, 'DisplayName', 'CAD');
end
xlabel(ax, 'spanwise r from root (mm)'); ylabel(ax, 'chord c(r) (mm)');
title(ax, 'Mean chord per wing (band = spread between photos)'); legend(ax, 'Location', 'northeast');

% silhouettes overlaid (canonical frame)
figS = figure('Name', 'Silhouette overlay', 'Color', 'w', 'Position', [150 150 1100 450]);
axS = axes(figS); hold(axS, 'on'); axis(axS, 'equal'); grid(axS, 'on'); set(axS, 'YDir', 'reverse')
allGeo = geos; names = photos(:,2) + " / " + photos(:,3);
styles = faceStyles(1 + (photos(:,3) == "down")); colsAll = cols;
if haveCad
    allGeo{end+1} = geoCAD; names(end+1) = "CAD";
    styles(end+1) = "-"; colsAll(end+1,:) = [0 0 0];
end
for k = 1:numel(allGeo)
    g = allGeo{k};
    B = bwboundaries(g.mask, 'noholes');
    [~, kb] = max(cellfun(@(b) size(b,1), B));
    b = B{kb};
    plot(axS, (b(:,2) - 0.5)/g.pxPerMm, (b(:,1) - 0.5)/g.pxPerMm, styles(k), 'Color', colsAll(k,:), ...
        'LineWidth', 1.2 + 0.6*(names(k) == "CAD"), 'DisplayName', names(k));
end
xlabel(axS, 'spanwise r from root (mm)'); ylabel(axS, 'chordwise x from LE (mm)');
title(axS, 'Planforms (root left, leading edge up)'); legend(axS, 'Location', 'southwest');

%% ---------------- save ----------------
if saveOutputs
    writetable(T, fullfile(outDir, "wing_geometry_photos.csv"));
    writetable(TW, fullfile(outDir, "wing_geometry_wings.csv"));
    chordNames = ["r_mm", photos(:,2).' + "_" + photos(:,3).', wings.' + "_mean"];
    chordData = [rGrid C Cw];
    if haveCad
        writetable(TCad, fullfile(outDir, "wing_geometry_vs_cad.csv"));
        chordNames(end+1) = "CAD";
        chordData = [chordData Ccad];
    end
    writetable(array2table(chordData, 'VariableNames', chordNames), ...
        fullfile(outDir, "wing_chord_distributions.csv"));
    exportgraphics(figC, fullfile(outDir, "chord_comparison.png"), 'Resolution', 150);
    exportgraphics(figS, fullfile(outDir, "silhouette_overlay.png"), 'Resolution', 150);
    stripFig = @(g) rmfield(g, intersect(fieldnames(g), {'fig'}));
    geosNoFig = cellfun(stripFig, geos, 'UniformOutput', false);
    if haveCad, geoCAD = stripFig(geoCAD); end
    save(fullfile(outDir, "wing_geometry.mat"), 'geosNoFig', 'geoCAD', 'T', 'TW', 'TCad', ...
        'rGrid', 'C', 'Cw', 'wings', 'photos', 'wingChordFun', 'opts', 'cadOpts');
    fprintf('\nResults saved to %s\n', outDir);
end
