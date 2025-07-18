function [distance_vals_chord, static_margin, slopes, x_ints] = findCOMrange(avg_results, AoA_sel, center_to_LE, chord, norm_bool, norm_factors)

    % ------------------------------------------------------------------
    % function assumes you are starting out with data measured at the
    % load cell rather than the leading edge (LE)
    % SO TURN OFF SHIFT PITCH
    % ------------------------------------------------------------------
    plot_bool = false;
    
    % increment to shift position where moments are considered
    diff_shift = 0.0001;

    pitch_moment = avg_results(5,:);

    % % get current slope of line based on regression
    % x = [ones(size(AoA_sel')), AoA_sel'];
    % y = pitch_moment';
    % b = x\y;
    % model = x*b;
    % og_Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    % og_slope = b(2);

    NP_pos = findNP(avg_results, AoA_sel);

    shift_distance_init = 2.5*chord - center_to_LE;
    max_shift_distance = center_to_LE + chord;
    [NP_pos_LE, NP_pos_chord] = posToChord(NP_pos, center_to_LE, chord);
    
    % shift_distance = NP_pos;
    % max_shift_distance = center_to_LE;

    % changed from 2*center_to_LE, seemed too big
    % Old comment:
    % this used to just be center_to_LE which would go all the
    % way from the NP to the LE (0% chord)

    slopes = NaN(1,10000);
    x_ints = NaN(1,10000);

    movie_bool = false;
    if (movie_bool)
        outputFolder = "COM_movie";
        mkdir(outputFolder)
    end

    shift_distance = shift_distance_init;
    iter = 0;
    while(shift_distance > -max_shift_distance)
        shifted_results = shiftPitchMom(avg_results, shift_distance, AoA_sel);
        shifted_pitch_moment = shifted_results(5,:);

        norm_shifted_results = dimensionless(shifted_results, norm_factors);
        norm_shifted_pitch_moment = norm_shifted_results(5,:);
    
        if (norm_bool)
            y = norm_shifted_pitch_moment';
        else
            y = shifted_pitch_moment';
        end

        x = [ones(size(AoA_sel')), AoA_sel'];
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        slope = b(2);
        x_int = - b(1) / b(2);

        shift_distance = shift_distance - diff_shift;
        iter = iter + 1;
        slopes(iter) = slope;
        x_ints(iter) = x_int;

        if (movie_bool && mod(iter,10) == 0)
        % Open a new figure.
        fig = figure;
        fig.Visible = "off";
        set(fig, 'Units','pixels','Position', [0, 0, 800, 800]);

        hold on
        scatter(AoA_sel, y, 'filled')
        plot(AoA_sel, model, 'k--')
        xline(0)
        yline(0)
        ylim([-2.5 2.5])

        exportgraphics(fig, fullfile(outputFolder, sprintf('frame%04d.png',iter)), ...
            'Resolution',300)

        disp(iter + " frames")
        end
    end

    if (movie_bool)
        % Save movie
        video_name = 'COM_shift.mp4';
        v = VideoWriter(video_name, 'MPEG-4');
        v.FrameRate = 20; % fps
        v.Quality = 100; % [0 - 100]
    
        open(v);
    
        % writeVideo(v,wingbeats_animation);
    
        frameFiles = dir(fullfile(outputFolder,'frame*.png'));
        for k = 1:length(frameFiles)
            % read each image
            img = imread(fullfile(outputFolder, frameFiles(k).name));
            writeVideo(v, img)
        end
    
        close(v);
    end

    % trim off remaining values at end
    slopes = slopes(~isnan(slopes));
    x_ints = x_ints(~isnan(x_ints));

    % distance_vals = linspace(NP_pos, shift_distance, iter);
    distance_vals = linspace(shift_distance_init, shift_distance, iter);
    [distance_vals_LE, distance_vals_chord] = posToChord(distance_vals, center_to_LE, chord);

    static_margin = NP_pos_chord - distance_vals_chord;

    if plot_bool
        figure
        plot(distance_vals_chord, slopes)
        xlabel("Shift Distance (% Chord)")
        ylabel("dM/d\alpha Slope")
    end

end