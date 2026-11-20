function geo = cad_planform_geometry(cadFile, opts)
% CAD_PLANFORM_GEOMETRY  Chord distribution and planform statistics of the
% wing from its CAD outline, measured exactly like the photos (same shared
% function, wing_mask_geometry), so the numbers can be compared directly.
%
%   geo = cad_planform_geometry("wing.dxf")
%   geo = cad_planform_geometry("wing.dxf", opts)
%   geo = cad_planform_geometry("wing.png", struct('pngPxPerMm', 20))
%
% Input
%   DXF (recommended): ASCII DXF of the planform as it should be after
%   folding, i.e. with the material beyond the fold lines (LE fold, tip
%   fold) already cut off. Supported entities: LINE, ARC, CIRCLE,
%   LWPOLYLINE, POLYLINE (incl. arc bulges), SPLINE, ELLIPSE. Blocks
%   (INSERT) are not expanded: explode them before exporting. The pieces
%   are chained end to end into closed loops; the loop enclosing the
%   largest area is the outline. Holes (bolt holes etc.) are ignored, i.e.
%   counted as wing, as they are covered by washers.
%   PNG (fallback): black wing on white (or set pngInvert), with its scale
%   in opts.pngPxPerMm.
%
% opts (all optional; plus the shared ones of wing_mask_geometry:
%       rootSide, leadingEdge, spanAxis, rootCut, rootOffset_mm, verbose)
%   .units          'auto' (default: from the DXF header $INSUNITS, mm if
%                   unset) | 'mm' | 'cm' | 'm' | 'in'
%   .layers         [] (default: all) or list of layer names to use
%   .chainTol_mm    0.05 (default) end points closer than this are joined
%   .resolution     10 (default) px/mm of the raster the outline is
%                   measured on (0.1 mm pixels; geo.stats.areaPolygon_mm2
%                   is the exact polygon area for comparison)
%   .rotation_deg   [] (default: auto, the longest straight edge (the LE)
%                   is put along x) or the angle (deg, CCW) of the span
%                   direction in the drawing
%   .pngPxPerMm     scale of a PNG input (required for PNG)
%   .pngInvert      false (default); true for a white wing on black
%   .plot           true (default)
%
% geo: same fields as wing_planform_geometry (mask, r_mm, chord_mm,
% chordFun, stats, ...) plus
%   .outline_mm   outline polygon in drawing coordinates (mm)
%   .cadInfo      units, scale, entity/loop counts, exact polygon area,
%                 rotation applied
%   .stats.areaPolygon_mm2  area of the polygon itself (no rasterization)

    if nargin < 2, opts = struct(); end
    opts = setDefaults(opts);
    cadFile = string(cadFile);
    [~, name, ext] = fileparts(cadFile);

    %% ---------------- outline polygon (mm) ----------------
    switch lower(ext)
        case ".dxf"
            [P, info, pieces] = readDxfOutline(cadFile, opts);
        case {".png", ".tif", ".tiff", ".bmp", ".jpg", ".jpeg"}
            [P, info] = readImageOutline(cadFile, opts);
            pieces = {P};
        otherwise
            error("cad_planform_geometry:format", ...
                "Unsupported CAD format '%s'. Export the outline as DXF (or PNG).", ext);
    end
    P = P(all(isfinite(P), 2), :);
    info.areaPolygon_mm2 = polyarea(P(:,1), P(:,2));

    %% ---------------- span direction along x ----------------
    if isempty(opts.rotation_deg)
        theta = dominantDirection(P);
    else
        theta = opts.rotation_deg;
    end
    info.rotation_deg = theta;
    Rm = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    Q = P*Rm;                  % rotates the drawing by -theta

    %% ---------------- rasterize ----------------
    res = opts.resolution;
    pad = 5;
    xmin = min(Q(:,1)); ymax = max(Q(:,2));
    cols = (Q(:,1) - xmin)*res + 0.5 + pad;
    rows = (ymax - Q(:,2))*res + 0.5 + pad;      % y up in CAD, rows down
    W = ceil(max(cols)) + pad;
    H = ceil(max(rows)) + pad;
    M = poly2mask(cols, rows, H, W);
    M = imfill(M, 'holes');

    %% ---------------- measure ----------------
    geo = wing_mask_geometry(M, res, opts, "CAD: " + name + ext);
    geo = rmfield(geo, 'frameMask');
    geo.file = cadFile;
    geo.pxPerMm = res;
    geo.outline_mm = P;
    geo.cadInfo = info;
    geo.stats.areaPolygon_mm2 = info.areaPolygon_mm2;
    if opts.verbose
        fprintf('  CAD              %s units (x%.4g to mm), %d pieces -> %d loops; polygon area %.1f mm^2 (raster %+.2f%%)\n', ...
            info.units, info.scale, info.nPieces, info.nLoops, info.areaPolygon_mm2, ...
            100*(geo.stats.area_mm2/info.areaPolygon_mm2 - 1));
    end

    if opts.plot
        geo.fig = plotCad(geo, pieces, name + ext);
    end
end

%% ======================================================================
function opts = setDefaults(opts)
    d = struct('units', 'auto', 'layers', [], 'chainTol_mm', 0.05, 'resolution', 10, ...
        'rotation_deg', [], 'pngPxPerMm', [], 'pngInvert', false, 'plot', true, 'verbose', true);
    f = fieldnames(d);
    for k = 1:numel(f)
        if ~isfield(opts, f{k})
            opts.(f{k}) = d.(f{k});
        end
    end
    if isempty(opts.resolution), opts.resolution = 10; end
    if isempty(opts.chainTol_mm), opts.chainTol_mm = 0.05; end
    if isempty(opts.units), opts.units = 'auto'; end
end

%% ======================================================================
function [P, info, pieces] = readDxfOutline(file, opts)
    txt = fileread(file);
    if startsWith(txt, "AutoCAD Binary DXF")
        error("cad_planform_geometry:binaryDxf", "Binary DXF is not supported; export as ASCII DXF.");
    end
    L = regexp(txt, '\r\n|\n|\r', 'split');
    if mod(numel(L), 2) == 1, L(end) = []; end
    codes = str2double(strtrim(L(1:2:end)));
    vals = strtrim(L(2:2:end));

    % ---- units ----
    insunits = 0;
    k = find(strcmp(vals, '$INSUNITS'), 1);
    if ~isempty(k) && k < numel(vals) && codes(k+1) == 70
        insunits = str2double(vals{k+1});
    end
    if strcmpi(opts.units, 'auto')
        switch insunits
            case 1, u = 'in';
            case 2, u = 'ft';
            case 4, u = 'mm';
            case 5, u = 'cm';
            case 6, u = 'm';
            otherwise, u = 'unitless';
        end
        if strcmp(u, 'unitless')
            warning("cad_planform_geometry:units", ...
                "DXF has no units ($INSUNITS); assuming mm. Set opts.units if not.");
            u = 'mm';
        end
    else
        u = lower(char(opts.units));
    end
    switch u
        case 'mm', scale = 1;
        case 'cm', scale = 10;
        case 'm',  scale = 1000;
        case 'in', scale = 25.4;
        case 'ft', scale = 304.8;
        otherwise, error("cad_planform_geometry:units", "Unknown units '%s'", u);
    end

    % ---- ENTITIES section ----
    iSec = find(codes == 2 & strcmp(vals, 'ENTITIES'), 1);
    if isempty(iSec)
        error("cad_planform_geometry:noEntities", "No ENTITIES section in %s", file);
    end
    iEnd = iSec + find(codes(iSec+1:end) == 0 & strcmp(vals(iSec+1:end), 'ENDSEC'), 1);
    starts = iSec + find(codes(iSec+1:iEnd) == 0);      % entity headers
    tolArc = 0.01/scale;          % chord error for arcs, in drawing units

    pieces = {};      % each: Nx2 points (drawing units)
    closedP = [];     % closed flag per piece
    skipped = strings(0);
    k = 1;
    while k < numel(starts)
        i0 = starts(k); i1 = starts(k+1) - 1;
        type = vals{i0};
        c = codes(i0+1:i1); v = vals(i0+1:i1);
        if ~layerOK(c, v, opts.layers) && ~strcmp(type, 'POLYLINE')
            k = k + 1; continue
        end
        pts = []; isClosed = false;
        switch type
            case 'LINE'
                pts = [num(c,v,10) num(c,v,20); num(c,v,11) num(c,v,21)];
            case 'ARC'
                pts = arcPts([num(c,v,10) num(c,v,20)], num(c,v,40), ...
                    num(c,v,50), num(c,v,51), tolArc);
                pts = ocs(pts, c, v);
            case 'CIRCLE'
                pts = arcPts([num(c,v,10) num(c,v,20)], num(c,v,40), 0, 360, tolArc);
                pts = ocs(pts(1:end-1,:), c, v);
                isClosed = true;
            case 'ELLIPSE'
                pts = ellipsePts(c, v, tolArc);
                isClosed = abs(mod(num(c,v,42) - num(c,v,41), 2*pi)) < 1e-9;
            case 'LWPOLYLINE'
                [pts, isClosed] = lwpolyPts(c, v, tolArc);
                pts = ocs(pts, c, v);
            case 'SPLINE'
                [pts, isClosed] = splinePts(c, v);
            case 'POLYLINE'
                % header, then VERTEX entities until SEQEND
                flag = num(c,v,70); if isnan(flag), flag = 0; end
                useIt = layerOK(c, v, opts.layers);
                vx = []; bulge = [];
                k = k + 1;
                while k < numel(starts) && strcmp(vals{starts(k)}, 'VERTEX')
                    j0 = starts(k); j1 = starts(k+1) - 1;
                    cc = codes(j0+1:j1); vv = vals(j0+1:j1);
                    vf = num(cc,vv,70); if isnan(vf), vf = 0; end
                    if ~bitand(vf, 16)          % skip spline frame points
                        vx(end+1,:) = [num(cc,vv,10) num(cc,vv,20)]; %#ok<AGROW>
                        b = num(cc,vv,42); if isnan(b), b = 0; end
                        bulge(end+1,1) = b; %#ok<AGROW>
                    end
                    k = k + 1;
                end
                isClosed = bitand(flag, 1) > 0;
                if useIt && size(vx,1) > 1
                    pts = bulgePolyline(vx, bulge, isClosed, tolArc);
                end
                k = k - 1;        % k now at SEQEND (or the next entity - 1)
            case {'TEXT', 'MTEXT', 'DIMENSION', 'POINT', 'HATCH', 'SEQEND', 'VERTEX', 'VIEWPORT'}
                % not geometry
            otherwise
                skipped(end+1) = string(type); %#ok<AGROW>
        end
        if size(pts, 1) > 1
            pieces{end+1} = pts*scale; %#ok<AGROW>
            closedP(end+1) = isClosed; %#ok<AGROW>
        end
        k = k + 1;
    end
    if ~isempty(skipped)
        warning("cad_planform_geometry:skipped", "Ignored DXF entities: %s%s", ...
            strjoin(unique(skipped), ", "), ...
            sprintf(" (explode blocks/INSERTs before exporting)"));
    end
    if isempty(pieces)
        error("cad_planform_geometry:empty", "No usable geometry in %s", file);
    end

    loops = chainPieces(pieces, logical(closedP), opts.chainTol_mm);
    areas = cellfun(@(q) abs(polyarea(q(:,1), q(:,2))), loops);
    [~, kOut] = max(areas);
    P = loops{kOut};
    info = struct('units', string(u), 'scale', scale, 'nPieces', numel(pieces), ...
        'nLoops', numel(loops), 'areaPolygon_mm2', NaN, 'rotation_deg', NaN);
end

%% ----------------------------------------------------------------------
function ok = layerOK(c, v, layers)
    ok = true;
    if isempty(layers), return, end
    lay = v(c == 8);
    ok = ~isempty(lay) && any(strcmpi(lay{1}, cellstr(string(layers))));
end

function x = num(c, v, code)
    i = find(c == code, 1);
    if isempty(i), x = NaN; else, x = str2double(v{i}); end
end

function x = nums(c, v, code)
    x = str2double(v(c == code));
    x = x(:);
end

function pts = ocs(pts, c, v)
% Entities drawn with extrusion (0,0,-1) (e.g. mirrored in CAD) are
% mirrored in x in their object coordinate system.
    ez = num(c, v, 230);
    if ~isnan(ez) && ez < 0
        pts(:,1) = -pts(:,1);
    end
end

function pts = arcPts(cen, r, a1, a2, tol)
    sweep = mod(a2 - a1, 360);
    if sweep < 1e-9, sweep = 360; end
    step = 2*acosd(max(-1, 1 - tol/r));
    nSeg = max(8, ceil(sweep/max(step, 0.05)));
    a = a1 + linspace(0, sweep, nSeg + 1).';
    pts = cen + r*[cosd(a) sind(a)];
end

function pts = ellipsePts(c, v, tol)
    cen = [num(c,v,10) num(c,v,20)];
    maj = [num(c,v,11) num(c,v,21)];
    ratio = num(c,v,40);
    t1 = num(c,v,41); t2 = num(c,v,42);
    if isnan(t1), t1 = 0; end
    if isnan(t2), t2 = 2*pi; end
    sweep = mod(t2 - t1, 2*pi);
    if sweep < 1e-9, sweep = 2*pi; end
    a = norm(maj);
    ez = num(c, v, 230);
    if ~isnan(ez) && ez < 0
        mn = ratio*[maj(2) -maj(1)];     % extrusion (0,0,-1): clockwise
    else
        mn = ratio*[-maj(2) maj(1)];
    end
    nSeg = max(16, ceil(sweep/(2*acos(max(-1, 1 - tol/a)))));
    t = t1 + linspace(0, sweep, nSeg + 1).';
    pts = cen + cos(t)*maj + sin(t)*mn;
