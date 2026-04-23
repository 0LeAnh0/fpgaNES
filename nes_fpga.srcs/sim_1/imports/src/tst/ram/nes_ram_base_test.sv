`ifndef NES_RAM_BASE_TEST_SV
`define NES_RAM_BASE_TEST_SV

// Lop "Catch" de hung moi log va ghi vao file
class nes_log_catcher extends uvm_report_catcher;
    UVM_FILE fd;
    function new(string name = "nes_log_catcher", UVM_FILE f);
        super.new(name);
        this.fd = f;
    endfunction

    virtual function action_e catch();
        string msg_txt = get_message();
        string id_txt  = get_id();
        $fdisplay(fd, "@ %0tps [%s] %s", $time, id_txt, msg_txt);
        $fflush(fd);
        return THROW; 
    endfunction
endclass

// ===========================================================================
// nes_ram_base_test
// Base test cho RAM Verification (WRAM + VRAM).
// ===========================================================================
class nes_ram_base_test extends uvm_test;
    `uvm_component_utils(nes_ram_base_test)

    nes_ram_env m_env;
    virtual tb_ctrl_if tb_ctrl_vif;
    virtual wram_if    wram_vif;
    virtual vram_if    vram_vif;
    nes_wram_vram_cfg  m_nes_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function bit enable_ram_env();
        return 1'b1;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (enable_ram_env())
            m_env = nes_ram_env::type_id::create("m_env", this);
        if (!uvm_config_db#(nes_wram_vram_cfg)::get(this, "", "nes_wram_vram_cfg", m_nes_cfg)) begin
            m_nes_cfg = nes_wram_vram_cfg::type_id::create("m_nes_cfg");
            uvm_config_db#(nes_wram_vram_cfg)::set(this, "*", "nes_wram_vram_cfg", m_nes_cfg);
        end
        void'(uvm_config_db#(virtual tb_ctrl_if)::get(this, "", "tb_ctrl_vif", tb_ctrl_vif));
        void'(uvm_config_db#(virtual wram_if)::get(this, "", "wram_vif", wram_vif));
        void'(uvm_config_db#(virtual vram_if)::get(this, "", "vram_vif", vram_vif));

        // Allow derived tests to extend the timeout for long-running video timing scenarios.
        uvm_top.set_timeout(m_nes_cfg.timeout_ms*1ms, 1);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("BASE_TEST", "Environment built, topology printed below", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    protected task print_case_header(string case_name, string goal);
        `uvm_info("NES_RAM_CASE", " ", UVM_NONE)
        `uvm_info("NES_RAM_CASE", "############################################################", UVM_NONE)
        `uvm_info("NES_RAM_CASE", "################### NES RAM TESTCASE #######################", UVM_NONE)
        `uvm_info("NES_RAM_CASE", "############################################################", UVM_NONE)
        `uvm_info("NES_RAM_CASE", $sformatf("CASE_ID : %s", case_name), UVM_NONE)
        `uvm_info("NES_RAM_CASE", $sformatf("PURPOSE : %s", goal), UVM_NONE)
        `uvm_info("NES_RAM_CASE", "############################################################", UVM_NONE)
        `uvm_info("NES_RAM_CASE", " ", UVM_NONE)
    endtask

    protected task apply_reset_pulse(int unsigned hold_cycles = 4);
        if (tb_ctrl_vif == null) begin
            `uvm_warning("NES_BASE", "tb_ctrl_vif is null, cannot drive reset pulse")
            return;
        end
        `uvm_info("NES_RST", $sformatf("Assert reset for %0d cycles", hold_cycles), UVM_NONE)
        tb_ctrl_vif.rst_req <= 1'b1;
        repeat (hold_cycles) @(tb_ctrl_vif.ctrl_cb);
        tb_ctrl_vif.rst_req <= 1'b0;
        repeat (2) @(tb_ctrl_vif.ctrl_cb);
        `uvm_info("NES_RST", "Deassert reset", UVM_NONE)
    endtask

    protected task check_ram_reset_state(string tag);
        bit pass = 1;
        `uvm_info("NES_RST_CHK", "---------------- RAM RESET CHECK ----------------", UVM_NONE)
        `uvm_info("NES_RST_CHK", $sformatf("TAG: %s", tag), UVM_NONE)
        if (wram_vif != null) begin
            `uvm_info("NES_RST_CHK", $sformatf("WRAM: en=%b r_nw=%b a=%04h d_in=%02h d_out=%02h", wram_vif.en_in, wram_vif.r_nw_in, wram_vif.a_in, wram_vif.d_in, wram_vif.d_out), UVM_NONE)
            if (wram_vif.en_in !== 1'b0) pass = 0;
        end
        if (vram_vif != null) begin
            `uvm_info("NES_RST_CHK", $sformatf("VRAM: en=%b r_nw=%b a=%04h d_in=%02h d_out=%02h", vram_vif.en_in, vram_vif.r_nw_in, vram_vif.a_in, vram_vif.d_in, vram_vif.d_out), UVM_NONE)
            if (vram_vif.en_in !== 1'b0) pass = 0;
        end

        if (pass)
            `uvm_info("NES_RST_CHK", "RESULT: PASS (en_in=0 for WRAM/VRAM after reset)", UVM_NONE)
        else
            `uvm_error("NES_RST_CHK", "RESULT: FAIL (unexpected RAM bus state after reset)")
        `uvm_info("NES_RST_CHK", "-------------------------------------------------", UVM_NONE)
    endtask

endclass

`endif
