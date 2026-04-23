`ifndef PPU_VGA_ENV_SV
`define PPU_VGA_ENV_SV

class ppu_vga_env extends uvm_env;
  `uvm_component_utils(ppu_vga_env)

  ppu_vga_master_agent master_agent;
  ppu_vga_master_subscriber master_subscriber;
  ppu_vga_cov          cov;
  ppu_vga_scoreboard   scoreboard;
  ppu_vga_cfg          cfg;

  function new(string name = "ppu_vga_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = ppu_vga_cfg::type_id::create("cfg");
    uvm_config_db#(ppu_vga_cfg)::set(this, "*", "cfg", cfg);

    master_agent = ppu_vga_master_agent::type_id::create("master_agent", this);
    master_subscriber = ppu_vga_master_subscriber::type_id::create("master_subscriber", this);
    cov          = ppu_vga_cov::type_id::create("cov", this);
    scoreboard   = ppu_vga_scoreboard::type_id::create("scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    master_agent.monitor.item_collected_port.connect(master_subscriber.analysis_export);
    master_agent.monitor.item_collected_port.connect(cov.analysis_export);
    master_subscriber.ap.connect(scoreboard.analysis_export);
  endfunction

endclass

`endif
