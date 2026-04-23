`ifndef PPU_BG_MASTER_MONITOR_SV
`define PPU_BG_MASTER_MONITOR_SV

class ppu_bg_master_monitor extends uvm_monitor;
  `uvm_component_utils(ppu_bg_master_monitor)

  virtual ppu_bg_if.MONITOR vif;
  uvm_analysis_port #(ppu_bg_sequence_item) item_collected_port;

  function new(string name = "ppu_bg_master_monitor", uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_bg_if.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_sequence_item item;

    forever begin
      @(vif.mon_cb);
      item = ppu_bg_sequence_item::type_id::create("item");
      item.en_in            = vif.mon_cb.en_in;
      item.rst_in           = vif.mon_cb.rst_in;
      item.ls_clip_in       = vif.mon_cb.ls_clip_in;
      item.fv_in            = vif.mon_cb.fv_in;
      item.vt_in            = vif.mon_cb.vt_in;
      item.v_in             = vif.mon_cb.v_in;
      item.fh_in            = vif.mon_cb.fh_in;
      item.ht_in            = vif.mon_cb.ht_in;
      item.h_in             = vif.mon_cb.h_in;
      item.s_in             = vif.mon_cb.s_in;
      item.nes_x_in         = vif.mon_cb.nes_x_in;
      item.nes_y_in         = vif.mon_cb.nes_y_in;
      item.nes_y_next_in    = vif.mon_cb.nes_y_next_in;
      item.pix_pulse_in     = vif.mon_cb.pix_pulse_in;
      item.vram_d_in        = vif.mon_cb.vram_d_in;
      item.ri_upd_cntrs_in  = vif.mon_cb.ri_upd_cntrs_in;
      item.ri_inc_addr_in   = vif.mon_cb.ri_inc_addr_in;
      item.ri_inc_addr_amt_in = vif.mon_cb.ri_inc_addr_amt_in;
      item.vram_a_out       = vif.mon_cb.vram_a_out;
      item.palette_idx_out  = vif.mon_cb.palette_idx_out;

      item_collected_port.write(item);
    end
  endtask

endclass

`endif
