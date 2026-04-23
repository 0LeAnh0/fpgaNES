`ifndef PPU_SPR_PKG_SV
`define PPU_SPR_PKG_SV

package ppu_spr_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Component files
  `include "../ppu_agt/seq/ppu_spr_sequence_item.sv"
  `include "../ppu_agt/seq/ppu_spr_sequencer.sv"
  `include "../ppu_agt/seq/ppu_spr_sequences.sv"
  `include "../ppu_agt/master/ppu_spr_master_driver.sv"
  `include "../ppu_agt/master/ppu_spr_master_monitor.sv"
  `include "../ppu_agt/master/ppu_spr_master_agent.sv"
  `include "../tlm/ppu_spr_master_subscriber.sv"
  `include "../cov/ppu_spr_cov.sv"
  `include "../chk/ppu_spr_scoreboard.sv"
  `include "../cfg/ppu_spr_cfg.sv"
  `include "../env/ppu_spr_env.sv"

  // Test files
  `include "../tst/ppu_spr/ppu_spr_base_test.sv"
  `include "../tst/ppu_spr/ppu_spr_sanity_test.sv"
  `include "../tst/ppu_spr/ppu_spr_oam_test.sv"
  `include "../tst/ppu_spr/ppu_spr_eval_test.sv"
  `include "../tst/ppu_spr/ppu_spr_overflow_test.sv"
  `include "../tst/ppu_spr/ppu_spr_render_test.sv"
  `include "../tst/ppu_spr/ppu_spr_full_frame_test.sv"
  `include "../tst/ppu_spr/ppu_spr_random_reset_test.sv"
  `include "../tst/ppu_spr/ppu_spr_full_regression_test.sv"

endpackage

`endif
