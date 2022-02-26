% Run flapping experiment and save video frames
% Allow for frequency sweep
clear 
global Nframes fps
Date = datetime('today');
medium = 'water';
U = 0.5;      % flow velocity [m/s]
freq = [0.2:0.2:2]; %[0.2:0.1:1.0];     %[0.4,0.8]; %0.5;   %  [0.2,1,2];   %  0.5; % 1; %[0.5:0.1:1.0]; % % frequency [Hz]
A = 0.3;    % heaving amplitude normalized by chord
theta = 0; %-45; % % pitching amplitude [deg]
Ncycles = 20;   % number of cycles

% fps = 50;   % acquisition rate, frames per second

%% setup arduino
newobjs = instrfind;
delete(newobjs);
% clear all;
led = serial('COM17','BaudRate',9600);
fopen(led);
% fprintf(led,'%s',char(1));

for kk = 1:length(freq)
    f = freq(kk)
    fps = min(50,100*f);   % acquisition rate, frames per second

    Nframes = fps*(Ncycles/f + 5);  % add 5 seconds buffer
    
    Properties = [char(Date),'_',medium,'_U',num2str(U,'%.1f'),'_f',num2str(f,'%.2f'),'_h',num2str(A),'_p',num2str(theta)];
    SaveFolder = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Membrane_Heave\In_water\EmptyFrame_with_EndPlates_Heave\',Properties,'_cam_fs',num2str(fps)];
%     SaveFolder = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Rigid_plate_no_LE_water_heave'];
    % SaveFile = sprintf('Membrane_frame_%d_%2.2f.mat',ipp,curr_hpos);
    if ~exist(SaveFolder,'dir')
        mkdir(SaveFolder);
    end
    cd(SaveFolder);
    
%% Create video object
    vid = CaptureVid;
    preview(vid);
    start(vid);
    pause(2)
%     tempTime = clock
    tic
    fprintf(led,'%s',char(1));
    led_time(:,1) = clock;
    toc
%     [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20190408(f,0,0,0,0,theta,A,0,0,Ncycles,90);
    [flume,out,dat,Prof2,Prof_out,daq_timeStamps,daq_triggerTime] = run_cycle_3rigs_20190510(f,0,0,0,0,theta,A,0,0,Ncycles,90);
    fprintf(led,'%s',char(0));
    led_time(:,2) = clock;
    
    wait(vid,25)
%     wait(vid)
    stoppreview(vid);
    stop(vid);
    [data, time, metadata] = getdata(vid,vid.FramesAvailable);
    
    delete(vid)
    clear vid
    
    MeanLoads = mean(out(:,7:12))
%% Save frames
    v = VideoWriter(Properties);
    open(v);
    for iff=1:size(data,4)
        SaveFile = [char(Date),'_',medium,'_U',num2str(U,'%.1f'),'_f',num2str(f,'%.2f'),'_h',num2str(A),'_p',num2str(theta),'_frame',num2str(iff,'%04.0f'),'.bmp'];
        
        I = squeeze(data(:,:,1,iff));
        %imwrite(I,SaveFile)
        
        writeVideo(v,I);
        
    end
    close(v);
    
    save('CamData.mat', 'data','-v7.3')
    clear data
    cd ..
    save([Properties,'.mat']);
%     save 'CamData.mat';
%     clear data time
%     
% %     cd C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Camera_calibration\Test_Experiments_membrane_lambda0_1\
% %     cd ..
%     
end

fclose(led);
