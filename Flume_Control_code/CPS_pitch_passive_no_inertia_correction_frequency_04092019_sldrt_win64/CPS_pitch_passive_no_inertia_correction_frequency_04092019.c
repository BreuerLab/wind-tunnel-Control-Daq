/*
 * CPS_pitch_passive_no_inertia_correction_frequency_04092019.c
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "CPS_pitch_passive_no_inertia_correction_frequency_04092019".
 *
 * Model version              : 1.233
 * Simulink Coder version : 8.12 (R2017a) 16-Feb-2017
 * C source code generated on : Tue Apr 09 22:09:33 2019
 *
 * Target selection: sldrt.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "CPS_pitch_passive_no_inertia_correction_frequency_04092019.h"
#include "CPS_pitch_passive_no_inertia_correction_frequency_04092019_private.h"
#include "CPS_pitch_passive_no_inertia_correction_frequency_04092019_dt.h"

/* options for Simulink Desktop Real-Time board 0 */
static double SLDRTBoardOptions0[] = {
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
};

/* options for Simulink Desktop Real-Time board 1 */
static double SLDRTBoardOptions1[] = {
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
};

/* list of Simulink Desktop Real-Time timers */
const int SLDRTTimerCount = 1;
const double SLDRTTimers[2] = {
  0.0005, 0.0,
};

/* list of Simulink Desktop Real-Time boards */
const int SLDRTBoardCount = 2;
SLDRTBOARD SLDRTBoards[2] = {
  { "National_Instruments/PCIe-6353", 4294967295U, 7, SLDRTBoardOptions0 },

  { "National_Instruments/PCIe-6351", 4294967295U, 7, SLDRTBoardOptions1 },
};

/* Block signals (auto storage) */
B_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B;

/* Block states (auto storage) */
DW_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW;

/* Real-time model */
RT_MODEL_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M_;
RT_MODEL_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T *const
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M =
  &CPS_pitch_passive_no_inertia_correction_frequency_04092019_M_;

