function acc = hr_accumulate(acc, data, phi, H)
% HR_ACCUMULATE Add a chunk of frames to the harmonic regression sums.
%
%   acc = hr_accumulate([], data, phi, H)   % first chunk (creates acc)
%   acc = hr_accumulate(acc, data, phi)     % later chunks
%
%   data - 1 x nf cell, data{f} is [nx ny nz n], one field per cell (the
%          order of get_STB_processing_fields), n frames in this chunk
%   phi  - n phases of those frames, in cycles
%   H    - number of harmonics (only needed for the first chunk)
%
%   The least-squares fit of field f at point p is the K x 1 vector c_p
%   solving  G_p c_p = r_p  with
%       G_p = sum over valid frames i of a_i a_i'   (K x K)
%       r_p = sum over valid frames i of a_i f_i    (K x 1)
%   where a_i = harmonic_basis(phi_i, H)'. Only the K sums r_p are kept per
%   point, so frames never have to be held in memory together.
%
%   Missing data (NaN) makes G_p depend on the point. acc.G holds the sum
%   over ALL frames, which is G_p wherever nothing is missing, and the
%   frames missing at a point are subtracted from it: G_p = G - C_p. C_p is
%   only stored for fields that have NaNs, and fields whose NaNs fall on
%   exactly the same points and frames (u, v and w usually do) share one
%   copy. C_p is symmetric, so only its upper triangle is stored (packed,
%   columns listed in acc.pairs).
%
%   Chunks can be accumulated on different parallel workers and combined
%   with hr_merge. hr_solve turns the sums into coefficients.

phi = double(phi(:));
n = numel(phi);
if n == 0, return, end
nf = numel(data);

if isempty(acc)
    if nargin < 4 || isempty(H)
        error("hr_accumulate: H (number of harmonics) is needed for the first chunk")
    end
    acc = init_acc(data, H);
end
if nf ~= acc.nf
    error("hr_accumulate: expected %d fields, got %d", acc.nf, nf)
end
sz = size(data{1});
if prod(sz(1:min(3,end))) ~= acc.npts
    error("hr_accumulate: grid size changed between chunks")
end

A = harmonic_basis(phi, acc.H);                      % n x K
acc.G = acc.G + A.' * A;
acc.N = acc.N + n;

% ----- right-hand sides and valid counts -----
masks = cell(1, nf);
for f = 1:nf
    X = reshape(double(data{f}), acc.npts, n);
    M = isnan(X);
    X(M) = 0;
    acc.rhs(:,:,f) = acc.rhs(:,:,f) + X * A;
    acc.cnt(:,f) = acc.cnt(:,f) + (n - sum(M, 2));
    masks{f} = M;
end

% ----- normal-matrix corrections for missing frames -----
% Fields stay in the same group as long as their NaN pattern has been
% identical in every chunk so far; a field whose pattern differs in this
% chunk gets its own copy of the group's corrections.
Apair = A(:, acc.pairs(:,1)) .* A(:, acc.pairs(:,2));  % n x P
P = size(acc.pairs, 1);
new_grp = zeros(1, nf);
new_C = {};
done = false(1, nf);
for f = 1:nf
    if done(f), continue, end
    has_nan = any(masks{f}(:));
    if acc.grp(f) == 0 && ~has_nan
        done(f) = true;            % still complete, no correction needed
        continue
    end

    members = f;
    for h = f+1:nf
        if ~done(h) && acc.grp(h) == acc.grp(f) && isequal(masks{h}, masks{f})
            members(end+1) = h; %#ok<AGROW>
        end
    end

    if acc.grp(f) > 0
        Cg = acc.C{acc.grp(f)};
    else
        Cg = zeros(acc.npts, P);
    end
    if has_nan
        M = masks{f};
        if nnz(M) < 0.1 * numel(M)
            Cg = Cg + full(sparse(double(M)) * Apair);
        else
            Cg = Cg + double(M) * Apair;
        end
    end

    new_C{end+1} = Cg; %#ok<AGROW>
    new_grp(members) = numel(new_C);
    done(members) = true;
end
acc.C = new_C;
acc.grp = new_grp;
end

function acc = init_acc(data, H)
sz = size(data{1});
sz(end+1:4) = 1;
K = 2*H + 1;
[r, s] = find(triu(true(K)));

acc.H = H;
acc.K = K;
acc.nf = numel(data);
acc.grid = sz(1:3);
acc.npts = prod(sz(1:3));
acc.N = 0;
acc.G = zeros(K, K);
acc.rhs = zeros(acc.npts, K, acc.nf);
acc.cnt = zeros(acc.npts, acc.nf);
acc.pairs = [r, s];
acc.grp = zeros(1, acc.nf);
acc.C = {};
end
