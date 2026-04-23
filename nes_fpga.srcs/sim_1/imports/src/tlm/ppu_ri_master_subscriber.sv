`ifndef PPU_RI_MASTER_SUBSCRIBER_SV
`define PPU_RI_MASTER_SUBSCRIBER_SV

// ===========================================================================
// ppu_ri_master_subscriber  (TLM Subscriber)
// Nam trong folder tlm/ — nhan transaction tu master_mon_ap cua agent.
// Chuc nang:
//   - Log tat ca transaction CPU-side o muc UVM_HIGH cho debug
//   - Co the mo rong them coverage group sau
// ===========================================================================
class ppu_ri_master_subscriber extends uvm_subscriber #(ppu_ri_sequence_item);
    `uvm_component_utils(ppu_ri_master_subscriber)

    // Bien tam cho covergroup sample.
    ppu_ri_sequence_item tr;

    // Functional coverage cho CPU-side access pattern.
    covergroup cg_master;
        option.per_instance = 1;

        cp_sel: coverpoint tr.sel {
            bins reg_all[] = {[0:7]};
        }
        cp_r_nw: coverpoint tr.r_nw {
            bins wr = {0};
            bins rd = {1};
        }
        cp_cross: cross cp_sel, cp_r_nw;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_master = new();
    endfunction

    virtual function void write(ppu_ri_sequence_item t);
        this.tr = t;
        cg_master.sample();
        if (t.r_nw == 1'b1) begin
            `uvm_info("PPU_RI_TLM_MST",
                $sformatf("TLM[MASTER] SEL=%0d ($200%0h) RD DIN=%02h DOUT=%02h | SCROLL fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d inc_amt=%0d",
                    t.sel, t.sel, t.data_in, t.data_out,
                    t.obs_fv, t.obs_vt, t.obs_v, t.obs_fh, t.obs_ht, t.obs_h, t.obs_s, t.obs_inc_addr_amt),
                UVM_HIGH)
        end else begin
            `uvm_info("PPU_RI_TLM_MST",
                $sformatf("TLM[MASTER] SEL=%0d ($200%0h) WR DIN=%02h | SCROLL fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d inc_amt=%0d",
                    t.sel, t.sel, t.data_in,
                    t.obs_fv, t.obs_vt, t.obs_v, t.obs_fh, t.obs_ht, t.obs_h, t.obs_s, t.obs_inc_addr_amt),
                UVM_HIGH)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PPU_RI_COV",
            $sformatf("MASTER coverage = %0.2f%%", cg_master.get_inst_coverage()), UVM_NONE)
    endfunction

endclass

`endif
