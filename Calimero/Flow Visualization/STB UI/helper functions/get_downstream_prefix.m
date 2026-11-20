function prefix = get_downstream_prefix(type, include_upstream)
% Measurement-position prefix of an STB case type, including the trailing
% underscore: "x3_" for "x3_wings", "MPS_" for "MPS_wings", "" if none.
%
% New flapper positions are x1 ... x5 and MPS. With include_upstream =
% true the old flapper upstream positions (UP_one_, UP_two_) count too.
% Add new measurement positions here.

positions = '(x\d+|MPS)';
if nargin > 1 && include_upstream
    positions = '(x\d+|MPS|UP_one|UP_two)';
end

prefix = string(regexp(char(type), ['^' positions '_'], 'match', 'once'));
end
