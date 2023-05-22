function i = handle_next_trial(i, num_freqs) 
% Wait for user input before continuing
txt = input("Continue?    ","s");
positive_responses = ["y", "Y", "yes", "Yes", "ye", "Ye"];
negative_responses = ["n", "N", "no", "No", "nope", "Nope"];
input_val = 0;
while (input_val == 0)
    for n = 1:length(positive_responses)
        if(strcmp(txt, positive_responses(n)))
            input_val = 1;
        end
    end
    for n = 1:length(negative_responses)
        if(strcmp(txt, negative_responses(n)))
            input_val = 2;
        end
    end
    pause(1);
    if (input_val == 0)
        disp("Unaccepted Input...")
        txt = input("Continue?    ","s");
    elseif (input_val == 2)
        txt = input("Repeat?    ","s");
        for n = 1:length(positive_responses)
            if(strcmp(txt, positive_responses(n)))
                input_val = 3;
            end
        end
        if (input_val == 3)
            i = i - 1;
        else
            i = num_freqs + 1;
        end
    end
end

    % close all open figures from last trial
    close all
end