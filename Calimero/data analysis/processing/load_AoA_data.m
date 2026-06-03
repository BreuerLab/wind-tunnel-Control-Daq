function load_AoA_data(baseFolder, modFileName)
%LOAD_AOA_DATA Loads all variables from a .mat file into the caller workspace.
%   This makes filtered_data, norm_factors, etc. immediately accessible
%   in the function that called load_AoA_data.

    filePath = fullfile(baseFolder, modFileName);
    maxTries = 5;

    for k = 1:maxTries
        if isfile(filePath)
            % Load everything into a struct first
            S = load(filePath);

            % Inject all fields into caller workspace
            fn = fieldnames(S);
            for i = 1:numel(fn)
                assignin('caller', fn{i}, S.(fn{i}));
            end
            return
        end
        pause(1); % wait 1 second before retry
    end

    error("load_AoA_data:FileNotFound", ...
          "File not found after %d attempts:\n%s", maxTries, filePath);
end
