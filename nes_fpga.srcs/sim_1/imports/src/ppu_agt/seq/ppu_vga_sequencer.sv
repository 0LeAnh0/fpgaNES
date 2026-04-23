`ifndef PPU_VGA_SEQUENCER_SV
`define PPU_VGA_SEQUENCER_SV

class ppu_vga_sequencer extends uvm_sequencer #(ppu_vga_sequence_item);
  `uvm_component_utils(ppu_vga_sequencer)

  function new(string name = "ppu_vga_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

`endif
