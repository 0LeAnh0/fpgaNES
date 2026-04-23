`ifndef PPU_SPR_MASTER_SUBSCRIBER_SV
`define PPU_SPR_MASTER_SUBSCRIBER_SV

class ppu_spr_master_subscriber extends uvm_subscriber #(ppu_spr_sequence_item);
  `uvm_component_utils(ppu_spr_master_subscriber)

  uvm_analysis_port #(ppu_spr_sequence_item) ap;

  function new(string name = "ppu_spr_master_subscriber", uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void write(ppu_spr_sequence_item t);
    ap.write(t);
  endfunction

endclass

`endif
