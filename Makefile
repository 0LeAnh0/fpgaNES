# =============================================================================
# NES FPGA - Multi-Tool Makefile (Questasim & XSim)
# =============================================================================

# --- Configuration & Paths ---
export LM_LICENSE_FILE := D:/questasim/win64/LICENSE.dat
QUESTA_BIN  := D:/questasim/win64
UVM_SRC     := D:/questasim/verilog_src/uvm-1.1d/src
TEST        ?= ppu_ri_full_regression_test

# Project Paths
ROOT        := $(CURDIR)
SRC_DIR     := $(ROOT)/nes_fpga.srcs
INC_FLAGS   := +incdir+"$(UVM_SRC)" +incdir+"$(SRC_DIR)/sim_1/imports/src" +incdir+"$(SRC_DIR)/sim_1/imports/src/pkg" \
               +incdir+"$(SRC_DIR)/sim_1/imports/src/cov" \
               +incdir+"$(SRC_DIR)/sources_1/imports/src/cmn/uart" \
               +incdir+"$(SRC_DIR)/sources_1/imports/src/cmn/fifo"

# Compilation Units
LOG_DIR     := ./logs
UCDB_FILE   := vsim.ucdb
FCOV_UCDB_FILE ?= fcov.ucdb
FCOV_HTML_DIR  ?= fcov_html
SIM_LOG     := $(LOG_DIR)/sim.log
RTL_LOG     := $(LOG_DIR)/rtl_compile.log
KEEP_LOGS   ?= 0
VLOG        := "$(QUESTA_BIN)/vlog" -sv -work work -timescale 1ns/1ps $(INC_FLAGS)
VLOG_CODE_COV := +cover
VSIM        := "$(QUESTA_BIN)/vsim" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" -l $(SIM_LOG) +UVM_TESTNAME=$(TEST) -coverage
UVM_SUMMARY := ^# UVM_INFO :|^# UVM_WARNING :|^# UVM_ERROR :|^# UVM_FATAL :

.PHONY: help questa questa-gui cov-gui cov-open fcov fcov-gui fcov-open fcov-html fcov-html-open clean check-dirs compile compile-fcov report

help:
	@echo "NES FPGA - Questasim Terminal Targets"
	@echo ""
	@echo "  make questa [TEST=<name>]     Compile and run simulation in CLI"
	@echo "  make questa-gui [TEST=<name>] Compile and open Questasim GUI"
	@echo "  make cov-gui [TEST=<name>]    Compile, run, and open live coverage GUI"
	@echo "  make cov-open [TEST=<name>]   Open vsim.ucdb if present, otherwise open live coverage GUI"
	@echo "  make fcov [TEST=<name>]       Functional coverage only: compile/run/save fcov.ucdb"
	@echo "  make fcov-gui [TEST=<name>]   Functional coverage GUI focused on Covergroups"
	@echo "  make fcov-open [TEST=<name>]  Open saved functional coverage database"
	@echo "  make fcov-html [TEST=<name>]  Generate HTML functional coverage bars (green/yellow/red)"
	@echo "  make fcov-html-open           Open generated HTML report"
	@echo "  Optional: KEEP_LOGS=1         Keep temporary simulator log files"
	@echo "  make report                   Generate text coverage report"
	@echo "  make clean                    Remove simulation artifacts & logs"

check-dirs:
	@mkdir -p $(LOG_DIR)

# --- Questasim Implementation ---

work:
	rm -rf work
	"$(QUESTA_BIN)/vlib" work
	"$(QUESTA_BIN)/vmap" work work
	@sed -i 's|^TranscriptFile = .*|TranscriptFile = NUL|' modelsim.ini

compile: work check-dirs
	@echo "--- Compiling UVM Package ---"
	"$(QUESTA_BIN)/vlog" -sv -work work +incdir+"$(UVM_SRC)" "$(UVM_SRC)/uvm_pkg.sv"
	@echo "--- Compiling RTL (Verilog-2001) ---"
	"$(QUESTA_BIN)/vlog" -work work -timescale 1ns/1ps $(INC_FLAGS) $(VLOG_CODE_COV) -l $(RTL_LOG) \
		"./nes_fpga.srcs/sources_1/imports/src/cart/cart.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/block_ram/block_ram.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/uart/uart.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/vga_sync/vga_sync.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_div.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_envelope_generator.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_frame_counter.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_length_counter.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_mixer.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_noise.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_pulse.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_triangle.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/cpu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/jp.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/rp2a03.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/sprdma.v" \
		"./nes_fpga.srcs/sources_1/imports/src/hci/hci.v" \
		"./nes_fpga.srcs/sources_1/imports/src/nes_top.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_bg.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_ri.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_spr.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_vga.v" \
		"./nes_fpga.srcs/sources_1/imports/src/vram.v" \
		"./nes_fpga.srcs/sources_1/imports/src/wram.v"
	@echo "--- Compiling Testbench (SystemVerilog) ---"
	"$(QUESTA_BIN)/vlog" -sv -work work -timescale 1ns/1ps $(INC_FLAGS) $(VLOG_CODE_COV) \
		"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/vram_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/wram_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_bg_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_ri_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_spr_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_vga_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_top_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/tb_if/tb_ctrl_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/nes_ram_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_bg_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_ri_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_spr_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_vga_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_top_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/nes_tb_top.sv"

