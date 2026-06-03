Author: Ronan Gissler
Written on: June 02 2026


The codes here are all those required to process and plot STB data, particularly
for Calimero data although wind turbine data is also supported.


-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------

STB processing ->
	Functions for processing and saving vector fields from velocity fields stored
in vc7s to velocity, vorticity, Q fields, and more stored in mat files.

loadpiv_3D ->
	loadpiv is a Breuer lab code that Ronan modified here to accommodate STB
data.

STB UI ->
	Functions for plotting processed STB data in a graphical user interface for
easy data exploration.

Plotting ->
	Functions for plotting vector fields

helmholtz extrapolation ->
	Codes for extrapolating the flowfield using the vorticity field (vorticity
to stream function to velocity)

Old - 2D ->
	Out of use codes from first version of data processing when Ronan collected
data pre-DFD 2025 using stereo-PIV.

Calimero properties ->
	Function that include parameters specific to the Calimero geometry

Calimero experiment setup ->
	Codes used during the initial phase of the STB experiment to select an
appropriate plano-concave lens for fanning the laser beam and to place the 
telescope at the appropriate position to achieve the desired beam thickness.
	