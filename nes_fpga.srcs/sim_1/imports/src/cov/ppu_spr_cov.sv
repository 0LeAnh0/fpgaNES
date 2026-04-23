`ifndef PPU_SPR_COV_SV
`define PPU_SPR_COV_SV

class ppu_spr_cov extends uvm_component;
  `uvm_component_utils(ppu_spr_cov)

  uvm_analysis_imp #(ppu_spr_sequence_item, ppu_spr_cov) analysis_export;

  bit        sample_en;
  bit        sample_h_mode;
  bit        sample_pt_sel;
  bit        sample_clip;
  bit [8:0]  sample_x;
  bit [8:0]  sample_y;
  bit [7:0]  sample_oam_a;
  bit        sample_primary;
  bit        sample_prio;
  bit        sample_overflow;

  covergroup cg_spr;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "ppu_spr_coverage";

    cp_en:      coverpoint sample_en;
    cp_h_mode:  coverpoint sample_h_mode {
      bins size_8x8  = {0};
      bins size_8x16 = {1};
    }
    cp_pt_sel:  coverpoint sample_pt_sel;
    cp_clip:    coverpoint sample_clip {
       bins clipping_on = {0};
       bins clipping_off = {1};
    }
    
    // Coordinates
    cp_x: coverpoint sample_x {
      bins left_edge  = {0};
      bins right_edge = {255};
      bins visible    = {[1:254]};
      bins hblank     = {[256:340]}; // Replaced off_screen to match NES timing
    }
    cp_y: coverpoint sample_y {
      bins top_edge    = {0};
      bins bottom_edge = {239};
      bins visible     = {[1:238]};
      bins post_render = {240};
      bins vblank      = {[241:260]};
      bins pre_render  = {261};
    }

    cp_oam_a:   coverpoint sample_oam_a {
      bins sprite_0    = {[0:3]};
      bins sprite_1_15 = {[4:63]};
      bins sprite_mid  = {[64:191]};
      bins sprite_last = {[252:255]};
    }
    
    cp_primary: coverpoint sample_primary;
    cp_prio:    coverpoint sample_prio;
    cp_overflow: coverpoint sample_overflow;

    // Meaningful crosses (Avoid impossible architectural states)
    cross_size_overflow: cross cp_h_mode, cp_overflow;
    cross_pos:           cross cp_x, cp_y;
    cross_hit_type:      cross cp_primary, cp_h_mode;
    cross_priority_hit:  cross cp_prio, cp_primary;
  endgroup

  function new(string name = "ppu_spr_cov", uvm_component parent = null);
    super.new(name, parent);
    cg_spr = new();
    analysis_export = new("analysis_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_spr.set_inst_name({get_full_name(), ".cg_spr"});
  endfunction

  virtual function void write(ppu_spr_sequence_item t);
    sample_en       = t.en_in;
    sample_h_mode   = t.spr_h_in;
    sample_pt_sel   = t.spr_pt_sel_in;
    sample_clip     = t.ls_clip_in;
    sample_x        = t.nes_x_in;
    sample_y        = t.nes_y_in;
    sample_oam_a    = t.oam_a_in;
    sample_primary  = t.primary_out;
    sample_prio     = t.priority_out;
    sample_overflow = t.overflow_out;
    cg_spr.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SPR_COV", $sformatf("Overall Sprite Coverage = %0.2f%%", cg_spr.get_inst_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_en Coverage = %0.2f%%", cg_spr.cp_en.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_h_mode Coverage = %0.2f%%", cg_spr.cp_h_mode.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_pt_sel Coverage = %0.2f%%", cg_spr.cp_pt_sel.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_clip Coverage = %0.2f%%", cg_spr.cp_clip.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_x Coverage = %0.2f%%", cg_spr.cp_x.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_y Coverage = %0.2f%%", cg_spr.cp_y.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_oam_a Coverage = %0.2f%%", cg_spr.cp_oam_a.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_primary Coverage = %0.2f%%", cg_spr.cp_primary.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_prio Coverage = %0.2f%%", cg_spr.cp_prio.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cp_overflow Coverage = %0.2f%%", cg_spr.cp_overflow.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cross_size_overflow Coverage = %0.2f%%", cg_spr.cross_size_overflow.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cross_pos Coverage = %0.2f%%", cg_spr.cross_pos.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cross_hit_type Coverage = %0.2f%%", cg_spr.cross_hit_type.get_coverage()), UVM_NONE)
    `uvm_info("SPR_COV", $sformatf("  cross_priority_hit Coverage = %0.2f%%", cg_spr.cross_priority_hit.get_coverage()), UVM_NONE)
  endfunction

endclass

`endif
