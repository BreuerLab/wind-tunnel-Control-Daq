function [x,v,a] = savitskyGolayDiff(x_raw, order, framelen, dt)
% Savitzky-Golay smoothing (x), first derivative (v) and second derivative
% (a) of x_raw. The first and last (framelen-1)/2 samples are set to zero
% since a full window isn't available there.
%
% Implemented as a convolution with the (flipped) Savitzky-Golay kernels,
% which is identical to sliding the window and taking dot products sample
% by sample, but much faster. Only the outputs requested are computed.
[~, g] = sgolay(order, framelen);
halfwin = (framelen-1)/2;
n = numel(x_raw);
valid = false(size(x_raw));
valid((halfwin+1):(n-halfwin)) = true;

% conv(x, flip(g(:,k)), 'same') at sample n = dot(g(:,k), x(n-halfwin:n+halfwin))
sg = @(k) conv(x_raw, flipud(g(:,k)), 'same') .* valid;

x = sg(1);
if nargout > 1
    v = sg(2) / dt;
end
if nargout > 2
    a = (sg(3) * 2) / (dt^2);
end
end
