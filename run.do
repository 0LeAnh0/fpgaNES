# =============================================================================
# Questasim Simulation Script (Updated for 10.2c)
# =============================================================================

set TEST_NAME "ppu_ri_full_regression_test"
if { $argc > 0 } {
    set TEST_NAME $1
}

# Questasim Path (Renamed to remove spaces)
set UVM_SRC "D:/questasim/verilog_src/uvm-1.1d/src"

if ![file exists work] {
    vlib work
    vmap work work
    if {[file exists modelsim.ini]} {
        set fp [open "modelsim.ini" r]
        set data [read $fp]
        close $fp
        regsub -all {(?m)^TranscriptFile = .*$} $data {TranscriptFile = NUL} data
        set fp [open "modelsim.ini" w]
        puts -nonewline $fp $data
        close $fp
    }
}

# Compile with manual UVM include
vlog -sv "+incdir+$UVM_SRC" -f filelist.f

# Check for compilation errors
if { [string match "*Error*" [verror]] } {
    echo "Compilation Failed!"
    return
}

# Run simulation
vsim -voptargs="+acc" \
     -L uvm \
     +UVM_TESTNAME=$TEST_NAME \
     work.nes_tb_top work.glbl

run -all
