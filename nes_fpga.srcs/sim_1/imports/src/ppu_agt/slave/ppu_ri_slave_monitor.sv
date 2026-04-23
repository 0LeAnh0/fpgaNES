`ifndef PPU_RI_SLAVE_MONITOR_SV
`define PPU_RI_SLAVE_MONITOR_SV

// ===========================================================================
// ppu_ri_slave_monitor  [ppu_agt/slave/]
// Quan sat PPU OUTPUT SIDE — cac tin hieu ma ppu_ri.v phat ra den
// VRAM/PRAM/OAM sau khi nhan lenh tu CPU ($2007 -> vram_wr/pram_wr,
//                                          $2004 -> spr_ram_wr).
//
// Slave monitor "lap day" cac truong obs_* trong transaction item va
// gui qua slave_mon_ap de Scoreboard cross-check side-effect.
// ===========================================================================
class ppu_ri_slave_monitor extends uvm_monitor;
    `uvm_component_utils(ppu_ri_slave_monitor)

    virtual ppu_ri_if vif;

    // Analysis port → Scoreboard (slave_export) + TLM Slave Subscriber
    uvm_analysis_port #(ppu_ri_sequence_item) slave_mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        slave_mon_ap = new("slave_mon_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", vif))
            `uvm_fatal("NO_VIF",
                $sformatf("[SLAVE_MON] virtual ppu_ri_if not found for %s", get_full_name()))
    endfunction

    virtual task run_phase(uvm_phase phase);
        ppu_ri_sequence_item tr;
        bit read_side_effect;
        forever begin
            @(vif.monitor_cb);

            // Quan sat khi bat ky side-effect nao active:
            // - vram_wr/pram_wr: write vao VRAM/PRAM boi $2007 WRITE
            // - spr_ram_wr:      write vao OAM boi $2004 WRITE
            // - inc_addr:        increment dia chi boi $2007 READ/WRITE
            // Observe when any side-effect becomes active.
            // Note: upd_cntrs is a 1-cycle pulse. If we are using clocking block,
            // we sample the value stable at the edge.
            if (vif.monitor_cb.vram_wr    === 1'b1 ||
                vif.monitor_cb.pram_wr    === 1'b1 ||
                vif.monitor_cb.spr_ram_wr === 1'b1 ||
                vif.monitor_cb.inc_addr   === 1'b1 ||
                vif.monitor_cb.upd_cntrs  === 1'b1 ||
                vif.upd_cntrs             === 1'b1) begin // Robust pulse catch

                tr = ppu_ri_sequence_item::type_id::create("slave_tr");

                // Chup CPU-side context de lien ket transaction
                tr.sel     = vif.monitor_cb.ri_sel;
                tr.r_nw    = vif.monitor_cb.ri_r_nw;
                tr.data_in = vif.monitor_cb.ri_din;

                // Chup PPU-side outputs (side-effects)
                // Use raw vif signals for status fields as pulses can be 1-cycle long
                tr.obs_vram_a    = vif.monitor_cb.vram_a;
                tr.obs_vram_dout = vif.monitor_cb.vram_dout;
                tr.obs_vram_wr   = vif.monitor_cb.vram_wr;
                tr.obs_pram_wr   = vif.monitor_cb.pram_wr;
                tr.obs_spr_a     = vif.monitor_cb.spr_ram_a;
                tr.obs_spr_dout  = vif.monitor_cb.spr_ram_dout;
                tr.obs_spr_wr    = vif.monitor_cb.spr_ram_wr;
                tr.obs_inc_addr  = (vif.monitor_cb.inc_addr === 1'b1 || vif.inc_addr === 1'b1);
                tr.obs_upd_cntrs = (vif.monitor_cb.upd_cntrs === 1'b1 || vif.upd_cntrs === 1'b1);

                // For $2007 reads, the slave driver returns vram_din on slave_cb with output #1ns,
                // while monitor_cb samples inputs at #1step. Wait a little and then sample raw vif
                // so the checker sees the real data that updated the DUT read buffer.
                read_side_effect = tr.obs_inc_addr && !tr.obs_vram_wr && !tr.obs_pram_wr;
                if (read_side_effect) begin
                    #2ns;
                    tr.obs_vram_din = vif.vram_din;
                end else begin
                    tr.obs_vram_din = vif.monitor_cb.vram_din;
                end

                `uvm_info("SLAVE_MON",
                    $sformatf("PPU OUTPUT: vram_a=%04h vram_wr=%b pram_wr=%b oam_a=%02h oam_wr=%b inc_addr=%b upd_cntrs=%b",
                        tr.obs_vram_a, tr.obs_vram_wr, tr.obs_pram_wr,
                        tr.obs_spr_a,  tr.obs_spr_wr, tr.obs_inc_addr, tr.obs_upd_cntrs), UVM_LOW)
                slave_mon_ap.write(tr);
            end
        end
    endtask

endclass

`endif
