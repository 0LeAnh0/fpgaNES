`ifndef UART_CFG_SV
`define UART_CFG_SV

class uart_cfg extends uvm_object;
    `uvm_object_utils(uart_cfg)

    int unsigned sys_clk_freq    = 50_000_000;
    int unsigned baud_rate       = 1_000_000;
    int unsigned data_bits       = 8;
    int unsigned stop_bits       = 1;
    int unsigned parity_mode     = 1; // 0=none, 1=odd, 2=even
    int unsigned oversample_rate = 16;
    int unsigned fifo_depth      = 8;
    int unsigned timeout_ms      = 20;

    function new(string name = "uart_cfg");
        super.new(name);
    endfunction

    function int unsigned clocks_per_oversample_tick();
        return (sys_clk_freq / baud_rate) / oversample_rate;
    endfunction

    function int unsigned clocks_per_bit();
        return clocks_per_oversample_tick() * oversample_rate;
    endfunction
endclass

`endif
