`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import uart_pkg::*;

module uart_tb_top;
    localparam int unsigned UART_SYS_CLK_FREQ = 50_000_000;
    localparam int unsigned UART_BAUD_RATE    = 1_000_000;
    localparam int unsigned UART_PARITY_MODE  = 1;
    localparam int unsigned UART_DATA_BITS    = 8;
    localparam int unsigned UART_STOP_BITS    = 1;

    logic clk;
    uart_if uart_vif(.clk(clk));
    uart_cfg m_uart_cfg;

    wire dut_rx;
    assign dut_rx     = uart_vif.rx_override_en ? uart_vif.rx_override_val : uart_vif.tx;
    assign uart_vif.rx = dut_rx;

    uart #(
        .SYS_CLK_FREQ(UART_SYS_CLK_FREQ),
        .BAUD_RATE   (UART_BAUD_RATE),
        .DATA_BITS   (UART_DATA_BITS),
        .STOP_BITS   (UART_STOP_BITS),
        .PARITY_MODE (UART_PARITY_MODE)
    ) dut (
        .clk       (clk),
        .reset     (uart_vif.reset),
        .rx        (uart_vif.rx),
        .tx_data   (uart_vif.tx_data),
        .rd_en     (uart_vif.rd_en),
        .wr_en     (uart_vif.wr_en),
        .tx        (uart_vif.tx),
        .rx_data   (uart_vif.rx_data),
        .rx_empty  (uart_vif.rx_empty),
        .tx_full   (uart_vif.tx_full),
        .parity_err(uart_vif.parity_err)
    );

    initial begin
        clk = 1'b0;
        forever #10ns clk = ~clk;
    end

    initial begin
        string testname;

        uart_vif.reset           = 1'b1;
        uart_vif.wr_en           = 1'b0;
        uart_vif.rd_en           = 1'b0;
        uart_vif.tx_data         = 8'h00;
        uart_vif.rx_override_en  = 1'b0;
        uart_vif.rx_override_val = 1'b1;

        m_uart_cfg = uart_cfg::type_id::create("m_uart_cfg");
        m_uart_cfg.sys_clk_freq    = UART_SYS_CLK_FREQ;
        m_uart_cfg.baud_rate       = UART_BAUD_RATE;
        m_uart_cfg.data_bits       = UART_DATA_BITS;
        m_uart_cfg.stop_bits       = UART_STOP_BITS;
        m_uart_cfg.parity_mode     = UART_PARITY_MODE;
        m_uart_cfg.oversample_rate = 16;
        m_uart_cfg.fifo_depth      = 8;
        m_uart_cfg.timeout_ms      = 20;

        uvm_config_db#(uart_cfg)::set(null, "uvm_test_top*", "uart_cfg", m_uart_cfg);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.*m_uart_agent.*", "vif", uart_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top", "uart_vif", uart_vif);

        fork
            begin
                #120ns;
                uart_vif.reset = 1'b0;
            end
        join_none

        if (!$value$plusargs("UVM_TESTNAME=%s", testname))
            run_test("uart_full_regression_test");
        else
            run_test();
    end
endmodule
