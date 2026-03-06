function [Qx,Qy,Qz,Q] = calQlate3D(u,v,w,dx,dy,dz,order,wdw)
disp("Calculating Q...")
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
        for i = size(u,2):-1:1
        for j = size(u,3):-1:1
            dudx(:,i,j) = conv(u(:,i,j), 1/(-dx)*g,'same');
            dvdx(:,i,j) = conv(v(:,i,j), 1/(-dx)*g,'same');
            dwdx(:,i,j) = conv(w(:,i,j), 1/(-dx)*g,'same');
        end
        end
        % y-derivative
        for i = size(u,1):-1:1
        for j = size(u,3):-1:1
            dudy(i,:,j) = conv(u(i,:,j), 1/(-dy)*g,'same');
            dvdy(i,:,j) = conv(v(i,:,j), 1/(-dy)*g,'same');
            dwdy(i,:,j) = conv(w(i,:,j), 1/(-dy)*g,'same');
        end
        end
        % z-derivative
        for i = size(u,1):-1:1
        for j = size(u,2):-1:1
            dudz(i,j,:) = conv(u(i,j,:), 1/(-dz)*g,'same');
            dvdz(i,j,:) = conv(v(i,j,:), 1/(-dz)*g,'same');
            dwdz(i,j,:) = conv(w(i,j,:), 1/(-dz)*g,'same');
        end
        end

    case 4 % For multiple frames
        % Pre-reshape the kernel for each dimension
        gx = reshape(1/(-dx)*g, [], 1, 1, 1); % Vertical kernel
        gy = reshape(1/(-dy)*g, 1, [], 1, 1); % Horizontal kernel
        gz = reshape(1/(-dz)*g, 1, 1, [], 1); % Depth kernel

        % X-derivatives (First dimension)
        dudx = convn(u, gx, 'same');
        dvdx = convn(v, gx, 'same');
        dwdx = convn(w, gx, 'same');

        % Y-derivatives (Second dimension)
        dudy = convn(u, gy, 'same');
        dvdy = convn(v, gy, 'same');
        dwdy = convn(w, gy, 'same');

        % Z-derivatives (Third dimension)
        dudz = convn(u, gz, 'same');
        dvdz = convn(v, gz, 'same');
        dwdz = convn(w, gz, 'same');

        % for m = size(u,4):-1:1
        %     % x-derivative
        %     for i = size(u,2):-1:1
        %     for j = size(u,3):-1:1
        %         dudx(:,i,j,m) = conv(squeeze(u(:,i,j,m)), 1/(-dx)*g,'same');
        %         dvdx(:,i,j,m) = conv(squeeze(v(:,i,j,m)), 1/(-dx)*g,'same');
        %         dwdx(:,i,j,m) = conv(squeeze(w(:,i,j,m)), 1/(-dx)*g,'same');
        %     end
        %     end
        %     % y-derivative
        %     for i = size(u,1):-1:1
        %     for j = size(u,3):-1:1
        %         dudy(i,:,j,m) = conv(squeeze(u(i,:,j,m)), 1/(-dy)*g,'same');
        %         dvdy(i,:,j,m) = conv(squeeze(v(i,:,j,m)), 1/(-dy)*g,'same');
        %         dwdy(i,:,j,m) = conv(squeeze(w(i,:,j,m)), 1/(-dy)*g,'same');
        %     end
        %     end
        %      % z-derivative
        %     for i = size(u,1):-1:1
        %     for j = size(u,2):-1:1
        %         dudz(i,j,:,m) = conv(squeeze(u(i,j,:,m)), 1/(-dz)*g,'same');
        %         dvdz(i,j,:,m) = conv(squeeze(v(i,j,:,m)), 1/(-dz)*g,'same');
        %         dwdz(i,j,:,m) = conv(squeeze(w(i,j,:,m)), 1/(-dz)*g,'same');
        %     end
        %     end
        % end
end

% Compute Q
% 2D variants calculated using second invariant for symmetric tensor
% (Wikipedia). This is equivalent to expression used by Banko & Eaton for Q
% where the divergence is added to the common expression for Q
Qz = dudx.*dvdy - dudy.*dvdx;
Qy = dudx.*dwdz - dudz.*dwdz;
Qx = dvdy.*dwdz - dvdz.*dwdy;
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



