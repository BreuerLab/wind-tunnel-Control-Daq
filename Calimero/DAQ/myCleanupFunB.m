function myCleanupFun(galil)
    disp("Stopping Motors...")
    % Create the carraige return and linefeed variable from the .dmc file.
    dmc = fileread("galil_clear.dmc");
    dmc = string(dmc);
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    
    % Command the galil to execute the program
    galil.command("XQ");

    % galil.command("ST");
    % pause(0.2)
    % galil.command("MO");
end