function bird = getBirdFromName(flapper_name, Flapperoo, MetaBird)

    if (flapper_name == "Flapperoo")
        bird = Flapperoo;
    elseif (flapper_name == "MetaBird")
        bird = MetaBird;
    else
        error("Oops. Unknown flapper name.")
    end

end