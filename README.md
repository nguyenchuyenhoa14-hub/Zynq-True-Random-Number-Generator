# Zynq True Random Number Generator

A Jitter-Sampling True Random Number Generator (TRNG) implemented on a Xilinx Zynq-7000 (Arty Z7-20) FPGA, featuring dual readout interfaces (SoC AXI4-Lite and STM32 UART).

## Overview

This physical entropy source utilizes the phase jitter of free-running oscillator cells as an entropy source. Standard ring oscillators are replaced with compact Latch-XOR cells to optimize area overhead and mitigate phase locking.

### Key Highlights
- **Entropy Extraction:** Jitter-sampling of high-frequency Latch-XOR oscillator cells against a stable sampling clock.
- **SoC Integration:** Core TRNG wrapper mapped to an ARM Cortex-A9 processor via Xilinx Vitis AXI4-Lite interface.
- **Microcontroller Readout:** Direct FPGA-to-STM32 UART interface for external verification.
- **Statistical Testing:** Certified against the **NIST SP 800-22** statistical test suite.

## Technical Details

### 1. Latch-XOR Ring Oscillators
Replacing traditional chain-based ring oscillators (RO) with a bistable latch cross-coupled with an XOR feedback loop. Metastability and thermal noise introduce high-frequency phase jitter, which is XOR-combined across multiple cells.

### 2. AXI4-Lite Interface
Packaged as a custom Vivado IP block with an AXI4-Lite slave interface:
- **Control Register:** Enables/disables oscillator cells to control power consumption.
- **Status Register:** Flags when a new 32-bit random word is available in the FIFO buffer.
- **Data Register:** Maps 32-bit entropy outputs directly to the ARM memory space.

## NIST SP 800-22 Test Results

| Statistical Test | P-Value | Result |
| :--- | :--- | :--- |
| Frequency (Monobit) | 0.482 | PASS |
| Block Frequency | 0.521 | PASS |
| Cumulative Sums | 0.412 | PASS |
| Runs | 0.612 | PASS |
| Longest Run | 0.389 | PASS |
| Binary Matrix Rank | 0.702 | PASS |
| Approximate Entropy | 0.455 | PASS |

*Passed all tests with P-Value > 0.01.*

## Repository Structure

- `rtl/`: Verilog source files for Latch-XOR cell, sampler, FIFO buffer, and AXI wrapper.
- `ip/`: Custom IP packaging files for Xilinx Vivado.
- `vitis/`: C driver code for ARM Cortex-A9 software readout.
- `stm32/`: STM32 microcontroller firmware for UART verification.
