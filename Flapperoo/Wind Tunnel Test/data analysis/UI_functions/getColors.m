function colors = getColors(num_types, num_speeds, num_freq, num_cases)
    sorted_nums = sort([num_types, num_speeds]); % ascending
    if (num_cases > sorted_nums(2)*num_freq)
        disp("Woah, not ready to make all those colors")
        colors = ["#3BD9A5","#D9CD3B","#9E312C";...
                  "#333268","#2C3331","#4BEA59";...
                  "#845A4F","#84804F","#673BD9";...
                  "#D95A3B","#645099","#4F8473"];
    elseif (sorted_nums(2) > 4)
        disp("Ah, but I only have 4 color shade groups")
        colors = ["#3BD9A5","#D9CD3B";...
                  "#9E312C","#333268";...
                  "#2C3331","#4BEA59";...
                  "#845A4F","#84804F";...
                  "#673BD9","#D95A3B";...
                  "#645099","#4F8473"];
    else
        % max_count = num_freq;
        % colors = strings(max_count, num_types);

    % colors picked from colorbrewer2.org
    % 9-class oranges, 9-class purples, 9-class greens
    for i = 1:sorted_nums(2)
    if (num_freq == 8)
        if (i == 1) % oranges
        colors(:,1) = ["#fee6ce";"#fdd0a2";"#fdae6b";"#fd8d3c";...
                    "#f16913";"#d94801";"#a63603";"#7f2704"];
        elseif (i == 2) % purples
        colors(:,2) = ["#efedf5";"#dadaeb";"#bcbddc";"#9e9ac8";...
                    "#807dba";"#6a51a3";"#54278f";"#3f007d"];
        elseif (i == 3) % blues
        colors(:,3) = ["#deebf7";"#c6dbef";"#9ecae1";"#6baed6";...
                    "#4292c6";"#2171b5";"#08519c";"#08306b"];
        else % greens
       colors(:,4) = ["#e5f5e0";"#c7e9c0";"#a1d99b";"#74c476";...
                    "#41ab5d";"#238b45";"#006d2c";"#00441b"]; 
        end
    elseif (num_freq == 7)
        if (i == 1)
        colors(:,1) = ["#fee6ce";"#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#f16913";"#d94801";"#8c2d04"];
        elseif (i == 2)
        colors(:,2) = ["#efedf5";"#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#807dba";"#6a51a3";"#4a1486"];
        elseif (i == 3)
        colors(:,3) = ["#deebf7";"#c6dbef";"#9ecae1";"#6baed6";...
                       "#4292c6";"#2171b5";"#084594"];
        else
        colors(:,4) = ["#e5f5e0";"#c7e9c0";"#a1d99b";"#74c476";...
                       "#41ab5d";"#238b45";"#005a32"];
        end
    elseif (num_freq == 6)
        if (i == 1)
        colors(:,1) = ["#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#f16913";"#d94801";"#8c2d04"];
        elseif (i == 2)
        colors(:,2) = ["#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#807dba";"#6a51a3";"#4a1486"];
        elseif (i == 3)
        colors(:,3) = ["#c6dbef";"#9ecae1";"#6baed6";...
                       "#4292c6";"#2171b5";"#084594"];
        else
        colors(:,4) = ["#c7e9c0";"#a1d99b";"#74c476";...
                       "#41ab5d";"#238b45";"#005a32"];  
        end
    elseif (num_freq == 5)
        if (i == 1)
        colors(:,1) = ["#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#e6550d";"#a63603"];
        elseif (i == 2)
        colors(:,2) = ["#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#756bb1";"#54278f"];
        elseif (i == 3)
        colors(:,3) = ["#c6dbef";"#9ecae1";"#6baed6";...
                       "#3182bd";"#08519c"];
        else
        colors(:,4) = ["#c7e9c0";"#a1d99b";"#74c476";...
                       "#31a354";"#006d2c"];    
        end
    elseif (num_freq == 4)
        if (i == 1)
        colors(:,1) = ["#fdbe85";"#fd8d3c";"#e6550d";...
                       "#a63603"];
        elseif (i == 2)
        colors(:,2) = ["#cbc9e2";"#9e9ac8";"#756bb1";...
                       "#54278f"];
        elseif (i == 3)
        colors(:,3) = ["#bdd7e7";"#6baed6";"#3182bd";...
                       "#08519c"];
        else
        colors(:,4) = ["#bae4b3";"#74c476";"#31a354";...
                       "#006d2c"];    
        end
    elseif (num_freq == 3)
        if (i == 1)
        colors(:,1) = ["#fdbe85";"#fd8d3c";"#d94701"];
        elseif (i == 2)
        colors(:,2) = ["#cbc9e2";"#9e9ac8";"#6a51a3"];
        elseif (i == 3)
        colors(:,3) = ["#bdd7e7";"#6baed6";"#2171b5"];
        else
        colors(:,4) = ["#bae4b3";"#74c476";"#238b45"];    
        end
    elseif (num_freq == 2)
        if (i == 1)
        colors(:,1) = ["#fdae6b";"#e6550d"];
        elseif (i == 2)
        colors(:,2) = ["#bcbddc";"#756bb1"];
        elseif (i == 3)
        colors(:,3) = ["#9ecae1";"#3182bd"];
        else
        colors(:,4) = ["#a1d99b";"#31a354"];    
        end
    elseif (num_freq == 1)
        if (i == 1)
        colors(:,1) = ["#e6550d"];
        elseif (i == 2)
        colors(:,2) = ["#756bb1"];
        elseif (i == 3)
        colors(:,3) = ["#3182bd"];
        else
        colors(:,4) = ["#31a354"];    
        end
    else
        colors = ["#3BD9A5";"#D9CD3B";"#9E312C";"#333268";...
        "#2C3331";"#4BEA59";"#845A4F";"#84804F";"#673BD9";"#D95A3B";"#645099";"#4F8473"];
    end
    end
    end
end