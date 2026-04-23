`ifndef PPU_SPR_MASTER_DRIVER_SV
`define PPU_SPR_MASTER_DRIVER_SV

class ppu_spr_master_driver extends uvm_driver #(ppu_spr_sequence_item);
  `uvm_component_utils(ppu_spr_master_driver)

  virtual ppu_spr_if.MASTER vif;

  function new(string name = "ppu_spr_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_spr_if.MASTER)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Initialize
    @(vif.spr_cb);
    vif.spr_cb.en_in         <= 0;
    vif.spr_cb.ls_clip_in    <= 0;
    vif.spr_cb.spr_h_in      <= 0;
    vif.spr_cb.spr_pt_sel_in <= 0;
    vif.spr_cb.oam_a_in      <= 0;
    vif.spr_cb.oam_d_in      <= 0;
    vif.spr_cb.oam_wr_in     <= 0;
    vif.spr_cb.nes_x_in      <= 0;
    vif.spr_cb.nes_y_in      <= 0;
    vif.spr_cb.nes_y_next_in <= 0;
    vif.spr_cb.pix_pulse_in  <= 0;
    vif.spr_cb.vram_d_in     <= 0;
    
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(ppu_spr_sequence_item item);
    // Drive inputs
    vif.spr_cb.en_in         <= item.en_in;
    vif.spr_cb.ls_clip_in    <= item.ls_clip_in;
    vif.spr_cb.spr_h_in      <= item.spr_h_in;
    vif.spr_cb.spr_pt_sel_in <= item.spr_pt_sel_in;
    vif.spr_cb.oam_a_in      <= item.oam_a_in;
    vif.spr_cb.oam_d_in      <= item.oam_d_in;
    vif.spr_cb.oam_wr_in     <= item.oam_wr_in;
    vif.spr_cb.nes_x_in      <= item.nes_x_in;
    vif.spr_cb.nes_y_in      <= item.nes_y_in;
    vif.spr_cb.nes_y_next_in <= item.nes_y_next_in;
    vif.spr_cb.pix_pulse_in  <= item.pix_pulse_in;
    vif.spr_cb.vram_d_in     <= item.vram_d_in;
    // Wait for the clock edge to register the signals
    @(vif.spr_cb);
    // De-assert write enable after the write cycle
    vif.spr_cb.oam_wr_in     <= 0;
  endtask

endclass

`endif