compile-fcov: work check-dirs
	@echo "--- Compiling UVM Package (Functional Coverage Focus) ---"
	"$(QUESTA_BIN)/vlog" -sv -work work +incdir+"$(UVM_SRC)" "$(UVM_SRC)/uvm_pkg.sv"
	@echo "--- Compiling RTL without code coverage instrumentation ---"
	"$(QUESTA_BIN)/vlog" -work work -timescale 1ns/1ps $(INC_FLAGS) -l $(RTL_LOG) \
		"./nes_fpga.srcs/sources_1/imports/src/cart/cart.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/block_ram/block_ram.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/uart/uart.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cmn/vga_sync/vga_sync.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_div.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_envelope_generator.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_frame_counter.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_length_counter.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_mixer.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_noise.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_pulse.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_triangle.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/cpu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/jp.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/rp2a03.v" \
		"./nes_fpga.srcs/sources_1/imports/src/cpu/sprdma.v" \
		"./nes_fpga.srcs/sources_1/imports/src/hci/hci.v" \
		"./nes_fpga.srcs/sources_1/imports/src/nes_top.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_bg.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_ri.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_spr.v" \
		"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_vga.v" \
		"./nes_fpga.srcs/sources_1/imports/src/vram.v" \
		"./nes_fpga.srcs/sources_1/imports/src/wram.v"
	@echo "--- Compiling Testbench with functional covergroups ---"
	"$(QUESTA_BIN)/vlog" -sv -work work -timescale 1ns/1ps $(INC_FLAGS) \
		"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/vram_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/wram_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_bg_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_ri_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_spr_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_vga_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_top_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/tb_if/tb_ctrl_if.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/nes_ram_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_bg_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_ri_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_spr_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_vga_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_top_pkg.sv" \
		"./nes_fpga.srcs/sim_1/imports/src/nes_tb_top.sv"

questa: compile
	@echo "--- Running Simulation: $(TEST) ---"
	"$(QUESTA_BIN)/vsim" -c -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" -l $(SIM_LOG) -coverage +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(UCDB_FILE); quit -f"
	@if [ ! -f $(UCDB_FILE) ]; then \
		echo "Warning: coverage database $(UCDB_FILE) was not created. Use 'make cov-gui TEST=$(TEST)' for live coverage GUI."; \
	fi
	@echo "--- Final Summary Extract ---"
	@grep -E '$(UVM_SUMMARY)' $(SIM_LOG) || true
	@if echo "$(TEST)" | grep -q "^nes_ram_"; then \
		grep -E 'RAM_COV|SCB_REPORT' $(SIM_LOG) || true; \
	elif echo "$(TEST)" | grep -q "^ppu_bg_"; then \
		grep -E 'BG_COV|BG_SCB_RPT' $(SIM_LOG) || true; \
	elif echo "$(TEST)" | grep -q "^ppu_spr_"; then \
		grep -E 'SPR_COV|SPR_SCB_RPT' $(SIM_LOG) || true; \
	elif echo "$(TEST)" | grep -q "^ppu_vga_"; then \
		grep -E 'VGA_COV|VGA_SCB_RPT' $(SIM_LOG) || true; \
	elif echo "$(TEST)" | grep -q "^ppu_full_"; then \
		grep -E 'PPU_TOP_COV|PPU_TOP_SCB_RPT' $(SIM_LOG) || true; \
	elif echo "$(TEST)" | grep -q "^ppu_ri_"; then \
		grep -E 'PPU_RI_COV|SCB_RPT' $(SIM_LOG) || true; \
	else \
		grep -E 'RAM_COV|BG_COV|SPR_COV|VGA_COV|PPU_TOP_COV|PPU_RI_COV|SCB_RPT|BG_SCB_RPT|SPR_SCB_RPT|VGA_SCB_RPT|PPU_TOP_SCB_RPT|SCB_REPORT' $(SIM_LOG) || true; \
	fi
	@if [ "$(KEEP_LOGS)" != "1" ]; then \
		rm -f $(SIM_LOG) $(RTL_LOG) sim_diag.log transcript; \
		rmdir $(LOG_DIR) 2>/dev/null || true; \
	fi

