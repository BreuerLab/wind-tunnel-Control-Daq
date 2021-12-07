# AFAM Wind Tunnel Control and Data Acquisition

## Calibration

-	Collect calibration data (Taking_Calibration_Data.m)
-	Process calibration data to get calibration matrix (Calibration_Matrix_SVD.m)

## Experiments

-	Put setup in the wind tunnel and collect data from tunnel (Wind_Tunnel_Data_Collection.m)
-	Process wind tunnel data (Wind_Tunnel_Data_Processing.m)
   -*Note this script needs editing based on how you collect data/ is not complete*
   
## Contribute to this repo

- Git tool is strongly recommended for colabotation and multi-source control
- To edit current code, make a branch or fork to your own repo by clicking the fork on top right corner
- Keep the main repo for general propose usage and always functional
- So **DO NOT commit directly to the main respo**, make a fork and pull request!

## Attached folders

- Scripts from Jenya/summer experiments: **Jenya**
- Script from Alex april 2020 that works, but was not very modular: voltageToForces.m , this relies on a few other files in this folder: **april23Matlab** 
