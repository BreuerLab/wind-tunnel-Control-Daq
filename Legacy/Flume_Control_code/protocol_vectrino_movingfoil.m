
function [complete_array_trino,complete_array_vec, velocity , STD ] = protocol_vectrino_v1
% the vectrino should be placed in the y minimum of the range of
% measurement () where y is at his minimum) 
% traverse should be initialized manually
% We still need to implement the moving of the Vector.

prompt = {'Enter measurement length (in mm): ','Enter desired number of steps (>=1): '};
name = 'Protocol Configuration';
num_lines = 1;
defaultanswer = {'0.0','1'};
answer = inputdlg(prompt,name,num_lines,defaultanswer);

meas_length = str2num(answer{1});
nb_step = str2num(answer{2});


% getting the data
for i = 0:(nb_step) 
 
 v
  A = flume; 
  A_trino = A.Vectrino ;  

  
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Rewriting my_phaseaveraging here %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  %% define variables
%clearvars -except flume
fs = A.foil3.sampling_rate; % sampling frequency [Hz]
  ds = 40; % down sample
  fsd = 25; % down-sampled frequency (i,e. 25 Hz )

% find U_inf
pts_initial = 600;
U_x = mean(hampel(A.out(1:pts_initial,13))); % streamwise
U_y = mean(hampel(A.out(1:pts_initial,14))); % flow_normal
U_z = (mean(hampel(A.out(1:pts_initial,15)))+mean(hampel(A.out(1:pts_initial,16))))/2; % flow out-of-plane
U_inf = sqrt(U_x^2 + U_y^2 + U_z^2);  

Uinf = [U_x; U_y; U_z; U_inf];

%   Question: the length of ux and that of pitch_pos do not match...WHY?
ux1 = A.foil3.Ux(1:ds:end-1); % Vectrino's streamwise velocity (is this correct?)
uy1 = A.foil3.Uy(1:ds:end-1); % Vectrino's flow-normal velocity
uz1 = A.foil3.Uz(1:ds:end-1); % Vectrino's out-of-plane velocity
t = A.foil3.t_sec(1:ds:end); % time in sec.
% Filter drop-outs
%k = 1; % drop-outs are typically one single point
ux = hampel(ux1);
uy = hampel(uy1);
uz = hampel(uz1);
theta = A.foil3.pitch_pos(1:ds:end); % hydrofoil's geometric angle of attack
heave = A.foil3.heave_pos(1:ds:end); % hydrofoil's heave position
%theta = heave; % for some reason there is nothing for theta
%phi_phase = pi/2;% phase change
%theta = ((heave - 0) .* (pi - -pi) ./ (2 - 0) + -pi + phi_phase);% simulating pitch from heave
%Nbins = round(1/0.8*fsd);
%Nbins = 30; % # of bins (your can change this number, e.g. 30 60 etc.)
%% Evaluate the pitch (or heave) frequency (FFT)
sr = length(t)/(t(end)-t(1));
Nfft = 2^nextpow2(length(theta)*2);
rF = [0:(Nfft-1)]*sr/Nfft;
Y  = fft(theta-mean(theta),Nfft);
pY = Y.*conj(Y);
fp = rF(find(pY==max(pY),1)); %  hydrofoil's driving frequency
%% Define filter parameter
fnorm = 5*fp/(fsd/2); % cut-off frequency to 5 times the pitching frequency
[b1, a1] = butter(6,fnorm,'low'); % 6th order Butterworth LPF

theta = filtfilt(b1,a1,theta); % filtered angular position signal
ux_f = filtfilt(b1,a1,ux);  % filtered streamwise vel.
uy_f = filtfilt(b1,a1,uy);  % filtered flow-normal vel.
uz_f = filtfilt(b1,a1,uz);  % filtered out-of-plane vel.


% ni = 1000;
% nf = 1500;
% figure (100)
% plot(t(ni:nf),ux1(ni:nf)), hold on
% plot(t(ni:nf),ux_f(ni:nf),'r','linewidth',1)
% legend('raw vectrino','filtered vectrino (Hampel + 6th order Butterworth')
% xlabel('time, t (sec.)')
% ylabel('Ux (m/s)')
% grid on

ux = ux_f;
uy = uy_f;
uz = uz_f;
%% Phase average

%binend= 2*pi * ([1:Nbins]/Nbins - 0.5);
binend = linspace(-pi, pi, Nbins);
binI = zeros([length(theta), 1]);
phi = zeros([length(theta), 1]);
a = zeros([length(theta), 1]);
h = zeros([length(theta),1]);

% Evaluate the instantaneous phase
ht=hilbert(theta);
phi=angle(ht);  % phase (-pi to +pi)
%plot(t,phi), hold on, plot(t, theta,'r')
%% loop through
XX = length(ux);
%% loop through times and phase bin
for i = 1:XX %length(vSa),
    %%
    binI(i) = find(phi(i) <= binend,1,'first');
end
%% loop through PIV, organize bins

bindata(length(binend)) = struct(...
    'Uinf',[], 'bUx',[],'bUy',[],'bUz',[],'ba',[],'bh',[],'bphi',[],...   % "b" denotes bin
    'mUx',[],'mUy',[],'mUz',[],'ma',[],'mh',[],'mphi',[],...   % "m" denotes mean
    'sUx',[],'sUy',[],'sUz',[],'sa',[],'sh',[],'sphi',[]);     % "s" denotes standard deviation
