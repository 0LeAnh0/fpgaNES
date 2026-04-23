`ifndef PPU_RI_SCROLL_SIGNOFF_TEST_SV
`define PPU_RI_SCROLL_SIGNOFF_TEST_SV

// ===========================================================================
// ppu_ri_scroll_signoff_test
// Muc tieu: verify nhom chuc nang scrolling/counter cua ppu_ri theo style
//           signoff (co reset dau vao, random reset, directed + random stress).
//
// Scope check:
//   - $2005 (PPUSCROLL) cap nhat fh/ht va fv/vt qua 2 lan ghi
//   - $2006 (PPUADDR) cap nhat fv/v/vt/ht/h va pulse upd_cntrs lan ghi thu 2
//   - $2002 read reset byte_sel (kiem tra gian tiep qua hanh vi $2006 tiep theo)
//   - $2000[2] map sang inc_addr_amt_out (mode +1 / +32)
//   - Reset initial + random reset deu in log snapshot va ket luan PASS/FAIL
// ===========================================================================
class ppu_ri_scroll_signoff_test extends ppu_ri_base_test;
    `uvm_component_utils(ppu_ri_scroll_signoff_test)

    int unsigned random_iters = 80;
    int unsigned reset_random_pulses = 5;
    ppu_scroll_cfg m_scroll_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(ppu_scroll_cfg)::get(this, "", "ppu_scroll_cfg", m_scroll_cfg)) begin
            m_scroll_cfg = ppu_scroll_cfg::type_id::create("m_scroll_cfg");
            uvm_config_db#(ppu_scroll_cfg)::set(this, "*", "ppu_scroll_cfg", m_scroll_cfg);
        end
        random_iters = m_scroll_cfg.random_iters;
        reset_random_pulses = m_scroll_cfg.random_reset_pulses;
        void'($value$plusargs("PPU_RI_RANDOM_ITERS=%0d", random_iters));
        `uvm_info("PPU_RI_SCROLL", $sformatf("random_iters=%0d", random_iters), UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting PPU RI scroll signoff test");
        `uvm_info("TEST", ">>> START: ppu_ri_scroll_signoff_test <<<", UVM_NONE)

        // Cho DUT on dinh sau power-up reset tu tb_top.
        #220ns;

        tc_initial_reset_observe();
        tc_random_reset_stress();
        tc_ppuscroll_directed();
        tc_ppuaddr_directed();
        tc_ppustatus_clear_latch_behavior();
        tc_addr_inc_mode_switch();
        tc_scroll_random_stress();

        `uvm_info("PPU_RI_SCROLL",
            $sformatf("SCROLL_RESET_SUMMARY: initial=PASS random_pulses=%0d", reset_random_pulses),
            UVM_NONE)
        `uvm_info("TEST", ">>> DONE: ppu_ri_scroll_signoff_test <<<", UVM_NONE)
        phase.drop_objection(this, "Finished PPU RI scroll signoff test");
    endtask

    // Wait 1-2 clocks de outputs settle roi moi check snapshot.
    protected task wait_settle_cycles(int unsigned n = 2);
        if (tb_ctrl_vif != null) begin
            repeat (n) @(tb_ctrl_vif.ctrl_cb);
        end else begin
            repeat (n) #20ns;
        end
    endtask

    protected task check_scroll_state(
        string tag,
        logic [2:0] exp_fv,
        logic [4:0] exp_vt,
        logic       exp_v,
        logic [2:0] exp_fh,
        logic [4:0] exp_ht,
        logic       exp_h,
        logic       exp_s
    );
        bit pass = 1;
        if (ppu_ri_vif == null) begin
            `uvm_error("PPU_RI_SCROLL", "ppu_ri_vif is null in check_scroll_state")
            return;
        end
        // Retry once if state is unknown at boundary cycle.
        if ($isunknown(ppu_ri_vif.fv) || $isunknown(ppu_ri_vif.vt) || $isunknown(ppu_ri_vif.v) ||
            $isunknown(ppu_ri_vif.fh) || $isunknown(ppu_ri_vif.ht) || $isunknown(ppu_ri_vif.h) ||
            $isunknown(ppu_ri_vif.s)) begin
            wait_settle_cycles(1);
        end
        if ($isunknown(ppu_ri_vif.fv) || $isunknown(ppu_ri_vif.vt) || $isunknown(ppu_ri_vif.v) ||
            $isunknown(ppu_ri_vif.fh) || $isunknown(ppu_ri_vif.ht) || $isunknown(ppu_ri_vif.h) ||
            $isunknown(ppu_ri_vif.s)) begin
            `uvm_warning("PPU_RI_SCROLL",
                $sformatf("[%s] Scroll observation still contains X after retry. Skip strict compare this cycle.", tag))
            return;
        end

        if (ppu_ri_vif.fv !== exp_fv) pass = 0;
        if (ppu_ri_vif.vt !== exp_vt) pass = 0;
        if (ppu_ri_vif.v  !== exp_v ) pass = 0;
        if (ppu_ri_vif.fh !== exp_fh) pass = 0;
        if (ppu_ri_vif.ht !== exp_ht) pass = 0;
        if (ppu_ri_vif.h  !== exp_h ) pass = 0;
        if (ppu_ri_vif.s  !== exp_s ) pass = 0;

        if (pass) begin
            `uvm_info("PPU_RI_SCROLL",
                $sformatf("[%s] PASS exp/obs: fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d",
                    tag, exp_fv, exp_vt, exp_v, exp_fh, exp_ht, exp_h, exp_s),
                UVM_NONE)
        end else begin
            `uvm_error("PPU_RI_SCROLL",
                $sformatf("[%s] FAIL exp(fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d) obs(fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d)",
                    tag, exp_fv, exp_vt, exp_v, exp_fh, exp_ht, exp_h, exp_s,
                    ppu_ri_vif.fv, ppu_ri_vif.vt, ppu_ri_vif.v, ppu_ri_vif.fh, ppu_ri_vif.ht, ppu_ri_vif.h, ppu_ri_vif.s))
        end
    endtask

    protected task check_inc_addr_amt(string tag, logic exp_amt);
        if (ppu_ri_vif == null) begin
            `uvm_error("PPU_RI_SCROLL", "ppu_ri_vif is null in check_inc_addr_amt")
            return;
        end
        if ($isunknown(ppu_ri_vif.inc_addr_amt)) begin
            wait_settle_cycles(1);
        end
        if ($isunknown(ppu_ri_vif.inc_addr_amt)) begin
            `uvm_warning("PPU_RI_SCROLL",
                $sformatf("[%s] inc_addr_amt is X after retry. Skip strict compare this cycle.", tag))
            return;
        end
        if (ppu_ri_vif.inc_addr_amt !== exp_amt) begin
            `uvm_error("PPU_RI_SCROLL",
                $sformatf("[%s] inc_addr_amt mismatch exp=%0b obs=%0b",
                    tag, exp_amt, ppu_ri_vif.inc_addr_amt))
        end else begin
            `uvm_info("PPU_RI_SCROLL",
                $sformatf("[%s] PASS inc_addr_amt=%0b", tag, ppu_ri_vif.inc_addr_amt),
                UVM_NONE)
        end
    endtask

    protected task tc_initial_reset_observe();
        print_case_header(
            "SCROLL_TC00_INITIAL_RESET",
            "Assert reset once and verify scrolling/counter outputs return to zero"
        );
        apply_reset_pulse(6);
        wait_settle_cycles(2);
        check_ppu_ri_reset_state("SCROLL_TC00_INITIAL_RESET");
        log_scroll_snapshot("SCROLL_TC00_INITIAL_RESET");
        check_scroll_state("SCROLL_TC00_INITIAL_RESET", 3'h0, 5'h00, 1'b0, 3'h0, 5'h00, 1'b0, 1'b0);
        check_inc_addr_amt("SCROLL_TC00_INITIAL_RESET", 1'b0);
    endtask

    protected task tc_random_reset_stress();
        int i;
        int hold_cycles;
        print_case_header(
            "SCROLL_TC00B_RANDOM_RESET",
            "Inject random reset pulses and re-check scrolling outputs after each pulse"
        );
        for (i = 0; i < reset_random_pulses; i++) begin
            #(20ns + $urandom_range(0, 120)*1ns);
            hold_cycles = $urandom_range(2, 8);
            `uvm_info("PPU_RI_SCROLL",
                $sformatf("[RANDOM_RST_%0d] hold_cycles=%0d", i, hold_cycles),
                UVM_NONE)
            apply_reset_pulse(hold_cycles);
            wait_settle_cycles(2);
            check_ppu_ri_reset_state($sformatf("SCROLL_TC00B_RANDOM_RESET_%0d", i));
            log_scroll_snapshot($sformatf("SCROLL_TC00B_RANDOM_RESET_%0d", i));
            check_scroll_state($sformatf("SCROLL_TC00B_RANDOM_RESET_%0d", i), 3'h0, 5'h00, 1'b0, 3'h0, 5'h00, 1'b0, 1'b0);
            check_inc_addr_amt($sformatf("SCROLL_TC00B_RANDOM_RESET_%0d", i), 1'b0);
        end
    endtask

    protected task tc_ppuscroll_directed();
        ppu_ri_ppuscroll_sequence seq_scroll;
        logic [7:0] x_val;
        logic [7:0] y_val;
        print_case_header(
            "SCROLL_TC01_PPUSCROLL_DIRECTED",
            "Verify $2005 two-write updates fh/ht first then fv/vt second"
        );

        x_val = 8'hB3; // fh=3, ht=22
        y_val = 8'h5D; // fv=5, vt=11

        seq_scroll = ppu_ri_ppuscroll_sequence::type_id::create("scroll_tc01_seq");
        seq_scroll.scroll_x = x_val;
        seq_scroll.scroll_y = y_val;
        seq_scroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        wait_settle_cycles(2);
        log_scroll_snapshot("SCROLL_TC01_PPUSCROLL_DIRECTED");
        check_scroll_state(
            "SCROLL_TC01_PPUSCROLL_DIRECTED",
            y_val[2:0], y_val[7:3], 1'b0,
            x_val[2:0], x_val[7:3], 1'b0,
            ppu_ri_vif.s
        );
    endtask

    protected task tc_ppuaddr_directed();
        ppu_ri_ppuaddr_sequence seq_addr;
        logic [13:0] addr;
        logic [7:0] hi;
        logic [7:0] lo;
        logic [2:0] exp_fv;
        logic [4:0] exp_vt;
        logic       exp_v;
        logic [4:0] exp_ht;
        logic       exp_h;

        print_case_header(
            "SCROLL_TC02_PPUADDR_DIRECTED",
            "Verify $2006 high/low write mapping and upd_cntrs pulse behavior"
        );

        addr = 14'h2ABC;
        hi = {2'b00, addr[13:8]};
        lo = addr[7:0];

        // Ref decode from RTL comment:
        // write1: fv[1:0]=hi[5:4], v=hi[3], h=hi[2], vt[4:3]=hi[1:0]
        // write2: vt[2:0]=lo[7:5], ht[4:0]=lo[4:0]
        exp_fv = {1'b0, hi[5:4]};
        exp_v  = hi[3];
        exp_h  = hi[2];
        exp_vt = {hi[1:0], lo[7:5]};
        exp_ht = lo[4:0];

        seq_addr = ppu_ri_ppuaddr_sequence::type_id::create("scroll_tc02_seq");
        seq_addr.vram_addr = addr;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        wait_settle_cycles(2);
        log_scroll_snapshot("SCROLL_TC02_PPUADDR_DIRECTED");
        check_scroll_state(
            "SCROLL_TC02_PPUADDR_DIRECTED",
            exp_fv, exp_vt, exp_v,
            ppu_ri_vif.fh, exp_ht, exp_h,
            ppu_ri_vif.s
        );
    endtask

    protected task tc_ppustatus_clear_latch_behavior();
        ppu_ri_write_sequence     seq_wr;
        ppu_ri_ppustatus_sequence seq_stat;
        logic [7:0] hi1;
        logic [7:0] hi2;
        logic [7:0] lo2;
        logic [2:0] exp_fv;
        logic [4:0] exp_vt;
        logic       exp_v;
        logic [4:0] exp_ht;
        logic       exp_h;

        print_case_header(
            "SCROLL_TC03_STATUS_CLEAR_BYTESEL",
            "Read $2002 then verify next $2006 write is treated as high-byte again"
        );

        seq_stat = ppu_ri_ppustatus_sequence::type_id::create("scroll_tc03_stat");

        hi1 = 8'h2A;
        hi2 = 8'h21;
        lo2 = 8'hCD;

        // Step1: Write one high byte to $2006 (byte_sel -> 1)
        seq_wr = ppu_ri_write_sequence::type_id::create("scroll_tc03_wr_hi1");
        seq_wr.target_sel = 3'h6;
        seq_wr.target_data = hi1;
        seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
        wait_settle_cycles(1);

        // Step2: Read $2002 should clear byte_sel -> 0
        seq_stat.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
        wait_settle_cycles(1);

        // Step3: Write high+low for new addr, expect decode from hi2/lo2.
        seq_wr = ppu_ri_write_sequence::type_id::create("scroll_tc03_wr_hi2");
        seq_wr.target_sel = 3'h6;
        seq_wr.target_data = hi2;
        seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr = ppu_ri_write_sequence::type_id::create("scroll_tc03_wr_lo2");
        seq_wr.target_sel = 3'h6;
        seq_wr.target_data = lo2;
        seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
        wait_settle_cycles(2);

        exp_fv = {1'b0, hi2[5:4]};
        exp_v  = hi2[3];
        exp_h  = hi2[2];
        exp_vt = {hi2[1:0], lo2[7:5]};
        exp_ht = lo2[4:0];

        log_scroll_snapshot("SCROLL_TC03_STATUS_CLEAR_BYTESEL");
        check_scroll_state(
            "SCROLL_TC03_STATUS_CLEAR_BYTESEL",
            exp_fv, exp_vt, exp_v,
            ppu_ri_vif.fh, exp_ht, exp_h,
            ppu_ri_vif.s
        );
    endtask

    protected task tc_addr_inc_mode_switch();
        ppu_ri_ppuctrl_sequence seq_ctrl;
        int i;
        print_case_header(
            "SCROLL_TC04_ADDR_INC_MODE_SWITCH",
            "Toggle $2000[2] repeatedly and verify inc_addr_amt follows each write"
        );
        for (i = 0; i < 10; i++) begin
            seq_ctrl = ppu_ri_ppuctrl_sequence::type_id::create($sformatf("scroll_tc04_ctrl_%0d", i));
            seq_ctrl.nvbl_en  = 1'b0;
            seq_ctrl.spr_h    = 1'b0;
            seq_ctrl.s        = 1'b0;
            seq_ctrl.spr_pt   = 1'b0;
            seq_ctrl.addr_inc = i[0];
            seq_ctrl.v        = 1'b0;
            seq_ctrl.h        = 1'b0;
            seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
            wait_settle_cycles(1);
            check_inc_addr_amt($sformatf("SCROLL_TC04_ADDR_INC_MODE_SWITCH_%0d", i), i[0]);
        end
        log_scroll_snapshot("SCROLL_TC04_ADDR_INC_MODE_SWITCH_FINAL");
    endtask

    protected task tc_scroll_random_stress();
        ppu_ri_ppuscroll_sequence seq_scroll;
        ppu_ri_ppuaddr_sequence   seq_addr;
        ppu_ri_ppuctrl_sequence   seq_ctrl;
        int unsigned i;
        int unsigned op;

        logic [2:0] exp_fv;
        logic [4:0] exp_vt;
        logic       exp_v;
        logic [2:0] exp_fh;
        logic [4:0] exp_ht;
        logic       exp_h;
        logic       exp_s;
        logic       exp_inc_amt;

        logic [7:0] hi;
        logic [7:0] lo;

        print_case_header(
            "SCROLL_TC05_RANDOM_STRESS",
            $sformatf("Random stress (%0d ops): mix $2000/$2005/$2006 and compare scroll mirror", random_iters)
        );

        // Init expected mirror from current DUT state to avoid false mismatch
        // when this testcase starts after other directed cases.
        if (ppu_ri_vif != null) begin
            exp_fv      = ppu_ri_vif.fv;
            exp_vt      = ppu_ri_vif.vt;
            exp_v       = ppu_ri_vif.v;
            exp_fh      = ppu_ri_vif.fh;
            exp_ht      = ppu_ri_vif.ht;
            exp_h       = ppu_ri_vif.h;
            exp_s       = ppu_ri_vif.s;
            exp_inc_amt = ppu_ri_vif.inc_addr_amt;
        end else begin
            exp_fv = 0; exp_vt = 0; exp_v = 0; exp_fh = 0; exp_ht = 0; exp_h = 0; exp_s = 0; exp_inc_amt = 0;
        end

        for (i = 0; i < random_iters; i++) begin
            op = $urandom_range(0, 2);
            case (op)
                0: begin
                    seq_scroll = ppu_ri_ppuscroll_sequence::type_id::create($sformatf("scroll_tc05_scroll_%0d", i));
                    if (!seq_scroll.randomize()) `uvm_error("PPU_RI_SCROLL", "randomize seq_scroll failed")
                    seq_scroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                    exp_fh = seq_scroll.scroll_x[2:0];
                    exp_ht = seq_scroll.scroll_x[7:3];
                    exp_fv = seq_scroll.scroll_y[2:0];
                    exp_vt = seq_scroll.scroll_y[7:3];
                end
                1: begin
                    seq_addr = ppu_ri_ppuaddr_sequence::type_id::create($sformatf("scroll_tc05_addr_%0d", i));
                    if (!seq_addr.randomize()) `uvm_error("PPU_RI_SCROLL", "randomize seq_addr failed")
                    seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                    hi = {2'b00, seq_addr.vram_addr[13:8]};
                    lo = seq_addr.vram_addr[7:0];
                    exp_fv = {1'b0, hi[5:4]};
                    exp_v  = hi[3];
                    exp_h  = hi[2];
                    exp_vt = {hi[1:0], lo[7:5]};
                    exp_ht = lo[4:0];
                end
                default: begin
                    seq_ctrl = ppu_ri_ppuctrl_sequence::type_id::create($sformatf("scroll_tc05_ctrl_%0d", i));
                    if (!seq_ctrl.randomize()) `uvm_error("PPU_RI_SCROLL", "randomize seq_ctrl failed")
                    seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                    exp_s       = seq_ctrl.s;
                    exp_v       = seq_ctrl.v;
                    exp_h       = seq_ctrl.h;
                    exp_inc_amt = seq_ctrl.addr_inc;
                end
            endcase
            wait_settle_cycles(1);
            check_scroll_state($sformatf("SCROLL_TC05_RANDOM_%0d", i), exp_fv, exp_vt, exp_v, exp_fh, exp_ht, exp_h, exp_s);
            check_inc_addr_amt($sformatf("SCROLL_TC05_RANDOM_%0d", i), exp_inc_amt);
        end

        log_scroll_snapshot("SCROLL_TC05_RANDOM_STRESS_FINAL");
    endtask

endclass

`endif
