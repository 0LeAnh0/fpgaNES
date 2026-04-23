`ifndef PPU_TOP_COV_SV
`define PPU_TOP_COV_SV

class ppu_top_cov extends uvm_component;
  `uvm_component_utils(ppu_top_cov)

  uvm_analysis_imp #(ppu_top_sequence_item, ppu_top_cov) analysis_export;

  int unsigned arbiter_src;
  bit          sample_pram_wr;
  bit          sample_vblank;
  int unsigned sample_mux_src;
  bit [2:0]    sample_nvbl_gate_state;
  bit          sample_spr_overflow;

  covergroup cg_top;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "ppu_top_integration_coverage";

    cp_arbiter_src: coverpoint arbiter_src {
      bins bg  = {0};
      bins spr = {1};
    }

    cp_pram_wr: coverpoint sample_pram_wr {
      bins idle  = {0};
      bins write = {1};
    }

    cp_vblank: coverpoint sample_vblank {
      bins low  = {0};
      bins high = {1};
    }

    cp_nvbl_gate_state: coverpoint sample_nvbl_gate_state {
      bins no_vblank_nmi0 = {3'b001};
      bins no_vblank_nmi1 = {3'b011};
      bins masked_vblank  = {3'b101};
      bins gated_vblank   = {3'b110};
    }

    cp_mux_src: coverpoint sample_mux_src {
      bins universal = {0};
      bins bg        = {1};
      bins spr       = {2};
    }

    cp_spr_overflow: coverpoint sample_spr_overflow {
      bins not_seen = {0};
      bins seen     = {1};
    }

    cross_arb_vblank: cross cp_arbiter_src, cp_vblank;
    cross_gate_vblank: cross cp_nvbl_gate_state, cp_pram_wr;
    cross_arb_overflow: cross cp_arbiter_src, cp_spr_overflow;
  endgroup

  function new(string name = "ppu_top_cov", uvm_component parent = null);
    super.new(name, parent);
    cg_top = new();
    analysis_export = new("analysis_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_top.set_inst_name({get_full_name(), ".cg_top"});
  endfunction

  virtual function void write(ppu_top_sequence_item t);
    bit spr_trans;
    bit bg_trans;
    bit spr_foreground;

    spr_trans      = ~|t.spr_palette_idx[1:0];
    bg_trans       = ~|t.bg_palette_idx[1:0];
    spr_foreground = ~t.spr_priority;

    arbiter_src    = t.spr_vram_req ? 1 : 0;
    sample_pram_wr = t.ri_pram_wr;
    sample_vblank  = t.ri_vblank;
    sample_nvbl_gate_state = {t.ri_vblank, t.ri_nvbl_en, t.nvbl_out};
    sample_spr_overflow = t.spr_overflow;
    if (((spr_foreground || bg_trans) && !spr_trans))
      sample_mux_src = 2;
    else if (!bg_trans)
      sample_mux_src = 1;
    else
      sample_mux_src = 0;
    cg_top.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("PPU_TOP_COV", $sformatf("Overall PPU Integration Coverage = %0.2f%%", cg_top.get_inst_coverage()), UVM_NONE)
  endfunction
endclass

`endif
