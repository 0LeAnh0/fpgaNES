`ifndef PPU_VGA_PKG_SV
`define PPU_VGA_PKG_SV

package ppu_vga_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import nes_ram_pkg::*;

  `include "../ppu_agt/seq/ppu_vga_sequence_item.sv"
  `include "../ppu_agt/seq/ppu_vga_sequencer.sv"
  `include "../ppu_agt/seq/ppu_vga_sequences.sv"
  `include "../ppu_agt/master/ppu_vga_master_driver.sv"
  `include "../ppu_agt/master/ppu_vga_master_monitor.sv"
  `include "../ppu_agt/master/ppu_vga_master_agent.sv"
  `include "../tlm/ppu_vga_master_subscriber.sv"
  `include "../cov/ppu_vga_cov.sv"
  `include "../chk/ppu_vga_scoreboard.sv"
  `include "../cfg/ppu_vga_cfg.sv"
  `include "../env/ppu_vga_env.sv"

  `include "../tst/ppu_vga/ppu_vga_base_test.sv"
  `include "../tst/ppu_vga/ppu_vga_reset_test.sv"
  `include "../tst/ppu_vga/ppu_vga_palette_visible_area_test.sv"
  `include "../tst/ppu_vga/ppu_vga_border_color_test.sv"
  `include "../tst/ppu_vga/ppu_vga_vblank_timing_test.sv"
  `include "../tst/ppu_vga/ppu_vga_full_regression_test.sv"

endpackage

`endif
