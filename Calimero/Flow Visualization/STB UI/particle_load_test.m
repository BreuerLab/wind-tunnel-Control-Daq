clear

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
% addpath('...\Calimero\Flow Visualization\STB Processing\particle tracks')
addpath(genpath('../'))

P = loadSTBParticles("F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\ShakeTheBox 2-pulse.set");   % metadata only, quick check