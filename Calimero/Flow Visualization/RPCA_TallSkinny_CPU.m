function [L, S] = RPCA_TallSkinny_CPU(X)
    [n1, n2] = size(X);
    norm_two = norm(X); 
    norm_fro = norm(X, 'fro');
    
    % 1. Dynamic parameter scaling (drops iterations from ~500 down to ~30)
    mu = 1.25 / norm_two; 
    max_mu = mu * 1e7;
    rho = 1.5; 
    c = 1; % c = 1 is default, c < 1 more filtering, c > 1 less filtering
    lambda = c / sqrt(max(n1, n2)); 
    thresh = 1e-7 * norm_fro;
    
    % 2. Initialize standard CPU arrays
    L = zeros(n1, n2);
    S = zeros(n1, n2);
    Y = zeros(n1, n2);
    
    count = 0;
    max_iter = 1000;
    
    while (norm(X - L - S, 'fro') > thresh) && (count < max_iter)   
        % Singular Value Thresholding using the QR trick
        L = SVT_TallSkinny(X - S + (1/mu)*Y, 1/mu);
        
        % Soft-thresholding
        S = shrink(X - L + (1/mu)*Y, lambda / mu);
        
        % Update Lagrange multiplier
        Y = Y + mu * (X - L - S);
        
        % Scale up mu to accelerate convergence
        mu = min(mu * rho, max_mu);
        
        count = count + 1;
    end
end

function out = shrink(X, tau)
    out = sign(X) .* max(abs(X) - tau, 0);
end

function out = SVT_TallSkinny(X, tau)
    % 1. Economic QR decomposition (Compresses 400,000 x 20 down to 20 x 20)
    [Q, R] = qr(X, 0);
    
    % 2. SVD on the tiny 20 x 20 matrix (takes microseconds on a CPU)
    [UR, Sigma, V] = svd(R, 'econ');
    
    % 3. Apply soft-thresholding to the tiny singular values
    Sigma_shrunk = sign(Sigma) .* max(abs(Sigma) - tau, 0);
    
    % 4. Reconstruct the 400,000 x 20 matrix
    out = Q * (UR * Sigma_shrunk * V');
end