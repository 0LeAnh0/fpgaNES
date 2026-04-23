`ifndef PPU_VGA_CFG_SV
`define PPU_VGA_CFG_SV

class ppu_vga_cfg extends uvm_object;
  `uvm_object_utils(ppu_vga_cfg)

  bit is_active = 1;

  function new(string name = "ppu_vga_cfg");
    super.new(name);
  endfunction

endclass

`endif
