`ifndef PPU_SPR_MASTER_MONITOR_SV
`define PPU_SPR_MASTER_MONITOR_SV

class ppu_spr_master_monitor extends uvm_monitor;
  `uvm_component_utils(ppu_spr_master_monitor)

  virtual ppu_spr_if.MONITOR vif;
  uvm_analysis_port #(ppu_spr_sequence_item) item_collected_port;

  function new(string name = "ppu_spr_master_monitor", uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_spr_if.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_spr_sequence_item item;
    forever begin
      @(vif.mon_cb);
      item = ppu_spr_sequence_item::type_id::create("item");
      
      // Sample inputs
      item.en_in         = vif.mon_cb.en_in;
      item.ls_clip_in    = vif.mon_cb.ls_clip_in;
      item.spr_h_in      = vif.mon_cb.spr_h_in;
      item.spr_pt_sel_in = vif.mon_cb.spr_pt_sel_in;
      item.oam_a_in      = vif.mon_cb.oam_a_in;
      item.oam_d_in      = vif.mon_cb.oam_d_in;
      item.oam_wr_in     = vif.mon_cb.oam_wr_in;
      item.nes_x_in      = vif.mon_cb.nes_x_in;
      item.nes_y_in      = vif.mon_cb.nes_y_in;
      item.nes_y_next_in = vif.mon_cb.nes_y_next_in;
      item.pix_pulse_in  = vif.mon_cb.pix_pulse_in;
      item.vram_d_in     = vif.mon_cb.vram_d_in;
      item.rst_in        = vif.mon_cb.rst_in;

      // Sample outputs
      item.oam_d_out       = vif.mon_cb.oam_d_out;
      item.overflow_out    = vif.mon_cb.overflow_out;
      item.palette_idx_out = vif.mon_cb.palette_idx_out;
      item.primary_out     = vif.mon_cb.primary_out;
      item.priority_out    = vif.mon_cb.priority_out;
      item.vram_a_out      = vif.mon_cb.vram_a_out;
      item.vram_req_out    = vif.mon_cb.vram_req_out;

      item_collected_port.write(item);
    end
  endtask

endclass

`endif
