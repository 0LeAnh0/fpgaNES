`ifndef PPU_VGA_MASTER_DRIVER_SV
`define PPU_VGA_MASTER_DRIVER_SV

class ppu_vga_master_driver extends uvm_driver #(ppu_vga_sequence_item);
  `uvm_component_utils(ppu_vga_master_driver)

  virtual ppu_vga_if.MASTER vif;

  function new(string name = "ppu_vga_master_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_vga_if.MASTER)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(vif.vga_cb);
    vif.vga_cb.sys_palette_idx_in <= 6'h00;

    forever begin
      seq_item_port.get_next_item(req);
      vif.vga_cb.sys_palette_idx_in <= req.sys_palette_idx_in;
      @(vif.vga_cb);
      seq_item_port.item_done();
    end
  endtask

endclass

`endif