end

function [pts, isClosed] = lwpolyPts(c, v, tol)
    flag = num(c,v,70); if isnan(flag), flag = 0; end
    isClosed = bitand(flag, 1) > 0;
    vx = zeros(0, 2); bulge = zeros(0, 1);
    for i = 1:numel(c)
        switch c(i)
            case 10
                vx(end+1,:) = [str2double(v{i}) NaN]; %#ok<AGROW>
                bulge(end+1,1) = 0; %#ok<AGROW>
            case 20
                vx(end,2) = str2double(v{i});
            case 42
                bulge(end) = str2double(v{i});
        end
    end
    pts = bulgePolyline(vx, bulge, isClosed, tol);
end

function pts = bulgePolyline(vx, bulge, isClosed, tol)
% Polyline whose segment i (vertex i -> i+1) is an arc when bulge(i) ~= 0
% (bulge = tan(included angle/4), > 0 counter-clockwise).
    n = size(vx, 1);
    nSegs = n - 1 + isClosed;
    pts = vx(1,:);
    for i = 1:nSegs
        p1 = vx(i,:); p2 = vx(mod(i, n) + 1, :);
        b = bulge(i);
        if abs(b) < 1e-12 || norm(p2 - p1) == 0
            pts(end+1,:) = p2; %#ok<AGROW>
            continue
        end
        th = 4*atan(b);                      % signed included angle
        d = p2 - p1; ch = norm(d);
        nrm = [-d(2) d(1)]/ch;               % left of p1 -> p2
        cen = (p1 + p2)/2 + nrm*(ch/2)/tan(th/2);
        r = norm(p1 - cen);
        a1 = atan2(p1(2) - cen(2), p1(1) - cen(1));
        nSeg = max(4, ceil(abs(th)/(2*acos(max(-1, 1 - tol/r)))));
        a = a1 + th*(1:nSeg).'/nSeg;
        pts = [pts; cen + r*[cos(a) sin(a)]]; %#ok<AGROW>
    end
end

