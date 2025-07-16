classdef flapper < handle % pass by reference instead of value
properties
    name;
    types;
    freqs;
    angles;
    speeds;
    AR;

    file_list;
    uniq_list;
    uniq_norm_list
    norm_list;
    shift_list;
    drift_list
end
methods
    function obj = flapper(name)
        obj.name = name;
        if (name == "Flapperoo")
            obj.types = ["Wings with Full Body", "Wings with Tail", ...
                "Wings with Half Body", "Full Body", "Tail", ...
                "Half Body", "Inertial Wings with Full Body", ...
                "Left Wing & Right Inertial", "No Shoulders"];
            obj.freqs = ["0 Hz", "0.1 Hz", "2 Hz", "2.5 Hz", "3 Hz", "3.5 Hz",...
                "3.75 Hz", "4 Hz", "4.5 Hz", "5 Hz", "2 Hz v2", "4 Hz v2"];
            obj.angles = [-16:1.5:-13 -12:1:-9 -8:0.5:8 9:1:12 13:1.5:16];
            obj.speeds = [0, 3, 4, 5, 6];
            obj.AR = 2.5;
        elseif (name == "Calimero")
            obj.types = ["flexible"];
            obj.freqs = ["0 PWM", "90 PWM", "120 PWM", "150 PWM", "180 PWM"];
            obj.angles = [-16:2:16];
            obj.speeds = [4];
            obj.AR = 2.5; % NEEDS UPDATING!
        elseif (name == "MetaBird")
            obj.types = ["Wings with Tail (Low)", "Wings", "Flipped Wings", "Body"];
            obj.freqs = ["0 Hz", "6 Hz", "8 Hz", "9 Hz", "12 Hz"];
            obj.angles = [-16:2:-10 -8:1:8 10:2:16];
            obj.speeds = [0, 2, 3, 4];
            obj.AR = 2.5; % NEEDS UPDATING!
        end

        obj.file_list = [];
        obj.uniq_list = [];
        obj.uniq_norm_list = [];
        obj.norm_list = [];
        obj.shift_list = [];
        obj.drift_list = [];
    end
end
end