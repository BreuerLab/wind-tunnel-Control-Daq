function [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements()
    % distance from center of force transducer to leading edge of wing
    center_to_LE = 0.06335; % in meters
    chord = 0.10; % in meters
    % spanwise location of COM
    COM_span = 0.12; % in meters
    wing_length = 0.25; % in meters
    arm_length = 0.016; % in meters
end

