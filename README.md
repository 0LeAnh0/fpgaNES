# fpgaNES

This repository contains the UVM verification environment for the NES FPGA project.

Publicly included:
- UVM testbench
- agents, monitors, scoreboards, coverage collectors
- verification scripts and reports

Excluded from the public repository:
- RTL source files under `nes_fpga.srcs/sources_1/imports/src/`

The RTL source is a third-party design reference and is intentionally kept out of the public repo.
To run full simulations locally, place the RTL back into the expected Vivado source tree on your machine.
