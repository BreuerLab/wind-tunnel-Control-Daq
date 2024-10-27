function [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements(flapper)
    % All distances are measuremed in meters

    if (flapper == "Flapperoo")
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.06335;
        chord = 0.10;
        wing_length = 0.25;
        arm_length = 0.016;
    
        % spanwise location of COM
        COM_span = 0.08; % from root of wing
        COM_span = COM_span + arm_length;
    elseif (flapper == "MetaBird")
        % ALL THESE VALUES NEED TO BE RE-EVALUATED
        center_to_LE = 0.04;
        chord = 0.0582; % mean chord
        wing_length = 0.0967; % mean span
        arm_length = 0.001;

        % spanwise location of COM
        COM_span = 0.05; % from root of wing
        COM_span = COM_span + arm_length;
    else
        error("Flapper: " + flapper + " not recognized")
    end
end

