`ifndef UART_ENV_SV
`define UART_ENV_SV

class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent      m_uart_agent;
    uart_scoreboard m_uart_scoreboard;
    uart_cov        m_uart_cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_uart_agent      = uart_agent     ::type_id::create("m_uart_agent", this);
        m_uart_scoreboard = uart_scoreboard::type_id::create("m_uart_scoreboard", this);
        m_uart_cov        = uart_cov       ::type_id::create("m_uart_cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_uart_agent.driver.cmd_ap.connect(m_uart_scoreboard.exp_export);
        m_uart_agent.monitor.evt_ap.connect(m_uart_scoreboard.act_export);
        m_uart_agent.driver.cmd_ap.connect(m_uart_cov.cmd_export);
        m_uart_agent.monitor.evt_ap.connect(m_uart_cov.evt_export);
    endfunction
endclass

`endif
