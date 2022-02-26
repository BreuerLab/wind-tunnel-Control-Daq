  function targMap = targDataMap(),

  ;%***********************
  ;% Create Parameter Map *
  ;%***********************
      
    nTotData      = 0; %add to this count as we go
    nTotSects     = 4;
    sectIdxOffset = 0;
    
    ;%
    ;% Define dummy sections & preallocate arrays
    ;%
    dumSection.nData = -1;  
    dumSection.data  = [];
    
    dumData.logicalSrcIdx = -1;
    dumData.dtTransOffset = -1;
    
    ;%
    ;% Init/prealloc paramMap
    ;%
    paramMap.nSections           = nTotSects;
    paramMap.sectIdxOffset       = sectIdxOffset;
      paramMap.sections(nTotSects) = dumSection; %prealloc
    paramMap.nTotData            = -1;
    
    ;%
    ;% Auto data (CPS_pitch_passive_no_inertia_correction_frequency_04092019_P)
    ;%
      section.nData     = 12;
      section.data(12)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bv
	  section.data(1).logicalSrcIdx = 0;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Ip
	  section.data(2).logicalSrcIdx = 1;
	  section.data(2).dtTransOffset = 1;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Kv
	  section.data(3).logicalSrcIdx = 2;
	  section.data(3).dtTransOffset = 2;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Wallace_Cal_tranp
	  section.data(4).logicalSrcIdx = 3;
	  section.data(4).dtTransOffset = 3;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_MaxMissedTicks
	  section.data(5).logicalSrcIdx = 8;
	  section.data(5).dtTransOffset = 39;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_MaxMissedTicks
	  section.data(6).logicalSrcIdx = 9;
	  section.data(6).dtTransOffset = 40;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_MaxMissedTicks
	  section.data(7).logicalSrcIdx = 10;
	  section.data(7).dtTransOffset = 41;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_MaxMissedTicks
	  section.data(8).logicalSrcIdx = 11;
	  section.data(8).dtTransOffset = 42;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_YieldWhenWaiting
	  section.data(9).logicalSrcIdx = 12;
	  section.data(9).dtTransOffset = 43;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_YieldWhenWaiting
	  section.data(10).logicalSrcIdx = 13;
	  section.data(10).dtTransOffset = 44;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_YieldWhenWaiting
	  section.data(11).logicalSrcIdx = 14;
	  section.data(11).dtTransOffset = 45;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_YieldWhenWaiting
	  section.data(12).logicalSrcIdx = 15;
	  section.data(12).dtTransOffset = 46;
	
      nTotData = nTotData + section.nData;
      paramMap.sections(1) = section;
      clear section
      
      section.nData     = 12;
      section.data(12)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_Channels
	  section.data(1).logicalSrcIdx = 16;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_Channels
	  section.data(2).logicalSrcIdx = 17;
	  section.data(2).dtTransOffset = 8;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_Channels
	  section.data(3).logicalSrcIdx = 18;
	  section.data(3).dtTransOffset = 12;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_Channels
	  section.data(4).logicalSrcIdx = 19;
	  section.data(4).dtTransOffset = 13;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_RangeMode
	  section.data(5).logicalSrcIdx = 20;
	  section.data(5).dtTransOffset = 14;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_RangeMode
	  section.data(6).logicalSrcIdx = 21;
	  section.data(6).dtTransOffset = 15;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_RangeMode
	  section.data(7).logicalSrcIdx = 22;
	  section.data(7).dtTransOffset = 16;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_RangeMode
	  section.data(8).logicalSrcIdx = 23;
	  section.data(8).dtTransOffset = 17;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_VoltRange
	  section.data(9).logicalSrcIdx = 24;
	  section.data(9).dtTransOffset = 18;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_VoltRange
	  section.data(10).logicalSrcIdx = 25;
	  section.data(10).dtTransOffset = 19;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_VoltRange
	  section.data(11).logicalSrcIdx = 26;
	  section.data(11).dtTransOffset = 20;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_VoltRange
	  section.data(12).logicalSrcIdx = 27;
	  section.data(12).dtTransOffset = 21;
	
      nTotData = nTotData + section.nData;
      paramMap.sections(2) = section;
      clear section
      
      section.nData     = 16;
      section.data(16)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.torad_Gain
	  section.data(1).logicalSrcIdx = 28;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.offsetdeg_Value
	  section.data(2).logicalSrcIdx = 29;
	  section.data(2).dtTransOffset = 1;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.forcebias_Bias
	  section.data(3).logicalSrcIdx = 30;
	  section.data(3).dtTransOffset = 2;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.UnitDelay1_InitialCondition
	  section.data(4).logicalSrcIdx = 31;
	  section.data(4).dtTransOffset = 8;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval
	  section.data(5).logicalSrcIdx = 32;
	  section.data(5).dtTransOffset = 9;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_IC
	  section.data(6).logicalSrcIdx = 33;
	  section.data(6).dtTransOffset = 10;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval_j
	  section.data(7).logicalSrcIdx = 34;
	  section.data(7).dtTransOffset = 11;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_IC_e
	  section.data(8).logicalSrcIdx = 35;
	  section.data(8).dtTransOffset = 12;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Constant2_Value
	  section.data(9).logicalSrcIdx = 36;
	  section.data(9).dtTransOffset = 13;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.angleoutdeg_Gain
	  section.data(10).logicalSrcIdx = 37;
	  section.data(10).dtTransOffset = 14;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.positionoutVoltage_Gain
	  section.data(11).logicalSrcIdx = 38;
	  section.data(11).dtTransOffset = 15;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion2_Gain
	  section.data(12).logicalSrcIdx = 39;
	  section.data(12).dtTransOffset = 16;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.targetpitchoutrad_Gain
	  section.data(13).logicalSrcIdx = 40;
	  section.data(13).dtTransOffset = 17;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.virtualmass1_Gain
	  section.data(14).logicalSrcIdx = 41;
	  section.data(14).dtTransOffset = 18;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bias_Bias
	  section.data(15).logicalSrcIdx = 42;
	  section.data(15).dtTransOffset = 19;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion1_Gain
	  section.data(16).logicalSrcIdx = 43;
	  section.data(16).dtTransOffset = 20;
	
      nTotData = nTotData + section.nData;
      paramMap.sections(3) = section;
      clear section
      
      section.nData     = 1;
      section.data(1)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.zero1_CurrentSetting
	  section.data(1).logicalSrcIdx = 44;
	  section.data(1).dtTransOffset = 0;
	
      nTotData = nTotData + section.nData;
      paramMap.sections(4) = section;
      clear section
      
    
      ;%
      ;% Non-auto Data (parameter)
      ;%
    

    ;%
    ;% Add final counts to struct.
    ;%
    paramMap.nTotData = nTotData;
    


  ;%**************************
  ;% Create Block Output Map *
  ;%**************************
      
    nTotData      = 0; %add to this count as we go
    nTotSects     = 1;
    sectIdxOffset = 0;
    
    ;%
    ;% Define dummy sections & preallocate arrays
    ;%
    dumSection.nData = -1;  
    dumSection.data  = [];
    
    dumData.logicalSrcIdx = -1;
    dumData.dtTransOffset = -1;
    
    ;%
    ;% Init/prealloc sigMap
    ;%
    sigMap.nSections           = nTotSects;
    sigMap.sectIdxOffset       = sectIdxOffset;
      sigMap.sections(nTotSects) = dumSection; %prealloc
    sigMap.nTotData            = -1;
    
    ;%
    ;% Auto data (CPS_pitch_passive_no_inertia_correction_frequency_04092019_B)
    ;%
      section.nData     = 9;
      section.data(9)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
	  section.data(1).logicalSrcIdx = 0;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.inverseInertia
	  section.data(2).logicalSrcIdx = 1;
	  section.data(2).dtTransOffset = 6;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1
	  section.data(3).logicalSrcIdx = 2;
	  section.data(3).dtTransOffset = 7;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e
	  section.data(4).logicalSrcIdx = 3;
	  section.data(4).dtTransOffset = 8;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.TmpSignalConversionAtForcesInport1
	  section.data(5).logicalSrcIdx = 4;
	  section.data(5).dtTransOffset = 9;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.pitchmeasuredrad
	  section.data(6).logicalSrcIdx = 5;
	  section.data(6).dtTransOffset = 12;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.targetpitchoutrad
	  section.data(7).logicalSrcIdx = 6;
	  section.data(7).dtTransOffset = 13;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Sum3
	  section.data(8).logicalSrcIdx = 7;
	  section.data(8).dtTransOffset = 14;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversion1
	  section.data(9).logicalSrcIdx = 8;
	  section.data(9).dtTransOffset = 15;
	
      nTotData = nTotData + section.nData;
      sigMap.sections(1) = section;
      clear section
      
    
      ;%
      ;% Non-auto Data (signal)
      ;%
    

    ;%
    ;% Add final counts to struct.
    ;%
    sigMap.nTotData = nTotData;
    


  ;%*******************
  ;% Create DWork Map *
  ;%*******************
      
    nTotData      = 0; %add to this count as we go
    nTotSects     = 3;
    sectIdxOffset = 1;
    
    ;%
    ;% Define dummy sections & preallocate arrays
    ;%
    dumSection.nData = -1;  
    dumSection.data  = [];
    
    dumData.logicalSrcIdx = -1;
    dumData.dtTransOffset = -1;
    
    ;%
    ;% Init/prealloc dworkMap
    ;%
    dworkMap.nSections           = nTotSects;
    dworkMap.sectIdxOffset       = sectIdxOffset;
      dworkMap.sections(nTotSects) = dumSection; %prealloc
    dworkMap.nTotData            = -1;
    
    ;%
    ;% Auto data (CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW)
    ;%
      section.nData     = 3;
      section.data(3)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.UnitDelay1_DSTATE
	  section.data(1).logicalSrcIdx = 0;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE
	  section.data(2).logicalSrcIdx = 1;
	  section.data(2).dtTransOffset = 1;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE_a
	  section.data(3).logicalSrcIdx = 2;
	  section.data(3).dtTransOffset = 2;
	
      nTotData = nTotData + section.nData;
      dworkMap.sections(1) = section;
      clear section
      
      section.nData     = 8;
      section.data(8)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.AnalogInput1_PWORK
	  section.data(1).logicalSrcIdx = 3;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.AnalogInput2_PWORK
	  section.data(2).logicalSrcIdx = 4;
	  section.data(2).dtTransOffset = 1;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.AnalogOutput_PWORK
	  section.data(3).logicalSrcIdx = 5;
	  section.data(3).dtTransOffset = 2;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.AnalogOutput1_PWORK
	  section.data(4).logicalSrcIdx = 6;
	  section.data(4).dtTransOffset = 3;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Forces_PWORK.LoggedData
	  section.data(5).logicalSrcIdx = 7;
	  section.data(5).dtTransOffset = 4;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.pos_pitch_PWORK.LoggedData
	  section.data(6).logicalSrcIdx = 8;
	  section.data(6).dtTransOffset = 5;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.torque_PWORK.LoggedData
	  section.data(7).logicalSrcIdx = 9;
	  section.data(7).dtTransOffset = 6;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.velocity_PWORK.LoggedData
	  section.data(8).logicalSrcIdx = 10;
	  section.data(8).dtTransOffset = 7;
	
      nTotData = nTotData + section.nData;
      dworkMap.sections(2) = section;
      clear section
      
      section.nData     = 2;
      section.data(2)  = dumData; %prealloc
      
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE
	  section.data(1).logicalSrcIdx = 11;
	  section.data(1).dtTransOffset = 0;
	
	  ;% CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE_h
	  section.data(2).logicalSrcIdx = 12;
	  section.data(2).dtTransOffset = 1;
	
      nTotData = nTotData + section.nData;
      dworkMap.sections(3) = section;
      clear section
      
    
      ;%
      ;% Non-auto Data (dwork)
      ;%
    

    ;%
    ;% Add final counts to struct.
    ;%
    dworkMap.nTotData = nTotData;
    


  ;%
  ;% Add individual maps to base struct.
  ;%

  targMap.paramMap  = paramMap;    
  targMap.signalMap = sigMap;
  targMap.dworkMap  = dworkMap;
  
  ;%
  ;% Add checksums to base struct.
  ;%


  targMap.checksum0 = 407093639;
  targMap.checksum1 = 244453348;
  targMap.checksum2 = 1457115984;
  targMap.checksum3 = 4021180424;

