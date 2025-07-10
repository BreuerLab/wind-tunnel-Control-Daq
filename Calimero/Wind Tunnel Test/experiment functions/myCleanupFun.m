function myCleanupFun(galil, f)
    disp("Stopping Motors...")
    % Create the carraige return and linefeed variable from the .dmc file.
    dmc = fileread("galil_clear.dmc");
    dmc = string(dmc);
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    
    % Command the galil to execute the program
    galil.command("XQ");

    disp("Closing Diary...")
    diary off

    disp("Saving AoA figure...")
    time_now = datetime;
    time_now.Format = 'yyyy-MM-dd HH-mm-ss';
    saveas(f,'data\plots\compareAoA_' + string(time_now) + ".fig")

    % disp("Closing all files...")
    % fclose('all')
end