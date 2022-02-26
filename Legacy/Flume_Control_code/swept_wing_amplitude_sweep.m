
f_pitch = 0.25;
amp_pitch = 10:10:120;

for i = 1:1:length(amp_pitch)
    [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(f_pitch,0,0,0,0,amp_pitch(i),0,0,0,15,90);
    save(sprintf('022219_NACA0012_c10_AR3_U05_swept_0_endplate_top_pitch_amp%d.mat',amp_pitch(i)));
end


