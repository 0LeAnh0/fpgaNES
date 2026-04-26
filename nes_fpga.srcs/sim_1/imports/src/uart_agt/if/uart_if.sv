`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if(input logic clk);
    logic       reset;
    logic       rx;
    logic [7:0] tx_data;
    logic       rd_en;
    logic       wr_en;
    logic       tx;
    logic [7:0] rx_data;
    logic       rx_empty;
    logic       tx_full;
    logic       parity_err;

    logic       rx_override_en;
    logic       rx_override_val;

    clocking drv_cb @(posedge clk);
        output reset;
        output tx_data;
        output rd_en;
        output wr_en;
        output rx_override_en;
        output rx_override_val;
        input  rx_data;
        input  rx_empty;
        input  tx_full;
        input  parity_err;
        input  tx;
    endclocking

    clocking mon_cb @(posedge clk);
        input reset;
        input tx_data;
        input rd_en;
        input wr_en;
        input tx;
        input rx_data;
        input rx_empty;
        input tx_full;
        input parity_err;
        input rx_override_en;
        input rx_override_val;
    endclocking

    task automatic wait_cycles(int unsigned cycles);
        repeat (cycles) @(drv_cb);
    endtask

    task automatic drive_idle();
        drv_cb.wr_en           <= 1'b0;
        drv_cb.rd_en           <= 1'b0;
        drv_cb.tx_data         <= 8'h00;
        drv_cb.rx_override_en  <= 1'b0;
        drv_cb.rx_override_val <= 1'b1;
    endtask

    task automatic pulse_reset(int unsigned hold_cycles = 4);
        drive_idle();
        drv_cb.reset <= 1'b1;
        wait_cycles(hold_cycles);
        drv_cb.reset <= 1'b0;
        wait_cycles(2);
    endtask

    task automatic send_serial_frame(
        input bit [7:0] data,
        input bit       bad_parity,
        input int unsigned bit_cycles,
        input int unsigned parity_mode
    );
        bit parity_bit;

        parity_bit = 1'b1;
        if (parity_mode == 1)
            parity_bit = ~^data;
        else if (parity_mode == 2)
            parity_bit = ^data;

        if ((parity_mode != 0) && bad_parity)
            parity_bit = ~parity_bit;

        drv_cb.rx_override_en  <= 1'b1;
        drv_cb.rx_override_val <= 1'b1;
        wait_cycles(2);

        drv_cb.rx_override_val <= 1'b0; // start bit
        wait_cycles(bit_cycles);

        for (int i = 0; i < 8; i++) begin
            drv_cb.rx_override_val <= data[i];
            wait_cycles(bit_cycles);
        end

        if (parity_mode != 0) begin
            drv_cb.rx_override_val <= parity_bit;
            wait_cycles(bit_cycles);
        end

        drv_cb.rx_override_val <= 1'b1; // stop bit
        wait_cycles(bit_cycles);

        drv_cb.rx_override_en  <= 1'b0;
        drv_cb.rx_override_val <= 1'b1;
        wait_cycles(2);
    endtask

endinterface

`endif