/* Model output function */
void CPS_pitch_passive_no_inertia_correction_frequency_04092019_output(void)
{
  /* local block i/o variables */
  real_T rtb_AnalogInput1[8];
  real_T rtb_AnalogInput2[4];
  real_T rtb_positionoutVoltage;
  real_T rtb_angleoutdeg;
  real_T tmp[6];
  int32_T i;
  int32_T i_0;

  /* S-Function (sldrtai): '<Root>/Analog Input1' */
  /* S-Function Block: <Root>/Analog Input1 */
  {
    ANALOGIOPARM parm;
    parm.mode = (RANGEMODE)
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_RangeMode;
    parm.rangeidx =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_VoltRange;
    RTBIO_DriverIO(0, ANALOGINPUT, IOREAD, 8,
                   CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_Channels,
                   &rtb_AnalogInput1[0], &parm);
  }

  /* S-Function (sldrtai): '<Root>/Analog Input2' */
  /* S-Function Block: <Root>/Analog Input2 */
  {
    ANALOGIOPARM parm;
    parm.mode = (RANGEMODE)
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_RangeMode;
    parm.rangeidx =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_VoltRange;
    RTBIO_DriverIO(1, ANALOGINPUT, IOREAD, 4,
                   CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput2_Channels,
                   &rtb_AnalogInput2[0], &parm);
  }

  /* Bias: '<Root>/force bias' incorporates:
   *  Gain: '<Root>/conversion  matrix'
   */
  for (i = 0; i < 6; i++) {
    tmp[i] = rtb_AnalogInput1[i] +
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.forcebias_Bias
      [i];
  }

  /* End of Bias: '<Root>/force bias' */

  /* Gain: '<Root>/conversion  matrix' */
  for (i = 0; i < 6; i++) {
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
      [i] = 0.0;
    for (i_0 = 0; i_0 < 6; i_0++) {
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
        [i] +=
        CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Wallace_Cal_tranp
        [6 * i + i_0] * tmp[i_0];
    }
  }

  /* Gain: '<Root>/inverse  Inertia' incorporates:
   *  Sum: '<Root>/Sum2'
   *  UnitDelay: '<Root>/Unit  Delay1'
   */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.inverseInertia =
    1.0 / CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Ip *
    (CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
     [5] -
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.UnitDelay1_DSTATE);

  /* DiscreteIntegrator: '<Root>/Integrator1' */
  if (CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE
      != 0) {
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1 =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE;
  } else {
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1 =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval
      * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.inverseInertia
      + CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE;
  }

  /* End of DiscreteIntegrator: '<Root>/Integrator1' */

  /* DiscreteIntegrator: '<Root>/Integrator 1' */
  if (CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE_h
      != 0) {
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE_a;
  } else {
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval_j
      * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1
      + CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE_a;
  }

  /* End of DiscreteIntegrator: '<Root>/Integrator 1' */

  /* ManualSwitch: '<Root>/zero1' incorporates:
   *  Constant: '<Root>/Constant2'
   *  Constant: '<Root>/offset(deg)'
   *  Gain: '<Root>/to rad'
   *  Sum: '<Root>/Sum1'
   */
  if (CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.zero1_CurrentSetting
      == 1) {
    rtb_angleoutdeg =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.torad_Gain *
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.offsetdeg_Value
      + CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e;
  } else {
    rtb_angleoutdeg =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Constant2_Value;
  }

  /* End of ManualSwitch: '<Root>/zero1' */

  /* Gain: '<Root>/angle out deg' */
  rtb_angleoutdeg *=
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.angleoutdeg_Gain;

  /* Gain: '<Root>/position out  (Voltage)' incorporates:
   *  Constant: '<Root>/Constant2'
   */
  rtb_positionoutVoltage =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.positionoutVoltage_Gain
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Constant2_Value;

  /* S-Function (sldrtao): '<Root>/Analog Output' */
  /* S-Function Block: <Root>/Analog Output */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE)
        CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_RangeMode;
      parm.rangeidx =
        CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput_Channels,
                     ((real_T*) (&rtb_angleoutdeg)), &parm);
    }
  }

  /* S-Function (sldrtao): '<Root>/Analog Output1' */
  /* S-Function Block: <Root>/Analog Output1 */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE)
        CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_RangeMode;
      parm.rangeidx =
        CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogOutput1_Channels,
                     ((real_T*) (&rtb_positionoutVoltage)), &parm);
    }
  }

  /* SignalConversion: '<Root>/TmpSignal ConversionAtForcesInport1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.TmpSignalConversionAtForcesInport1
    [0] =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
    [5];
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.TmpSignalConversionAtForcesInport1
    [1] =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
    [0];
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.TmpSignalConversionAtForcesInport1
    [2] =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
    [1];

  /* Gain: '<Root>/conversion2' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.pitchmeasuredrad =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion2_Gain
    * rtb_AnalogInput1[6];

  /* Gain: '<Root>/target pitch out(rad)' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.targetpitchoutrad
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.targetpitchoutrad_Gain
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e;

  /* Sum: '<Root>/Sum3' incorporates:
   *  Gain: '<Root>/virtual damping1'
   *  Gain: '<Root>/virtual mass1'
   *  Gain: '<Root>/virtual stiffness1'
   */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Sum3 =
    (CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.virtualmass1_Gain
     * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.inverseInertia
     + CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bv *
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1) +
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Kv *
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e;

  /* Gain: '<Root>/conversion1' incorporates:
   *  Bias: '<Root>/Bias'
   */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversion1[0] =
    (rtb_AnalogInput2[0] +
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bias_Bias) *
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion1_Gain;
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversion1[1] =
    (rtb_AnalogInput2[1] +
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bias_Bias) *
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion1_Gain;
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversion1[2] =
    (rtb_AnalogInput2[2] +
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bias_Bias) *
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion1_Gain;
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversion1[3] =
    (rtb_AnalogInput2[3] +
     CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bias_Bias) *
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.conversion1_Gain;
}