function [pts, isClosed] = splinePts(c, v)
    flag = num(c,v,70); if isnan(flag), flag = 0; end
    isClosed = bitand(flag, 1) > 0;
    p = num(c,v,71);
    U = nums(c,v,40);
    w = nums(c,v,41);
    Pc = [nums(c,v,10) nums(c,v,20)];
    Pf = [nums(c,v,11) nums(c,v,21)];
    nC = size(Pc, 1);
    if nC > p && numel(U) == nC + p + 1
        if numel(w) ~= nC, w = ones(nC, 1); end
        nS = max(200, 30*nC);
        u = linspace(U(p+1), U(nC+1), nS).';
        pts = zeros(nS, 2);
        Pw = [Pc.*w, w];                      % homogeneous control points
        for j = 1:nS
            pts(j,:) = deBoor(u(j), p, U, Pw, nC);
        end
    elseif size(Pf, 1) > 1
        % fit points only: interpolate with a cubic through them
        s = [0; cumsum(hypot(diff(Pf(:,1)), diff(Pf(:,2))))];
        ss = linspace(0, s(end), max(200, 20*size(Pf,1))).';
        pts = [spline(s, Pf(:,1), ss) spline(s, Pf(:,2), ss)];
    else
        pts = [];
    end
end

function pt = deBoor(u, p, U, Pw, nC)
% Point of a (rational) B-spline at parameter u (homogeneous de Boor).
    k = find(U(1:nC) <= u, 1, 'last');       % knot span, p+1 <= k <= nC
    k = min(max(k, p + 1), nC);
    d = Pw(k-p:k, :);
    for r = 1:p
        for j = p+1:-1:r+1
            i = k - p + j - 1;
            den = U(i + p - r + 1) - U(i);
            if den == 0, a = 0; else, a = (u - U(i))/den; end
            d(j,:) = (1 - a)*d(j-1,:) + a*d(j,:);
        end
    end
    pt = d(p+1, 1:2)/d(p+1, 3);
end

function loops = chainPieces(pieces, isClosed, tol)
% Join open pieces end to end into closed loops.
    loops = pieces(isClosed);
    open = pieces(~isClosed);
    used = false(1, numel(open));
    openChains = {};
    for k0 = 1:numel(open)
        if used(k0), continue, end
        used(k0) = true;
        ch = open{k0};
        closed = false;
        while true
            if norm(ch(end,:) - ch(1,:)) <= tol && size(ch,1) > 2
                closed = true; break
            end
            found = false;
            for j = find(~used)
                q = open{j};
                if norm(q(1,:) - ch(end,:)) <= tol
                    ch = [ch; q(2:end,:)];
                elseif norm(q(end,:) - ch(end,:)) <= tol
                    ch = [ch; flipud(q(1:end-1,:))];
                elseif norm(q(end,:) - ch(1,:)) <= tol
                    ch = [q(1:end-1,:); ch];
                elseif norm(q(1,:) - ch(1,:)) <= tol
                    ch = [flipud(q(2:end,:)); ch];
                else
                    continue
                end
                used(j) = true; found = true;
                break
            end
            if ~found, break, end
        end
        if closed
            loops{end+1} = ch; %#ok<AGROW>
        else
            openChains{end+1} = ch; %#ok<AGROW>
        end
    end
    if ~isempty(openChains)
        % close an open chain whose ends nearly meet (gap < 2% of its length)
        for k = 1:numel(openChains)
            ch = openChains{k};
            len = sum(hypot(diff(ch(:,1)), diff(ch(:,2))));
            gap = norm(ch(end,:) - ch(1,:));
            if gap < 0.02*len && size(ch, 1) > 2
                loops{end+1} = ch; %#ok<AGROW>
                warning("cad_planform_geometry:gap", ...
                    "Outline had a %.3f mm gap; closed it. Check opts.chainTol_mm.", gap);
            end
        end
    end
    if isempty(loops)
        error("cad_planform_geometry:notClosed", ...
            "Could not chain the DXF geometry into a closed outline (try a larger opts.chainTol_mm).");
    end
end

