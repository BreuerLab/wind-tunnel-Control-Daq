galil_address = "192.168.1.3";
filename = "galil_clear.dmc";

% Connect to galil
try
    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f));
catch
    disp("Oops couldn't connect to Galil, trying again...")
    pause(2)

    galil = galil_setup(galil_address);
    % Ensure Galil stops motor when the run_trial function completes
    % (either on its own or termination by user)
    cleanup = onCleanup(@()myCleanupFun(galil, f));
end

dmc = fileread(filename);
dmc = string(dmc);

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);
% Command the galil to execute the program
galil.command("XQ");
