`ifndef PPU_RI_BASE_TEST_SV
`define PPU_RI_BASE_TEST_SV

// ===========================================================================
// ppu_ri_base_test
// Base test rieng cho PPU RI — tao ppu_ri_env thay vi nes_env.
// Tat ca PPU RI tests phai extend class nay.
// ===========================================================================
class ppu_ri_base_test extends uvm_test;
    `uvm_component_utils(ppu_ri_base_test)

    ppu_ri_env m_ppu_ri_env;
    UVM_FILE   log_file;
    nes_log_catcher m_catcher;
    bit enable_file_log;
    virtual tb_ctrl_if tb_ctrl_vif;
    virtual ppu_ri_if  ppu_ri_vif;
    ppu_ri_cfg         m_ppu_ri_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_ppu_ri_env = ppu_ri_env::type_id::create("m_ppu_ri_env", this);
        if (!uvm_config_db#(ppu_ri_cfg)::get(this, "", "ppu_ri_cfg", m_ppu_ri_cfg)) begin
            m_ppu_ri_cfg = ppu_ri_cfg::type_id::create("m_ppu_ri_cfg");
            uvm_config_db#(ppu_ri_cfg)::set(this, "*", "ppu_ri_cfg", m_ppu_ri_cfg);
        end
        void'(uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", tb_ctrl_vif));
        void'(uvm_config_db#(virtual ppu_ri_if)::get(this, "", "ppu_ri_vif", ppu_ri_vif));

        // Mac dinh van in console nhu UVM chuan.
        // File log la tuy chon: bat bang +PPU_RI_FILE_LOG=1
        enable_file_log = m_ppu_ri_cfg.enable_file_log;
        if ($value$plusargs("PPU_RI_FILE_LOG=%0d", enable_file_log) && enable_file_log) begin
            log_file = $fopen("ppu_ri_verification.log", "w");
            if (log_file == 0) begin
                `uvm_warning("PPU_RI_BASE", "Cannot open ppu_ri_verification.log, continue with console-only logging")
            end else begin
                m_catcher = new("m_catcher", log_file);
                uvm_report_cb::add(null, m_catcher);
                `uvm_info("PPU_RI_BASE", "File logging enabled: ppu_ri_verification.log", UVM_LOW)
            end
        end

        // Allow integration-level tests to extend timeout beyond the RI block default.
        uvm_top.set_timeout(m_ppu_ri_cfg.timeout_ms*1ms, 1);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("PPU_RI_BASE", "PPU RI Environment topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        if (log_file != 0)
            $fclose(log_file);
    endfunction

    // In tieu de testcase ro rang de nguoi doc log theo doi nhanh.
    protected task print_case_header(string case_name, string goal);
        `uvm_info("PPU_RI_CASE", "============================================================", UVM_NONE)
        `uvm_info("PPU_RI_CASE", $sformatf("TESTCASE: %s", case_name), UVM_NONE)
        `uvm_info("PPU_RI_CASE", $sformatf("GOAL    : %s", goal), UVM_NONE)
        `uvm_info("PPU_RI_CASE", "============================================================", UVM_NONE)
    endtask

    // Drive reset pulse from test (active-high reset).
    protected task apply_reset_pulse(int unsigned hold_cycles = 4);
        if (tb_ctrl_vif == null) begin
            `uvm_warning("PPU_RI_BASE", "tb_ctrl_vif is null, cannot drive reset pulse")
            return;
        end
        `uvm_info("PPU_RI_RST", $sformatf("Assert reset for %0d cycles", hold_cycles), UVM_NONE)
        tb_ctrl_vif.rst_req <= 1'b1;
        repeat (hold_cycles) @(tb_ctrl_vif.ctrl_cb);
        tb_ctrl_vif.rst_req <= 1'b0;
        repeat (2) @(tb_ctrl_vif.ctrl_cb);
        `uvm_info("PPU_RI_RST", "Deassert reset", UVM_NONE)
    endtask

    // Log and check key PPU RI outputs after reset.
    protected task check_ppu_ri_reset_state(string tag);
        bit pass = 1;
        `uvm_info("PPU_RI_RST_CHK", "-------------- PPU_RI RESET CHECK --------------", UVM_NONE)
        `uvm_info("PPU_RI_RST_CHK", $sformatf("TAG: %s", tag), UVM_NONE)
        if (ppu_ri_vif == null) begin
            `uvm_error("PPU_RI_RST_CHK", "ppu_ri_vif is null")
            return;
        end

        `uvm_info("PPU_RI_RST_CHK",
            $sformatf("vram_wr=%b pram_wr=%b spr_ram_wr=%b inc_addr=%b upd_cntrs=%b ri_dout=%02h",
                ppu_ri_vif.vram_wr, ppu_ri_vif.pram_wr, ppu_ri_vif.spr_ram_wr,
                ppu_ri_vif.inc_addr, ppu_ri_vif.upd_cntrs, ppu_ri_vif.ri_dout),
            UVM_NONE)

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
            `uvm_info("PPU_RI_RST_CHK", "RESULT: PASS (side-effects low and scroll state reset to 0)", UVM_NONE)
        else
            `uvm_error("PPU_RI_RST_CHK", "RESULT: FAIL (unexpected side-effect or scroll state after reset)")
        `uvm_info("PPU_RI_RST_CHK", "------------------------------------------------", UVM_NONE)
    endtask

    // Snapshot scroll/address related outputs to make logs easy to inspect.
    protected task log_scroll_snapshot(string tag);
        if (ppu_ri_vif == null) begin
            `uvm_warning("PPU_RI_SCROLL", "ppu_ri_vif is null, cannot print scroll snapshot")
            return;
        end
        `uvm_info("PPU_RI_SCROLL", "================ SCROLL SNAPSHOT ================", UVM_NONE)
        `uvm_info("PPU_RI_SCROLL", $sformatf("TAG: %s", tag), UVM_NONE)
        `uvm_info("PPU_RI_SCROLL",
            $sformatf("fv=%0d vt=%0d v=%0d | fh=%0d ht=%0d h=%0d | s=%0d inc_addr_amt=%0d upd_cntrs=%0d",
                ppu_ri_vif.fv, ppu_ri_vif.vt, ppu_ri_vif.v,
                ppu_ri_vif.fh, ppu_ri_vif.ht, ppu_ri_vif.h,
                ppu_ri_vif.s, ppu_ri_vif.inc_addr_amt, ppu_ri_vif.upd_cntrs),
            UVM_NONE)
        `uvm_info("PPU_RI_SCROLL", "=================================================", UVM_NONE)
    endtask

    // Reset ban dau: assert/deassert va check output side-effect ve 0.
    protected task tc_initial_reset_observe();
        print_case_header(
            "RST01_INITIAL_RESET",
            "Assert initial reset and confirm side-effect outputs stay low during reset"
        );
        apply_reset_pulse(6);
        check_ppu_ri_reset_state("RST01_INITIAL_RESET");
    endtask

    // Random reset stress trong qua trinh verify.
    protected task tc_random_reset_stress();
        int i;
        int hold_cycles;
        print_case_header(
            "RST02_RANDOM_RESET",
            "Inject random reset pulses to verify recovery and no stuck side-effects"
        );
        for (i = 0; i < 5; i++) begin
            #(20ns + $urandom_range(0, 120)*1ns);
            hold_cycles = $urandom_range(2, 8);
            `uvm_info("PPU_RI_RST",
                $sformatf("[RANDOM_RST_%0d] hold_cycles=%0d", i, hold_cycles),
                UVM_NONE)
            apply_reset_pulse(hold_cycles);
            check_ppu_ri_reset_state($sformatf("RST02_RANDOM_RESET_%0d", i));
        end
    endtask

endclass

`endif
