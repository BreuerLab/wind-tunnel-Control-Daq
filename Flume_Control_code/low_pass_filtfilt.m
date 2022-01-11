function y = low_pass_filtfilt(varargin)
switch nargin
    case 1
        Fs = 1000;
    case 2
        Fs = varargin{2};
end
x = varargin{1};

% persistent lpFilt
% if isempty(lpFilt)
    
    Fpass = 50 ;   % Passband Frequency
    Fstop = 80;     % Stopband Frequency
    Apass = 1;     % Passband Ripple (dB)
    Astop = 60;    % Stopband Attenuation (dB)
%     Fs    = 100;  % Sampling Frequency
    
    lpFilt = designfilt('lowpassfir','PassbandFrequency',Fpass, ...
         'StopbandFrequency',Fstop,'PassbandRipple',Apass, ...
         'StopbandAttenuation',Astop,'DesignMethod','kaiserwin','SampleRate',Fs);
% end

% fvtool(lpFilt) %Visualize frequency response
% xlim([0 100])
% xlim([0 100])

y = filtfilt(lpFilt,x);