d = daq("ni");
% addinput(d,"Dev4","ctr0","EdgeCount")
addinput(d,"Dev4","ai1","Voltage");
data = read(d,seconds(1),"OutputFormat","Matrix");
% data = read(d,"OutputFormat","Matrix");
plot(data)