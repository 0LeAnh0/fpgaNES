`ifndef PPU_VGA_COV_SV
`define PPU_VGA_COV_SV

class ppu_vga_cov extends uvm_component;
  `uvm_component_utils(ppu_vga_cov)

  uvm_analysis_imp #(ppu_vga_sequence_item, ppu_vga_cov) analysis_export;

  int unsigned sample_area;
  bit [5:0]    sample_palette;
  bit          sample_vblank;
  bit          sample_pix_pulse;
  bit          sample_set_evt;
  bit          sample_clear_evt;

  covergroup cg_vga;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "ppu_vga_coverage";

    cp_area: coverpoint sample_area {
      bins blank_region  = {0};
      bins top_border    = {1};
      bins visible_area  = {2};
      bins right_border  = {3};
      bins bottom_border = {4};
    }

    cp_palette_visible: coverpoint sample_palette iff (sample_area == 2) {
      bins all_idx[] = {[0:63]};
    }

    cp_vblank: coverpoint sample_vblank {
      bins inactive = {0};
      bins active   = {1};
    }

    cp_pix_pulse: coverpoint sample_pix_pulse {
      bins low  = {0};
      bins high = {1};
    }

    cp_vblank_set_evt: coverpoint sample_set_evt {
      bins hit = {1};
    }

    cp_vblank_clear_evt: coverpoint sample_clear_evt {
      bins hit = {1};
    }

    cross_area_palette: cross cp_area, cp_palette_visible {
      ignore_bins non_visible_palette =
        (binsof(cp_area.blank_region)  ||
         binsof(cp_area.top_border)    ||
         binsof(cp_area.right_border)  ||
         binsof(cp_area.bottom_border)) && binsof(cp_palette_visible);
    }
  endgroup

  function new(string name = "ppu_vga_cov", uvm_component parent = null);
    super.new(name, parent);
    cg_vga = new();
    analysis_export = new("analysis_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_vga.set_inst_name({get_full_name(), ".cg_vga"});
  endfunction

  protected function int unsigned classify_area(ppu_vga_sequence_item t);
    if (!t.sync_en)
      return 0;
    if (t.nes_y_out < 10'd8)
      return 1;
    if (t.nes_y_out >= 10'd232)
      return 4;
    if (t.nes_x_out >= 10'd256)
      return 3;
    return 2;
  endfunction

  virtual function void write(ppu_vga_sequence_item t);
    sample_area      = classify_area(t);
    sample_palette   = t.sys_palette_idx_in;
    sample_vblank    = t.vblank_out;
    sample_pix_pulse = t.pix_pulse_out;
    sample_set_evt   = ((t.sync_x == 10'd730) && (t.sync_y == 10'd477));
    sample_clear_evt = ((t.sync_x == 10'd64) && (t.sync_y == 10'd519));
    cg_vga.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("VGA_COV", $sformatf("Overall VGA Coverage = %0.2f%%", cg_vga.get_inst_coverage()), UVM_NONE)
  endfunction

endclass

`endif
