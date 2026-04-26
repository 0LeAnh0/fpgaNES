`ifndef UART_BASE_TEST_SV
`define UART_BASE_TEST_SV

class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)

    uart_env        m_env;
    uart_cfg        m_cfg;
    virtual uart_if uart_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        time timeout_limit;
        super.build_phase(phase);
        m_env = uart_env::type_id::create("m_env", this);
        if (!uvm_config_db#(uart_cfg)::get(this, "", "uart_cfg", m_cfg)) begin
            m_cfg = uart_cfg::type_id::create("m_cfg");
            uvm_config_db#(uart_cfg)::set(this, "*", "uart_cfg", m_cfg);
        end
        void'(uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", uart_vif));
        timeout_limit = 1_000_000;
        timeout_limit = timeout_limit * 50_000;
        uvm_top.set_timeout(timeout_limit, 1);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    protected task print_case_header(string case_name, string goal);
        `uvm_info("UART_CASE", " ", UVM_NONE)
        `uvm_info("UART_CASE", "############################################################", UVM_NONE)
        `uvm_info("UART_CASE", "#################### UART TESTCASE #########################", UVM_NONE)
        `uvm_info("UART_CASE", "############################################################", UVM_NONE)
        `uvm_info("UART_CASE", $sformatf("CASE_ID : %s", case_name), UVM_NONE)
        `uvm_info("UART_CASE", $sformatf("PURPOSE : %s", goal), UVM_NONE)
        `uvm_info("UART_CASE", "############################################################", UVM_NONE)
        `uvm_info("UART_CASE", " ", UVM_NONE)
    endtask

    protected task wait_for_uart_drain(int unsigned max_cycles = 2000);
        int unsigned cycles;

        if (uart_vif == null)
            return;

        cycles = 0;
        while ((m_env.m_uart_scoreboard.m_expected_rx_q.size() != 0) && (cycles < max_cycles)) begin
            @(uart_vif.mon_cb);
            cycles++;
        end

        repeat (4)
            @(uart_vif.mon_cb);
    endtask
endclass

`endif
