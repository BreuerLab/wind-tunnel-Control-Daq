function i = handle_next_AoA(i, AoA)

% Wait for user input before continuing
txt = input("Continue to next AoA?    ","s");
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
        txt = input("Continue to next AoA?    ","s");
    elseif (input_val == 2)
        i = length(AoA) + 1; % end now
    end
end
end