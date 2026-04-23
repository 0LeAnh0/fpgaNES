`ifndef PPU_BG_CFG_SV
`define PPU_BG_CFG_SV

class ppu_bg_cfg extends uvm_object;
  `uvm_object_utils(ppu_bg_cfg)

  bit is_active = 1;

  function new(string name = "ppu_bg_cfg");
    super.new(name);
  endfunction

endclass

`endif
