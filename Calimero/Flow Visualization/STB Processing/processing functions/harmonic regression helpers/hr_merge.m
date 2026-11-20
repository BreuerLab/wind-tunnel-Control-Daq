function acc = hr_merge(accs)
% HR_MERGE Combine harmonic regression sums from several workers.
%
%   acc = hr_merge({acc1, acc2, ...})
%
%   Each acc comes from hr_accumulate on a different set of frames. Empty
%   entries (workers that got no frames) are skipped.

acc = [];
for k = 1:numel(accs)
    b = accs{k};
    if isempty(b), continue, end
    if isempty(acc)
        acc = b;
    else
        acc = merge_two(acc, b);
    end
end
end

function a = merge_two(a, b)
if a.H ~= b.H || a.npts ~= b.npts || a.nf ~= b.nf
    error("hr_merge: accumulators differ in harmonics, grid or field count")
end
a.G = a.G + b.G;
a.N = a.N + b.N;
a.rhs = a.rhs + b.rhs;
a.cnt = a.cnt + b.cnt;

% A field's correction is the sum of its corrections in a and b. Fields
% that share a group in both stay together.
P = size(a.pairs, 1);
keys = [a.grp(:), b.grp(:)];
[ukeys, ~, ic] = unique(keys, 'rows');
new_grp = zeros(1, a.nf);
new_C = {};
for u = 1:size(ukeys, 1)
    ga = ukeys(u, 1);
    gb = ukeys(u, 2);
    if ga == 0 && gb == 0, continue, end
    Cg = zeros(a.npts, P);
    if ga > 0, Cg = Cg + a.C{ga}; end
    if gb > 0, Cg = Cg + b.C{gb}; end
    new_C{end+1} = Cg; %#ok<AGROW>
    new_grp(ic == u) = numel(new_C);
end
a.C = new_C;
a.grp = new_grp;
end
