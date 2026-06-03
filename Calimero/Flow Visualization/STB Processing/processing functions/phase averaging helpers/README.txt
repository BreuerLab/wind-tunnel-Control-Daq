Author: Ronan Gissler
Written on: June 02 2026

The codes here assist with the phase averaging process, mostly developing a map
between image frames and phase times, although another file is used to calculate
phase averaged kinematics and power consumption.

-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------
frame_to_bin.m ->
	Primary function used to translate assign image frames to their
corresponding phase bin number. This function calls findBestNumBins.m and 
get_norm_signal.m.

findBestNumBins.m ->
	Function that iteratively searches for the 'best' number of bins. The
program searches for the largest number of bins that still satisfies the
condition that each bin has at least X images and that the total number of bins
is divisible by 5.

get_norm_signal.m ->
	Finds the exact phase time corresponding to each image frame, either
using the motor position phase or the wingbeat time using the assumed wingbeat
frequency (rather than that measured). This exact phase time is binned later in
frame_to_bin.m.

speed_phase_avg.m ->
	Phase averages the kinematic data (motor position, speed, acceleration;
wing position, speed, acceleration) and the power consumption data (voltage and
current) using the motor position phase.

