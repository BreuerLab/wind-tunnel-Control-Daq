classdef slackMsg

properties
    url;
end

methods
    function obj = slackMsg(slack_path)
        % This url requires customization. In my case this url is
        % directed to the flapparoo channel on the BreuerLab slack
        % channel
        load(slack_path + "slackIDs.mat", "url");
        obj.url = url;
    end

    function send(obj, message_string)
        % The rest of the code can remain unchanged
        message = struct('text', message_string);
        json_message = jsonencode(message);
        
        options = weboptions('MediaType','application/json');
        response = webwrite(obj.url, json_message, options);
    end
end

end
