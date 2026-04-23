`ifndef PPU_VGA_SEQUENCE_ITEM_SV
`define PPU_VGA_SEQUENCE_ITEM_SV

class ppu_vga_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(ppu_vga_sequence_item)

  rand bit [5:0] sys_palette_idx_in;

  bit       rst_in;
  bit       hsync_out;
  bit       vsync_out;
  bit [2:0] r_out;
  bit [2:0] g_out;
  bit [1:0] b_out;
  bit [9:0] nes_x_out;
  bit [9:0] nes_y_out;
  bit [9:0] nes_y_next_out;
  bit       pix_pulse_out;
  bit       vblank_out;
  bit       sync_en;
  bit [9:0] sync_x;
  bit [9:0] sync_y;
  bit [9:0] sync_x_next;
  bit [9:0] sync_y_next;

  function new(string name = "ppu_vga_sequence_item");
    super.new(name);
    sys_palette_idx_in = 6'h00;
    rst_in             = 1'b0;
    hsync_out          = 1'b0;
    vsync_out          = 1'b0;
    r_out              = 3'h0;
    g_out              = 3'h0;
    b_out              = 2'h0;
    nes_x_out          = 10'h000;
    nes_y_out          = 10'h000;
    nes_y_next_out     = 10'h000;
    pix_pulse_out      = 1'b0;
    vblank_out         = 1'b0;
    sync_en            = 1'b0;
    sync_x             = 10'h000;
    sync_y             = 10'h000;
    sync_x_next        = 10'h000;
    sync_y_next        = 10'h000;
  endfunction

  virtual function string convert2string();
    return $sformatf(
      "pal=%02h rgb=%01h%01h%01h x=%0d y=%0d y_next=%0d sync=(%0d,%0d)->(%0d,%0d) hs=%0b vs=%0b pix=%0b vb=%0b rst=%0b",
      sys_palette_idx_in, r_out, g_out, b_out, nes_x_out, nes_y_out, nes_y_next_out,
      sync_x, sync_y, sync_x_next, sync_y_next, hsync_out, vsync_out, pix_pulse_out, vblank_out, rst_in);
  endfunction

endclass

`endif
