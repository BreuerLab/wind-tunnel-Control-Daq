function [Qx,Qy,Qz,Q] = calQlate3D(u,v,w,dx,dy,dz,order,wdw)
% A Q-te function to calculate 2D-Q: the second (not first) invariant of the velocity gradient tensor.
% sgolay filter of order = 3 and window length = 9

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

g = fetch_coeff(order,wdw);

switch numel(size(u))
    case 3 % For a single frame
        % x-derivative
        for i = size(u,1):-1:1
            dudx(i,:,:) = conv(u(i,:,:), 1/(-dx)*g,'same');
            dvdx(i,:,:) = conv(v(i,:,:), 1/(-dx)*g,'same');
            dwdx(i,:,:) = conv(w(i,:,:), 1/(-dx)*g,'same');
        end
        % y-derivative
        for j = size(u,2):-1:1
            dudy(:,j,:) = conv(u(:,j,:), 1/(-dy)*g,'same');
            dvdy(:,j,:) = conv(v(:,j,:), 1/(-dy)*g,'same');
            dwdy(:,j,:) = conv(w(:,j,:), 1/(-dy)*g,'same');
        end
        % z-derivative
        for j = size(u,3):-1:1
            dudz(:,:,k) = conv(u(:,:,k), 1/(-dz)*g,'same');
            dvdz(:,:,k) = conv(v(:,:,k), 1/(-dz)*g,'same');
            dwdz(:,:,k) = conv(w(:,:,k), 1/(-dz)*g,'same');
        end

    case 4 % For multiple frames
        for m = size(u,4):-1:1
            % x-derivative
            for i = size(u,1):-1:1
                dudx(i,:,:,m) = conv(u(i,:,:,m), 1/(-dx)*g,'same');
                dvdx(i,:,:,m) = conv(v(i,:,:,m), 1/(-dx)*g,'same');
                dwdx(i,:,:,m) = conv(w(i,:,:,m), 1/(-dx)*g,'same');
            end
            % y-derivative
            for j = size(u,2):-1:1
                dudy(:,j,:,m) = conv(u(:,j,:,m), 1/(-dy)*g,'same');
                dvdy(:,j,:,m) = conv(v(:,j,:,m), 1/(-dy)*g,'same');
                dwdy(:,j,:,m) = conv(w(:,j,:,m), 1/(-dy)*g,'same');
            end
             % z-derivative
            for j = size(u,3):-1:1
                dudz(:,:,k,m) = conv(u(:,:,k,m), 1/(-dz)*g,'same');
                dvdz(:,:,k,m) = conv(v(:,:,k,m), 1/(-dz)*g,'same');
                dwdz(:,:,k,m) = conv(w(:,:,k,m), 1/(-dz)*g,'same');
            end
        end
end

% Compute Q
% 2D variants calculated using second invariant for symmetric tensor
% (Wikipedia). This is equivalent to expression used by Banko & Eaton for Q
% where the divergence is added to the common expression for Q
Qx = dudx.*dvdy - dudy.*dvdx;
Qy = dudx.*dwdz - dudz.*dwdz;
Qz = dvdy.*dwdz - dvdz.*dwdy;
Q = Qx + Qy + Qz;

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



