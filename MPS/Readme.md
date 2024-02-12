# MPS functions
## Quick start
- Pitch_Move and Pitch_Read are the two parent functions drive and read from Kollmorgen Workbench.
- pitch_target(target) call the two primary parent functions, and set the pitch servo to the target position(in deg).
- When using, include these three fuctions in your path, you should able to move MPS pitch. 
- The defalut speed is a little slow. Make sure the servo to reach target position before excuting next step, the defalut waiting time is 30s.
- **The range of MPS is +_ 20 deg**, although there are safty switchs, try not rely on them. 
- The servos are heavy, make sure the path is clear before use. 
- i.e. pitch_target(-5) will set pitch to -5 deg AOA
## Advanced
- ACC and DEC can be set in Pitch_Move
- A position feedback can be read from Pitch_Read.
- The defalut waiting time can be change in pitch_target.
- Zero position has been calibrated by gravity fitting, 52238083 now. To tare the system, see gravityFit.m.
