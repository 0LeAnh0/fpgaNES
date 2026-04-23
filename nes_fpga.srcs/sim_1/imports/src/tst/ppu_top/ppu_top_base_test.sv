class ppu_top_log_catcher extends uvm_report_catcher;
  `uvm_object_utils(ppu_top_log_catcher)

  function new(string name = "ppu_top_log_catcher");
    super.new(name);
  endfunction

  protected function bit suppress_ri_info_id(string id_txt);
    case (id_txt)
      "MASTER_MON",
      "SLAVE_MON",
      "SLAVE_DRV",
      "PPU_RI_COV",
      "SCB_RPT",
      "ppu_ri_ppuctrl_sequence",
      "ppu_ri_ppumask_sequence",
      "ppu_ri_ppuaddr_sequence",
      "ppu_ri_ppudata_write_sequence",
      "ppu_ri_oamaddr_sequence",
      "ppu_ri_oamdata_sequence": return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  virtual function action_e catch();
    if ((get_severity() == UVM_INFO) && suppress_ri_info_id(get_id()))
      return CAUGHT;
    return THROW;
  endfunction
endclass

class ppu_top_base_test extends uvm_test;
  `uvm_component_utils(ppu_top_base_test)

  ppu_top_env        m_env;
  ppu_top_log_catcher m_log_catcher;
  virtual tb_ctrl_if tb_ctrl_vif;
  virtual ppu_ri_if  ppu_ri_vif;
  virtual ppu_top_if ppu_top_vif;
  virtual ppu_bg_if  bg_vif;
  virtual ppu_spr_if spr_vif;
  virtual ppu_vga_if vga_vif;
  ppu_ri_cfg         m_ppu_ri_cfg;
  ppu_top_cfg        m_ppu_top_cfg;

  function new(string name = "ppu_top_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(ppu_ri_cfg)::get(this, "", "ppu_ri_cfg", m_ppu_ri_cfg)) begin
      m_ppu_ri_cfg = ppu_ri_cfg::type_id::create("m_ppu_ri_cfg");
      m_ppu_ri_cfg.set_regression_defaults();
      uvm_config_db#(ppu_ri_cfg)::set(this, "*", "ppu_ri_cfg", m_ppu_ri_cfg);
    end

    if (!uvm_config_db#(ppu_top_cfg)::get(this, "", "ppu_top_cfg", m_ppu_top_cfg)) begin
      m_ppu_top_cfg = ppu_top_cfg::type_id::create("m_ppu_top_cfg");
      uvm_config_db#(ppu_top_cfg)::set(this, "*", "ppu_top_cfg", m_ppu_top_cfg);
    end

    if (!uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", tb_ctrl_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get tb_ctrl_vif")
    if (!uvm_config_db#(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", ppu_ri_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get ppu_ri_vif")
    if (!uvm_config_db#(virtual ppu_top_if)::get(this, "", "ppu_top_vif", ppu_top_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get ppu_top_vif")
    if (!uvm_config_db#(virtual ppu_bg_if)::get(this, "", "bg_vif", bg_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get bg_vif")
    if (!uvm_config_db#(virtual ppu_spr_if)::get(this, "", "spr_vif", spr_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get spr_vif")
    if (!uvm_config_db#(virtual ppu_vga_if)::get(this, "", "vga_vif", vga_vif))
      `uvm_fatal("PPU_TOP_BASE", "Cannot get vga_vif")

    uvm_top.set_timeout(m_ppu_ri_cfg.timeout_ms*1ms, 1);
    m_env = ppu_top_env::type_id::create("m_env", this);
    m_log_catcher = ppu_top_log_catcher::type_id::create("m_log_catcher");
    uvm_report_cb::add(null, m_log_catcher);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("PPU_TOP_BASE", "PPU top integration environment topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction

  protected task print_case_header(string case_name, string goal);
    `uvm_info("PPU_TOP_CASE", "============================================================", UVM_NONE)
    `uvm_info("PPU_TOP_CASE", $sformatf("TESTCASE: %s", case_name), UVM_NONE)
    `uvm_info("PPU_TOP_CASE", $sformatf("GOAL    : %s", goal), UVM_NONE)
    `uvm_info("PPU_TOP_CASE", "============================================================", UVM_NONE)
  endtask

  protected task apply_reset_pulse(int unsigned hold_cycles = 4);
    if (tb_ctrl_vif == null) begin
      `uvm_warning("PPU_TOP_BASE", "tb_ctrl_vif is null, cannot drive reset pulse")
      return;
    end
    `uvm_info("PPU_TOP_RST", $sformatf("Assert reset for %0d cycles", hold_cycles), UVM_NONE)
    tb_ctrl_vif.rst_req <= 1'b1;
    repeat (hold_cycles) @(tb_ctrl_vif.ctrl_cb);
    tb_ctrl_vif.rst_req <= 1'b0;
    repeat (2) @(tb_ctrl_vif.ctrl_cb);
    `uvm_info("PPU_TOP_RST", "Deassert reset", UVM_NONE)
  endtask

  protected task check_ppu_ri_reset_state(string tag);
    bit pass = 1;
    `uvm_info("PPU_TOP_RST_CHK", "-------------- PPU RI RESET CHECK --------------", UVM_NONE)
    `uvm_info("PPU_TOP_RST_CHK", $sformatf("TAG: %s", tag), UVM_NONE)

    if (ppu_ri_vif.vram_wr    !== 1'b0) pass = 0;
    if (ppu_ri_vif.pram_wr    !== 1'b0) pass = 0;
    if (ppu_ri_vif.spr_ram_wr !== 1'b0) pass = 0;
    if (ppu_ri_vif.inc_addr   !== 1'b0) pass = 0;
    if (ppu_ri_vif.upd_cntrs  !== 1'b0) pass = 0;
    if (ppu_ri_vif.fv         !== 3'h0) pass = 0;
    if (ppu_ri_vif.vt         !== 5'h00) pass = 0;
    if (ppu_ri_vif.v          !== 1'b0) pass = 0;
    if (ppu_ri_vif.fh         !== 3'h0) pass = 0;
    if (ppu_ri_vif.ht         !== 5'h00) pass = 0;
    if (ppu_ri_vif.h          !== 1'b0) pass = 0;
    if (ppu_ri_vif.s          !== 1'b0) pass = 0;
    if (ppu_ri_vif.inc_addr_amt !== 1'b0) pass = 0;

    if (pass)
      `uvm_info("PPU_TOP_RST_CHK", "RESULT: PASS (RI state reset to 0)", UVM_NONE)
    else
      `uvm_error("PPU_TOP_RST_CHK", "RESULT: FAIL (unexpected RI state after reset)")
    `uvm_info("PPU_TOP_RST_CHK", "------------------------------------------------", UVM_NONE)
  endtask

  protected task tc_initial_reset_observe();
    print_case_header(
      "RST01_INITIAL_RESET",
      "Assert initial reset and confirm RI-facing side-effects reset cleanly"
    );
    apply_reset_pulse(6);
    check_ppu_ri_reset_state("RST01_INITIAL_RESET");
  endtask
endclass
