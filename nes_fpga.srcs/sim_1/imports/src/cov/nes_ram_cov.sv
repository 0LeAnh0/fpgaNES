`ifndef NES_RAM_COV_SV
`define NES_RAM_COV_SV

class nes_ram_cov extends uvm_component;
  `uvm_component_utils(nes_ram_cov)

  uvm_analysis_imp #(nes_ram_item, nes_ram_cov) analysis_export;

  bit         sample_is_vram;
  bit         sample_r_nw;
  bit [15:0]  sample_addr;

  covergroup cg_wram;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "nes_wram_access_coverage";

    cp_wram_addr: coverpoint sample_addr iff (!sample_is_vram) {
      // WRAM base page and mirrored aliases
      bins b_wram0 = {[16'h0000:16'h07FF]};
      bins b_wram1 = {[16'h0800:16'h0FFF]};
      bins b_wram2 = {[16'h1000:16'h17FF]};
      bins b_wram3 = {[16'h1800:16'h1FFF]};
      bins b_zero_page = {[16'h0000:16'h00FF]};
      bins b_stack     = {[16'h0100:16'h01FF]};
      bins b_edges[]   = {16'h0000, 16'h07FF, 16'h0800, 16'h0FFF, 16'h1000, 16'h17FF, 16'h1800, 16'h1FFF};
    }
    
    cp_wram_r_nw: coverpoint sample_r_nw iff (!sample_is_vram) {
      bins rd = {1};
      bins wr = {0};
    }
    
    cross_wram_addr_op: cross cp_wram_addr, cp_wram_r_nw;
  endgroup

  covergroup cg_vram;
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;
    option.name = "nes_vram_access_coverage";

    cp_vram_addr: coverpoint sample_addr iff (sample_is_vram) {
      bins b_phys0 = {[16'h0000:16'h07FF]};
      bins b_phys1 = {[16'h0800:16'h0FFF]};
      bins b_phys2 = {[16'h1000:16'h17FF]};
      bins b_phys3 = {[16'h1800:16'h1FFF]};
      bins b_edges[] = {16'h0000, 16'h07FF, 16'h0800, 16'h0FFF, 16'h1000, 16'h17FF, 16'h1800, 16'h1FFF};
      bins b_low_quadrant  = {[16'h0000:16'h01FF]};
      bins b_mid_quadrant  = {[16'h0200:16'h05FF]};
      bins b_high_quadrant = {[16'h0600:16'h07FF]};
    }

    cp_vram_r_nw: coverpoint sample_r_nw iff (sample_is_vram) {
      bins rd = {1};
      bins wr = {0};
    }

    cross_vram_addr_op: cross cp_vram_addr, cp_vram_r_nw;
  endgroup

  function new(string name = "nes_ram_cov", uvm_component parent = null);
    super.new(name, parent);
    cg_wram = new();
    cg_vram = new();
    analysis_export = new("analysis_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg_wram.set_inst_name({get_full_name(), ".cg_wram"});
    cg_vram.set_inst_name({get_full_name(), ".cg_vram"});
  endfunction

  virtual function void write(nes_ram_item t);
    sample_is_vram = t.is_vram;
    sample_r_nw    = t.r_nw;
    sample_addr    = t.addr;
    if (sample_is_vram)
      cg_vram.sample();
    else
      cg_wram.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("RAM_COV", $sformatf("Overall RAM Coverage = %0.2f%%",
      (cg_wram.get_inst_coverage() + cg_vram.get_inst_coverage()) / 2.0), UVM_NONE)
    `uvm_info("RAM_COV", $sformatf("  WRAM Coverage = %0.2f%%", cg_wram.get_inst_coverage()), UVM_NONE)
    `uvm_info("RAM_COV", $sformatf("  VRAM Coverage = %0.2f%%", cg_vram.get_inst_coverage()), UVM_NONE)
  endfunction

endclass

`endif
