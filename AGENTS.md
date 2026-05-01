# AGENTS.md

## Cursor Cloud specific instructions

This is a **laboratory instrumentation codebase** (Breuer Lab, Brown University) for wind tunnel aerodynamics research. It is primarily MATLAB-based with two embedded firmware components that can be built in a cloud environment.

### Buildable components (no hardware required)

| Component | Path | Tool | Build command |
|-----------|------|------|---------------|
| ESP32 firmware (Calimero) | `Calimero/ESP32/` | PlatformIO | `pio run` (from that directory) |
| TriggerBox v2.6 | `TriggerBox/TriggerBox_v2.6/` | Arduino CLI | `arduino-cli compile --fqbn arduino:avr:uno TriggerBox/TriggerBox_v2.6/TriggerBox_v2.6.ino` |

### Lint/static analysis

- **ESP32 (PlatformIO):** `cd Calimero/ESP32 && pio check --skip-packages`
- **Arduino sketches:** compilation itself serves as the lint step (`arduino-cli compile`)

### Known pre-existing issues

- `Calimero/ESP32/src/main.cpp` line 76 has a missing semicolon — `pio run` will fail until fixed.
- `TriggerBox/TriggerBox2.0/TriggerBox2.0.ino` has pre-existing syntax errors.
- `TriggerBox/TriggerBox_v2.6/TriggerBox_v2.6.ino` compiles cleanly.

### What cannot run in a cloud environment

The MATLAB scripts (majority of the repo) require:
- MATLAB with Data Acquisition Toolbox
- Physical hardware (NI-DAQ, ATI load cells, Galil DMC controllers, Kollmorgen servo drives)
- Vendor drivers (NI-DAQmx, Galil ActiveX toolkit)

These are inherently hardware-dependent and cannot be tested without lab equipment.
