`ifndef PPU_TOP_PKG_SV
`define PPU_TOP_PKG_SV

package ppu_top_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import ppu_ri_pkg::*;

  `include "../cfg/ppu_top_cfg.sv"
  `include "../ppu_agt/seq/ppu_top_sequence_item.sv"
  `include "../ppu_agt/master/ppu_top_monitor.sv"
  `include "../tlm/ppu_top_subscriber.sv"
  `include "../cov/ppu_top_cov.sv"
  `include "../chk/ppu_top_scoreboard.sv"
  `include "../env/ppu_top_env.sv"
  `include "../tst/ppu_top/ppu_top_base_test.sv"
  `include "../tst/ppu_top/ppu_full_integration_test.sv"

endpackage

`endif
