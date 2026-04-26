`ifndef UART_FIFO_STRESS_TEST_SV
`define UART_FIFO_STRESS_TEST_SV

class uart_fifo_stress_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_stress_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_fifo_stress_seq seq;
        phase.raise_objection(this);
        print_case_header("UART_TC02_FIFO_STRESS", "Fill TX FIFO, hit full, reject overflow writes, drain loopback bytes");
        seq = uart_fifo_stress_seq::type_id::create("seq");
        seq.start(m_env.m_uart_agent.sequencer);
        wait_for_uart_drain();
        phase.drop_objection(this);
    endtask
endclass

`endif
