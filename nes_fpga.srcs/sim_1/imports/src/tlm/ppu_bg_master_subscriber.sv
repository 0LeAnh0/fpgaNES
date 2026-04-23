`ifndef PPU_BG_MASTER_SUBSCRIBER_SV
`define PPU_BG_MASTER_SUBSCRIBER_SV

class ppu_bg_master_subscriber extends uvm_subscriber #(ppu_bg_sequence_item);
  `uvm_component_utils(ppu_bg_master_subscriber)

  uvm_analysis_port #(ppu_bg_sequence_item) ap;

  function new(string name = "ppu_bg_master_subscriber", uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void write(ppu_bg_sequence_item t);
    // Write customized processing logic here, then broadcast
    ap.write(t);
  endfunction

endclass

`endif
