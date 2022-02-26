Nbins = 41; % gives us actually 40 points - we like 40 because we can precisely identify t/T = 0, 0.25, 0.5, 0.75, 1
PLOT = 0;
fp = '/Volumes/FlumeData/Michael Manning/Data/';
direcs = dir([fp, 'THIS-10-Apr-2017-0p12fstar-065pitch*']);

h = waitbar(0,'Initializing waitbar...');
h2 = waitbar(0,'Initializing waitbar...');
%direc = '/Volumes/FlumeData/Michael Manning/Data/10-Apr-2017-0p12fstar/';
for j = 1:length(direcs);
    direc = [fp, direcs(j).name, '/'];
    files = dir([direc, 'flume*.mat']); % load all files in directory
    for i = 1:length(files)
        try
            filename = [direc, files(i).name];
            pos{i} = my_phaseaveraging(filename, Nbins, PLOT);
            waitbar(i/length(files),h2,'Run progress')
        catch ME
            e_string = ['There was an error while processing', direc];
            disp(e_string)
            disp(filename)
            continue
        end
    end
    save([fp,'processed27Apr/PROCESSED_', files(j).name(1:end-18), '.mat'],'pos');
    waitbar(j/length(direcs),h,'Bulk progress')
end