`ifndef PPU_RI_SEQUENCER_SV
`define PPU_RI_SEQUENCER_SV

// ===========================================================================
// ppu_ri_sequencer
// Sequencer chuyen biet cho PPU RI Agent.
// Ke thua uvm_sequencer voi item la ppu_ri_sequence_item.
// Dat ten ro rang de phan biet voi nes_ram (uvm_sequencer#(nes_ram_item))
// ===========================================================================
class ppu_ri_sequencer extends uvm_sequencer #(ppu_ri_sequence_item);
    `uvm_component_utils(ppu_ri_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

`endif
