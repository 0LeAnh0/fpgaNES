`ifndef UART_PKG_SV
`define UART_PKG_SV

package uart_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "../cfg/uart_cfg.sv"
    `include "../uart_agt/seq/uart_item.sv"
    `include "../uart_agt/seq/uart_sequences.sv"
    `include "../uart_agt/uart_sequencer.sv"
    `include "../uart_agt/driver/uart_driver.sv"
    `include "../uart_agt/monitor/uart_monitor.sv"
    `include "../uart_agt/uart_agent.sv"
    `include "../chk/uart_scoreboard.sv"
    `include "../cov/uart_cov.sv"
    `include "../env/uart_env.sv"
    `include "../tst/uart/uart_base_test.sv"
    `include "../tst/uart/uart_sanity_test.sv"
    `include "../tst/uart/uart_fifo_stress_test.sv"
    `include "../tst/uart/uart_parity_error_test.sv"
    `include "../tst/uart/uart_reset_recovery_test.sv"
    `include "../tst/uart/uart_full_regression_test.sv"
endpackage

`endif
