d = daq("ni");
addinput(d,"Dev1","ctr0","EdgeCount")
addinput(d,"Dev1","ai1","Voltage");
data = read(d,seconds(1),"OutputFormat","Matrix");
% data = read(d,"OutputFormat","Matrix");
plot(data)