`ifndef PPU_RI_SLAVE_DRIVER_SV
`define PPU_RI_SLAVE_DRIVER_SV

// ===========================================================================
// ppu_ri_slave_driver  [ppu_agt/slave/]
// Dong vai VRAM/Memory — nhan dia chi tu PPU va tra du lieu nguoc lai.
//
// Vai tro quan trong:
//   Khi CPU doc $2007 (PPUDATA READ):
//     1. PPU phat ra vram_a (dia chi can doc)
//     2. Slave Driver nhan vram_a, tra bang noi bo (mem_model)
//     3. Slave Driver drive vram_din = data tuong ung -> PPU nhan va latch
//
//   Khi CPU ghi $2007 (PPUDATA WRITE):
//     1. PPU phat ra vram_a + vram_dout + vram_wr=1
//     2. Slave Driver quan sat, cap nhat mem_model[vram_a] = vram_dout
//     -> Slave Driver tu dong bo noi bo, khong can drive vram_din
//
// mem_model: Associative array [14-bit addr] = [8-bit data]
//   Co the pre-load tu test sequence truoc khi run.
// ===========================================================================
class ppu_ri_slave_driver extends uvm_driver #(ppu_ri_sequence_item);
    `uvm_component_utils(ppu_ri_slave_driver)

    virtual ppu_ri_if vif;

    // Internal memory model (gia lap VRAM 16KB)
    logic [7:0] mem_model [logic [13:0]];
    bit mem_init_done;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", vif))
            `uvm_fatal("NO_VIF",
                $sformatf("[SLAVE_DRV] virtual ppu_ri_if not found for %s", get_full_name()))
        mem_init_done = 0;
    endfunction

    // Task de test pre-load du lieu vao mem_model
    function void preload_mem(logic [13:0] addr, logic [7:0] data);
        mem_model[addr] = data;
        `uvm_info("SLAVE_DRV",
            $sformatf("PRELOAD mem[%04h] = %02h", addr, data), UVM_HIGH)
    endfunction

    // Initialize all VRAM locations once to deterministic value.
    // This removes READ UNINITIALIZED noise and models known power-up state.
    protected function void init_mem_model();
        int unsigned a;
        if (mem_init_done) return;
        for (a = 0; a < 16384; a++) begin
            mem_model[a[13:0]] = 8'h00;
        end
        mem_init_done = 1;
        `uvm_info("SLAVE_DRV", "Initialized mem_model[0000..3FFF] to 00", UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        init_mem_model();
        // Default: drive vram_din = 0
        vif.slave_cb.vram_din <= 8'h00;
        // Khong co spr_ram (OAM) trong mem_model hien tai, drive default:
        vif.slave_cb.spr_ram_din <= 8'h77;

        forever begin
            @(vif.slave_cb);

            // Truong hop PPU dang READ tu VRAM (vram_wr=0 trong khi NCS active)
            // PPU dat dia chi ra vram_a, slave phai respond vram_din
            if (vif.slave_cb.vram_wr === 1'b0 &&
                vif.monitor_cb.ri_ncs === 1'b0 &&
                vif.monitor_cb.ri_r_nw === 1'b1 &&
                vif.monitor_cb.ri_sel === 3'h7) begin

                logic [13:0] req_addr = vif.slave_cb.vram_a;

                if (mem_model.exists(req_addr)) begin
                    vif.slave_cb.vram_din <= mem_model[req_addr];
                    `uvm_info("SLAVE_DRV",
                        $sformatf("READ RESPONSE: vram_a=%04h -> vram_din=%02h",
                            req_addr, mem_model[req_addr]), UVM_LOW)
                end else begin
                    // Should not happen after full initialization. Keep deterministic fallback.
                    vif.slave_cb.vram_din <= 8'h00;
                    mem_model[req_addr]   = 8'h00;
                    `uvm_error("SLAVE_DRV",
                        $sformatf("Unexpected missing mem_model entry at %04h after init", req_addr))
                end
            end

            // Truong hop PPU dang WRITE vao VRAM: cap nhat mem_model
            if (vif.slave_cb.vram_wr === 1'b1) begin
                logic [13:0] wr_addr  = vif.slave_cb.vram_a;
                logic [ 7:0] wr_data  = vif.monitor_cb.vram_dout;
                mem_model[wr_addr] = wr_data;
                `uvm_info("SLAVE_DRV",
                    $sformatf("WRITE CAPTURED: mem[%04h] = %02h", wr_addr, wr_data), UVM_HIGH)
            end

            // OAM WRITE: cap nhat mem_model tai dia chi OAM (offset 0x3F00 conceptually)
            if (vif.slave_cb.spr_ram_wr === 1'b1) begin
                `uvm_info("SLAVE_DRV",
                    $sformatf("OAM WRITE: oam_a=%02h data=%02h",
                        vif.monitor_cb.spr_ram_a, vif.monitor_cb.spr_ram_dout), UVM_HIGH)
            end

            // Hoan thanh item neu co tu sequencer
            if (seq_item_port.has_do_available()) begin
                seq_item_port.get_next_item(req);
                seq_item_port.item_done();
            end
        end
    endtask

endclass

`endif
