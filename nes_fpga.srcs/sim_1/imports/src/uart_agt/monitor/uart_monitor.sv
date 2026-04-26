`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_component;
    `uvm_component_utils(uart_monitor)

    virtual uart_if vif;
    uvm_analysis_port #(uart_item) evt_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        evt_ap = new("evt_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("UART_MON", "No uart_if found in config DB")
    endfunction

    task run_phase(uvm_phase phase);
        bit prev_parity_err;
        prev_parity_err = 1'b0;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.reset)
                prev_parity_err = 1'b0;

            if (vif.mon_cb.rd_en && !vif.mon_cb.rx_empty) begin
                uart_item rx_evt;
                rx_evt = uart_item::type_id::create("rx_evt");
                rx_evt.kind              = UART_EVT_RX_DATA;
                rx_evt.data              = vif.mon_cb.rx_data;
                rx_evt.rx_empty_snapshot = vif.mon_cb.rx_empty;
                rx_evt.tx_full_snapshot  = vif.mon_cb.tx_full;
                evt_ap.write(rx_evt);
                `uvm_info("UART_MON", $sformatf("RX_DATA data=0x%02h", rx_evt.data), UVM_MEDIUM)
            end

            if (!prev_parity_err && vif.mon_cb.parity_err) begin
                uart_item parity_evt;
                parity_evt = uart_item::type_id::create("parity_evt");
                parity_evt.kind              = UART_EVT_PARITY_ERR;
                parity_evt.rx_empty_snapshot = vif.mon_cb.rx_empty;
                parity_evt.tx_full_snapshot  = vif.mon_cb.tx_full;
                evt_ap.write(parity_evt);
                `uvm_info("UART_MON", "PARITY_ERR observed", UVM_MEDIUM)
            end

            prev_parity_err = vif.mon_cb.parity_err;
        end
    endtask
endclass

`endif
