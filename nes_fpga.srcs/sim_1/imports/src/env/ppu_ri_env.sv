`ifndef PPU_RI_ENV_SV
`define PPU_RI_ENV_SV

// ===========================================================================
// ppu_ri_env
// Environment rieng biet cho PPU Register Interface Verification.
//
// Cau truc Agent:
//   m_ppu_ri_mst_agent — Master Agent (CPU side: drives $2000-$2007)
//   m_ppu_ri_slv_agent — Slave Agent  (Memory side: VRAM BFM + strobe monitor)
//
// TLM Flow:
//   master_agent.master_ap → scoreboard.master_export + mst_subscriber
//   slave_agent.slave_ap   → scoreboard.slave_export  + slv_subscriber
// ===========================================================================
class ppu_ri_env extends uvm_env;
    `uvm_component_utils(ppu_ri_env)

    // Agents
    ppu_ri_master_agent m_ppu_ri_mst_agent;
    ppu_ri_slave_agent  m_ppu_ri_slv_agent;

    // Scoreboard
    ppu_ri_scoreboard   m_ppu_ri_scoreboard;

    // TLM Subscribers & Coverage
    ppu_ri_master_subscriber m_ppu_ri_mst_sub;
    ppu_ri_slave_subscriber  m_ppu_ri_slv_sub;
    ppu_ri_cov               m_ppu_ri_cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_ppu_ri_mst_agent  = ppu_ri_master_agent::type_id::create("m_ppu_ri_mst_agent", this);
        m_ppu_ri_slv_agent  = ppu_ri_slave_agent::type_id::create("m_ppu_ri_slv_agent",  this);
        m_ppu_ri_scoreboard = ppu_ri_scoreboard::type_id::create("m_ppu_ri_scoreboard",  this);
        m_ppu_ri_mst_sub    = ppu_ri_master_subscriber::type_id::create("m_ppu_ri_mst_sub", this);
        m_ppu_ri_slv_sub    = ppu_ri_slave_subscriber::type_id::create("m_ppu_ri_slv_sub",  this);
        m_ppu_ri_cov        = ppu_ri_cov::type_id::create("m_ppu_ri_cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Master ap → Scoreboard (master port) + TLM Master Subscriber + Coverage
        m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_scoreboard.master_export);
        m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_mst_sub.analysis_export);
        m_ppu_ri_mst_agent.master_ap.connect(m_ppu_ri_cov.analysis_export);

        // Slave ap → Scoreboard (slave port) + TLM Slave Subscriber
        m_ppu_ri_slv_agent.slave_ap.connect(m_ppu_ri_scoreboard.slave_export);
        m_ppu_ri_slv_agent.slave_ap.connect(m_ppu_ri_slv_sub.analysis_export);
    endfunction

endclass

`endif
