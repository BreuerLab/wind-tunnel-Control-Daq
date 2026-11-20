function geo = wing_planform_geometry(imageFile, opts)
% WING_PLANFORM_GEOMETRY  Wing planform (silhouette), chord distribution and
% summary geometry from a photo of a wing lying flat next to a ruler.
%
%   geo = wing_planform_geometry(imageFile)
%   geo = wing_planform_geometry(imageFile, opts)
%
% The photo should show the dark wing membrane on a lighter background
% with a steel ruler lying roughly along the span (as in the Calimero wing
% photos). The script:
%   1. finds the ruler (light, bluish-grey compared with the wooden table),
%      fits its two long edges and uses them as the spanwise direction;
%   2. measures the scale (px/mm) from the period of the ruler's tick marks
%      (FFT along each edge). With an inch scale on the other edge, the
%      ratio of the two tick periods tells which edge is the mm scale and
%      double-checks the result;
%   3. segments the dark membrane, fills holes (washers, bolts), keeps the
%      largest blob, and rotates it into the ruler frame;
%   4. cuts off whatever sticks out past the straight root edge of the
%      membrane (3D-printed root parts, bolt heads);
%   5. orients the planform root-left / leading-edge-up (so face-up and
%      face-down photos, and left and right wings, are directly comparable)
%      and measures chord c(r) and span s(x) per pixel column / row.
%
% opts (all optional):
%   .rootSide        'auto' (default) | 'left' | 'right'   which end is the
%                    root, in the ruler-aligned view. auto = the end the
%                    area centroid is closer to.
%   .leadingEdge     'auto' (default) | 'top' | 'bottom'   in the ruler-
%                    aligned view, after the root is put on the left.
%                    auto = the straighter of the two long edges.
%   .spanAxis        'ruler' (default) | 'leadingEdge'  spanwise direction:
%                    the ruler, or a line fitted to the leading edge.
%   .pxPerMm         [] (default: measured from the ruler ticks) or a number
%   .tickSpacing_mm  1 (default) spacing of the finest ticks on the metric
%                    edge
%   .manualCalibration false (default). true = click two points on the
%                    ruler edge next to the wing a known distance apart
%                    (asked for afterwards); gives span direction and scale.
%   .darkThreshold   [] (default: multithresh) or gray level 0..1 below
%                    which a pixel counts as membrane
%   .closeRadius_mm  1 (default) closing radius used before filling holes
%                    (closes washers sitting on the membrane edge)
%   .rootCut         true (default) cut off parts outside the root edge
%   .rootCutTol_mm   0.5 (default) material more than this beyond the
%                    fitted root edge line is removed
%   .rootOpen_mm     3 (default) radius of the opening used to find the
%                    root edge without the root hardware
%   .excludePolygons {} cell array of [x y] polygons (original image px)
%                    to remove from the wing mask by hand
%   .rootOffset_mm   0 (default) distance from the flapping/rotation axis
%                    to the wing root; only used for the radial moments
%                    r1hat, r2hat, r3hat
%   .plot            true (default) make a summary figure
%   .verbose         true (default) print the summary
%
% geo fields (lengths in mm, area in mm^2):
%   .file, .pxPerMm, .scaleInfo (ruler/scale diagnostics)
%   .mask       planform in the canonical frame (root left, LE top);
%               column j <-> spanwise r = (j-0.5)/pxPerMm,
%               row i    <-> chordwise x = (i-0.5)/pxPerMm from the LE
%   .r_mm, .chord_mm, .chordSmooth_mm  chord at each spanwise station
%               (membrane length in the column, so slots/notches count)
%   .xLE_mm, .xTE_mm   leading and trailing edge position vs r
%               (chordwise, measured down from the most forward LE point)
%   .chordFun   @(r) chord at spanwise r (mm), 0 outside the wing
%   .x_mm, .spanAtX_mm  spanwise extent of the membrane at each chordwise
%               station x
%   .stats      area, span (root-to-tip length R), chord max/mean/median,
%               span max/mean/median, mean geometric chord S/R, aspect
%               ratio R^2/S, centroid, r1hat/r2hat/r3hat, LE angle
%   .boundaryXY wing outline in original image pixel coordinates
%   .fig        figure handle (if opts.plot)

    if nargin < 2, opts = struct(); end
    opts = setDefaults(opts);
    geo = struct();
    geo.file = string(imageFile);

    %% ---------------- load ----------------
    I = im2double(imread(imageFile));
    if size(I,3) == 1
        I = repmat(I, 1, 1, 3);
    elseif size(I,3) > 3
        I = I(:,:,1:3);
    end
    [H, W, ~] = size(I);
    gray = rgb2gray(I);

    if isempty(opts.darkThreshold)
        thr = multithresh(gray, 2);  % wing | ruler | table
        darkThr = thr(1);
    else
        darkThr = opts.darkThreshold;
    end
    dark = gray < darkThr;

    %% ---------------- ruler: direction and scale ----------------
    c0 = [W H]/2;   % rotation centre (image centre)
    scaleInfo = struct('method', "", 'pxPerMm', NaN, 'edgePeriods_px', [NaN NaN], ...
        'mmEdge', NaN, 'otherTick_mm', NaN, 'consistencyErr', NaN, ...
        'localPxPerMm', [], 'localVariation', NaN, 'rulerAngle_deg', NaN);

    if opts.manualCalibration
        [e, n, vEdges, pxPerMm, rulerMask] = manualRuler(I, dark, c0, opts);
        scaleInfo.method = "manual";
    else
        [e, n, vEdges, rulerMask, rulerLen] = findRuler(I, dark, c0);
        scaleInfo.method = "ruler ticks (FFT)";
    end
    scaleInfo.rulerAngle_deg = atan2d(e(2), e(1));

    % pixel coordinate grids in the original image
    [X, Y] = meshgrid(1:W, 1:H);
    V = (X - c0(1))*n(1) + (Y - c0(2))*n(2);   % distance across the ruler

    if ~opts.manualCalibration
        if ~isempty(opts.pxPerMm)
            pxPerMm = opts.pxPerMm;
            scaleInfo.method = "given (opts.pxPerMm)";
        else
            % which edge is closer to the wing (for the fallback choice)
            wingGuess = dark & (V < min(vEdges) - 20 | V > max(vEdges) + 20);
            wingGuess = bwareafilt(wingGuess, 1);
            vWing = mean(V(wingGuess));
            [~, nearEdge] = min(abs(vEdges - vWing));
            [pxPerMm, scaleInfo] = rulerScale(gray, rulerMask, e, n, c0, vEdges, ...
                rulerLen, nearEdge, opts.tickSpacing_mm, scaleInfo);
        end
    end
    scaleInfo.pxPerMm = pxPerMm;
    geo.pxPerMm = pxPerMm;

    %% ---------------- wing mask ----------------
    if opts.manualCalibration
        rulerSide = rulerMask;              % half-plane beyond the clicked edge
    else
        marg = max(1, 0.1*pxPerMm);   % ~0.1 mm: keeps the LE that touches the ruler
        rulerSide = V > min(vEdges) - marg & V < max(vEdges) + marg;
    end
    wing = dark & ~rulerSide;
    for k = 1:numel(opts.excludePolygons)
        P = opts.excludePolygons{k};
        wing = wing & ~poly2mask(P(:,1), P(:,2), H, W);
    end
    wing = bwareafilt(wing, 1);
    rClose = max(1, round(opts.closeRadius_mm*pxPerMm));
    wing = imclose(wing, strel('disk', rClose));
    wing = imfill(wing, 'holes');
    wing = bwareafilt(wing, 1);
    clear X Y V

    %% ---------------- rotate into the ruler frame ----------------
    % u along the ruler (span), v across it. Grid covers the wing's bbox.
    [yy, xx] = find(wing);
    uu = (xx - c0(1))*e(1) + (yy - c0(2))*e(2);
    vv = (xx - c0(1))*n(1) + (yy - c0(2))*n(2);
    uVec = floor(min(uu)) - 3 : ceil(max(uu)) + 3;
    vVec = floor(min(vv)) - 3 : ceil(max(vv)) + 3;
    clear xx yy uu vv
    [Ug, Vg] = meshgrid(uVec, vVec);
    Xs = c0(1) + Ug*e(1) + Vg*n(1);
    Ys = c0(2) + Ug*e(2) + Vg*n(2);
    M = interp2(double(wing), Xs, Ys, 'linear', 0) > 0.5;
    clear Ug Vg Xs Ys
    M = bwareafilt(M, 1);

    %% ---------------- root side ----------------
    rOpen = max(1, round(opts.rootOpen_mm*pxPerMm));
    O = imopen(M, strel('disk', rOpen));
    if ~any(O(:)), O = M; end
    colsO = find(any(O, 1));
    colMass = sum(O, 1);
    uCentroid = sum(colMass .* (1:size(O,2))) / sum(colMass);
    switch lower(string(opts.rootSide))
        case "auto",  flipU = uCentroid > (colsO(1) + colsO(end))/2;
        case "left",  flipU = false;
        case "right", flipU = true;
        otherwise, error("opts.rootSide must be 'auto', 'left' or 'right'")
    end
    if flipU
        M = fliplr(M);
        O = fliplr(O);
    end

    %% ---------------- remove root hardware ----------------
    rootLine = [NaN NaN];
    if opts.rootCut
        [M, rootLine] = cutRoot(M, O, opts.rootCutTol_mm*pxPerMm);
    end

    %% ---------------- leading edge side ----------------
    [topFit, botFit] = edgeFits(M);
    switch lower(string(opts.leadingEdge))
        case "auto",   flipV = botFit.rms < topFit.rms;
        case "top",    flipV = false;
        case "bottom", flipV = true;
        otherwise, error("opts.leadingEdge must be 'auto', 'top' or 'bottom'")
    end
    if flipV
        M = flipud(M);
        leFit = botFit;
        leFit.slope = -leFit.slope;
    else
        leFit = topFit;
    end
    leAngle = atand(leFit.slope);   % LE angle relative to the ruler (deg)

    %% ---------------- outline in the original image ----------------
    Mr = M;
    if flipV, Mr = flipud(Mr); end
    if flipU, Mr = fliplr(Mr); end
    B = bwboundaries(Mr, 'noholes');
    [~, kb] = max(cellfun(@(b) size(b,1), B));
    b = B{kb};                          % [row col] in the rotated grid
    ub = uVec(b(:,2)); vb = vVec(b(:,1));
    geo.boundaryXY = [c0(1) + ub(:)*e(1) + vb(:)*n(1), c0(2) + ub(:)*e(2) + vb(:)*n(2)];

    %% ---------------- optional: span axis = leading edge ----------------
    if strcmpi(opts.spanAxis, "leadingEdge")
        % rotate counter-clockwise by the LE angle so the LE is horizontal
        M = imrotate(double(M), leAngle, 'bilinear', 'loose') > 0.5;
        M = bwareafilt(M, 1);
    end

    %% ---------------- crop & measure ----------------
    rows = find(any(M, 2)); cols = find(any(M, 1));
    M = M(rows(1):rows(end), cols(1):cols(end));
    geo.mask = M;
    [nR, nC] = size(M);

    r = ((1:nC) - 0.5)/pxPerMm;
    chord = sum(M, 1)/pxPerMm;
    [hasCol, iLE] = max(M, [], 1);
    [~, iTEf] = max(flipud(M), [], 1);
    iTE = nR - iTEf + 1;
    xLE = (iLE - 1)/pxPerMm;  xTE = iTE/pxPerMm;
    xLE(~hasCol) = NaN; xTE(~hasCol) = NaN;

    x = ((1:nR)' - 0.5)/pxPerMm;
    spanAtX = sum(M, 2)/pxPerMm;

    geo.r_mm = r(:);
    geo.chord_mm = chord(:);
    sgWin = 2*floor(pxPerMm) + 1;              % ~2 mm Savitzky-Golay window
    if nC > sgWin + 2
        geo.chordSmooth_mm = max(0, smoothdata(chord(:), 'sgolay', sgWin));
    else
        geo.chordSmooth_mm = chord(:);
    end
    geo.xLE_mm = xLE(:);
    geo.xTE_mm = xTE(:);
    geo.x_mm = x;
    geo.spanAtX_mm = spanAtX;

    Rspan = nC/pxPerMm;
    rr = geo.r_mm; cc = geo.chord_mm;
    geo.chordFun = @(rq) (rq >= 0 & rq <= Rspan) .* ...
        interp1(rr, cc, min(max(rq, rr(1)), rr(end)), 'linear');

    %% ---------------- statistics ----------------
    S = nnz(M)/pxPerMm^2;
    cv = chord(chord > 0);
    sv = spanAtX(spanAtX > 0);
    dr = 1/pxPerMm;
    rAx = r + opts.rootOffset_mm;              % radius from the flapping axis
    Rtip = Rspan + opts.rootOffset_mm;
    st = struct();
    st.area_mm2          = S;
    st.span_mm           = Rspan;              % root-to-tip length (R)
    st.chordMax_mm       = max(cv);
    st.chordMean_mm      = mean(cv);
    st.chordMedian_mm    = median(cv);
    st.spanMax_mm        = max(sv);
    st.spanMean_mm       = mean(sv);
    st.spanMedian_mm     = median(sv);
    st.chordExtent_mm    = nR/pxPerMm;         % LE-most to TE-most point
    st.meanGeomChord_mm  = S/Rspan;
    st.aspectRatio       = Rspan^2/S;          % one wing: R^2/S
    st.centroidR_mm      = sum(chord.*r)*dr/S;
    st.centroidX_mm      = sum(spanAtX.*x)*dr/S;
    st.r1hat             = (sum(chord.*rAx   )*dr/(S*Rtip  ));
    st.r2hat             = (sum(chord.*rAx.^2)*dr/(S*Rtip^2))^(1/2);
    st.r3hat             = (sum(chord.*rAx.^3)*dr/(S*Rtip^3))^(1/3);
    st.rootOffset_mm     = opts.rootOffset_mm;
    st.leAngleToRuler_deg = leAngle;
    st.leStraightness_mm = leFit.rms/pxPerMm;  % RMS deviation of LE from a line
    geo.stats = st;
    geo.scaleInfo = scaleInfo;
    geo.orientation = struct('rootFlipped', flipU, 'leFlipped', flipV, ...
        'rootLine', rootLine, 'spanAxis', string(opts.spanAxis));

    if opts.verbose
        printSummary(geo);
    end
    if opts.plot
        geo.fig = plotSummary(I, geo, e, n, c0, vEdges, opts);
    end
end

%% ======================================================================
function opts = setDefaults(opts)
    d = struct('rootSide', 'auto', 'leadingEdge', 'auto', 'spanAxis', 'ruler', ...
        'pxPerMm', [], 'tickSpacing_mm', 1, 'manualCalibration', false, ...
        'darkThreshold', [], 'closeRadius_mm', 1, 'rootCut', true, ...
        'rootCutTol_mm', 0.5, 'rootOpen_mm', 3, 'excludePolygons', {{}}, ...
        'rootOffset_mm', 0, 'plot', true, 'verbose', true);
    f = fieldnames(d);
    for k = 1:numel(f)
        if ~isfield(opts, f{k}) || (isempty(opts.(f{k})) && ~isempty(d.(f{k})))
            opts.(f{k}) = d.(f{k});
        end
    end
end

%% ======================================================================
function [e, n, vEdges, rulerMask, rulerLen] = findRuler(I, dark, c0)
% Ruler = largest light region that is bluer (lower Lab b*) than the table.
    lab = rgb2lab(I);
    bstar = lab(:,:,3);
    light = ~dark;
    tb = multithresh(bstar(light), 1);
    rul = light & bstar < tb;
    rul = imopen(rul, strel('disk', 3));
    rul = bwareafilt(rul, 1);
    rul = imclose(rul, strel('square', 25));    % fill tick marks & text
    if nnz(rul) < 0.005*numel(rul)
        error("wing_planform_geometry:noRuler", ...
            "Could not find the ruler. Try opts.manualCalibration = true.");
    end
    rp = regionprops(rul, 'Orientation', 'MajorAxisLength');
    rulerLen = rp(1).MajorAxisLength;
    vertical = abs(rp(1).Orientation) > 45;

    R = rul;
    if vertical, R = R.'; end     % work with a "horizontal" ruler
    [h, w] = size(R);
    cols = find(sum(R, 1) > 20);
    [~, top] = max(R(:, cols), [], 1);
    [~, botf] = max(flipud(R(:, cols)), [], 1);
    bot = h - botf + 1;
    pTop = robustLineFit(cols, top);
    pBot = robustLineFit(cols, bot);
    s = (pTop(1) + pBot(1))/2;
    xm = w/2;
    ptsT = [xm, polyval(pTop, xm)];
    ptsB = [xm, polyval(pBot, xm)];
    if vertical                     % back to original (x, y)
        e = [s 1]/hypot(1, s);
        ptsT = fliplr(ptsT); ptsB = fliplr(ptsB);
    else
        e = [1 s]/hypot(1, s);
    end
    n = [-e(2) e(1)];
    vEdges = [(ptsT - c0)*n.', (ptsB - c0)*n.'];
    rulerMask = rul;
end

%% ======================================================================
function [pxPerMm, info] = rulerScale(gray, rulerMask, e, n, c0, vEdges, ...
        rulerLen, nearEdge, tick_mm, info)
% Tick period along each long edge of the ruler from the FFT of a thin band
% just inside the edge.
    width = abs(diff(vEdges));
    vLo = min(vEdges); vHi = max(vEdges);
    % u extent of the ruler along its centreline
    [yy, xx] = find(rulerMask);
    uu = (xx - c0(1))*e(1) + (yy - c0(2))*e(2);
    uu = sort(uu);
    uR = [uu(max(1, round(0.01*numel(uu)))), uu(round(0.99*numel(uu)))];
    uR = uR + [1 -1]*0.02*diff(uR);
    uVec = ceil(uR(1)):floor(uR(2));
    pMin = 3; pMax = max(20, numel(uVec)/40);

    bands = {[vLo + 0.01*width, vLo + 0.04*width], ...     % edge 1 (vLo)
             [vHi - 0.04*width, vHi - 0.01*width]};        % edge 2 (vHi)
    edgeOrder = [vLo vHi];
    per = NaN(1,2); prom = NaN(1,2);
    profs = cell(1,2);
    for k = 1:2
        vVec = linspace(bands{k}(1), bands{k}(2), max(3, round(diff(bands{k}))));
        [Ug, Vg] = meshgrid(uVec, vVec);
        Xs = c0(1) + Ug*e(1) + Vg*n(1);
        Ys = c0(2) + Ug*e(2) + Vg*n(2);
        G = interp2(gray, Xs, Ys, 'linear', NaN);
        profs{k} = mean(G, 1, 'omitnan');
        [per(k), prom(k)] = tickPeriod(profs{k}, pMin, pMax);
    end

    % Which edge is metric? The other edge should then be an inch scale.
    inchTicks = 25.4 ./ [8 10 16 20 32 50 64];
    best = [Inf NaN NaN];   % [err, mmEdge, otherTick_mm]
    for k = 1:2
        o = 3 - k;
        ratio = per(o)/per(k)*tick_mm;     % other tick spacing in mm
        [err, j] = min(abs(ratio - inchTicks)./inchTicks);
        if err < best(1), best = [err, k, inchTicks(j)]; end
    end
    if best(1) < 0.03
        mmEdge = best(2);
    else
        % no consistent inch scale: assume the edge next to the wing is mm
        mmEdge = find(abs(edgeOrder - vEdges(nearEdge)) < 1e-9, 1);
        warning("wing_planform_geometry:scaleCheck", ...
            ['Tick periods on the two ruler edges (%.2f, %.2f px) do not match a ' ...
             'mm/inch pair; using the edge next to the wing as %g mm ticks. ' ...
             'Check geo.scaleInfo or set opts.pxPerMm.'], per(1), per(2), tick_mm);
    end
    pxPerMm = per(mmEdge)/tick_mm;

    % local scale along the ruler (camera tilt / lens distortion check)
    prof = profs{mmEdge};
    nW = min(numel(prof), max(round(numel(prof)/5), round(40*per(mmEdge))));
    starts = 1:round(nW/2):(numel(prof) - nW + 1);
    loc = NaN(size(starts));
    for k = 1:numel(starts)
        % search near the global period only (avoids locking onto harmonics)
        loc(k) = tickPeriod(prof(starts(k):starts(k)+nW-1), ...
            0.8*per(mmEdge), 1.25*per(mmEdge))/tick_mm;
    end

    info.edgePeriods_px = per;
    info.edgeProminence = prom;
    info.mmEdge = mmEdge;
    info.otherTick_mm = best(3);
    info.consistencyErr = best(1);
    info.localPxPerMm = loc;
    % spread of the local scale, ignoring single windows spoiled by glare
    med = median(loc);
    good = abs(loc - med) <= max(3.5*1.4826*median(abs(loc - med)), 0.005*med);
    info.localVariation = (max(loc(good)) - min(loc(good)))/med;
    if info.localVariation > 0.04
        warning("wing_planform_geometry:perspective", ...
            ['Scale varies by %.1f%% along the ruler: the camera was probably not ' ...
             'parallel to the table. Lengths are only as good as this.'], ...
            100*info.localVariation);
    end
end

%% ======================================================================
function [period, prominence] = tickPeriod(prof, pMin, pMax)
    prof = prof(:).';
    prof = prof(~isnan(prof));
    nP = numel(prof);
    prof = prof - movmean(prof, 2*round(pMax) + 1);
    win = 0.5 - 0.5*cos(2*pi*(0:nP-1)/(nP-1));
    N = 2^(nextpow2(nP) + 3);
    F = abs(fft(prof.*win, N));
    F = F(1:N/2+1);
    f = (0:N/2)/N;
    ok = f > 1/pMax & f < 1/pMin;
    Fk = F; Fk(~ok) = 0;
    [pk, i] = max(Fk);
    a = log(F(i-1)); b = log(F(i)); c = log(F(i+1));
    d = 0.5*(a - c)/(a - 2*b + c);           % parabolic peak refinement
    period = 1/(f(i) + d/N);
    prominence = pk/median(F(ok));
end

%% ======================================================================
function [e, n, vEdges, pxPerMm, farSide] = manualRuler(I, dark, c0, opts)
    hf = figure('Name', 'Ruler calibration');
    imshow(I); hold on
    title({'Click two points on the ruler edge NEXT TO THE WING,', ...
           'a known distance apart (e.g. two cm marks far apart)'});
    [xp, yp] = ginput(2);
    plot(xp, yp, 'r+-', 'LineWidth', 1.5, 'MarkerSize', 14);
    answer = inputdlg('Distance between the two points (mm):', 'Scale', 1, {'200'});
    close(hf);
    dist = str2double(answer{1});
    p1 = [xp(1) yp(1)]; p2 = [xp(2) yp(2)];
    e = (p2 - p1)/norm(p2 - p1);
    if abs(e(1)) >= abs(e(2)), e = e*sign(e(1)); else, e = e*sign(e(2)); end
    n = [-e(2) e(1)];
    pxPerMm = norm(p2 - p1)/dist;
    if ~isempty(opts.pxPerMm), pxPerMm = opts.pxPerMm; end
    vEdge = (p1 - c0)*n.';
    vEdges = [vEdge vEdge];
    % which side is the wing on? drop a 1 mm band around the edge so the
    % ruler's ticks come apart from the wing, take the biggest dark blob
    [H, W] = size(dark);
    [X, Y] = meshgrid(1:W, 1:H);
    V = (X - c0(1))*n(1) + (Y - c0(2))*n(2);
    blob = bwareafilt(dark & abs(V - vEdge) > pxPerMm, 1);
    wingSide = sign(mean(V(blob)) - vEdge);
    farSide = (V - vEdge)*wingSide < 0;
end

%% ======================================================================
function [M, rootLine] = cutRoot(M, O, tol)
% Root is on the left. Fit a line to the left edge of the opened mask (the
% opening removes thin hardware) and drop everything left of it.
    nC = size(M, 2);
    k = max(1, round(0.15*nC));
    rowsWith = find(any(O(:, 1:k), 2));
    rootLine = [NaN NaN];
    if numel(rowsWith) < 10, return, end
    nr = numel(rowsWith);
    sel = rowsWith(round(0.1*nr)+1 : nr - round(0.1*nr));
    [~, lx] = max(O(sel, :), [], 2);
    p = robustLineFit(sel, lx);           % col = p(1)*row + p(2)
    [Cg, Rg] = meshgrid(1:nC, 1:size(M,1));
    cutReg = Cg < polyval(p, Rg) - tol;
    M = bwareafilt(M & ~cutReg, 1);
    % washers sitting on the root edge leave notches open towards the root;
    % close them by filling holes with the cut-away side counted as solid
    M = imfill(M | cutReg, 'holes') & ~cutReg;
    rootLine = p;
end

%% ======================================================================
function [topFit, botFit] = edgeFits(M)
% Line fits to the upper and lower outline over the middle 80% of the span.
    cols = find(any(M, 1));
    c1 = cols(1); c2 = cols(end);
    sel = round(c1 + 0.1*(c2 - c1)) : round(c1 + 0.9*(c2 - c1));
    sel = sel(any(M(:, sel), 1));
    [~, top] = max(M(:, sel), [], 1);
    [~, botf] = max(flipud(M(:, sel)), [], 1);
    bot = size(M,1) - botf + 1;
    pt = polyfit(sel, top, 1);
    pb = polyfit(sel, bot, 1);
    topFit = struct('slope', pt(1), 'rms', sqrt(mean((top - polyval(pt, sel)).^2)));
    botFit = struct('slope', pb(1), 'rms', sqrt(mean((bot - polyval(pb, sel)).^2)));
end

%% ======================================================================
function p = robustLineFit(x, y)
% Straight-line fit with iterative outlier rejection (3 x robust sigma).
    x = double(x(:)); y = double(y(:));
    keep = true(size(x));
    for it = 1:15
        p = polyfit(x(keep), y(keep), 1);
        res = y - polyval(p, x);
        med = median(res(keep));
        sig = 1.4826*median(abs(res(keep) - med));
        newKeep = abs(res - med) < max(3*sig, 1);
        if isequal(newKeep, keep), break, end
        keep = newKeep;
    end
end

%% ======================================================================
function printSummary(geo)
    st = geo.stats; si = geo.scaleInfo;
    [~, name, ext] = fileparts(geo.file);
    fprintf('\n== %s%s ==\n', name, ext);
    fprintf('  scale            %.3f px/mm (%s)\n', geo.pxPerMm, si.method);
    if isfinite(si.consistencyErr)
        fprintf('  scale check      other edge = %.4g mm ticks, mismatch %.2f%%; along-ruler variation %.1f%%\n', ...
            si.otherTick_mm, 100*si.consistencyErr, 100*si.localVariation);
    end
    fprintf('  area             %.1f mm^2\n', st.area_mm2);
    fprintf('  span R           %.2f mm   (spanwise extent: max %.2f, mean %.2f, median %.2f)\n', ...
        st.span_mm, st.spanMax_mm, st.spanMean_mm, st.spanMedian_mm);
    fprintf('  chord            max %.2f, mean %.2f, median %.2f mm (S/R = %.2f mm)\n', ...
        st.chordMax_mm, st.chordMean_mm, st.chordMedian_mm, st.meanGeomChord_mm);
    fprintf('  AR = R^2/S       %.3f\n', st.aspectRatio);
    fprintf('  r1hat, r2hat, r3hat  %.3f, %.3f, %.3f (root offset %.1f mm)\n', ...
        st.r1hat, st.r2hat, st.r3hat, st.rootOffset_mm);
    fprintf('  LE vs ruler      %.2f deg (LE RMS deviation from a line %.2f mm)\n', ...
        st.leAngleToRuler_deg, st.leStraightness_mm);
end

%% ======================================================================
function fig = plotSummary(I, geo, e, n, c0, vEdges, opts)
    [~, name, ext] = fileparts(geo.file);
    fig = figure('Name', "Wing planform: " + name + ext, 'Color', 'w', ...
        'Position', [80 80 1300 800]);
    tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, name + ext, 'Interpreter', 'none');

    % 1) photo with outline and ruler edges
    ax1 = nexttile(tl, 1, [1 2]);
    imshow(I, 'Parent', ax1); hold(ax1, 'on')
    plot(ax1, geo.boundaryXY(:,1), geo.boundaryXY(:,2), 'c-', 'LineWidth', 1.5);
    [H, W, ~] = size(I);
    L = hypot(H, W);
    for v = unique(vEdges)
        p0 = c0 + v*n;
        q = [p0 - L*e; p0 + L*e];
        plot(ax1, q(:,1), q(:,2), 'm--', 'LineWidth', 1);
    end
    xlim(ax1, [0.5 W+0.5]); ylim(ax1, [0.5 H+0.5]);
    title(ax1, sprintf('Detected wing (cyan) and ruler edges (magenta); %.3f px/mm', ...
        geo.pxPerMm));

    % 2) canonical silhouette
    ax2 = nexttile(tl, 3);
    M = geo.mask;
    imagesc(ax2, [geo.r_mm(1) geo.r_mm(end)], [geo.x_mm(1) geo.x_mm(end)], double(~M));
    colormap(ax2, gray); axis(ax2, 'image'); hold(ax2, 'on')
    plot(ax2, geo.r_mm, geo.xLE_mm, 'b-', geo.r_mm, geo.xTE_mm, 'r-', 'LineWidth', 1);
    xlabel(ax2, 'spanwise r from root (mm)'); ylabel(ax2, 'chordwise x from LE (mm)');
    title(ax2, sprintf('Silhouette: S = %.0f mm^2, R = %.1f mm, AR = %.2f', ...
        geo.stats.area_mm2, geo.stats.span_mm, geo.stats.aspectRatio));
    legend(ax2, {'LE', 'TE'}, 'Location', 'southwest');

    % 3) chord distribution
    ax3 = nexttile(tl, 4);
    plot(ax3, geo.r_mm, geo.chord_mm, '-', 'Color', [0.6 0.6 0.6]); hold(ax3, 'on')
    plot(ax3, geo.r_mm, geo.chordSmooth_mm, 'k-', 'LineWidth', 1.5);
    yline(ax3, geo.stats.chordMean_mm, 'b--', 'mean');
    yline(ax3, geo.stats.chordMedian_mm, 'r:', 'median');
    grid(ax3, 'on'); xlabel(ax3, 'spanwise r from root (mm)'); ylabel(ax3, 'chord c(r) (mm)');
    title(ax3, sprintf('Chord: max %.1f, mean %.1f, median %.1f mm', ...
        geo.stats.chordMax_mm, geo.stats.chordMean_mm, geo.stats.chordMedian_mm));
    xlim(ax3, [0 geo.stats.span_mm]);
    if strcmpi(opts.spanAxis, "leadingEdge")
        subtitle(ax3, 'span axis = leading edge');
    end
end
