`ifndef PPU_BG_SLAVE_MONITOR_SV
`define PPU_BG_SLAVE_MONITOR_SV

class ppu_bg_slave_monitor extends uvm_monitor;
  `uvm_component_utils(ppu_bg_slave_monitor)

  virtual ppu_bg_if.MONITOR vif;
  uvm_analysis_port #(ppu_bg_sequence_item) item_collected_port;

  function new(string name = "ppu_bg_slave_monitor", uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ppu_bg_if.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_sequence_item item;

    forever begin
      @(vif.mon_cb);
      item = ppu_bg_sequence_item::type_id::create("item");
      item.vram_a_out      = vif.mon_cb.vram_a_out;
      item.palette_idx_out = vif.mon_cb.palette_idx_out;
      item.rst_in          = vif.mon_cb.rst_in;
      
      item_collected_port.write(item);
    end
  endtask

endclass

`endif
