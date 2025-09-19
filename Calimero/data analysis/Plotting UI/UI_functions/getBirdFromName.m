function bird = getBirdFromName(flapper_name, Calimero)

    if (flapper_name == "Calimero")
        bird = Calimero;
    else
        error("Oops. Unknown flapper name.")
    end

end