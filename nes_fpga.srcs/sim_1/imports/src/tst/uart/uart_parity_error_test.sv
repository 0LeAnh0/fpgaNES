`ifndef UART_PARITY_ERROR_TEST_SV
`define UART_PARITY_ERROR_TEST_SV

class uart_parity_error_test extends uart_base_test;
    `uvm_component_utils(uart_parity_error_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_parity_error_seq seq;
        phase.raise_objection(this);
        print_case_header("UART_TC03_PARITY", "Inject clean and corrupted RX frames and observe parity error behavior");
        seq = uart_parity_error_seq::type_id::create("seq");
        seq.start(m_env.m_uart_agent.sequencer);
        wait_for_uart_drain();
        phase.drop_objection(this);
    endtask
endclass

`endif
