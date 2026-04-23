`ifndef PPU_TOP_SEQUENCE_ITEM_SV
`define PPU_TOP_SEQUENCE_ITEM_SV

class ppu_top_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(ppu_top_sequence_item)

  bit        rst_in;
  bit [7:0]  ri_d_out;
  bit        nvbl_out;
  bit [13:0] vram_a_out;
  bit [7:0]  vram_d_out;
  bit        vram_wr_out;

  bit [13:0] bg_vram_a;
  bit [3:0]  bg_palette_idx;
  bit [13:0] spr_vram_a;
  bit        spr_vram_req;
  bit [3:0]  spr_palette_idx;
  bit        spr_primary;
  bit        spr_priority;
  bit        spr_overflow;

  bit [5:0]  vga_sys_palette_idx;
  bit        ri_pram_wr;
  bit [7:0]  ri_vram_dout;
  bit        ri_vblank;
  bit        ri_nvbl_en;

  function new(string name = "ppu_top_sequence_item");
    super.new(name);
  endfunction
endclass

`endif
