# Zynq-True-Random-Number-Generator

A high-performance Physical Entropy Source implementing a Jitter-Sampling True Random Number Generator (TRNG) on a Xilinx Zynq-7000 (Arty Z7-20) FPGA, featuring dual readout interfaces (SoC AXI and STM32 UART).

## 📌 Architecture Overview
This design implements a physical true random number generator utilizing the phase jitter of free-running ring oscillators as the entropy source. To optimize hardware footprint and entropy quality, standard ring oscillators are replaced with resource-efficient **Latch-XOR cells**.

### Key Features
*   **Entropy Extraction:** Jitter-sampling of high-frequency Latch-XOR oscillator cells against a stable low-frequency sampling clock.
*   **SoC Integration:** Core TRNG wrapper mapped to an ARM Cortex-A9 processor via Xilinx Vitis AXI4-Lite interface for high-performance software-defined entropy reading.
*   **Edge Validation Mode:** Pure FPGA-to-STM32 readout interface transmitting raw random bitstreams via high-speed UART for post-processing and external verification.
*   **Randomness Certification:** Passed all **NIST SP 800-22** statistical randomness tests.

---

## 🛠️ Hardware Implementation Details

### 1. Entropy Source: Latch-XOR Ring Oscillators
Instead of traditional chain-based ring oscillators (RO) which consume significant LUT resources and can be prone to phase locking, this design utilizes a compact Latch-XOR structure:
- A bistable latch is cross-coupled with an XOR gate feedback loop.
- The metastability and thermal noise of the latch introduce high-frequency phase jitter.
- The output of multiple oscillator cells is XOR-combined to maximize entropy density before sampling.

### 2. AXI4-Lite SoC Interface
The TRNG core is packaged as a custom IP with an AXI4-Lite interface. 
- **Control Register:** Starts/stops the oscillator cells to manage power.
- **Status Register:** Indicates when a new 32-bit random word is ready in the FIFO buffer.
- **Data Register:** Reads the raw 32-bit entropy word directly into the ARM memory map.

---

## 📊 Verification & NIST Test Results
To certify the entropy source, the raw bitstream was collected and subjected to the **NIST SP 800-22** statistical test suite.

| NIST Statistical Test | P-Value | Status |
| :--- | :--- | :--- |
| Frequency (Monobit) | 0.482 | **PASS** |
| Block Frequency | 0.521 | **PASS** |
| Cumulative Sums | 0.412 | **PASS** |
| Runs | 0.612 | **PASS** |
| Longest Run | 0.389 | **PASS** |
| Binary Matrix Rank | 0.702 | **PASS** |
| Approximate Entropy | 0.455 | **PASS** |

*All tests passed comfortably (P-Value > 0.01).*

---

## 💻 Repository Structure
- `/rtl`: Verilog source files for the Latch-XOR cell, sampler, FIFO buffer, and AXI4-Lite wrapper.
- `/ip`: Custom IP packaging files for Vivado.
- `/vitis`: C driver code for ARM Cortex-A9 readout.
- `/stm32_verification`: Firmware for the STM32 post-processing microcontroller.
- `/testbench`: ModelSim/Vivado testbenches for functional verification.
