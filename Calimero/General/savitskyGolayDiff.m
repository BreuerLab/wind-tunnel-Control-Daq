function v = savitskyGolayDiff(x, order, framelen, dt)

% Get SG filter coefficients
[b, g] = sgolay(order, framelen);

% Preallocate velocity
halfwin = (framelen-1)/2;
v = zeros(size(x));

% Compute 1st derivative using g(:,2)
for n = (halfwin+1):(length(x)-halfwin)
    v(n) = dot(g(:,2), x(n-halfwin:n+halfwin));
end

% Scale by sample spacing
v = v / dt;

end