questa-gui: compile
	@echo "--- Opening Questasim GUI ---"
	"$(QUESTA_BIN)/vsim" -onfinish stop -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all"

cov-gui: compile
	@echo "--- Opening Live Coverage GUI ($(TEST)) ---"
	"$(QUESTA_BIN)/vsim" -onfinish stop -coverage -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(UCDB_FILE); view covergroups"

cov-open:
	@if [ ! -f $(UCDB_FILE) ]; then \
		echo "$(UCDB_FILE) not found. Opening live coverage GUI for TEST=$(TEST) instead."; \
		"$(QUESTA_BIN)/vsim" -onfinish stop -coverage -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(UCDB_FILE); view covergroups"; \
		exit 0; \
	fi
	@echo "--- Opening Coverage GUI ($(UCDB_FILE)) ---"
	"$(QUESTA_BIN)/vsim" -viewcov $(UCDB_FILE) -do "view covergroups"

fcov: compile-fcov
	@echo "--- Running Functional Coverage Simulation: $(TEST) ---"
	"$(QUESTA_BIN)/vsim" -c -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" -l $(SIM_LOG) -coverage +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(FCOV_UCDB_FILE); quit -f"
	@if [ ! -f $(FCOV_UCDB_FILE) ]; then \
		echo "Warning: functional coverage database $(FCOV_UCDB_FILE) was not created."; \
	fi
	@grep -E 'RAM_COV|BG_COV|SPR_COV|VGA_COV|PPU_TOP_COV|PPU_RI_COV' $(SIM_LOG) || true
	@if [ "$(KEEP_LOGS)" != "1" ]; then \
		rm -f $(SIM_LOG) $(RTL_LOG) sim_diag.log transcript; \
		rmdir $(LOG_DIR) 2>/dev/null || true; \
	fi

fcov-gui: compile-fcov
	@echo "--- Opening Functional Coverage GUI ($(TEST)) ---"
	"$(QUESTA_BIN)/vsim" -onfinish stop -coverage -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(FCOV_UCDB_FILE); view covergroups"

fcov-open:
	@if [ ! -f $(FCOV_UCDB_FILE) ]; then \
		echo "$(FCOV_UCDB_FILE) not found. Running functional coverage GUI for TEST=$(TEST) instead."; \
		"$(QUESTA_BIN)/vsim" -onfinish stop -coverage -voptargs="+acc" -sv_lib "D:/questasim/uvm-1.1d/win64/uvm_dpi" +UVM_TESTNAME=$(TEST) work.tb_top -do "run -all; coverage save $(FCOV_UCDB_FILE); view covergroups"; \
		exit 0; \
	fi
	@echo "--- Opening Functional Coverage GUI ($(FCOV_UCDB_FILE)) ---"
	"$(QUESTA_BIN)/vsim" -viewcov $(FCOV_UCDB_FILE) -do "view covergroups"

fcov-html:
	@if [ ! -f $(FCOV_UCDB_FILE) ]; then \
		echo "$(FCOV_UCDB_FILE) not found. Run 'make fcov TEST=$(TEST)' first."; \
		exit 1; \
	fi
	@rm -rf $(FCOV_HTML_DIR)
	@echo "--- Generating Functional Coverage HTML ($(FCOV_HTML_DIR)) ---"
	"$(QUESTA_BIN)/vcover" report -html -cvg -details -htmldir $(FCOV_HTML_DIR) -threshH 90 -threshL 70 $(FCOV_UCDB_FILE)
	@echo "HTML report: $(FCOV_HTML_DIR)/index.html"

fcov-html-open: fcov-html
	@echo "--- Opening Functional Coverage HTML ---"
	@explorer.exe "$(subst /,\,$(abspath $(FCOV_HTML_DIR)/index.html))" >/dev/null 2>&1 || true

report:
	@echo "--- Generating Coverage Report ---"
	"$(QUESTA_BIN)/vcover" report -details -all $(UCDB_FILE)

clean:
	rm -rf work vsim.wlf transcript modelsim.ini sim.log uvm_verification.log sim_diag.log $(UCDB_FILE) $(FCOV_UCDB_FILE) $(LOG_DIR)
