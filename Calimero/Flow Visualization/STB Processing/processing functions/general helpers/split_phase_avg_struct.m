function [Sh, Sf, Sba] = split_phase_avg_struct(S, D)
% SPLIT_PHASE_AVG_STRUCT  Split phase_avg_STB's struct S (plus the DAQ
% struct D) into the shared part, the flow fields and the per-frame-
% averaged forces (stb_shared_names).
%
% The shared bin_placement is where the FRAMES of each bin sit (with
% harmonic regression S.bin_placement is 0 and S.bin_placement_frames holds
% it). The fields keep the method's own bin_placement, which
% merge_stb_structs lets take precedence.
    if nargin < 2, D = struct(); end
    [shared, before_avg] = stb_shared_names();
    Sh = struct();  Sf = struct();  Sba = struct();
    f = fieldnames(S);
    for i = 1:numel(f)
        n = f{i};
        if ismember(n, before_avg)
            Sba.(n) = S.(n);
        elseif ismember(n, shared) && ~strcmp(n, 'bin_placement')
            Sh.(n) = S.(n);
        elseif ~strcmp(n, 'bin_placement_frames')
            Sf.(n) = S.(n);                      % incl. the method's bin_placement
        end
    end
    if isfield(S, 'bin_placement_frames')
        Sh.bin_placement = S.bin_placement_frames;
    elseif isfield(S, 'bin_placement')
        Sh.bin_placement = S.bin_placement;
    end
    g = fieldnames(D);
    for i = 1:numel(g), Sh.(g{i}) = D.(g{i}); end
    if isfield(S, 'PIV_case_name'), Sf.PIV_case_name = S.PIV_case_name; end
end
