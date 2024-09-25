--------------------------------------------------------------------
--------------------------File Structure----------------------------
--------------------------------------------------------------------
files who need some fixing - Files that can be used to create other nice
                             plots that may not be operational now
plotting - Matlab functions called by other files to produce a variety
           of plot types.
process trial - Matlab functions to process the data from a raw
                experiment csv file to a collection of variables
                describing the data from the experiment stored in a
                Matlab mat file. Before you can start plotting any data,
                you need to process it by running process_all_trials.m
compare_trials_AoA.m - Run this file to produce scatter plots showing the
                       forces and moments vs. AoA. You can compare data from
                       several different trials simultaneously. Looking at
                       the pitching moment vs. AoA plot we can assess the
                       static pitching stability.
main.m - Running this file allows you to select any trial and plot the
         data from that trial.