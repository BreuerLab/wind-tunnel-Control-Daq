freq = .6:.2:1;
heave = .25:.25:1.25;


for ii = 1:numel(freq)
    for jj = 1:numel(heave)
        flume = run_cycle_3rigs(freq(ii),0,0,0,0,45,heave(jj),0,0,20,90);
        hdesired(ii,jj) = heave(jj);
        fdesired(ii,jj) = freq(ii);
        h0(ii,jj) = max(flume.foil3.heave_pos)/2;
        
        hphase(ii,jj) = find_phase(flume.foil3.t_sec,flume.foil3.heave_pos,freq(ii));
        pphase(ii,jj) = find_phase(flume.foil3.t_sec,flume.foil3.pitch_pos,freq(ii));
    end
end
deltaphase = hphase-pphase;


hrat = h0./hdesired;
