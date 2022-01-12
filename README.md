# AFAM Wind Tunnel Control and Data Acquisition

## Contribute to this repo

- Git tool is strongly recommended for colabotation and multi-source control
- To edit current code, make a branch (collaberators) or fork (everyone else feel interested) to your own repo by clicking the fork on top right corner
- Keep the main branch for general propose usage and always functional
- So **DO NOT commit directly to the main branch**, make a branch and pull request instead.
- To become a collaberator, please contact siyang_hao@brown.edu
- more introductions for collaberators refer to  https://medium.com/@jonathanmines/the-ultimate-github-collaboration-guide-df816e98fb67

## Using AeroLab loadcells 
 Go to **AeroLabSting**
### Calibration

-	Collect calibration data (Taking_Calibration_Data.m)
-	Process calibration data to get calibration matrix (Calibration_Matrix_SVD.m)

### Experiments

-	Put setup in the wind tunnel and collect data from tunnel (Wind_Tunnel_Data_Collection.m)
-	Process wind tunnel data (Wind_Tunnel_Data_Processing.m)
   -*Note this script needs editing based on how you collect data/ is not complete*
   
## Using ATI loadcells
- ATI Gamma: go to **Gamma65**
## Reference

- Scripts from Jenya/summer experiments: **Jenya's code**
- Script from Alex april 2020 that works, but was not very modular: voltageToForces.m , this relies on a few other files in this folder: **Alex's code** 
- Script from flume: **Flume_Control_code**
