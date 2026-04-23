`ifndef PPU_RI_COV_SV
`define PPU_RI_COV_SV

class ppu_ri_cov extends uvm_component;
    `uvm_component_utils(ppu_ri_cov)

    uvm_analysis_imp #(ppu_ri_sequence_item, ppu_ri_cov) analysis_export;

    bit [2:0] sample_sel;
    bit       sample_r_nw;
    bit [7:0] sample_data_in;
    bit [7:0] sample_data_out;
    bit [2:0] last_sel;
    bit       last_r_nw;

    covergroup cg_master;
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;
        option.name = "ppu_ri_cpu_interface_coverage";

        // Register Selection
        cp_sel: coverpoint sample_sel {
            bins PPUCTRL   = {0};
            bins PPUMASK   = {1};
            bins PPUSTATUS  = {2};
            bins OAMADDR   = {3};
            bins OAMDATA   = {4};
            bins PPUSCROLL = {5};
            bins PPUADDR   = {6};
            bins PPUDATA   = {7};
        }

        // Operation type
        cp_r_nw: coverpoint sample_r_nw {
            bins wr = {0};
            bins rd = {1};
        }

        // --- PPUCTRL bits ($2000) ---
        cp_ctrl_nmi: coverpoint sample_data_in[7] iff (sample_sel == 0 && sample_r_nw == 0) {
            bins disabled = {0};
            bins enabled = {1};
        }
        cp_ctrl_spr_size: coverpoint sample_data_in[5] iff (sample_sel == 0 && sample_r_nw == 0) {
            bins size_8x8 = {0};
            bins size_8x16 = {1};
        }
        cp_ctrl_bg_pt: coverpoint sample_data_in[4] iff (sample_sel == 0 && sample_r_nw == 0) {
            bins table_0 = {0};
            bins table_1 = {1};
        }

        // --- PPUMASK bits ($2001) ---
        cp_mask_bg: coverpoint sample_data_in[3] iff (sample_sel == 1 && sample_r_nw == 0) {
            bins hidden = {0};
            bins shown = {1};
        }
        cp_mask_spr: coverpoint sample_data_in[4] iff (sample_sel == 1 && sample_r_nw == 0) {
            bins hidden = {0};
            bins shown = {1};
        }

        // --- PPUSTATUS bits ($2002) READ ---
        cp_status_vblank: coverpoint sample_data_out[7] iff (sample_sel == 2 && sample_r_nw == 1) {
            bins not_in_vblank = {0};
            bins in_vblank = {1};
        }

        // --- Sequence Coverage (Double write to $2005/$2006) ---
        cp_double_write: coverpoint sample_sel iff (sample_r_nw == 0 && last_r_nw == 0 && last_sel == sample_sel) {
            bins scroll_seq = {5};
            bins addr_seq   = {6};
        }

        cp_cross: cross cp_sel, cp_r_nw;
    endgroup

    function new(string name = "ppu_ri_cov", uvm_component parent = null);
        super.new(name, parent);
        cg_master = new();
        analysis_export = new("analysis_export", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cg_master.set_inst_name({get_full_name(), ".cg_master"});
    endfunction

    virtual function void write(ppu_ri_sequence_item t);
        sample_sel      = t.sel;
        sample_r_nw     = t.r_nw;
        sample_data_in  = t.data_in;
        sample_data_out = t.data_out;
        cg_master.sample();
        // Update history for sequence coverage
        last_sel  = sample_sel;
        last_r_nw = sample_r_nw;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PPU_RI_COV", $sformatf("Overall Register Coverage = %0.2f%%", cg_master.get_inst_coverage()), UVM_NONE)
    endfunction

endclass

`endif
