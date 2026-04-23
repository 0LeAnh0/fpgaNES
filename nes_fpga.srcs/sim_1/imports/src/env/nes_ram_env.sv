`ifndef NES_RAM_ENV_SV
`define NES_RAM_ENV_SV

// ===========================================================================
// nes_ram_env
// Environment cho RAM Verification (WRAM + VRAM) — chỉ chứa RAM agents.
// ===========================================================================
class nes_ram_env extends uvm_env;
    `uvm_component_utils(nes_ram_env)

    // RAM Agents (dùng chung nes_ram_agent parametric)
    nes_ram_agent #(virtual wram_if) m_wram_agent;
    nes_ram_agent #(virtual vram_if) m_vram_agent;

    // Coverage & Scoreboard
    nes_ram_cov        m_ram_cov;
    nes_ram_scoreboard m_ram_scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_wram_agent    = nes_ram_agent #(virtual wram_if)::type_id::create("m_wram_agent",    this);
        m_vram_agent    = nes_ram_agent #(virtual vram_if)::type_id::create("m_vram_agent",    this);
        uvm_config_db#(bit)::set(this, "m_wram_agent.monitor", "is_vram_agent", 1'b0);
        uvm_config_db#(bit)::set(this, "m_vram_agent.monitor", "is_vram_agent", 1'b1);
        m_ram_cov       = nes_ram_cov::type_id::create("m_ram_cov", this);
        m_ram_scoreboard= nes_ram_scoreboard::type_id::create("m_ram_scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_wram_agent.agent_ap.connect(m_ram_scoreboard.wram_export);
        m_vram_agent.agent_ap.connect(m_ram_scoreboard.vram_export);
        m_wram_agent.agent_ap.connect(m_ram_cov.analysis_export);
        m_vram_agent.agent_ap.connect(m_ram_cov.analysis_export);
    endfunction

endclass

`endif
