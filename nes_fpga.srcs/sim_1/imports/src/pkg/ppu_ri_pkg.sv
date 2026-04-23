`ifndef PPU_RI_PKG_SV
`define PPU_RI_PKG_SV

// ===========================================================================
// ppu_ri_pkg
// Package rieng biet cho PPU Register Interface Verification.
// Import sau nes_uvm_pkg (dung nes_log_catcher tu nes_base_test).
//
// Thu tu include theo dependency layer:
//   Seq Item → Sequencer → Sequences
//   → Master [driver, monitor, agent]
//   → Slave  [driver, monitor, agent]
//   → TLM → Scoreboard → Env → Tests
// ===========================================================================
package ppu_ri_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import nes_ram_pkg::*;   // de dung nes_log_catcher

    // =========================================================================
    // SECTION 1: SEQUENCE ITEM
    // =========================================================================
    `include "../ppu_agt/seq/ppu_ri_sequence_item.sv"

    // =========================================================================
    // SECTION 2: SEQUENCER  (dung chung cho ca master va slave)
    // =========================================================================
    `include "../ppu_agt/seq/ppu_ri_sequencer.sv"

    // =========================================================================
    // SECTION 3: SEQUENCES
    // =========================================================================
    `include "../ppu_agt/seq/ppu_ri_sequences.sv"

    // =========================================================================
    // SECTION 4: MASTER AGENT COMPONENTS  [ppu_agt/master/]
    // =========================================================================
    `include "../ppu_agt/master/ppu_ri_master_driver.sv"
    `include "../ppu_agt/master/ppu_ri_master_monitor.sv"
    `include "../ppu_agt/master/ppu_ri_master_agent.sv"

    // =========================================================================
    // SECTION 5: SLAVE AGENT COMPONENTS  [ppu_agt/slave/]
    // =========================================================================
    `include "../ppu_agt/slave/ppu_ri_slave_driver.sv"
    `include "../ppu_agt/slave/ppu_ri_slave_monitor.sv"
    `include "../ppu_agt/slave/ppu_ri_slave_agent.sv"

    // =========================================================================
    // SECTION 6: TLM SUBSCRIBERS  [tlm/]
    // =========================================================================
    `include "../tlm/ppu_ri_master_subscriber.sv"
    `include "../tlm/ppu_ri_slave_subscriber.sv"
    `include "../cov/ppu_ri_cov.sv"

    // =========================================================================
    // SECTION 7: SCOREBOARD  [chk/]
    // =========================================================================
    `include "../chk/ppu_ri_scoreboard.sv"

    // =========================================================================
    // SECTION 8: ENVIRONMENT  [env/]
    // =========================================================================
    `include "../env/ppu_ri_env.sv"

    // =========================================================================
    // SECTION 8.5: CONFIG OBJECTS  [cfg/]
    // =========================================================================
    `include "../cfg/ppu_ri_cfg.sv"
    `include "../cfg/ppu_scroll_cfg.sv"

    // =========================================================================
    // SECTION 9: TESTS  [tst/ppu_ri/]
    // =========================================================================
    `include "../tst/ppu_ri/ppu_ri_base_test.sv"
    `include "../tst/ppu_ri/ppu_ri_sanity_test.sv"
    `include "../tst/ppu_ri/ppu_ri_signoff_test.sv"
    `include "../tst/ppu_ri/ppu_ri_full_regression_test.sv"
    `include "../tst/ppu_ri/ppu_ri_scroll_signoff_test.sv"

endpackage

`endif
