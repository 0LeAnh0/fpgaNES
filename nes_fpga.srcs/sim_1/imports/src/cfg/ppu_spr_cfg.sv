`ifndef PPU_SPR_CFG_SV
`define PPU_SPR_CFG_SV

class ppu_spr_cfg extends uvm_object;
  `uvm_object_utils(ppu_spr_cfg)

  bit is_active = 1;

  function new(string name = "ppu_spr_cfg");
    super.new(name);
  endfunction

endclass

`endif
