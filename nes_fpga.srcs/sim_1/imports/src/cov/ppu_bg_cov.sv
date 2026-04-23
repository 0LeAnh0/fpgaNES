`ifndef PPU_BG_COV_SV
`define PPU_BG_COV_SV

class ppu_bg_cov extends uvm_component;
  `uvm_component_utils(ppu_bg_cov)

  uvm_analysis_imp #(ppu_bg_sequence_item, ppu_bg_cov) analysis_export;

  bit        sample_en;
  bit [8:0]  sample_x;
  bit [8:0]  sample_y;
  bit [2:0]  sample_fh;
  bit [2:0]  sample_fv;
  bit [4:0]  sample_ht;
  bit [4:0]  sample_vt;
  bit [1:0]  sample_nt;
  bit        sample_s;
  bit [3:0]  sample_palette_idx;
  bit        sample_clip;

  covergroup cg_bg;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "ppu_bg_coverage";

    cp_en: coverpoint sample_en;
    
    // Coordinates
    cp_x:  coverpoint sample_x {
      bins visible   = {[0:255]};
      bins fetch     = {[256:319]};
      bins hblank    = {[320:340]};
    }
    cp_y:  coverpoint sample_y {
      bins visible   = {[0:239]};
      bins vblank    = {[240:260]};
      bins pre_render = {261};
    }

    // Scroll Logic
    cp_fine_scroll_x: coverpoint sample_fh {
      bins values[] = {[0:7]};
    }
    cp_fine_scroll_y: coverpoint sample_fv {
      bins values[] = {[0:7]};
    }
    cp_coarse_scroll_x: coverpoint sample_ht {
      bins min = {0};
      bins mid = {[1:30]};
      bins max = {31};
    }
    cp_coarse_scroll_y: coverpoint sample_vt {
      bins min = {0};
      bins mid = {[1:28]};
      bins max = {29}; // Standard NES attributes go up to 29
    }

    // Nametable Selection
    cp_nt_select: coverpoint sample_nt {
      bins nt_0 = {2'b00};
      bins nt_1 = {2'b01};
      bins nt_2 = {2'b10};
      bins nt_3 = {2'b11};
    }
    
    // Pattern Table Selection
    cp_s_in: coverpoint sample_s;

    // Output palette activity
    cp_palette_idx: coverpoint sample_palette_idx {
      bins transparent = {4'h0};
      bins non_zero[]  = {[4'h1:4'hF]};
    }

    cp_clip: coverpoint sample_clip {
      bins clip_on  = {1'b1};
      bins clip_off = {1'b0};
    }

    // Crosses
    cross_pos_en: cross cp_x, cp_y, cp_en;
    cross_nt_scroll: cross cp_nt_select, cp_s_in;
    cross_clip_palette: cross cp_clip, cp_palette_idx {
      ignore_bins clipped_non_zero =
        binsof(cp_clip.clip_on) && binsof(cp_palette_idx.non_zero);
    }
  endgroup

  function new(string name = "ppu_bg_cov", uvm_component parent = null);
    super.new(name, parent);
    cg_bg = new();
    analysis_export = new("analysis_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_bg.set_inst_name({get_full_name(), ".cg_bg"});
  endfunction

  virtual function void write(ppu_bg_sequence_item t);
    sample_en          = t.en_in;
    sample_x           = t.nes_x_in;
    sample_y           = t.nes_y_in;
    sample_fh          = t.fh_in;
    sample_fv          = t.fv_in;
    sample_ht          = t.ht_in;
    sample_vt          = t.vt_in;
    sample_nt          = {t.v_in, t.h_in};
    sample_s           = t.s_in;
    sample_palette_idx = t.palette_idx_out;
    sample_clip        = t.ls_clip_in;
    cg_bg.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("BG_COV", $sformatf("Overall Background Coverage = %0.2f%%", cg_bg.get_inst_coverage()), UVM_NONE)
  endfunction

endclass

`endif
