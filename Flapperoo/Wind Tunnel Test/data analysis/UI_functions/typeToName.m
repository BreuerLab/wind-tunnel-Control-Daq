function name = typeToName(flapper, type)
    if (flapper == "Flapperoo")
        if (type == "blue wings")
            name = "Wings with Full Body";
        elseif (type == "tail blue wings")
            name = "Wings with Tail";
        elseif (type == "blue wings half body")
            name = "Wings with Half Body";
        elseif (type == "no wings")
            name = "Full Body";
        elseif (type == "tail no wings")
            name = "Tail";
        elseif (type == "half body no wings")
            name = "Half Body";
        elseif (type == "inertial wings")
            name = "Inertial Wings with Full Body";
        end
    elseif (flapper == "MetaBird")
        if (type == "full body short tail low")
            name = "Wings with Tail (Low)";
        end
    else
        name = type;
    end
end