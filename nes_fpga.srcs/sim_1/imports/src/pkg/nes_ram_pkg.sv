`ifndef NES_RAM_PKG_SV
`define NES_RAM_PKG_SV

// ===========================================================================
// nes_ram_pkg
// Package chung cho RAM Verification (WRAM + VRAM).
// ===========================================================================
package nes_ram_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // SECTION 1: SEQUENCE ITEM
    // =========================================================================
    `include "../nes_ram_agt/seq/nes_ram_item.sv"

    // =========================================================================
    // SECTION 2: SEQUENCES
    // =========================================================================
    `include "../nes_ram_agt/seq/nes_ram_seq.sv"

    // =========================================================================
    // SECTION 3: COMPONENTS (Driver + Monitor + Agent)
    // =========================================================================
    `include "../nes_ram_agt/nes_ram_sequencer.sv"
    `include "../nes_ram_agt/driver/nes_ram_driver.sv"
    `include "../nes_ram_agt/monitor/nes_ram_monitor.sv"
    `include "../nes_ram_agt/nes_ram_agent.sv"

    // =========================================================================
    // SECTION 4: SCOREBOARD
    // =========================================================================
    `include "../chk/nes_ram_scoreboard.sv"

    // =========================================================================
    // SECTION 5: ENVIRONMENT & TLM
    // =========================================================================
    `include "../tlm/nes_ram_subscriber.sv"
    `include "../cov/nes_ram_cov.sv"
    `include "../env/nes_ram_env.sv"

    // =========================================================================
    // SECTION 5.5: CONFIG OBJECTS
    // =========================================================================
    `include "../cfg/nes_wram_vram_cfg.sv"

    // =========================================================================
    // SECTION 6: TESTS
    // =========================================================================
    `include "../tst/ram/nes_ram_base_test.sv"
    `include "../tst/ram/nes_ram_regression_test.sv"

endpackage

`endif
