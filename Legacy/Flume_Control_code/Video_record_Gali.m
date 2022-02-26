% Run flapping experiment and save video frames
clear
global Nframes fps
Date = datetime('today');
medium = 'water';
U = 0.5;      % flow velocity [m/s]
f = 1;      % frequency [Hz]
A = 0.1;    % heaving amplitude normalized by chord
theta = 0;  % pitching amplitude [deg]
Ncycles = 20;   % number of cycles

fps = 50;   % acquisition rate, frames per second
Nframes = fps*(Ncycles/f + 5);  % add 5 seconds buffer

Properties = [char(Date),'_',medium,'_U',num2str(U,'%.1f'),'_f',num2str(f,'%.2f'),'_h',num2str(A),'_p',num2str(theta)];
SaveFolder = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Camera_calibration\',Properties,'_fs',num2str(fps)];
% SaveFile = sprintf('Membrane_frame_%d_%2.2f.mat',ipp,curr_hpos);
if ~exist(SaveFolder)
    mkdir(SaveFolder);
end
cd(SaveFolder);

% Create video object
vid = CaptureVid;
preview(vid);
start(vid);
[flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20190408(f,0,0,0,0,theta,A,0,0,Ncycles,90);
wait(vid,25)
% wait(vid)
stoppreview(vid);
stop(vid);
[data time] = getdata(vid,vid.FramesAvailable);

delete(vid)
clear vid

% Save frames
v = VideoWriter(Properties);
open(v);
for iff=1:size(data,4)
    SaveFile = [char(Date),'_',medium,'_U',num2str(U,'%.1f'),'_f',num2str(f,'%.2f'),'_h',num2str(A),'_p',num2str(theta),'_frame',num2str(iff,'%04.0f'),'.bmp'];
    
    I = squeeze(data(:,:,1,iff));
    imwrite(I,SaveFile)

    writeVideo(v,I);

end
close(v);

save 'CamData.mat';
