`ifndef PPU_TOP_CFG_SV
`define PPU_TOP_CFG_SV

class ppu_top_cfg extends uvm_object;
  `uvm_object_utils(ppu_top_cfg)

  bit is_active = 0;

  function new(string name = "ppu_top_cfg");
    super.new(name);
  endfunction
endclass

`endif
