Author: Ronan Gissler
Written on: June 02 2026

The codes here are used to process the STB vector field data from velocity
fields stored in vc7 files to velocity, vorticity, Q fields and more stored
in mat files. Two types of files are saved for each case: one containing field
variables (e.g. a matrix of velocity values) and one containing integral values
(e.g. lift force). This was done so that tweaks could be made to the calculation
of the integral values without having to recompute and save big matrices of
vector field results.

-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------
main_processing.m ->
	The main file to run when processing a single case.

main_processing_batch.m ->
	The main file to run when processing all cases. Only Calimero data is
supported here, not turbine data.

process_case.m ->
	Lower level function called by main_processing.m and
main_processing_batch.m that computes either the phase averaged data for turbine
and Calimero flapping cases or the time averaged data for Calimero gliding cases.

filepath setup ->
	files containing map between a particular case and its filepaths for
vc7 data, DAQ data (time series of laser firing and motor encoder), wind tunnel
data.

processing functions ->
	files that do the brunt of the 'processing' work, which includes the
phase averaging, time averaging, and calculation of secondary statistics (e.g.
lift force).

general functions ->
	functions that are used in the processing but are highly general and
could be used in any other code (e.g. calculating vorticity)
