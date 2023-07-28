--------------------------------------------------------------------
--------------------------File Structure----------------------------
--------------------------------------------------------------------
old files - Files that I had used before which are no longer in active
            use. This folder can be ignored.
plotting - Matlab functions called by other files to produce a variety
           of plot types.
process trial - Matlab functions to process the data from a raw
                experiment csv file to a collection of variables
                describing the data from the experiment stored in a
                Matlab mat file. 
compare_trials_dot.m - Running this file you can produce scatter plots
                       showing the forces and moments vs. AoA. These
                       plots are characteristic of the typical
                       stability plots where the pitching moment is
                       plotted against angle of attack. You can
                       compare data from several different trials
                       simultaneously.
compare_trials_wingbeat.m - Running this file you can produce plots
                            showing the forces and moments over the
                            course of a wingbeat period on average.
                            You can compare data from several different
                            trials simultaneously. 
main.m - Running this file allows you to select any trial and plot the
         data from that trial.
dominant_freq_barchart.m - Running this file allows you to produce a
                           barchart showing how often certain
                           frequencies dominated the frequency spectrum
                           across a large group of trials. 
process_all_trials.m - This file is used to convert all csv files into
                       mat files. It is run once to produce the data
                       that's stored in the processed data folder.