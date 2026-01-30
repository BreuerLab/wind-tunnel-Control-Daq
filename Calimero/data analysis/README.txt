-----------------------------------------------------------
------------------- Data Analysis Scheme ------------------
-----------------------------------------------------------

The raw data from the experiment must be processed before
further analysis. See process_trial.m for those steps in detail
but they include trimming, filtering, rotating.

It is easier to store processed files rather than processing
the data anew each time you wish to view the results.

Since we often focus on examining trends with angle of attack,
it is also easier to store the data for those plots rather than
moving through dozens if not hundreds of processed files to
produce those plots each time.

Here we are favoring quick data access at the cost of data
storage. If we processed everything live, we wouldn't need to
store as much on the PC, but it would take a while for each
plot to be produced.

-----------------------------------------------------------
------------------- Data Analysis Steps -------------------
-----------------------------------------------------------

Comb through the data, deleting any 'bad data'. For example,
say you restarted data collection. You should then remove the
data before you restarted data collection which had failed.
Additionally you should remove any repeat data. Say you did
-16 degrees multiple times, only keep the last data set.

In the processing folder, run process_all_trials.m to process
all the data you've collected at a given wind speed and wing
type. Once the processed data is prepared, run
compare_trials_AoA.m to prepare the data for plotting
variation with angle of attack.

Then in the plotting UI folder run main_analysis.m to plot
the data in the GUI.