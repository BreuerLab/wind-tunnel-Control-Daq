function [out] = my_phaseaveraging(filename, Nbins, PLOT)
%% Kyohei Onoue
%% 03152017
%% Edited by Michael Manning
% close all
% clc
%% Load data
load(filename);
%% define variables
%clearvars -except flume
fs = flume.foil3.sampling_rate; % sampling frequency [Hz]
ds = 40; % down sample
fsd = 25; % down-sampled frequency (i,e. 25 Hz )

% find U_inf
pts_initial = 600;
U_x = mean(hampel(flume.out(1:pts_initial,13))); % streamwise
U_y = mean(hampel(flume.out(1:pts_initial,14))); % flow_normal
U_z = (mean(hampel(flume.out(1:pts_initial,15)))+mean(hampel(flume.out(1:pts_initial,16))))/2; % flow out-of-plane
U_inf = sqrt(U_x^2 + U_y^2 + U_z^2);

Uinf = [U_x; U_y; U_z; U_inf];

%   Question: the length of ux and that of pitch_pos do not match...WHY?
ux1 = flume.foil3.Ux(1:ds:end-1); % Vectrino's streamwise velocity (is this correct?)
uy1 = flume.foil3.Uy(1:ds:end-1); % Vectrino's flow-normal velocity
uz1 = flume.foil3.Uz(1:ds:end-1); % Vectrino's out-of-plane velocity
t = flume.foil3.t_sec(1:ds:end); % time in sec.
% Filter drop-outs
%k = 1; % drop-outs are typically one single point
ux = hampel(ux1);
uy = hampel(uy1);
uz = hampel(uz1);
theta = flume.foil3.pitch_pos(1:ds:end); % hydrofoil's geometric angle of attack
heave = flume.foil3.heave_pos(1:ds:end); % hydrofoil's heave position
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
    
end

%% collect output
pla_results.bindata = bindata;
pla_results_PA = pla_results;
%% plot something!
if PLOT
    figure (200)
    subplot(1,3,1)
    plot([bindata.mphi], [bindata.mUx]/U_inf,'bo'), hold on
    errorbar([bindata.mphi], [bindata.mUx]/U_inf, [bindata.sUx]/U_inf,'.b')
    axis([-pi pi 0.5 1.5])
    grid on
    set(gca,'fontsize',14)
    xlabel('Phase, \phi (rad.)','fontsize',14)
    ylabel('Streamwise velocity, U_x/U_{\infty} ','fontsize',14)
    
    subplot(1,3,2)
    plot([bindata.mphi], [bindata.mUy]/U_inf,'ro'), hold on
    errorbar([bindata.mphi], [bindata.mUy]/U_inf, [bindata.sUy]/U_inf,'.r')
    axis([-pi pi -0.6 0.6])
    grid on
    set(gca,'fontsize',14)
    xlabel('Phase, \phi (rad.)','fontsize',14)
    ylabel('Flow-normal velocity, U_y/U_{\infty} ','fontsize',14)
    
    subplot(1,3,3)
    plot([bindata.mphi], [bindata.mUz]/U_inf,'ko'), hold on
    errorbar([bindata.mphi], [bindata.mUz]/U_inf, [bindata.sUz]/U_inf,'.k')
    axis([-pi pi -0.5 0.5])
    grid on
    set(gca,'fontsize',14)
    xlabel('Phase, \phi (rad.)','fontsize',14)
    ylabel('Out-of-plane velocity, U_z/U_{\infty} ','fontsize',14)
    
    figure(300)
    plot([bindata.mphi], [bindata.ma],'ko:'), hold on
    axis([-pi pi -1.5 1.5])
    grid on
    set(gca,'fontsize',14)
    xlabel('Phase, \phi (rad.)','fontsize',14)
    ylabel('Angular position, \alpha (rad.) ','fontsize',14)
end
%% Save results
%save('data.mat', 'pla_results_PA','-v7.3')

%%
Len = zeros(1,Nbins);
for ii = 1:Nbins
    Len(ii) = length(bindata(ii).bUx);
end


%%

out = bindata;
end