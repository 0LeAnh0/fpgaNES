`ifndef PPU_SPR_SEQUENCER_SV
`define PPU_SPR_SEQUENCER_SV

class ppu_spr_sequencer extends uvm_sequencer #(ppu_spr_sequence_item);
  `uvm_component_utils(ppu_spr_sequencer)

  function new(string name = "ppu_spr_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif
