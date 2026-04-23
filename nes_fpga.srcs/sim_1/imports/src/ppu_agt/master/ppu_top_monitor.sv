`ifndef PPU_TOP_MONITOR_SV
`define PPU_TOP_MONITOR_SV

class ppu_top_monitor extends uvm_monitor;
  `uvm_component_utils(ppu_top_monitor)

  virtual ppu_top_if.MONITOR vif;
  uvm_analysis_port #(ppu_top_sequence_item) ap;

  function new(string name = "ppu_top_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_top_if.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("ppu_top_if.MONITOR not found for %s", get_full_name()))
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_top_sequence_item item;
    forever begin
      @(vif.mon_cb);
      item = ppu_top_sequence_item::type_id::create("item");
      item.rst_in             = vif.mon_cb.rst_in;
      item.ri_d_out           = vif.mon_cb.ri_d_out;
      item.nvbl_out           = vif.mon_cb.nvbl_out;
      item.vram_a_out         = vif.mon_cb.vram_a_out;
      item.vram_d_out         = vif.mon_cb.vram_d_out;
      item.vram_wr_out        = vif.mon_cb.vram_wr_out;
      item.bg_vram_a          = vif.mon_cb.bg_vram_a;
      item.bg_palette_idx     = vif.mon_cb.bg_palette_idx;
      item.spr_vram_a         = vif.mon_cb.spr_vram_a;
      item.spr_vram_req       = vif.mon_cb.spr_vram_req;
      item.spr_palette_idx    = vif.mon_cb.spr_palette_idx;
      item.spr_primary        = vif.mon_cb.spr_primary;
      item.spr_priority       = vif.mon_cb.spr_priority;
      item.spr_overflow       = vif.mon_cb.spr_overflow;
      item.vga_sys_palette_idx = vif.mon_cb.vga_sys_palette_idx;
      item.ri_pram_wr         = vif.mon_cb.ri_pram_wr;
      item.ri_vram_dout       = vif.mon_cb.ri_vram_dout;
      item.ri_vblank          = vif.mon_cb.ri_vblank;
      item.ri_nvbl_en         = vif.mon_cb.ri_nvbl_en;
      ap.write(item);
    end
  endtask

endclass

`endif
