`ifndef UART_FULL_REGRESSION_TEST_SV
`define UART_FULL_REGRESSION_TEST_SV

class uart_full_regression_test extends uart_base_test;
    `uvm_component_utils(uart_full_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_full_regression_seq seq;
        phase.raise_objection(this);
        print_case_header("UART_TC00_FULL_REGRESSION", "Run UART sanity, FIFO stress, parity, and reset-recovery scenarios");
        seq = uart_full_regression_seq::type_id::create("seq");
        seq.start(m_env.m_uart_agent.sequencer);
        wait_for_uart_drain();
        phase.drop_objection(this);
    endtask
endclass

`endif
