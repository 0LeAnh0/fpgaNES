`ifndef PPU_TOP_SUBSCRIBER_SV
`define PPU_TOP_SUBSCRIBER_SV

class ppu_top_subscriber extends uvm_subscriber #(ppu_top_sequence_item);
  `uvm_component_utils(ppu_top_subscriber)

  uvm_analysis_port #(ppu_top_sequence_item) ap;

  function new(string name = "ppu_top_subscriber", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void write(ppu_top_sequence_item t);
    ap.write(t);
  endfunction
endclass

`endif
