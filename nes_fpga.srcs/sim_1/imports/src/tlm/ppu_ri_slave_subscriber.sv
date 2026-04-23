`ifndef PPU_RI_SLAVE_SUBSCRIBER_SV
`define PPU_RI_SLAVE_SUBSCRIBER_SV

// ===========================================================================
// ppu_ri_slave_subscriber  (TLM Subscriber)
// Nam trong folder tlm/ — nhan transaction tu slave_mon_ap cua agent.
// Chuc nang:
//   - Log tat ca PPU memory-side (VRAM/PRAM/OAM) outputs o muc UVM_HIGH
//   - Co the mo rong thanh coverage cho VRAM access pattern sau
// ===========================================================================
class ppu_ri_slave_subscriber extends uvm_subscriber #(ppu_ri_sequence_item);
    `uvm_component_utils(ppu_ri_slave_subscriber)

    // Bien tam cho covergroup sample.
    ppu_ri_sequence_item tr;

    // Functional coverage cho side-effects cua PPU RI.
    covergroup cg_slave;
        option.per_instance = 1;

        cp_vram_wr: coverpoint tr.obs_vram_wr { bins off = {0}; bins on = {1}; }
        cp_pram_wr: coverpoint tr.obs_pram_wr { bins off = {0}; bins on = {1}; }
        cp_spr_wr : coverpoint tr.obs_spr_wr  { bins off = {0}; bins on = {1}; }
        cp_inc    : coverpoint tr.obs_inc_addr { bins off = {0}; bins on = {1}; }

        cp_sidefx: cross cp_vram_wr, cp_pram_wr, cp_spr_wr, cp_inc;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_slave = new();
    endfunction

    virtual function void write(ppu_ri_sequence_item t);
        this.tr = t;
        cg_slave.sample();
        `uvm_info("PPU_RI_TLM_SLV",
            $sformatf("TLM[SLAVE] vram_a=%04h vram_wr=%b pram_wr=%b oam_a=%02h oam_wr=%b inc_addr=%b upd_cntrs=%b",
                t.obs_vram_a, t.obs_vram_wr, t.obs_pram_wr,
                t.obs_spr_a,  t.obs_spr_wr, t.obs_inc_addr, t.obs_upd_cntrs), UVM_HIGH)
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PPU_RI_COV",
            $sformatf("SLAVE coverage = %0.2f%%", cg_slave.get_inst_coverage()), UVM_NONE)
    endfunction

endclass

`endif
