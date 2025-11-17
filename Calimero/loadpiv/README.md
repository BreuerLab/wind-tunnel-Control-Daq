# loadpiv
This MATLAB function extracts data from LaVision DaVis PIV files.
Extracts and formats data from "vc7" files contained in "folderPIV".

**IMPORTANT: For this function to work, the user must download the [MATLAB add-on provided by LaVision](https://www.lavision.de/en/downloads/software/matlab_add_ons.php) (i.e., the *readimx_WIN* or *readimx_MAC* folder).
Make sure the add-on corresponds to the correct Operating System.**

 **IMPORTANT NOTES:**
 - For this function to work, the *readimx* folder **MUST** be in your PATH.
 - Whenever new updates are made, PLEASE UPDATE THE DOCUMENTATION AND ADD A
   VERSION DESCRIPTION IN THE FORMAT SPECIFIED.
 -------------------------------------------------------------------------
 ## Sintax:

 `D = loadpiv(folderPIV)`

 `D = loadpiv(folderPIV, params, "nondim")`

 `D = loadpiv(folderPIV, "extractAllVariables")`

 `D = loadpiv(folderPIV, "numCamFields", 2)`

 `D = loadpiv(folderPIV, "frameRange", [1:2:100])`

 `D = loadpiv(folderPIV, "fovCenter", [-0.2, 3.1])`

 `D = loadpiv(folderPIV, "fovRot", 0.23)`

 `D = loadpiv(folderPIV, "Validate", 0.4)`

 -------------------------------------------------------------------------
 ### Mandatory inputs:

 `D = loadpiv(folderPIV)` : Extracts PIV data from directory "`folderPIV`" and stores it in the structure `D`.
           The directory must contain the ".vc7" files. Only extracts
           coordinates, velocity components, and z-vorticity. Depending on
           the dataset, the extracted variables might include the
           following: <br />
- `D.x` : x-coordinates matrix <br />
- `D.y` : y-coordinates matrix <br />
- `D.u` : x-velocity component <br />
- `D.v` : y-velocity component <br />
- `D.w` : z-velocity component <br />
- `D.vort` : z-vorticity component

 -------------------------------------------------------------------------
 ### Optional inputs:

 `D = loadpiv(__, params, "nondim")` : Extracts and non-dimensionalizes
           data using parameters contained in the structure "`params`".
           "`params`" must have the form: <br />
- `params.L` = characteristic_length <br />
- `params.U` = characteristic_velocity <br />

 `D = loadpiv(__, params, "extractAllVariables")` : Extracts all data
           found in the ".vc7" files. Depending on the dataset, the extract
           ed variables might include the following: <br />
- `D.x` : x-coordinates matrix <br />
- `D.y` : y-coordinates matrix <br />
- `D.u` : x-velocity component <br />
- `D.v` : y-velocity component <br />
- `D.w` : z-velocity component <br />
- `D.vort` : z-vorticity component <br />
- `D.corr` : correlation values <br />
- `D.uncU` : x-velocity uncertainty <br />
- `D.uncV` : y-velocity uncertainty <br />
- `D.uncW` : z-velocity uncertainty <br />

 -------------------------------------------------------------------------
 ### Name-value arguments:

 `D = loadpiv(__, "numCamFields", numCamera)` : Number of independent fields
               from different cameras. Used for processing.

 `D = loadpiv(__, "frameRange", frames)` : Specifies specific frames to
               be extracted instead of the full dataset. Must be followed
               by a 1D array containing the frame numbers.

 `D = loadpiv(__, "fovCenter", [xcntr, ycntr])` : Specifies the location
               of the desired origin of the coordinate axis. Must be
               followed by a `[xcntr, ycntr]` array specified in meters.

 `D = loadpiv(__, "fovRot", rotAngle)` : Specifies the rotation of the
               fov with respect to the origin. Must be followed by the
               angle's value in radians.

 `D = loadpiv(__, "Validate", minCorrelationValue)` : Sets a minimum
               correlation value, otherwise passes NaN-values.

 -------------------------------------------------------------------------
 ### Output arguments

 `D = loadpiv(__)` : outputs flow data in structure `D`.

 `[D,A] = loadpiv(__)` : outputs flow data in structure `D`, and recording
               attributes in structure `A`. Currently only outputs 
               **total acquisition time** in seconds.

 -------------------------------------------------------------------------
 ### Output flow data - data structure "D":

`x` : array containing x-coordinates with size `[n, m]`.

`y` : array containing y-coordinates with size `[n, m]`.

`u` : array containing x-component of flow velocity with size `[n, m, N]`.

`v` : array containing y-component of flow velocity with size `[n, m, N]`.

`w` : array containing z-component of flow velocity with size `[n, m, N]`.

`vort` : array containing z-component of vorticity with size `[n, m, N]`.

`corr` : array containing correlation values with size `[n, m, N]`.

`uncU` : array containing u-velocity uncertainty with size `[n, m, N]`.

`uncV` : array containing v-velocity uncertainty with size `[n, m, N]`.

`uncW` : array containing z-velocity uncertainty with size `[n, m, N]`.

 -------------------------------------------------------------------------
 ### Output recording attributes - structure "A":

`totalAcquisitionTime` : total PIV acquisition time in seconds.

 -------------------------------------------------------------------------
 ## UPDATES:

 #### Version 1.0.0
 2024/10/31 - Eric Handy (with snippets from Alex, Siyang, and Kenny)

 #### Version 1.1.0
 2024/11/06 - Eric Handy
 - Bug fixes.
 - Changed vorticity calculation from MATLAB's "curl()" function to the
   algorithm specified by Raffel's PIV Handbook.

 #### Version 1.1.1
 2025/05/12 - Eric Handy
 - Fixed bug that immediately identified any second parameter as "params".
 - Fixed a bug that did not assign all output variables specified when
   using the "extractAllVariables" option.
 NOTE: These issues have not been robustly tested.

 #### Version 2.0.0
 2025/08/06 - Kenny Breuer
 - Added a "validate" option that returns data only if it meets a correlation
   threshold.
 - Output data is NaN if there is no value (instead of 0).
 - Returns results in a structure - solves several problems with ordering
   output results.
 - Doesn't return "isvalid" - that doesn't seem to be present in all the PIV
   data.

 #### Version 2.1.0
 2025/09/30 - Pedro C Ormonde
 - Fixed hard-coded indices for field names ('U0','V0','TS:Correlation
   value', etc). Now the function reads from available field names.
 - Added optional input "n_camField" if data contains multiple monoPIV 
   fields from multiple cameras. Default: n_camField = 1.

#### Version 2.1.1
 2025/10/01 - Eric Handy
 - Bug fixes.

#### Version 2.2.0
 2025/10/15 - Eric Handy
 - Added option to output a recording attributes structure `A`.
 - Bug fixes.
--------------------------------------------------------------------------
 **SINTAX FOR UPDATES:**
 #### Version N1.N2.N3
 YYYY/MM/DD - Name Last
 - N1 for large structural overhauls to the function (new data structure,
   new input/output format, new algorithm, etc.).
 - N2 for small additions to fn (new arguments, new outputs, etc.).
 - N3 for bug fixes and compatibility updates.
--------------------------------------------------------------------------
