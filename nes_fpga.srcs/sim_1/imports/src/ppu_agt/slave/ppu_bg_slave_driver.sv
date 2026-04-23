`ifndef PPU_BG_SLAVE_DRIVER_SV
`define PPU_BG_SLAVE_DRIVER_SV

class ppu_bg_slave_driver extends uvm_driver #(ppu_bg_sequence_item);
  `uvm_component_utils(ppu_bg_slave_driver)

  virtual ppu_bg_if.SLAVE vif;

  function new(string name = "ppu_bg_slave_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_bg_if.SLAVE)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(ppu_bg_sequence_item item);
    // Dummy drive for slave
    @(vif.bg_cb);
  endtask

endclass

`endif
