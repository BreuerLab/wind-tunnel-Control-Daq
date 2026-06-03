% The callback function
function recCallback(~, event, ref)
    % This callback is triggered on each DR record event.
    %
    % Inputs:
    %   ~, ~   : reserved for event signature
    %   g      : the Galil COM object

    % Retrieve one record
    rec = event.record;

    % Append it to the user data buffer
    ref.Data = [ref.Data rec];
end
