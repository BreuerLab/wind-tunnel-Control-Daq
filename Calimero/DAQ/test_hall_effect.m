clear
close all

d = daq("ni");
d.addinput("Dev4", "port0/line25", "Digital");
d.addinput("Dev4", "ai20", "Voltage");

pause(5)
data = read(d,seconds(15),"OutputFormat","Matrix");
% data = read(d,"OutputFormat","Matrix");
figure
% plot(data)
plot(data(:,1))