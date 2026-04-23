`ifndef PPU_BG_PKG_SV
`define PPU_BG_PKG_SV

package ppu_bg_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import nes_ram_pkg::*;

  // Component files (Included inside the package)
  `include "../ppu_agt/seq/ppu_bg_sequence_item.sv"
  `include "../ppu_agt/seq/ppu_bg_sequencer.sv"
  `include "../ppu_agt/seq/ppu_bg_sequences.sv"
  `include "../ppu_agt/master/ppu_bg_master_driver.sv"
  `include "../ppu_agt/master/ppu_bg_master_monitor.sv"
  `include "../ppu_agt/master/ppu_bg_master_agent.sv"
  `include "../ppu_agt/slave/ppu_bg_slave_driver.sv"
  `include "../ppu_agt/slave/ppu_bg_slave_monitor.sv"
  `include "../ppu_agt/slave/ppu_bg_slave_agent.sv"
  `include "../tlm/ppu_bg_master_subscriber.sv"
  `include "../tlm/ppu_bg_slave_subscriber.sv"
  `include "../cov/ppu_bg_cov.sv"
  `include "../chk/ppu_bg_scoreboard.sv"
  `include "../cfg/ppu_bg_cfg.sv"
  `include "../env/ppu_bg_env.sv"

  // Test files (Included inside the package)
  `include "../tst/ppu_bg/ppu_bg_base_test.sv"
  `include "../tst/ppu_bg/ppu_bg_sanity_test.sv"
  `include "../tst/ppu_bg/ppu_bg_ri_update_test.sv"
  `include "../tst/ppu_bg/ppu_bg_render_fetch_test.sv"
  `include "../tst/ppu_bg/ppu_bg_random_reset_test.sv"
  `include "../tst/ppu_bg/ppu_bg_full_regression_test.sv"
  `include "../tst/ppu_bg/ppu_bg_complex_scroll_test.sv"
  `include "../tst/ppu_bg/ppu_bg_pixel_test.sv"

endpackage

`endif
