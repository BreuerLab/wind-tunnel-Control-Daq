function [x,v,a] = savitskyGolayDiff(x_raw, order, framelen, dt)

% Get SG filter coefficients
[b, g] = sgolay(order, framelen);

% Preallocate velocity
halfwin = (framelen-1)/2;

x = zeros(size(x_raw)); v = zeros(size(x_raw)); a = zeros(size(x_raw));

% Compute 1st derivative using g(:,2) over a sliding window
for n = (halfwin+1):(length(x_raw)-halfwin)
    x(n) = dot(g(:,1), x_raw(n-halfwin:n+halfwin));
    v(n) = dot(g(:,2), x_raw(n-halfwin:n+halfwin));
    a(n) = dot(g(:,3), x_raw(n-halfwin:n+halfwin));
end

% Scale by sample spacing
v = v / dt;
a = (a * 2) / (dt^2);

end