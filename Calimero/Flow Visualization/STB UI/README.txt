Author: Ronan Gissler
Written on: June 02 2026

The codes here are used to produce graphical user interfaces for analyzing the
STB data stored in .mat files after having been processed by codes in the folder
'STB processing'. Each GUI file (STB_UI, compareWingbeatUI, or avgForceUI) is
a class to compactly organize things. The general structure of each one is to
first construct the basic appearance of the GUI (selection boxes on left hand
side and figure box on right hand side) and then to call a function called 
'update_plot' to update the plot each time after the user modifies the input to
one of the selection boxes.

-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------
main_analysis.m ->
	The main file to run which will call either STB_UI, compareWingbeatUI,
or avgForceUI.

flowField_UI.m ->
	Constructs a GUI for viewing vector field results (wake topology) in
a number of different formats.

phaseAvg_UI.m ->
	Constructs a GUI for viewing phase-averaged results (forces, kinematics
current, voltage, etc). X-axis here is time over a wingbeat

timeAvg_UI.m ->
	Constructs a GUI for viewing time-averaged results (forces, kinematics
current, voltage, etc).	X-axis here is wingbeat frequency

helper functions ->
	functions called by one of the '..._UI' files.