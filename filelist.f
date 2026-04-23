# =============================================================================
# NES FPGA - Questasim File List
# =============================================================================

# Include Directories
+incdir+./nes_fpga.srcs/sim_1/imports/src
+incdir+./nes_fpga.srcs/sim_1/imports/src/pkg

# Xilinx Glbl
"./nes_fpga.sim/sim_1/behav/xsim/glbl.v"

# Interfaces
"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/vram_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/nes_ram_agt/if/wram_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_bg_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_ri_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_spr_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_vga_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/ppu_agt/ppu_if/ppu_top_if.sv"
"./nes_fpga.srcs/sim_1/imports/src/tb_if/tb_ctrl_if.sv"

# Packages (These include all UVM components: drivers, monitors, envs, tests)
"./nes_fpga.srcs/sim_1/imports/src/pkg/nes_ram_pkg.sv"
"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_bg_pkg.sv"
"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_ri_pkg.sv"
"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_spr_pkg.sv"
"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_vga_pkg.sv"
"./nes_fpga.srcs/sim_1/imports/src/pkg/ppu_top_pkg.sv"

# RTL Files
"./nes_fpga.srcs/sources_1/imports/src/cart/cart.v"
"./nes_fpga.srcs/sources_1/imports/src/cmn/block_ram/block_ram.v"
"./nes_fpga.srcs/sources_1/imports/src/cmn/uart/uart.v"
"./nes_fpga.srcs/sources_1/imports/src/cmn/vga_sync/vga_sync.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_div.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_envelope_generator.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_frame_counter.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_length_counter.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_mixer.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_noise.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_pulse.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/apu/apu_triangle.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/cpu.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/jp.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/rp2a03.v"
"./nes_fpga.srcs/sources_1/imports/src/cpu/sprdma.v"
"./nes_fpga.srcs/sources_1/imports/src/hci/hci.v"
"./nes_fpga.srcs/sources_1/imports/src/nes_top.v"
"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu.v"
"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_bg.v"
"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_ri.v"
"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_spr.v"
"./nes_fpga.srcs/sources_1/imports/src/ppu/ppu_vga.v"
"./nes_fpga.srcs/sources_1/imports/src/vram.v"
"./nes_fpga.srcs/sources_1/imports/src/wram.v"

# Top Bench
"./nes_fpga.srcs/sim_1/imports/src/nes_tb_top.sv"
