`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;
    uart_cfg        m_cfg;

    uvm_analysis_port #(uart_item) cmd_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cmd_ap = new("cmd_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("UART_DRV", "No uart_if found in config DB")
        if (!uvm_config_db#(uart_cfg)::get(this, "", "uart_cfg", m_cfg))
            m_cfg = uart_cfg::type_id::create("m_cfg");
    endfunction

    task run_phase(uvm_phase phase);
        uart_item req;
        vif.drive_idle();
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    protected task drive_item(uart_item req);
        uart_item obs;

        obs = uart_item::type_id::create("obs");
        obs.copy(req);

        if (req.idle_cycles != 0)
            vif.wait_cycles(req.idle_cycles);

        obs.rx_empty_snapshot = vif.mon_cb.rx_empty;
        obs.tx_full_snapshot  = vif.mon_cb.tx_full;

        case (req.kind)
            UART_CMD_TX_WRITE:  do_tx_write(obs);
            UART_CMD_RX_READ:   do_rx_read(obs);
            UART_CMD_INJECT_RX: do_inject_rx(obs);
            UART_CMD_RESET:     do_reset(obs);
            default: `uvm_warning("UART_DRV", $sformatf("Ignoring unsupported request kind %s", req.kind.name()))
        endcase

        cmd_ap.write(obs);
    endtask

    protected task do_tx_write(uart_item tr);
        if (!tr.allow_tx_while_full) begin
            while (vif.mon_cb.tx_full)
                @(vif.drv_cb);
        end

        tr.tx_full_snapshot = vif.mon_cb.tx_full;
        tr.rx_empty_snapshot = vif.mon_cb.rx_empty;
        tr.tx_accept        = !vif.mon_cb.tx_full;
        tr.expect_rx        = tr.tx_accept;
        tr.expect_parity_err= 1'b0;

        vif.drv_cb.tx_data <= tr.data;
        vif.drv_cb.wr_en   <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.wr_en   <= 1'b0;

        `uvm_info("UART_DRV", $sformatf("TX_WRITE data=0x%02h accept=%0b tx_full=%0b", tr.data, tr.tx_accept, tr.tx_full_snapshot), UVM_MEDIUM)
    endtask

    protected task do_rx_read(uart_item tr);
        tr.tx_accept         = 1'b0;
        tr.expect_rx         = 1'b0;
        tr.expect_parity_err = 1'b0;
        tr.rx_empty_snapshot = vif.mon_cb.rx_empty;
        tr.tx_full_snapshot  = vif.mon_cb.tx_full;

        while (vif.mon_cb.rx_empty)
            @(vif.drv_cb);

        // Give the FIFO state a clean cycle to settle before issuing the read pulse.
        @(vif.drv_cb);
        vif.drv_cb.rd_en <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.rd_en <= 1'b0;

        `uvm_info("UART_DRV", "RX_READ issued", UVM_MEDIUM)
    endtask

    protected task do_inject_rx(uart_item tr);
        tr.tx_accept         = 1'b0;
        tr.expect_rx         = 1'b1;
        tr.expect_parity_err = tr.inject_bad_parity;
        vif.send_serial_frame(tr.data, tr.inject_bad_parity, m_cfg.clocks_per_bit(), m_cfg.parity_mode);
        `uvm_info("UART_DRV", $sformatf("INJECT_RX data=0x%02h bad_parity=%0b", tr.data, tr.inject_bad_parity), UVM_MEDIUM)
    endtask

    protected task do_reset(uart_item tr);
        tr.tx_accept         = 1'b0;
        tr.expect_rx         = 1'b0;
        tr.expect_parity_err = 1'b0;
        vif.pulse_reset(tr.reset_cycles);
        `uvm_info("UART_DRV", $sformatf("RESET pulse_cycles=%0d", tr.reset_cycles), UVM_MEDIUM)
    endtask
endclass

`endif
