`ifndef PPU_SPR_SEQUENCE_ITEM_SV
`define PPU_SPR_SEQUENCE_ITEM_SV

class ppu_spr_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(ppu_spr_sequence_item)

  // Control Inputs
  rand bit        en_in;
  rand bit        ls_clip_in;
  rand bit        spr_h_in;
  rand bit        spr_pt_sel_in;
  
  // OAM Access
  rand bit [ 7:0] oam_a_in;
  rand bit [ 7:0] oam_d_in;
  rand bit        oam_wr_in;
  
  // Timing / Coordinates
  rand bit [ 9:0] nes_x_in;
  rand bit [ 9:0] nes_y_in;
  rand bit [ 9:0] nes_y_next_in;
  rand bit        pix_pulse_in;
  
  // Slave / External
  rand bit [ 7:0] vram_d_in;

  // Outputs (Captured by monitor)
  bit [ 7:0] oam_d_out;
  bit        overflow_out;
  bit [ 3:0] palette_idx_out;
  bit        primary_out;
  bit        priority_out; 
  bit [13:0] vram_a_out;
  bit        vram_req_out;

  // For reset observation
  bit        rst_in;

  function new(string name = "ppu_spr_sequence_item");
    super.new(name);
    en_in           = 1'b0;
    ls_clip_in      = 1'b0;
    spr_h_in        = 1'b0;
    spr_pt_sel_in   = 1'b0;
    oam_a_in        = 8'h00;
    oam_d_in        = 8'h00;
    oam_wr_in       = 1'b0;
    nes_x_in        = 10'h000;
    nes_y_in        = 10'h000;
    nes_y_next_in   = 10'h000;
    pix_pulse_in    = 1'b0;
    vram_d_in       = 8'h00;
    oam_d_out       = 8'h00;
    overflow_out    = 1'b0;
    palette_idx_out = 4'h0;
    primary_out     = 1'b0;
    priority_out    = 1'b0;
    vram_a_out      = 14'h0000;
    vram_req_out    = 1'b0;
    rst_in          = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("X=%0d Y=%0d Pix=%b OAM_A=%0h OAM_D_IN=%0h OAM_WR=%b VRAM_A=%0h REQ=%b PAL=%0h", 
                     nes_x_in, nes_y_in, pix_pulse_in, oam_a_in, oam_d_in, oam_wr_in, vram_a_out, vram_req_out, palette_idx_out);
  endfunction

endclass

`endif
