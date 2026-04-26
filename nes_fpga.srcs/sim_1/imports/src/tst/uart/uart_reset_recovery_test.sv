`ifndef UART_RESET_RECOVERY_TEST_SV
`define UART_RESET_RECOVERY_TEST_SV

class uart_reset_recovery_test extends uart_base_test;
    `uvm_component_utils(uart_reset_recovery_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_reset_recovery_seq seq;
        phase.raise_objection(this);
        print_case_header("UART_TC04_RESET_RECOVERY", "Reset while traffic exists, then verify clean recovery");
        seq = uart_reset_recovery_seq::type_id::create("seq");
        seq.start(m_env.m_uart_agent.sequencer);
        wait_for_uart_drain();
        phase.drop_objection(this);
    endtask
endclass

`endif
