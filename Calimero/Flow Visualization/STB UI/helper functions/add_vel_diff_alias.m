function S = add_vel_diff_alias(S)
% Files processed before lift.vel was renamed to lift.vel_diff (the
% (u+U)*w velocity term from get_wake_lift) only have a "vel" field. For
% any struct in S (e.g. lift, lift_phase_avg) that has "vel" but no
% "vel_diff", copy it across so older files keep working until they are
% reprocessed.
names = fieldnames(S);
for k = 1:numel(names)
    sub = S.(names{k});
    if isstruct(sub) && isscalar(sub) && isfield(sub, 'vel') && ~isfield(sub, 'vel_diff')
        S.(names{k}).vel_diff = sub.vel;
    end
end
end
