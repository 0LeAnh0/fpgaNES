`ifndef NES_RAM_SEQUENCER_SV
`define NES_RAM_SEQUENCER_SV

class nes_ram_sequencer extends uvm_sequencer #(nes_ram_item);
    `uvm_component_utils(nes_ram_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
