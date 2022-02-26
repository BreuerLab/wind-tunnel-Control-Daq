
clear;
nb_step = 45;
meas_length = 600;
num_chords = 6;

for freq = 0.4:0.1:0.8
    for pitch = 65
        for ii = 0:(nb_step)
            [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(freq,00,0,0,0,pitch,0.5,0,0,25,95);
            pause (1);
            save(sprintf('chords_%d_freq_%d_pitch_%d_%d.mat', num_chords, freq, pitch, ii));
            if ii ~= nb_step
                move_traverse_walker(meas_length/nb_step,0);
            end
        end
        move_traverse_walker(-meas_length,0);
        pause(25);
    end
    
end

for freq = 0.6
    for pitch = [45 55 75 85]
        for ii = 0:(nb_step)
            [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(freq,00,0,0,0,pitch,0.5,0,0,25,95);
            pause (1);
            save(sprintf('chords_%d_freq_%d_pitch_%d_%d.mat', num_chords, freq, pitch, ii));
            if ii ~= nb_step
                move_traverse_walker(meas_length/nb_step,0);
            end
        end
        move_traverse_walker(-meas_length,0);
        pause(25);
    end
    
end