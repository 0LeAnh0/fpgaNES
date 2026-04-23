`ifndef PPU_VGA_MASTER_SUBSCRIBER_SV
`define PPU_VGA_MASTER_SUBSCRIBER_SV

class ppu_vga_master_subscriber extends uvm_subscriber #(ppu_vga_sequence_item);
  `uvm_component_utils(ppu_vga_master_subscriber)

  uvm_analysis_port #(ppu_vga_sequence_item) ap;

  function new(string name = "ppu_vga_master_subscriber", uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void write(ppu_vga_sequence_item t);
    ap.write(t);
  endfunction

endclass

`endif
