function sel = typeToSel(flapper, type)
    if (flapper == "Flapperoo")
        if (type == "blue wings")
            sel = "Full Wings";
        elseif (type == "tail blue wings")
            sel = "Tail Wings";
        elseif (type == "blue wings half body")
            sel = "Half Wings";
        elseif (type == "no wings")
            sel = "Full Body";
        elseif (type == "tail no wings")
            sel = "Tail Body";
        elseif (type == "half body no wings")
            sel = "Half Body";
        elseif (type == "inertial wings")
            sel = "Full Inertial";
        else
            sel = type;
        end
    elseif (flapper == "MetaBird")
        if (type == "full body short tail low")
            sel = "Tail Low Wings";
        end
    else
        sel = type;
    end
end