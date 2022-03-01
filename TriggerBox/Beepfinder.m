% BeepFinder V2.0
% find beeps in vesper audio data, using short term fourier transfromation
% and 2D-cross-corelation of frequency (2000-3000Hz).

% Siyang Hao
% Brown University,
% 06-Jul-2021
% siyang_hao@brown.edu

% put the script under same dir of wav files,
% run the script can automaticaly read beep time in date time (or datetime serial 
% by disable datetime function)
% need manual check... normally it will find more(fake) beeps....
beep=zeros();
file = dir('*.wav');
for i =1:length(file)
    filename = file(i).name;
    audio = read_beep(filename);
    beep = [beep audio.beep];
    n=length(audio.beep)
   
end
beeptime =  datetime(beep,'ConvertFrom','datenum') % print data-time in command window
save('beeptime.txt','beep','-ascii') % save beep time to txt file

function audio = read_beep(audio_file)

close all
beepsample= load('beepsample.mat');
%% get the time data
timeStr         = regexp(audio_file,'(\d*_\d*_*\d_\d*_\d*_\d*_\d*.\d\d.\d*)','match');
audio.timeStart = datenum(timeStr{1},'yy_mm_dd_HH_MM_SS.FFF');
audio.timeEnd   = datenum(timeStr{2},'yy_mm_dd_HH_MM_SS.FFF');

[audio.data, fs]      = audioread(audio_file);
sig = audio.data;
% correct sample rate
audio.timeDiffSec   = (audio.timeEnd - audio.timeStart)*24*60*60; %in Secs
audio.samples       = length(audio.data);
audio.sampleRateAcc = audio.samples/audio.timeDiffSec; % Sep/Sec
audio.time          = linspace(audio.timeStart, audio.timeEnd, audio.samples);% serial date number

fprintf('AUD file: %s\n', audio_file);
fprintf('   NPTS: %d;  Rate: %f\n', audio.samples, audio.sampleRateAcc);
% fprintf('   Time [usec] %12d - %12d\n', ...
%     round(audio.timeStart*24*60*60*1000), round(audio.timeEnd*24*60*60*1000))

%% STFT

 window = round(fs/10); % 0.1s time scale/2000hz
 noverlap = 0.8*window; %default 50%
 f = linspace(2100, 2800, 60);   % scan band of freq

 [~, f, t, p] = spectrogram(sig, window, noverlap, f, fs);

% figure;
% contour(t, f, p);xlabel('Samples'); ylabel('Freqency');
% colorbar;
% stft(y,20000,'Window','FFTLength',10000,'OverlapLength',500) 
%% beep picking logic
r = xcorr2(p,beepsample.double); % cross corelation on power spectrum
% figure
% contour(r);
% colorbar;
R = sum(r(59:61,:)); % anti dopler effect
R_norm = R/mean(R); % normalize correlation matrix
% plot(R_norm)
[pks,y]=findpeaks(R_norm,'MinPeakHeight',7,'MinPeakDistance',15); % find peaks 
% powerlevel_2700 = sum(p(49:54,:));
% figure
% contour(t,f,p); xlabel('time,[s]'); ylabel('Freqency,[Hz]');
% colorbar

%%
% k = find(p(28,:)>1.5e-5,1);
% beeptime(1) = t(k);
truebeep = [];
f1 = figure;
for i = 1:length(y)
    beeppos= y(i)-size(beepsample.double,2)+1;
    a = p([5 15 45 55],beeppos-10:beeppos+10)>1e-5; % noise level on freq domain
    
     if sum(sum(a))== 0 % exam noise level on freq domain
          
         if pks(i)<50 % manually select
             
             contour(t, f, p);xlabel('Time,[s]'); ylabel('Freqency,[Hz]');
             hold on
             rectangle('position',[t(beeppos) 2670 1 60] ,'edgecolor','r');
             hold off
             
             prompt = 'Is this a beep? Hit [Enter] to confirm/ [N] to deny \n';
            
             str = input(prompt,'s');
              figure(f1)
               if isempty(str)
                  disp('beep found by user');
                  truebeep =  [truebeep, beeppos];
               else
                   disp('fake beep denied')
                  
               end
         else
             disp('beep found automatically');
             truebeep =  [truebeep, beeppos];
         end
     
     else
      disp('noise filted out');    
     end
end
        scale=size(sig,1)/size(t,2);
        audio.beep =[];

        j=round(scale.*truebeep);
        audio.beep= audio.time(j);
        
   end
   
