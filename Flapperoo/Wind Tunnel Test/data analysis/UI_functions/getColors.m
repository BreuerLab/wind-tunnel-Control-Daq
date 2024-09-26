function colors = getColors(num_dir, num_freq)
    if (num_dir > 2)
        disp("Not enough colors!")
        colors = ["#3BD9A5","#D9CD3B","#9E312C","#333268",...
        "#2C3331","#4BEA59";"#845A4F","#84804F","#673BD9","#D95A3B","#645099","#4F8473"];
        return;
    else
        max_count = num_freq;
        colors = strings(max_count, num_dir);
    end

    for i = 1:num_dir
    if (num_freq == 8)
        if (i == 1)
        colors(:,1) = ["#fee6ce";"#fdd0a2";"#fdae6b";"#fd8d3c";...
                    "#f16913";"#d94801";"#a63603";"#7f2704"];
        else
        colors(:,2) = ["#efedf5";"#dadaeb";"#bcbddc";"#9e9ac8";...
                    "#807dba";"#6a51a3";"#54278f";"#3f007d"];
        end
    elseif (num_freq == 7)
        if (i == 1)
        colors(:,1) = ["#fee6ce";"#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#f16913";"#d94801";"#8c2d04"];
        else
        colors(:,2) = ["#efedf5";"#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#807dba";"#6a51a3";"#4a1486"];
        end
    elseif (num_freq == 6)
        if (i == 1)
        colors(:,1) = ["#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#f16913";"#d94801";"#8c2d04"];
        else
        colors(:,2) = ["#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#807dba";"#6a51a3";"#4a1486"];
        end
    elseif (num_freq == 5)
        if (i == 1)
        colors(:,1) = ["#fdd0a2";"#fdae6b";"#fd8d3c";...
                       "#e6550d";"#a63603"];
        else
        colors(:,2) = ["#dadaeb";"#bcbddc";"#9e9ac8";...
                       "#756bb1";"#54278f"];
        end
    elseif (num_freq == 4)
        if (i == 1)
        colors(:,1) = ["#fdbe85";"#fd8d3c";"#e6550d";...
                       "#a63603"];
        else
        colors(:,2) = ["#cbc9e2";"#9e9ac8";"#756bb1";...
                       "#54278f"];
        end
    elseif (num_freq == 3)
        if (i == 1)
        colors(:,1) = ["#fdbe85";"#fd8d3c";"#d94701"];
        else
        colors(:,2) = ["#cbc9e2";"#9e9ac8";"#6a51a3"];
        end
    elseif (num_freq == 2)
        if (i == 1)
        colors(:,1) = ["#fdae6b";"#e6550d"];
        else
        colors(:,2) = ["#bcbddc";"#756bb1"];
        end
    elseif (num_freq == 1)
        if (i == 1)
        colors(:,1) = ["#e6550d"];
        else
        colors(:,2) = ["#756bb1"];
        end
    else
        colors = ["#3BD9A5";"#D9CD3B";"#9E312C";"#333268";...
        "#2C3331";"#4BEA59";"#845A4F";"#84804F";"#673BD9";"#D95A3B";"#645099";"#4F8473"];
    end
    end
end