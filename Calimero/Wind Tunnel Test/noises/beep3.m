function beep3
% Play a sine wave
res = 22050;
len = 0.5 * res;
hz = 700;
sound( sin( hz*(2*pi*(0:len)/res) ), res);
end