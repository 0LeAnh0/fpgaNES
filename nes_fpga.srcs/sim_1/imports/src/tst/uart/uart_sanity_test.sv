`ifndef UART_SANITY_TEST_SV
`define UART_SANITY_TEST_SV

class uart_sanity_test extends uart_base_test;
    `uvm_component_utils(uart_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_sanity_seq seq;
        phase.raise_objection(this);
        print_case_header("UART_TC01_SANITY", "Loopback basic data patterns and reads");
        seq = uart_sanity_seq::type_id::create("seq");
        seq.start(m_env.m_uart_agent.sequencer);
        wait_for_uart_drain();
        phase.drop_objection(this);
    endtask
endclass

`endif
