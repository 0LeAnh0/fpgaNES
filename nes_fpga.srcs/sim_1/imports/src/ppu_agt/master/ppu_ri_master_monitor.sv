`ifndef PPU_RI_MASTER_MONITOR_SV
`define PPU_RI_MASTER_MONITOR_SV

// ===========================================================================
// ppu_ri_master_monitor
// Quan sat CPU-side bus (ri_sel, ri_ncs, ri_r_nw, ri_din, ri_dout).
// Thu thap transaction moi khi phat hien NCS = 0 (active).
// Gui item qua TLM analysis port den Scoreboard va Subscriber.
// ===========================================================================
class ppu_ri_master_monitor extends uvm_monitor;
    `uvm_component_utils(ppu_ri_master_monitor)

    virtual ppu_ri_if vif;

    // Analysis port → Scoreboard (master_export) + TLM Master Subscriber
    uvm_analysis_port #(ppu_ri_sequence_item) master_mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        master_mon_ap = new("master_mon_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", vif))
            `uvm_fatal("NO_VIF",
                $sformatf("[MASTER_MON] virtual ppu_ri_if not found for %s", get_full_name()))
    endfunction

    virtual task run_phase(uvm_phase phase);
        ppu_ri_sequence_item tr;
        logic ncs_last = 1'b1;
        logic ncs_synced;
        forever begin
            @(vif.monitor_cb);
            ncs_synced = vif.monitor_cb.ri_ncs;

            // Edge detection: capture only on NCS falling edge
            if (ncs_last === 1'b1 && ncs_synced === 1'b0) begin
                tr = ppu_ri_sequence_item::type_id::create("master_tr");
                tr.sel     = vif.monitor_cb.ri_sel;
                tr.r_nw    = vif.monitor_cb.ri_r_nw;
                tr.data_in = vif.monitor_cb.ri_din;
                tr.obs_spr_din = vif.monitor_cb.spr_ram_din;

                // Doi them 1 chu ky clock de tranh race condition va cho ban cap nhat (theo yeu cau "capture tre 1 chu ky clock")
                @(vif.monitor_cb); // Wait cycle 1
                @(vif.monitor_cb); // Wait cycle 2 for stability

                if (tr.r_nw == 1'b1)
                    tr.data_out = vif.monitor_cb.ri_dout;
                tr.obs_fv           = vif.monitor_cb.fv;
                tr.obs_vt           = vif.monitor_cb.vt;
                tr.obs_v            = vif.monitor_cb.v;
                tr.obs_fh           = vif.monitor_cb.fh;
                tr.obs_ht           = vif.monitor_cb.ht;
                tr.obs_h            = vif.monitor_cb.h;
                tr.obs_s            = vif.monitor_cb.s;
                tr.obs_inc_addr_amt = vif.monitor_cb.inc_addr_amt;

                if (tr.r_nw == 1'b1) begin
                    `uvm_info("MASTER_MON",
                        $sformatf("CAPTURED MASTER: SEL=%0d ($200%0h) RD DIN=%02h DOUT=%02h | SCROLL fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d inc_amt=%0d",
                            tr.sel, tr.sel, tr.data_in, tr.data_out,
                            tr.obs_fv, tr.obs_vt, tr.obs_v, tr.obs_fh, tr.obs_ht, tr.obs_h, tr.obs_s, tr.obs_inc_addr_amt),
                        UVM_LOW)
                end else begin
                    `uvm_info("MASTER_MON",
                        $sformatf("CAPTURED MASTER: SEL=%0d ($200%0h) WR DIN=%02h | SCROLL fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d inc_amt=%0d",
                            tr.sel, tr.sel, tr.data_in,
                            tr.obs_fv, tr.obs_vt, tr.obs_v, tr.obs_fh, tr.obs_ht, tr.obs_h, tr.obs_s, tr.obs_inc_addr_amt),
                        UVM_LOW)
                end
                master_mon_ap.write(tr);
            end

            ncs_last = ncs_synced;
        end
    endtask

endclass

`endif
