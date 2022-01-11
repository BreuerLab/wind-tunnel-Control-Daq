clear;
nb_step = 45;
meas_length = 600;
Chord = 0.1 ; U = 0.5;

% Freq sweep
for redfreq = 0.18
    for pitch = 65
        for ii = 0:(nb_step)
            freq = redfreq*U/Chord;
            [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(freq,00,0,0,0,pitch,1,0,0,25,95);
            pause (1);
            save(sprintf('sweep_6chords_velocity05ms_Heave_1_redfreq_%d_pitch_%d_%d.mat', redfreq, pitch, ii));
            if ii ~= nb_step
                move_traverse_walker(meas_length/nb_step,0);
            end
        end
        move_traverse_walker(-meas_length,0);
        pause(25);
        
    end
    
end

for redfreq = 0.15
    for pitch = 65
        for ii = 0:(nb_step)
            freq = redfreq*U/Chord;
            [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(freq,00,0,0,0,pitch,1,0,0,25,95);
            pause (1);
            save(sprintf('sweep_6chords_velocity05ms_Heave_1_redfreq_%d_pitch_%d_%d.mat', redfreq, pitch, ii));
            if ii ~= nb_step
                move_traverse_walker(meas_length/nb_step,0);
            end
        end
        move_traverse_walker(-meas_length,0);
        pause(25);
        
    end
    
end


% Pitch Sweep 

for redfreq = 0.12
    for pitch = 55:10:85
        for ii = 0:(nb_step)
            freq = redfreq*U/Chord;
            [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(freq,00,0,0,0,pitch,1,0,0,25,95);
            pause (1);
            save(sprintf('sweep_6chords_velocity05ms_Heave_1_redfreq_%d_pitch_%d_%d.mat', redfreq, pitch, ii));
            if ii ~= nb_step
                move_traverse_walker(meas_length/nb_step,0);
            end
        end
        move_traverse_walker(-meas_length,0);
        pause(25);
        
    end
    
end