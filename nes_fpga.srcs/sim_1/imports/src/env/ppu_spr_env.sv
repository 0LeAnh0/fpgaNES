`ifndef PPU_SPR_ENV_SV
`define PPU_SPR_ENV_SV

class ppu_spr_env extends uvm_env;
  `uvm_component_utils(ppu_spr_env)

  ppu_spr_master_agent      master_agent;
  ppu_spr_master_subscriber master_subscriber;
  ppu_spr_cov               cov;
  ppu_spr_scoreboard        scoreboard;
  ppu_spr_cfg               cfg;

  function new(string name = "ppu_spr_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    cfg = ppu_spr_cfg::type_id::create("cfg");
    uvm_config_db#(ppu_spr_cfg)::set(this, "*", "cfg", cfg);

    master_agent      = ppu_spr_master_agent::type_id::create("master_agent", this);
    master_subscriber = ppu_spr_master_subscriber::type_id::create("master_subscriber", this);
    cov               = ppu_spr_cov::type_id::create("cov", this);
    scoreboard        = ppu_spr_scoreboard::type_id::create("scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    master_agent.monitor.item_collected_port.connect(master_subscriber.analysis_export);
    master_agent.monitor.item_collected_port.connect(cov.analysis_export);

    master_subscriber.ap.connect(scoreboard.master_fifo.analysis_export);
  endfunction

endclass

`endif
