function [Qx,Qy,Qz,Q] = calQlate3D(u,v,w,dx,dy,dz,order,wdw)
% A Q-te function to calculate 2D-Q: the second (not first) invariant of the velocity gradient tensor.
% sgolay filter of order = 3 and window length = 9
%
% u, v, w : [nx ny nz] (one frame / bin) or [nx ny nz nFrames]
% dx, dy, dz : grid spacing along dims 1, 2, 3
%
% Edge handling: each derivative is taken with the array padded by
% repeating its edge values (not zeros), so the boundary values are no
% longer pulled toward zero. Along a dimension shorter than the window
% (e.g. 5 planes across the STB slab) the window is reduced to the largest
% one that fits, so the centre plane needs no padding at all.

% Check inputs
if ~exist('order','Var') || isempty(order)
    order = 3;
elseif order > 4
    warning('"order" out of range. Using default value "order == 3"');
    order = 3;
end

if order < 3
    if ~exist('wdw','Var') || isempty(wdw)
        wdw = 5;
    elseif ~any([3,5,7,9]==wdw)
        warning(['"wdw" out of range for order ',num2str(order),', or is even integer. Using default value "wdw == 5"']);
        wdw = 5;
    end
elseif order < 5
    if ~exist('wdw','Var') || isempty(wdw)
        wdw = 9;
    elseif ~any([5,7,9]==wdw)
        warning(['"wdw" out of range for order ',num2str(order),', or is even integer. Using default value "wdw == 9"']);
        wdw = 9;
    end
end

% X-derivatives (First dimension)
dudx = sg_deriv(u, dx, 1, order, wdw);
dvdx = sg_deriv(v, dx, 1, order, wdw);
dwdx = sg_deriv(w, dx, 1, order, wdw);

% Y-derivatives (Second dimension)
dudy = sg_deriv(u, dy, 2, order, wdw);
dvdy = sg_deriv(v, dy, 2, order, wdw);
dwdy = sg_deriv(w, dy, 2, order, wdw);

% Z-derivatives (Third dimension)
dudz = sg_deriv(u, dz, 3, order, wdw);
dvdz = sg_deriv(v, dz, 3, order, wdw);
dwdz = sg_deriv(w, dz, 3, order, wdw);

% Compute Q
% 2D variants calculated using second invariant for symmetric tensor
% (Wikipedia). This is equivalent to expression used by Banko & Eaton for Q
% where the divergence is added to the common expression for Q
Qz = dudx.*dvdy - dudy.*dvdx;
Qy = dudx.*dwdz - dudz.*dwdx;
Qx = dvdy.*dwdz - dvdz.*dwdy;
Q = Qx + Qy + Qz;

    function dA = sg_deriv(A, h, dim, order, wdw)
        % First derivative of A along dimension dim with a Savitzky-Golay
        % kernel, replicate (edge-value) padding instead of zero padding.
        n = size(A, dim);
        [ord, win] = fit_window(order, wdw, n);
        g = fetch_coeff(ord, win);
        half = (win - 1) / 2;

        % kernel oriented along dim (same sign convention as before:
        % convn flips the kernel, hence 1/(-h))
        kshape = ones(1, max(3, ndims(A)));
        kshape(dim) = win;
        kernel = reshape(1/(-h) * g, kshape);

        % pad by repeating the first / last slice along dim
        idx = [ones(1, half), 1:n, n * ones(1, half)];
        subs = repmat({':'}, 1, ndims(A));
        subs{dim} = idx;
        A_pad = A(subs{:});

        dA = convn(A_pad, kernel, 'valid');
    end

    function [ord, win] = fit_window(order, wdw, n)
        % largest supported window <= wdw that fits in n points
        if order >= 3
            wins = [9 7 5];
            wins = wins(wins <= min(wdw, n));
            if ~isempty(wins)
                ord = order; win = wins(1);
                return
            end
        end
        % too few points for the higher-order filter: fall back to
        % order 2 (3-point central difference at minimum)
        wins = [9 7 5 3];
        wins = wins(wins <= min(max(wdw, 3), n));
        if isempty(wins)
            error("calQlate3D:tooFewPoints", "Need at least 3 points along each dimension (got %d).", n);
        end
        ord = 2; win = wins(1);
    end

    function g = fetch_coeff(order, wdw)
        % coefficients for first derivative. Taken from Wikipedia
        if order < 3
        G = [
              1,   2,   3,   4,   5,   6,   7,   8,   9; % window size
            nan, nan, nan, nan, nan, nan, nan, nan,  -4; % -4
            nan, nan, nan, nan, nan, nan,  -3, nan,  -3; % -3
            nan, nan, nan, nan,  -2, nan,  -2, nan,  -2; % -2
            nan, nan,  -1, nan,  -1, nan,  -1, nan,  -1; % -1
            nan, nan,   0, nan,   0, nan,   0, nan,   0; %  0
            nan, nan,   1, nan,   1, nan,   1, nan,   1; % +1
            nan, nan, nan, nan,   2, nan,   2, nan,   2; % +2
            nan, nan, nan, nan, nan, nan,   3, nan,   3; % +3
            nan, nan, nan, nan, nan, nan, nan, nan,   4; % +4
            nan, nan,   2, nan,  10, nan,  28, nan,  60 % Normalization
            ];
        elseif order < 5
            G = [
              1,   2,   3,   4,   5,   6,   7,   8,   9; % window size
            nan, nan, nan, nan, nan, nan, nan, nan,  86; % -4
            nan, nan, nan, nan, nan, nan,  22, nan,-142; % -3
            nan, nan, nan, nan,   1, nan, -67, nan,-193; % -2
            nan, nan, nan, nan,  -8, nan, -58, nan,-126; % -1
            nan, nan, nan, nan,   0, nan,   0, nan,   0; %  0
            nan, nan, nan, nan,   8, nan,  58, nan, 126; % +1
            nan, nan, nan, nan,  -1, nan,  67, nan, 193; % +2
            nan, nan, nan, nan, nan, nan, -22, nan, 142; % +3
            nan, nan, nan, nan, nan, nan, nan, nan, -86; % +4
            nan, nan, nan, nan,  12, nan, 252, nan,1188 % Normalization
            ];
        else
            error('Filter order too high. Code not configured for order higher than 4.')
        end

        g = G( (6-floor(wdw/2)):(6+floor(wdw/2)) , wdw)/(G(end,wdw));
    end

end
