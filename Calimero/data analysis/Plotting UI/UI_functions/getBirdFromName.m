function bird = getBirdFromName(flapper_name, Flapperoo, Calimero)

    if (flapper_name == "Flapperoo")
        bird = Flapperoo;
    elseif (flapper_name == "Calimero")
        bird = Calimero;
    else
        error("Oops. Unknown flapper name.")
    end

end