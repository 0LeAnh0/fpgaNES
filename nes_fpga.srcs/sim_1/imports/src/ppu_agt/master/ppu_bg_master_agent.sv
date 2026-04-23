`ifndef PPU_BG_MASTER_AGENT_SV
`define PPU_BG_MASTER_AGENT_SV

class ppu_bg_master_agent extends uvm_agent;
  `uvm_component_utils(ppu_bg_master_agent)

  ppu_bg_master_driver  driver;
  ppu_bg_master_monitor monitor;
  ppu_bg_sequencer      sequencer;

  function new(string name = "ppu_bg_master_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = ppu_bg_master_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver = ppu_bg_master_driver::type_id::create("driver", this);
      sequencer = ppu_bg_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass

`endif
