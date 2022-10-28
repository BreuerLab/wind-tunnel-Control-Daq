flapping_amp = 30;
flapping_frequency = 3;
dt = round(1/flapping_frequency/4*1024);
amp = round(flapping_amp/360*8000);
angFreq = 2*pi*flapping_frequency;
spd = abs(round(amp*angFreq*sin(angFreq*1/flapping_frequency/4)));



% Connect to the Galil device.
        galil = actxserver("galil");

        % Set the Galil's address.
        galil.address = "192.168.1.20";%Open connections dialog box
galil.command("ST");
%dmc = fileread('program1.dmc');
dmc = fileread('HoldA.dmc');
dmc = string(dmc);
dmc = strrep(dmc, "timeholder",...
        num2str(dt));
dmc = strrep(dmc, "speedholder",...
        num2str(spd));
dmc = strrep(dmc, "ampholder",...
        num2str(amp));    



        % Load the program described by the .dmc file to the Galil device.
        galil.programDownload(dmc);
        galil.command("XQ");