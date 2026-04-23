#!/bin/bash
# =============================================================================
# NES FPGA - Questasim Simulation Script for Git Bash
# Updated with Absolute Paths for vlog/vsim
# =============================================================================

TEST_NAME=${1:-ppu_ri_full_regression_test}

# Questasim Paths
QUESTA_BIN="D:/questasim/win64"
UVM_PATH="D:/questasim/verilog_src/uvm-1.1d/src"

echo "--- Starting Questa Compilation ---"

# Create library if not exists
if [ ! -d "work" ]; then
    "$QUESTA_BIN/vlib" work
    "$QUESTA_BIN/vmap" work work
    sed -i 's|^TranscriptFile = .*|TranscriptFile = NUL|' modelsim.ini
fi

# Multi-line vlog for readability. Uses absolute path to vlog.exe
"$QUESTA_BIN/vlog" -sv "+incdir+$UVM_PATH" -f filelist.f

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "--- Starting Simulation: $TEST_NAME ---"

# vsim using absolute path and UVM library link
"$QUESTA_BIN/vsim" -c -voptargs="+acc" -L uvm \
     +UVM_TESTNAME=$TEST_NAME \
     work.nes_tb_top work.glbl \
     -do "run -all; quit"
