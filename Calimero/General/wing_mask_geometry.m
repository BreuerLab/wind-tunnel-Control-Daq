function geo = wing_mask_geometry(M, pxPerMm, opts, label)
% WING_MASK_GEOMETRY  Chord distribution and planform statistics from a
% binary wing mask. Shared by wing_planform_geometry (photos) and
% cad_planform_geometry (CAD outline), so both use identical definitions.
%
%   geo = wing_mask_geometry(M, pxPerMm, opts, label)
%
% M        logical mask of the wing, span roughly along the columns (x),
%          e.g. the photo rotated into the ruler frame
% pxPerMm  mask resolution
% opts     .rootSide ('auto'|'left'|'right'), .leadingEdge ('auto'|'top'|
%          'bottom'), .spanAxis ('rootNormal'|'ruler'|'leadingEdge'; 'ruler'
%          = keep the input x axis), .rootCut, .rootCutTol_mm, .rootOpen_mm,
%          .rootOffset_mm, .verbose -- see wing_planform_geometry.m
% label    name printed in the summary (optional)
%
% Steps: root side (end the area centroid is nearer) -> cut everything
% beyond the straight root edge -> leading edge = straighter long edge ->
% put root left / LE up -> rotate to the span axis -> per-column chord and
% per-row span -> statistics. See wing_planform_geometry.m for the output
% fields; geo.frameMask is the final wing in the input frame (for overlays).

    if nargin < 3, opts = struct(); end
    if nargin < 4, label = ""; end
    opts = setDefaults(opts);
    geo = struct();
    M = bwareafilt(logical(M), 1);

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
    leAngle = atand(leFit.slope);   % LE angle relative to the input x axis (deg)
    rootTilt = NaN;                 % root edge angle from the input y axis
    if all(isfinite(rootLine))
        rootTilt = atand(rootLine(1));
        if flipV, rootTilt = -rootTilt; end
    end

    %% ---------------- final wing in the input frame ----------------
    Mr = M;
    if flipV, Mr = flipud(Mr); end
    if flipU, Mr = fliplr(Mr); end
    geo.frameMask = Mr;                 % same size and frame as the input mask

    %% ---------------- span axis ----------------
    % imrotate turns counter-clockwise (as displayed) by the given angle
    switch lower(string(opts.spanAxis))
        case "rootnormal"
            if isfinite(rootTilt)
                axisRot = -rootTilt;          % root edge -> vertical
            else
                warning("wing_mask_geometry:noRootLine", ...
                    "No root edge was fitted; using the input x axis as the span axis.");
                axisRot = 0;
            end
        case "leadingedge", axisRot = leAngle;   % LE -> horizontal
        case "ruler",       axisRot = 0;
        otherwise, error("opts.spanAxis must be 'rootNormal', 'ruler' or 'leadingEdge'")
    end
    if axisRot ~= 0
        M = imrotate(double(M), axisRot, 'bilinear', 'loose') > 0.5;
        M = bwareafilt(M, 1);
    end

    %% ---------------- crop & measure ----------------
    rows = find(any(M, 2)); cols = find(any(M, 1));
    M = M(rows(1):rows(end), cols(1):cols(end));
    if opts.rootCut
        % drop partial pixel columns left at the root by the rotation
        cs = sum(M, 1);
        k0 = 1;
        while k0 < min(4, numel(cs)) && cs(k0) < 0.5*cs(k0+1)
            k0 = k0 + 1;
        end
        M = M(:, k0:end);
        rows = find(any(M, 2));
        M = M(rows(1):rows(end), :);
    end
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
    st.rootChord_mm      = mean(chord(1:min(nC, max(1, round(pxPerMm)))));  % first 1 mm
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
    st.rootAngle_deg     = rootTilt;           % root edge vs. the input frame's chordwise axis
    st.leAngleToSpanAxis_deg = leAngle - axisRot;   % > 0: LE slopes back towards the tip
    st.leStraightness_mm = leFit.rms/pxPerMm;  % RMS deviation of LE from a line
    geo.stats = st;
    geo.orientation = struct('rootFlipped', flipU, 'leFlipped', flipV, ...
        'rootLine', rootLine, 'spanAxis', string(opts.spanAxis), 'axisRotation_deg', axisRot);

    if opts.verbose
        printSummary(geo, string(label));
    end
end

%% ======================================================================
function opts = setDefaults(opts)
    d = struct('rootSide', 'auto', 'leadingEdge', 'auto', 'spanAxis', 'rootNormal', ...
        'rootCut', true, 'rootCutTol_mm', 0, 'rootOpen_mm', 3, ...
        'rootOffset_mm', 0, 'verbose', true);
    f = fieldnames(d);
    for k = 1:numel(f)
        if ~isfield(opts, f{k}) || isempty(opts.(f{k}))
            opts.(f{k}) = d.(f{k});
        end
    end
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
function printSummary(geo, label)
    st = geo.stats;
    if strlength(label) > 0
        fprintf('\n== %s ==\n', label);
    end
    fprintf('  area             %.1f mm^2\n', st.area_mm2);
    fprintf('  span R           %.2f mm   (spanwise extent: max %.2f, mean %.2f, median %.2f)\n', ...
        st.span_mm, st.spanMax_mm, st.spanMean_mm, st.spanMedian_mm);
    fprintf('  chord            root %.2f, max %.2f, mean %.2f, median %.2f mm (S/R = %.2f mm)\n', ...
        st.rootChord_mm, st.chordMax_mm, st.chordMean_mm, st.chordMedian_mm, st.meanGeomChord_mm);
    fprintf('  AR = R^2/S       %.3f\n', st.aspectRatio);
    fprintf('  r1hat, r2hat, r3hat  %.3f, %.3f, %.3f (root offset %.1f mm)\n', ...
        st.r1hat, st.r2hat, st.r3hat, st.rootOffset_mm);
    fprintf('  angles           root edge %.2f deg from input y axis; LE %.2f deg to input x axis (ruler / CAD LE), %.2f deg to span axis (%s)\n', ...
        st.rootAngle_deg, st.leAngleToRuler_deg, st.leAngleToSpanAxis_deg, geo.orientation.spanAxis);
    fprintf('  LE straightness  %.2f mm RMS from a line\n', st.leStraightness_mm);
end

