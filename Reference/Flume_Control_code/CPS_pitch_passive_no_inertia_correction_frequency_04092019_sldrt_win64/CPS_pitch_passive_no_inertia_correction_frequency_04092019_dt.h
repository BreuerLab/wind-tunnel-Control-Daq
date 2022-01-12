/*
 * CPS_pitch_passive_no_inertia_correction_frequency_04092019_dt.h
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

#include "ext_types.h"

/* data type size table */
static uint_T rtDataTypeSizes[] = {
  sizeof(real_T),
  sizeof(real32_T),
  sizeof(int8_T),
  sizeof(uint8_T),
  sizeof(int16_T),
  sizeof(uint16_T),
  sizeof(int32_T),
  sizeof(uint32_T),
  sizeof(boolean_T),
  sizeof(fcn_call_T),
  sizeof(int_T),
  sizeof(pointer_T),
  sizeof(action_T),
  2*sizeof(uint32_T)
};

/* data type name table */
static const char_T * rtDataTypeNames[] = {
  "real_T",
  "real32_T",
  "int8_T",
  "uint8_T",
  "int16_T",
  "uint16_T",
  "int32_T",
  "uint32_T",
  "boolean_T",
  "fcn_call_T",
  "int_T",
  "pointer_T",
  "action_T",
  "timer_uint32_pair_T"
};

/* data type transitions for block I/O structure */
static DataTypeTransition rtBTransitions[] = {
  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_B.conversionmatrix
     [0]), 0, 0, 19 }
  ,

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.UnitDelay1_DSTATE),
    0, 0, 3 },

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.AnalogInput1_PWORK),
    11, 0, 8 },

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_DW.Integrator1_SYSTEM_ENABLE),
    3, 0, 2 }
};

/* data type transition table for block I/O structure */
static DataTypeTransitionTable rtBTransTable = {
  4U,
  rtBTransitions
};

/* data type transitions for Parameters structure */
static DataTypeTransition rtPTransitions[] = {
  { (char_T *)(&CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.Bv),
    0, 0, 47 },

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.AnalogInput1_Channels
     [0]), 6, 0, 22 },

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.torad_Gain),
    0, 0, 21 },

  { (char_T *)
    (&CPS_pitch_passive_no_inertia_correction_frequency_04092019_P.zero1_CurrentSetting),
    3, 0, 1 }
};

/* data type transition table for Parameters structure */
static DataTypeTransitionTable rtPTransTable = {
  4U,
  rtPTransitions
};

/* [EOF] CPS_pitch_passive_no_inertia_correction_frequency_04092019_dt.h */
