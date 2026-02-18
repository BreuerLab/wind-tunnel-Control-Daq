function [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements(flapper)
    % All distances are measuremed in meters

    if (flapper == "Flapperoo")
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.06335;
        chord = 0.10;
        wing_length = 0.25;
        arm_length = 0.063;
        % arm length used to be 0.016, not sure where I got that # from now
    
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
    elseif (flapper == "Calimero")
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % ALL THESE VALUES NEED TO BE UPDATED
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.06335;
        chord = 0.10;
        wing_length = 0.216; % meters, distance from wingtip to axis of rotation
        arm_length = 0.063;
        % arm length used to be 0.016, not sure where I got that # from now
    
        % spanwise location of COM
        COM_span = 0.08; % from root of wing
        COM_span = COM_span + arm_length;
    elseif (flapper == "default") || strcmp(flapper, "default sub")
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % ALL THESE VALUES NEED TO BE UPDATED
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.03872; % vertical distance?
        chord = 0.073;
        wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        arm_length = 0.063;
        % arm length used to be 0.016, not sure where I got that # from now
    
        % spanwise location of COM
        COM_span = 0.08; % from root of wing
        COM_span = COM_span + arm_length;
    elseif  strcmp(flapper, "span_half") || strcmp(flapper, "span half sub") || strcmp(flapper, "span half")
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % ALL THESE VALUES NEED TO BE UPDATED
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.03872;
        chord = 0.073;
        wing_length = 0.1125; % meters, distance from wingtip to axis of rotation
        arm_length = 0.063;
        % arm length used to be 0.016, not sure where I got that # from now
    
        % spanwise location of COM
        COM_span = 0.08; % from root of wing
        COM_span = COM_span + arm_length;
    elseif (flapper == "chord_half") || strcmp(flapper, "chord half sub") || strcmp(flapper, "chord half")
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % ALL THESE VALUES NEED TO BE UPDATED
        % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        % distance from center of force transducer to leading edge of wing
        center_to_LE = 0.02047;
        chord = 0.0365;
        wing_length = 0.201; % meters, distance from wingtip to axis of rotation
        arm_length = 0.063;
        % arm length used to be 0.016, not sure where I got that # from now
    
        % spanwise location of COM
        COM_span = 0.08; % from root of wing
        COM_span = COM_span + arm_length;
    else
        error("Flapper: " + flapper + " not recognized")
    end
end

