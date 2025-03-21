% Calculate total number of trials
AoA = [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16];
freq = [0,0.1,2,2.5,3,3.5,3.75,4,4.5,5];
speed = [0,3,4,5,6];
% with and without wings
% half, full, tail
num_trials = (length(AoA) * length(freq) * length(speed) - 2*length(AoA)) * 6