function acqTimes = checkFrameOrder(folderPIV)
    
    if isempty(folderPIV)
        error('Missing input argument: "folderPIV".');
    elseif isstring(folderPIV)
        folderPIV = convertStringsToChars(folderPIV);
    elseif ~ischar(folderPIV)
        error('Input "folderPIV" must be a character vector or string scalar.');
    end
    
    originalFolder = cd();
    restoreFolder = onCleanup(@() cd(originalFolder));
    
    files = dir(fullfile(folderPIV, '*.vc7'));
    if isempty(files)
        error('No ".vc7" files found in specified directory "folderPIV". Check path.')
    end
    
    configureReadimxPath();
    
    acqTimes = zeros(1,length(files));

    for i = 1:length(files)
        filePath = fullfile(folderPIV, files(i).name);
        acqTimes(i) = extractAcqTime(filePath);
        if mod(i,100) == 0
            disp(i + " / " + length(files))
        end
    end

    % ------------------------------------------
    % Check that acquisiton times are good
    % ------------------------------------------

    % Calculate time intervals between consecutive frames
    dt = diff(acqTimes);
    
    % Check strictly ascending order
    isAscending = all(dt > 0);

    % Check that dt is only 2 unqiue values
    uniq_dts = unique(dt);

    check_bool = isAscending & length(uniq_dts) == 2;

    disp("done")
end

function acqTime = extractAcqTime(filePath)
    rawFrame = readimx(filePath);
    acqTime = NaN;
    
    attributes = rawFrame.Frames{1}.Attributes;
    for attributeIndex = 1:length(attributes)
        if strcmp(attributes{attributeIndex}.Name, 'AcqTimeSeries')
            acqTime = str2double(attributes{attributeIndex}.Value(1:end-3)) * 10^-6;
            break
        end
    end
end