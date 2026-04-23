`ifndef PPU_BG_MASTER_DRIVER_SV
`define PPU_BG_MASTER_DRIVER_SV

class ppu_bg_master_driver extends uvm_driver #(ppu_bg_sequence_item);
  `uvm_component_utils(ppu_bg_master_driver)

  virtual ppu_bg_if.MASTER vif;

  function new(string name = "ppu_bg_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_bg_if.MASTER)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Initialize
    @(vif.bg_cb);
    vif.bg_cb.en_in <= 0;
    vif.bg_cb.ls_clip_in <= 0;
    vif.bg_cb.fv_in <= 0;
    vif.bg_cb.vt_in <= 0;
    vif.bg_cb.v_in <= 0;
    vif.bg_cb.fh_in <= 0;
    vif.bg_cb.ht_in <= 0;
    vif.bg_cb.h_in <= 0;
    vif.bg_cb.s_in <= 0;
    vif.bg_cb.nes_x_in <= 0;
    vif.bg_cb.nes_y_in <= 0;
    vif.bg_cb.nes_y_next_in <= 0;
    vif.bg_cb.pix_pulse_in <= 0;
    vif.bg_cb.vram_d_in <= 0;
    vif.bg_cb.ri_upd_cntrs_in <= 0;
    vif.bg_cb.ri_inc_addr_in <= 0;
    vif.bg_cb.ri_inc_addr_amt_in <= 0;
    
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(ppu_bg_sequence_item item);
    @(vif.bg_cb);
    vif.bg_cb.en_in <= item.en_in;
    vif.bg_cb.ls_clip_in <= item.ls_clip_in;
    vif.bg_cb.fv_in <= item.fv_in;
    vif.bg_cb.vt_in <= item.vt_in;
    vif.bg_cb.v_in <= item.v_in;
    vif.bg_cb.fh_in <= item.fh_in;
    vif.bg_cb.ht_in <= item.ht_in;
    vif.bg_cb.h_in <= item.h_in;
    vif.bg_cb.s_in <= item.s_in;
    vif.bg_cb.nes_x_in <= item.nes_x_in;
    vif.bg_cb.nes_y_in <= item.nes_y_in;
    vif.bg_cb.nes_y_next_in <= item.nes_y_next_in;
    vif.bg_cb.pix_pulse_in <= item.pix_pulse_in;
    vif.bg_cb.vram_d_in <= item.vram_d_in;
    vif.bg_cb.ri_upd_cntrs_in <= item.ri_upd_cntrs_in;
    vif.bg_cb.ri_inc_addr_in <= item.ri_inc_addr_in;
    vif.bg_cb.ri_inc_addr_amt_in <= item.ri_inc_addr_amt_in;
  endtask

endclass

`endif
