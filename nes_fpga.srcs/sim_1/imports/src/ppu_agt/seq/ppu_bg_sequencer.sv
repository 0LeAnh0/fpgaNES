`ifndef PPU_BG_SEQUENCER_SV
`define PPU_BG_SEQUENCER_SV

class ppu_bg_sequencer extends uvm_sequencer #(ppu_bg_sequence_item);
  `uvm_component_utils(ppu_bg_sequencer)

  function new(string name = "ppu_bg_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif
