`ifndef UART_SEQUENCES_SV
`define UART_SEQUENCES_SV

class uart_base_sequence extends uvm_sequence #(uart_item);
    `uvm_object_utils(uart_base_sequence)

    function new(string name = "uart_base_sequence");
        super.new(name);
    endfunction

    protected task issue_item(
        uart_tr_kind_e kind,
        bit [7:0]      data             = 8'h00,
        int unsigned   idle_cycles      = 0,
        int unsigned   reset_cycles     = 4,
        bit            bad_parity       = 0,
        bit            allow_while_full = 0
    );
        uart_item item;
        item = uart_item::type_id::create($sformatf("uart_item_%0d", $time));
        start_item(item);
        item.kind                = kind;
        item.data                = data;
        item.idle_cycles         = idle_cycles;
        item.reset_cycles        = reset_cycles;
        item.inject_bad_parity   = bad_parity;
        item.allow_tx_while_full = allow_while_full;
        finish_item(item);
    endtask

    protected task issue_tx(bit [7:0] data, int unsigned idle_cycles = 0, bit allow_while_full = 0);
        issue_item(UART_CMD_TX_WRITE, data, idle_cycles, 4, 0, allow_while_full);
    endtask

    protected task issue_read(int unsigned idle_cycles = 0);
        issue_item(UART_CMD_RX_READ, 8'h00, idle_cycles);
    endtask

    protected task issue_inject(bit [7:0] data, bit bad_parity = 0, int unsigned idle_cycles = 0);
        issue_item(UART_CMD_INJECT_RX, data, idle_cycles, 4, bad_parity);
    endtask

    protected task issue_reset(int unsigned hold_cycles = 4);
        issue_item(UART_CMD_RESET, 8'h00, 0, hold_cycles);
    endtask
endclass

class uart_sanity_seq extends uart_base_sequence;
    `uvm_object_utils(uart_sanity_seq)

    function new(string name = "uart_sanity_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] patterns[$] = '{
            8'h00, 8'hFF, 8'h55, 8'hAA,
            8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80,
            8'hFE, 8'hFD, 8'hFB, 8'hF7, 8'hEF, 8'hDF, 8'hBF, 8'h7F,
            8'h3C
        };

        issue_reset(6);
        foreach (patterns[i]) begin
            issue_tx(patterns[i], i[1:0]);
            issue_read(0);
        end
    endtask
endclass

class uart_fifo_stress_seq extends uart_base_sequence;
    `uvm_object_utils(uart_fifo_stress_seq)

    function new(string name = "uart_fifo_stress_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] fill_data[$] = '{8'h11, 8'h22, 8'h44, 8'h88, 8'hEE, 8'hDD, 8'hBB, 8'h77, 8'h33, 8'hCC};

        issue_reset(5);
        foreach (fill_data[i])
            issue_tx(fill_data[i], 0, 1'b1);

        repeat (8)
            issue_read();
    endtask
endclass

class uart_parity_error_seq extends uart_base_sequence;
    `uvm_object_utils(uart_parity_error_seq)

    function new(string name = "uart_parity_error_seq");
        super.new(name);
    endfunction

    task body();
        issue_reset(5);
        issue_inject(8'h3C, 1'b0, 1);
        issue_read();
        issue_inject(8'hC3, 1'b1, 2);
        issue_read();
    endtask
endclass

class uart_reset_recovery_seq extends uart_base_sequence;
    `uvm_object_utils(uart_reset_recovery_seq)

    function new(string name = "uart_reset_recovery_seq");
        super.new(name);
    endfunction

    task body();
        issue_reset(4);
        issue_tx(8'hA5, 0);
        issue_tx(8'h5A, 0);
        issue_reset(6);
        issue_tx(8'h3C, 1);
        issue_read();
        issue_tx(8'hC3, 1);
        issue_read();
    endtask
endclass

class uart_full_regression_seq extends uart_base_sequence;
    `uvm_object_utils(uart_full_regression_seq)

    function new(string name = "uart_full_regression_seq");
        super.new(name);
    endfunction

    task body();
        uart_sanity_seq         sanity_seq;
        uart_fifo_stress_seq    fifo_seq;
        uart_parity_error_seq   parity_seq;
        uart_reset_recovery_seq reset_seq;

        sanity_seq = uart_sanity_seq::type_id::create("sanity_seq");
        fifo_seq   = uart_fifo_stress_seq::type_id::create("fifo_seq");
        parity_seq = uart_parity_error_seq::type_id::create("parity_seq");
        reset_seq  = uart_reset_recovery_seq::type_id::create("reset_seq");

        sanity_seq.start(m_sequencer);
        fifo_seq.start(m_sequencer);
        parity_seq.start(m_sequencer);
        reset_seq.start(m_sequencer);
    endtask
endclass

`endif
