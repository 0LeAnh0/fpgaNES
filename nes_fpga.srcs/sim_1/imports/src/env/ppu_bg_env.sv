`ifndef PPU_BG_ENV_SV
`define PPU_BG_ENV_SV

class ppu_bg_env extends uvm_env;
  `uvm_component_utils(ppu_bg_env)

  ppu_bg_master_agent      master_agent;
  ppu_bg_slave_agent       slave_agent;
  ppu_bg_master_subscriber master_subscriber;
  ppu_bg_slave_subscriber  slave_subscriber;
  ppu_bg_cov               cov;
  ppu_bg_scoreboard        scoreboard;
  ppu_bg_cfg               cfg;

  function new(string name = "ppu_bg_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    cfg = ppu_bg_cfg::type_id::create("cfg");
    uvm_config_db#(ppu_bg_cfg)::set(this, "*", "cfg", cfg);

    master_agent = ppu_bg_master_agent::type_id::create("master_agent", this);
    slave_agent  = ppu_bg_slave_agent::type_id::create("slave_agent", this);

    master_subscriber = ppu_bg_master_subscriber::type_id::create("master_subscriber", this);
    slave_subscriber  = ppu_bg_slave_subscriber::type_id::create("slave_subscriber", this);
    cov               = ppu_bg_cov::type_id::create("cov", this);
    scoreboard = ppu_bg_scoreboard::type_id::create("scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    master_agent.monitor.item_collected_port.connect(master_subscriber.analysis_export);
    master_agent.monitor.item_collected_port.connect(cov.analysis_export);

    master_subscriber.ap.connect(scoreboard.master_fifo.analysis_export);
  endfunction

endclass

`endif