for i = 1:length(binend),
    
    %%
    bIs = find(binI==i);
    bindata(i).Uinf = Uinf;
    % bin data
    bindata(i).bUx = ux(bIs);
    bindata(i).bUy = uy(bIs);
    bindata(i).bUz = uz(bIs);
    bindata(i).ba = theta(bIs);
    bindata(i).bphi = phi(bIs);
    bindata(i).bh = heave(bIs);
    
    % mean data
    bindata(i).mM =  length(a(bIs));
    bindata(i).mUx = sum(bindata(i).bUx)./bindata(i).mM;
    bindata(i).mUy = sum(bindata(i).bUy)./bindata(i).mM;
    bindata(i).mUz = sum(bindata(i).bUz)./bindata(i).mM;
    bindata(i).ma = mean(theta(bIs));
    bindata(i).mphi = mean(phi(bIs));
    bindata(i).mh = mean(heave(bIs));
    
    bindata(i).mUx(isnan(bindata(i).mUx))=0;
    bindata(i).mUy(isnan(bindata(i).mUy))=0;
    bindata(i).mUz(isnan(bindata(i).mUz))=0;
    
    % standard deviation
    bindata(i).sUx = std(ux(bIs));
    bindata(i).sUy = std(uy(bIs));
    bindata(i).sUz = std(uz(bIs));
    bindata(i).sa = std(theta(bIs));
    bindata(i).sphi = std(phi(bIs));
    bindata(i).sh = std(heave(bIs));
    
    bindata(i).sUx(isnan(bindata(i).sUx))=0;
    bindata(i).sUy(isnan(bindata(i).sUy))=0;
    bindata(i).sUz(isnan(bindata(i).sUz))=0;
    
    triple=bUx;
  
end
  

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % End of my_phaseaveraging 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
 
  if i == 0
     tempo_trino = A_trino(:,2:end);
     
  else 
     tempo_trino = horzcat(tempo_trino,A_trino(:,2:end));
  end
  
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0); 
  end
  
  complete_array_trino = tempo_trino;
  
end
  
  
%Processing data
% Averaged velocity
Velocity_mean_trino_tempo = mean(complete_array_trino);

for i = 1:(nb_step+1)
  if i == 1
        Ux_trino = Velocity_mean_trino_tempo (:,1); 
        Uy_trino = Velocity_mean_trino_tempo (:,2);
        Uz_trino = Velocity_mean_trino_tempo (:,3);          
  else 
        Ux_trino = horzcat(Ux_trino, Velocity_mean_trino_tempo (:,3*(i-1) +1 )); 
        Uy_trino = horzcat(Uy_trino, Velocity_mean_trino_tempo (:,3*(i-1) +2 ));
        Uz_trino = horzcat(Uz_trino, Velocity_mean_trino_tempo (:,3*(i-1) +3 ));
  end
       
end
Velocity_mean_trino = [Ux_trino', Uy_trino', Uz_trino' ]; 
velocity = Velocity_mean_trino;
end

%Processing data
% Standard deviation of velocity

STD_trino_tempo = std(complete_array_trino);

for i = 1:(nb_step+1)
  if i == 1
         STDx_trino = STD_trino_tempo(:,1);
         STDy_trino = STD_trino_tempo (:,2);
         STDz_trino = STD_trino_tempo (:,3);
     
  else 
         STDx_trino = horzcat(STDx_trino, STD_trino_tempo (:,3*(i-1) +1 ));
         STDy_trino = horzcat(STDy_trino, STD_trino_tempo (:,3*(i-1) +2 ));
         STDz_trino = horzcat(STDz_trino, STD_trino_tempo (:,3*(i-1) +3 ));
  end
       
end
STD_trino = [STDx_trino', STDy_trino', STDz_trino' ]; 
STD = STD_trino;
end


% Velocity_mean_trino_tempo = mean(complete_array_trino);
% Velocity_mean_vec_tempo = mean(complete_array_vec); 
% 
% for i = 1:(nb_step)
%   if i == 1
%      Ux_trino = Velocity_mean_trino_tempo (:,1);
%      Uy_trino = Velocity_mean_trino_tempo (:,2);
%      Uz_trino = Velocity_mean_trino_tempo (:,3);
%      Ux_vec = Velocity_mean_vec_tempo (:,1);
%      Uy_vec = Velocity_mean_vec_tempo (:,2);
%      Uz_vec = Velocity_mean_vec_tempo (:,3);
%           
%   else 
%      Ux_trino = horzcat(Ux_trino, Velocity_mean_trino_tempo (:,3*(i-1) +1 ));
%      Uy_trino = horzcat(Uy_trino, Velocity_mean_trino_tempo (:,3*(i-1) +2 ));
%      Uz_trino = horzcat(Uz_trino, Velocity_mean_trino_tempo (:,3*(i-1) +3 ));
%      Ux_vec = horzcat(Ux_vec, Velocity_mean_vec_tempo (:,3*(i-1) +1 ));
%      Uy_vec = horzcat(Uy_vec, Velocity_mean_vec_tempo (:,3*(i-1) +2 ));
%      Uz_vec = horzcat(Uz_vec, Velocity_mean_vec_tempo (:,3*(i-1) +3 ));
%   end
%        
% end
% Velocity_mean_trino = [Ux_trino', Uy_trino', Uz_trino' ]; 
% Velocity_mean_vec = [Ux_vec', Uy_vec', Uz_vec' ]; 




% [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(.5,00,0,0,0,40,1,0,0,10,90);
% A = flume; 
% A_trino = A.Vectrino ;
% 
% [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(.5,00,0,0,0,40,1,0,0,10,90);
% B = flume; 
% B_trino = B.Vectrino ;
% 
% [n_trino,m_trino] = size(A_trino); tableau = zeros(n_trino,m_trino);tempo8 = horzcat(tableau,A_trino); tempo9 = horzcat(tempo8,B_trino);