/* Model update function */
void CPS_pitch_passive_no_inertia_correction_frequency_04092019_update(void)
{
  /* Update for UnitDelay: '<Root>/Unit  Delay1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.UnitDelay1_DSTATE
    = CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Sum3;

  /* Update for DiscreteIntegrator: '<Root>/Integrator1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE
    = 0U;
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.inverseInertia
    + CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1;

  /* Update for DiscreteIntegrator: '<Root>/Integrator 1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE_h
    = 0U;
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE_a
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_gainval_j
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1 +
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.Integrator1_e;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.clockTick0))
  {
    ++CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.clockTickH0;
  }

  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.t[0] =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.clockTick0
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.stepSize0
    + CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.clockTickH0
    * CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.stepSize0
    * 4294967296.0;
}

/* Model initialize function */
void CPS_pitch_passive_no_inertia_correction_frequency_04092019_initialize(void)
{
  /* Start for S-Function (sldrtao): '<Root>/Analog Output' */

  /* S-Function Block: <Root>/Analog Output */

  /* no initial value should be set */

  /* Start for S-Function (sldrtao): '<Root>/Analog Output1' */

  /* S-Function Block: <Root>/Analog Output1 */

  /* no initial value should be set */

  /* InitializeConditions for UnitDelay: '<Root>/Unit  Delay1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.UnitDelay1_DSTATE
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.UnitDelay1_InitialCondition;

  /* InitializeConditions for DiscreteIntegrator: '<Root>/Integrator1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_IC;

  /* InitializeConditions for DiscreteIntegrator: '<Root>/Integrator 1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_DSTATE_a
    =
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Integrator1_IC_e;

  /* Enable for DiscreteIntegrator: '<Root>/Integrator1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE
    = 1U;

  /* Enable for DiscreteIntegrator: '<Root>/Integrator 1' */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE_h
    = 1U;
}

/* Model terminate function */
void CPS_pitch_passive_no_inertia_correction_frequency_04092019_terminate(void)
{
  /* Terminate for S-Function (sldrtao): '<Root>/Analog Output' */

  /* S-Function Block: <Root>/Analog Output */

  /* no final value should be set */

  /* Terminate for S-Function (sldrtao): '<Root>/Analog Output1' */

  /* S-Function Block: <Root>/Analog Output1 */

  /* no final value should be set */
}

/*========================================================================*
 * Start of Classic call interface                                        *
 *========================================================================*/
void MdlOutputs(int_T tid)
{
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_output();
  UNUSED_PARAMETER(tid);
}

void MdlUpdate(int_T tid)
{
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_update();
  UNUSED_PARAMETER(tid);
}

void MdlInitializeSizes(void)
{
}

void MdlInitializeSampleTimes(void)
{
}

void MdlInitialize(void)
{
}

void MdlStart(void)
{
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_initialize();
}

void MdlTerminate(void)
{
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_terminate();
}

/* Registration function */
RT_MODEL_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T
  *CPS_pitch_passive_no_inertia_correction_frequency_04092019(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  /* initialize real-time model */
  (void) memset((void *)
                CPS_pitch_passive_no_inertia_correction_frequency_04092019_M, 0,
                sizeof
                (RT_MODEL_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T));

  /* Initialize timing info */
  {
    int_T *mdlTsMap =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleTimeTaskIDPtr
      = (&mdlTsMap[0]);
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleTimes
      =
      (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleTimesArray
       [0]);
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.offsetTimes
      =
      (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.offsetTimesArray
       [0]);

    /* task periods */
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleTimes
      [0] = (0.0005);

    /* task offsets */
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.offsetTimes
      [0] = (0.0);
  }

  rtmSetTPtr(CPS_pitch_passive_no_inertia_correction_frequency_04092019_M,
             &CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.tArray
             [0]);

  {
    int_T *mdlSampleHits =
      CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.sampleHits
      = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(CPS_pitch_passive_no_inertia_correction_frequency_04092019_M,
               1640.0);
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.stepSize0
    = 0.0005;

  /* External mode info */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.checksums
    [0] = (407093639U);
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.checksums
    [1] = (244453348U);
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.checksums
    [2] = (1457115984U);
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.checksums
    [3] = (4021180424U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[2];
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->extModeInfo =
      (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    systemRan[1] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr
      (CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->extModeInfo,
       &CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr
      (CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->extModeInfo,
       CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.checksums);
    rteiSetTPtr
      (CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->extModeInfo,
       rtmGetTPtr(CPS_pitch_passive_no_inertia_correction_frequency_04092019_M));
  }

  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->solverInfoPtr =
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->solverInfo);
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Timing.stepSize =
    (0.0005);
  rtsiSetFixedStepSize
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->solverInfo,
     0.0005);
  rtsiSetSolverMode
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->solverInfo,
     SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->blockIO = ((void
    *) &CPS_pitch_passive_no_inertia_correction_frequency_04092019_B);
  (void) memset(((void *)
                 &CPS_pitch_passive_no_inertia_correction_frequency_04092019_B),
                0,
                sizeof
                (B_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T));

  /* parameters */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->defaultParam =
    ((real_T *)&CPS_pitch_passive_no_inertia_correction_frequency_04092019_P);

  /* states (dwork) */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->dwork = ((void *)
    &CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW);
  (void) memset((void *)
                &CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW,
                0,
                sizeof
                (DW_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T));

  /* data type transition information */
  {
    static DataTypeTransInfo dtInfo;
    (void) memset((char_T *) &dtInfo, 0,
                  sizeof(dtInfo));
    CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->SpecialInfo.mappingInfo
      = (&dtInfo);
    dtInfo.numDataTypes = 14;
    dtInfo.dataTypeSizes = &rtDataTypeSizes[0];
    dtInfo.dataTypeNames = &rtDataTypeNames[0];

    /* Block I/O transition table */
    dtInfo.BTransTable = &rtBTransTable;

    /* Parameters transition table */
    dtInfo.PTransTable = &rtPTransTable;
  }

  /* Initialize Sizes */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numContStates
    = (0);                             /* Number of continuous states */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numY = (0);/* Number of model outputs */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numU = (0);/* Number of model inputs */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.sysDirFeedThru
    = (0);                             /* The model is not direct feedthrough */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numSampTimes
    = (1);                             /* Number of sample times */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numBlocks =
    (32);                              /* Number of blocks */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numBlockIO
    = (9);                             /* Number of block outputs */
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_M->Sizes.numBlockPrms
    = (91);                            /* Sum of parameter "widths" */
  return CPS_pitch_passive_no_inertia_correction_frequency_04092019_M;
}

/*========================================================================*
 * End of Classic call interface                                          *
 *========================================================================*/
