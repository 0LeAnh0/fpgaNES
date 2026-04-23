`ifndef PPU_BG_SEQUENCE_ITEM_SV
`define PPU_BG_SEQUENCE_ITEM_SV

class ppu_bg_sequence_item extends uvm_sequence_item;
  rand logic        en_in;
  rand logic        rst_in;
  rand logic        ls_clip_in;
  rand logic [ 2:0] fv_in;
  rand logic [ 4:0] vt_in;
  rand logic        v_in;
  rand logic [ 2:0] fh_in;
  rand logic [ 4:0] ht_in;
  rand logic        h_in;
  rand logic        s_in;
  rand logic [ 9:0] nes_x_in;
  rand logic [ 9:0] nes_y_in;
  rand logic [ 9:0] nes_y_next_in;
  rand logic        pix_pulse_in;
  rand logic [ 7:0] vram_d_in;
  rand logic        ri_upd_cntrs_in;
  rand logic        ri_inc_addr_in;
  rand logic        ri_inc_addr_amt_in;

  logic [13:0] vram_a_out;
  logic [ 3:0] palette_idx_out;

  `uvm_object_utils_begin(ppu_bg_sequence_item)
    `uvm_field_int(en_in, UVM_ALL_ON)
    `uvm_field_int(rst_in, UVM_ALL_ON)
    `uvm_field_int(ls_clip_in, UVM_ALL_ON)
    `uvm_field_int(fv_in, UVM_ALL_ON)
    `uvm_field_int(vt_in, UVM_ALL_ON)
    `uvm_field_int(v_in, UVM_ALL_ON)
    `uvm_field_int(fh_in, UVM_ALL_ON)
    `uvm_field_int(ht_in, UVM_ALL_ON)
    `uvm_field_int(h_in, UVM_ALL_ON)
    `uvm_field_int(s_in, UVM_ALL_ON)
    `uvm_field_int(nes_x_in, UVM_ALL_ON)
    `uvm_field_int(nes_y_in, UVM_ALL_ON)
    `uvm_field_int(nes_y_next_in, UVM_ALL_ON)
    `uvm_field_int(pix_pulse_in, UVM_ALL_ON)
    `uvm_field_int(vram_d_in, UVM_ALL_ON)
    `uvm_field_int(ri_upd_cntrs_in, UVM_ALL_ON)
    `uvm_field_int(ri_inc_addr_in, UVM_ALL_ON)
    `uvm_field_int(ri_inc_addr_amt_in, UVM_ALL_ON)
    `uvm_field_int(vram_a_out, UVM_ALL_ON)
    `uvm_field_int(palette_idx_out, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ppu_bg_sequence_item");
    super.new(name);
    en_in              = 1'b0;
    rst_in             = 1'b0;
    ls_clip_in         = 1'b0;
    fv_in              = 3'h0;
    vt_in              = 5'h00;
    v_in               = 1'b0;
    fh_in              = 3'h0;
    ht_in              = 5'h00;
    h_in               = 1'b0;
    s_in               = 1'b0;
    nes_x_in           = 10'h000;
    nes_y_in           = 10'h000;
    nes_y_next_in      = 10'h000;
    pix_pulse_in       = 1'b0;
    vram_d_in          = 8'h00;
    ri_upd_cntrs_in    = 1'b0;
    ri_inc_addr_in     = 1'b0;
    ri_inc_addr_amt_in = 1'b0;
    vram_a_out         = 14'h0000;
    palette_idx_out    = 4'h0;
  endfunction

endclass

`endif
