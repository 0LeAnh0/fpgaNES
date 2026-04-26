`ifndef UART_ITEM_SV
`define UART_ITEM_SV

typedef enum int {
    UART_CMD_TX_WRITE,
    UART_CMD_RX_READ,
    UART_CMD_INJECT_RX,
    UART_CMD_RESET,
    UART_EVT_RX_DATA,
    UART_EVT_PARITY_ERR
} uart_tr_kind_e;

class uart_item extends uvm_sequence_item;
    rand uart_tr_kind_e kind;
    rand bit [7:0]      data;
    rand int unsigned   idle_cycles;
    rand int unsigned   reset_cycles;
    rand bit            inject_bad_parity;
    rand bit            allow_tx_while_full;

    bit tx_accept;
    bit expect_rx;
    bit expect_parity_err;
    bit rx_empty_snapshot;
    bit tx_full_snapshot;

    `uvm_object_utils_begin(uart_item)
        `uvm_field_enum(uart_tr_kind_e, kind, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(idle_cycles, UVM_ALL_ON)
        `uvm_field_int(reset_cycles, UVM_ALL_ON)
        `uvm_field_int(inject_bad_parity, UVM_ALL_ON)
        `uvm_field_int(allow_tx_while_full, UVM_ALL_ON)
        `uvm_field_int(tx_accept, UVM_ALL_ON)
        `uvm_field_int(expect_rx, UVM_ALL_ON)
        `uvm_field_int(expect_parity_err, UVM_ALL_ON)
        `uvm_field_int(rx_empty_snapshot, UVM_ALL_ON)
        `uvm_field_int(tx_full_snapshot, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_item_defaults {
        idle_cycles inside {[0:4]};
        reset_cycles inside {[2:8]};
    }

    function new(string name = "uart_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "kind=%s data=0x%02h idle=%0d reset=%0d bad_parity=%0b allow_full=%0b accept=%0b exp_rx=%0b exp_perr=%0b rx_empty=%0b tx_full=%0b",
            kind.name(), data, idle_cycles, reset_cycles, inject_bad_parity, allow_tx_while_full,
            tx_accept, expect_rx, expect_parity_err, rx_empty_snapshot, tx_full_snapshot
        );
    endfunction
endclass

`endif
