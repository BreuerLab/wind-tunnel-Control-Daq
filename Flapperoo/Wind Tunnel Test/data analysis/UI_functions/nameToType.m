function type = nameToType(flapper, name)
    if (flapper == "Flapperoo")
        if (name == "Wings with Full Body")
            type = "blue wings";
        elseif (name == "Wings with Tail")
            type = "tail blue wings";
        elseif (name == "Wings with Half Body")
            type = "blue wings half body";
        elseif (name == "Full Body")
            type = "no wings";
        elseif (name == "Tail")
            type = "tail no wings";
        elseif (name == "Half Body")
            type = "half body no wings";
        elseif (name == "Inertial Wings with Full Body")
            type = "inertial wings";
        end
    elseif (flapper == "MetaBird")
        if (name == "Wings with Tail (Low)")
            type = "full body short tail low";
        end
    else
        type = name;
    end
end