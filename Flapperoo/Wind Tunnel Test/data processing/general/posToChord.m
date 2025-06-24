function [pos_LE, pos_chord] = posToChord(pos, center_to_LE, chord)
    pos_LE = pos + center_to_LE;
    pos_chord = (pos_LE / chord) * 100;
end