%% ======================================================================
function [P, info] = readImageOutline(file, opts)
    if isempty(opts.pngPxPerMm)
        error("cad_planform_geometry:pngScale", "Set opts.pngPxPerMm for an image input.");
    end
    I = im2double(imread(file));
    if size(I,3) == 4, I = I(:,:,1:3); end
    if size(I,3) == 3, I = rgb2gray(I); end
    BW = I < 0.5;
    if opts.pngInvert, BW = ~BW; end
    BW = bwareafilt(imfill(BW, 'holes'), 1);
    B = bwboundaries(BW, 'noholes');
    b = B{1};
    P = [b(:,2), -b(:,1)]/opts.pngPxPerMm;      % y up, mm
    info = struct('units', "image", 'scale', 1/opts.pngPxPerMm, 'nPieces', 1, ...
        'nLoops', 1, 'areaPolygon_mm2', NaN, 'rotation_deg', NaN);
end

%% ======================================================================
function theta = dominantDirection(P)
% Direction (deg, 0..180) of the longest straight edge: length-weighted
% histogram of the outline's segment directions. For the wing this is the
% leading edge.
    d = diff([P; P(1,:)]);
    len = hypot(d(:,1), d(:,2));
    ang = mod(atan2d(d(:,2), d(:,1)), 180);
    edges = 0:0.25:180;
    h = accumarray(min(floor(ang/0.25) + 1, numel(edges) - 1), len, [numel(edges) - 1, 1]);
    [~, i] = max(h);                              % one straight edge = one bin
    a0 = (i - 0.5)*0.25;
    dAng = mod(ang - a0 + 90, 180) - 90;          % wrap around 0/180
    sel = abs(dAng) <= 0.3;
    theta = a0 + sum(dAng(sel).*len(sel))/sum(len(sel));
end

%% ======================================================================
function fig = plotCad(geo, pieces, label)
    fig = figure('Name', "CAD planform: " + label, 'Color', 'w', 'Position', [100 100 1300 750]);
    tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, "CAD: " + label, 'Interpreter', 'none');

    ax1 = nexttile(tl, 1, [1 2]); hold(ax1, 'on'); axis(ax1, 'equal'); grid(ax1, 'on')
    for k = 1:numel(pieces)
        plot(ax1, pieces{k}(:,1), pieces{k}(:,2), '-', 'Color', [0.7 0.7 0.7]);
    end
    P = geo.outline_mm;
    plot(ax1, P([1:end 1],1), P([1:end 1],2), 'k-', 'LineWidth', 1.5);
    xlabel(ax1, 'x (mm)'); ylabel(ax1, 'y (mm)');
    title(ax1, sprintf('Drawing (outline in black); span direction %.2f deg', geo.cadInfo.rotation_deg));

    ax2 = nexttile(tl, 3);
    imagesc(ax2, [geo.r_mm(1) geo.r_mm(end)], [geo.x_mm(1) geo.x_mm(end)], double(~geo.mask));
    colormap(ax2, gray); axis(ax2, 'image'); hold(ax2, 'on')
    plot(ax2, geo.r_mm, geo.xLE_mm, 'b-', geo.r_mm, geo.xTE_mm, 'r-', 'LineWidth', 1);
    xlabel(ax2, 'spanwise r from root (mm)'); ylabel(ax2, 'chordwise x (mm)');
    title(ax2, sprintf('S = %.0f mm^2, R = %.1f mm, AR = %.2f', ...
        geo.stats.area_mm2, geo.stats.span_mm, geo.stats.aspectRatio));

    ax3 = nexttile(tl, 4);
    plot(ax3, geo.r_mm, geo.chord_mm, 'k-', 'LineWidth', 1.5); hold(ax3, 'on')
    yline(ax3, geo.stats.chordMean_mm, 'b--', 'mean');
    yline(ax3, geo.stats.chordMedian_mm, 'r:', 'median');
    grid(ax3, 'on'); xlim(ax3, [0 geo.stats.span_mm]);
    xlabel(ax3, 'spanwise r from root (mm)'); ylabel(ax3, 'chord c(r) (mm)');
    title(ax3, sprintf('Chord: root %.1f, max %.1f, mean %.1f, median %.1f mm', ...
        geo.stats.rootChord_mm, geo.stats.chordMax_mm, geo.stats.chordMean_mm, geo.stats.chordMedian_mm));
end
