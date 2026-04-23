`ifndef PPU_TOP_ENV_SV
`define PPU_TOP_ENV_SV

class ppu_top_env extends uvm_env;
  `uvm_component_utils(ppu_top_env)

  ppu_ri_cfg               m_ppu_ri_cfg;
  ppu_top_cfg              m_ppu_top_cfg;
  ppu_ri_master_agent      m_ppu_ri_mst_agent;
  ppu_ri_slave_agent       m_ppu_ri_slv_agent;
  ppu_ri_master_subscriber m_ppu_ri_mst_sub;
  ppu_ri_slave_subscriber  m_ppu_ri_slv_sub;
  ppu_ri_cov               m_ppu_ri_cov;
  ppu_ri_scoreboard        m_ppu_ri_scoreboard;

  ppu_top_monitor          m_ppu_top_monitor;
  ppu_top_subscriber       m_ppu_top_subscriber;
  ppu_top_cov              m_ppu_top_cov;
  ppu_top_scoreboard       m_ppu_top_scoreboard;

  function new(string name = "ppu_top_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(ppu_ri_cfg)::get(this, "", "ppu_ri_cfg", m_ppu_ri_cfg))
      `uvm_fatal("PPU_TOP_ENV", "ppu_ri_cfg not found for ppu_top_env")
    if (!uvm_config_db#(ppu_top_cfg)::get(this, "", "ppu_top_cfg", m_ppu_top_cfg))
      `uvm_fatal("PPU_TOP_ENV", "ppu_top_cfg not found for ppu_top_env")

    uvm_config_db#(ppu_top_cfg)::set(this, "*", "cfg", m_ppu_top_cfg);

    m_ppu_ri_mst_agent  = ppu_ri_master_agent::type_id::create("m_ppu_ri_mst_agent", this);
    m_ppu_ri_slv_agent  = ppu_ri_slave_agent::type_id::create("m_ppu_ri_slv_agent", this);
    m_ppu_ri_mst_sub    = ppu_ri_master_subscriber::type_id::create("m_ppu_ri_mst_sub", this);
    m_ppu_ri_slv_sub    = ppu_ri_slave_subscriber::type_id::create("m_ppu_ri_slv_sub", this);
    m_ppu_ri_cov        = ppu_ri_cov::type_id::create("m_ppu_ri_cov", this);
    m_ppu_ri_scoreboard = ppu_ri_scoreboard::type_id::create("m_ppu_ri_scoreboard", this);

    m_ppu_top_monitor    = ppu_top_monitor::type_id::create("m_ppu_top_monitor", this);
    m_ppu_top_subscriber = ppu_top_subscriber::type_id::create("m_ppu_top_subscriber", this);
    m_ppu_top_cov        = ppu_top_cov::type_id::create("m_ppu_top_cov", this);
    m_ppu_top_scoreboard = ppu_top_scoreboard::type_id::create("m_ppu_top_scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_scoreboard.master_export);
    m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_mst_sub.analysis_export);
    m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_cov.analysis_export);

    m_ppu_ri_slv_agent.slave_ap.connect(m_ppu_ri_scoreboard.slave_export);
    m_ppu_ri_slv_agent.slave_ap.connect(m_ppu_ri_slv_sub.analysis_export);

    m_ppu_top_monitor.ap.connect(m_ppu_top_subscriber.analysis_export);
    m_ppu_top_monitor.ap.connect(m_ppu_top_cov.analysis_export);
    m_ppu_top_subscriber.ap.connect(m_ppu_top_scoreboard.analysis_export);
  endfunction
endclass

`endif
