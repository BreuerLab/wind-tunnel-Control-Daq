
function [vec_inds] = TriggerFinder(High,Low,stateVals)
%TriggerFinder :find rising edge of a TTL/digital signal
%High: define the upper bound of signal
%Low: define the lowerbound of the signal
stateVals(stateVals>=High)=High;
stateVals(stateVals<=Low)=Low;
TriggerVals = diff(stateVals);
[~,vec_inds] =  findpeaks(TriggerVals);%,'MinPeakHeight',4);
end
