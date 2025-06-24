classdef slackProgressBar
% Things to do:
% enable chat:write for bot on Slack side
% /invite @Slack-bot in slack channel

properties
% Define Slack API token and channel ID
botToken;
channel;

% Define Slack API endpoint
urlPostMessage = 'https://slack.com/api/chat.postMessage';
urlUpdateMessage = 'https://slack.com/api/chat.update';
end

methods
% Get slack identifiers for accessing correct channel
function obj = slackProgressBar(slack_path)
    load(slack_path + "slackIDs.mat", "botToken", "channel");
    obj.botToken = botToken;
    obj.channel = channel;
end

% Define the initial progress bar message
function [channelID, ts] = makeBar(obj)
    headers = weboptions('HeaderFields',...
        {'Authorization', ['Bearer ' obj.botToken]},...
        'MediaType','application/json');
    initialMessage = struct('channel', obj.channel, 'text', 'Progress: [-----] 0% Complete');
    response = webwrite(obj.urlPostMessage, initialMessage, headers);
    % disp(response)
    ts = response.ts;
    channelID = response.channel;
end

% Define the function to update the progress
function updateProgress(obj, channelID, messageTs, progressPercentage)
    progressBar = [repmat('#', 1, floor(progressPercentage / 10)) repmat('-', 1, 10 - floor(progressPercentage / 10))];
    progressText = sprintf("Progress: [%s] %.2f%% Complete", progressBar, progressPercentage);
    headers = weboptions('HeaderFields',...
        {'Authorization', ['Bearer ' obj.botToken]},...
        'MediaType','application/json');
    updateMessage = struct('channel', channelID, 'text', progressText, 'ts', messageTs);
    response = webwrite(obj.urlUpdateMessage, updateMessage, headers);
    % disp(response);
end
end

end