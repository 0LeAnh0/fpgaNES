`ifndef PPU_RI_MASTER_DRIVER_SV
`define PPU_RI_MASTER_DRIVER_SV

// ===========================================================================
// ppu_ri_master_driver
// Dong vai tro CPU: lai cac tin hieu ri_sel, ri_ncs, ri_r_nw, ri_din
// vao PPU theo dung timing cua RTL ppu_ri.v.
//
// RTL note (ppu_ri.v line 218):
//   "Only evaluate RI reads/writes on /CS falling edges"
//   => PPU phat hien khi q_ncs_in=1 va ncs_in=0 (canh xuong cua NCS).
//   => Driver phai dam bao NCS xuong dung 1 canh ro rang.
// ===========================================================================
class ppu_ri_master_driver extends uvm_driver #(ppu_ri_sequence_item);
    `uvm_component_utils(ppu_ri_master_driver)

    virtual ppu_ri_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", vif))
            `uvm_fatal("NO_VIF",
                $sformatf("[MASTER_DRV] virtual ppu_ri_if not found for %s", get_full_name()))
    endfunction

    virtual task run_phase(uvm_phase phase);
        drive_idle();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    //----------------------------------------------------------------------
    local task drive_idle();
        @(vif.master_cb);
        vif.master_cb.ri_ncs  <= 1'b1;
        vif.master_cb.ri_r_nw <= 1'b1;
        vif.master_cb.ri_sel  <= 3'h0;
        vif.master_cb.ri_din  <= 8'h00;
    endtask

    local task drive_transaction(ppu_ri_sequence_item item);
        // CYCLE 1: On dinh address/control, NCS van = 1
        @(vif.master_cb);
        vif.master_cb.ri_sel  <= item.sel;
        vif.master_cb.ri_r_nw <= item.r_nw;
        vif.master_cb.ri_din  <= item.data_in;
        vif.master_cb.ri_ncs  <= 1'b1;

        // CYCLE 2: Keo NCS xuong 0 -> PPU bat falling edge
        @(vif.master_cb);
        vif.master_cb.ri_ncs <= 1'b0;

        // CYCLE 3-4-5: Giu lau hon để chac chan RTL bat duoc (đặc biệt là với clock 100MHz)
        repeat(3) @(vif.master_cb);

        // CYCLE 4: Capture dout neu la READ
        if (item.r_nw == 1'b1) begin
            item.data_out = vif.master_cb.ri_dout;
            `uvm_info("MASTER_DRV",
                $sformatf("READ  $200%0h -> data_out=%02h", item.sel, item.data_out), UVM_HIGH)
        end else begin
            `uvm_info("MASTER_DRV",
                $sformatf("WRITE $200%0h <- data_in=%02h", item.sel, item.data_in), UVM_HIGH)
        end

        // CYCLE 5: Nha NCS (end of transaction)
        @(vif.master_cb);
        vif.master_cb.ri_ncs <= 1'b1;
    endtask

endclass

`endif
