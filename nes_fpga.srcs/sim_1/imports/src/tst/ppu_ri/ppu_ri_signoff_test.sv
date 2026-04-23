`ifndef PPU_RI_SIGNOFF_TEST_SV
`define PPU_RI_SIGNOFF_TEST_SV

// ===========================================================================
// ppu_ri_signoff_test
// Muc tieu: mo rong tu full_regression thanh bo test "gan signoff"
// gom:
//  - Directed corner cases (boundary, +1/+32 increment mode)
//  - Random stress transactions (mix read/write tren cac thanh ghi hop le)
// ===========================================================================
class ppu_ri_signoff_test extends ppu_ri_base_test;
    `uvm_component_utils(ppu_ri_signoff_test)

    int unsigned random_iters = 120;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("PPU_RI_RANDOM_ITERS=%0d", random_iters));
        `uvm_info("PPU_RI_SIGNOFF", $sformatf("random_iters=%0d", random_iters), UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting PPU RI signoff test");
        `uvm_info("TEST", ">>> START: ppu_ri_signoff_test <<<", UVM_NONE)

        // Cho reset deassert xong trong tb_top.
        #220ns;

        // Preload 1 block VRAM de random read khong bi canh bao uninitialized qua nhieu.
        preload_vram_window(14'h2000, 14'h20FF);

        tc_initial_reset_observe();
        tc_random_reset_stress();
        tc_directed_baseline();
        tc_oamdata_read_path();
        tc_byte_sel_multiwrite();
        tc_ppudata_buffered_read_model();
        tc_boundary_vram_to_pram();
        tc_increment_mode_32();
        tc_mode_switch_stress();
        tc_random_stress();

        #300ns;
        `uvm_info("TEST", ">>> DONE: ppu_ri_signoff_test <<<", UVM_NONE)
        phase.drop_objection(this, "Finished PPU RI signoff test");
    endtask

    // Reset ban dau: assert/deassert va check output side-effect ve 0.
    protected task tc_initial_reset_observe();
        print_case_header(
            "SO00_INITIAL_RESET",
            "Assert initial reset and confirm side-effect outputs stay low during reset"
        );

        apply_reset_pulse(6);
        check_ppu_ri_reset_state("SO00_INITIAL_RESET");
    endtask

    // Random reset stress nhe trong qua trinh verify.
    protected task tc_random_reset_stress();
        int i;
        int hold_cycles;
        print_case_header(
            "SO00B_RANDOM_RESET",
            "Inject random reset pulses to verify recovery and no stuck side-effects"
        );
        for (i = 0; i < 5; i++) begin
            #(20ns + $urandom_range(0, 120)*1ns);
            hold_cycles = $urandom_range(2, 8);
            `uvm_info("PPU_RI_RST",
                $sformatf("[RANDOM_RST_%0d] hold_cycles=%0d", i, hold_cycles),
                UVM_NONE)
            apply_reset_pulse(hold_cycles);
            check_ppu_ri_reset_state($sformatf("SO00B_RANDOM_RESET_%0d", i));
        end
    endtask

    // Preload 1 cua so dia chi [start_addr..end_addr] voi pattern de debug de nhin.
    protected task preload_vram_window(logic [13:0] start_addr, logic [13:0] end_addr);
        logic [13:0] a;
        logic [7:0] d;
        for (a = start_addr; a <= end_addr; a++) begin
            d = a[7:0] ^ 8'hA5;
            m_ppu_ri_env.m_ppu_ri_slv_agent.preload_vram(a, d);
        end
    endtask

    //--------------------------------------------------------------------------
    // CASE 1: baseline duong co ban
    //--------------------------------------------------------------------------
    protected task tc_directed_baseline();
        ppu_ri_ppuctrl_sequence       seq_ctrl;
        ppu_ri_ppumask_sequence       seq_mask;
        ppu_ri_ppustatus_sequence     seq_stat;
        ppu_ri_oamaddr_sequence       seq_oamaddr;
        ppu_ri_oamdata_sequence       seq_oamdata;
        ppu_ri_ppuaddr_sequence       seq_addr;
        ppu_ri_ppudata_write_sequence seq_wr;
        ppu_ri_ppudata_read_sequence  seq_rd;

        print_case_header(
            "SO01_BASELINE",
            "Directed baseline: config + status + OAM + PPUDATA"
        );

        seq_ctrl          = ppu_ri_ppuctrl_sequence::type_id::create("so01_seq_ctrl");
        seq_ctrl.nvbl_en  = 1'b1;
        seq_ctrl.spr_h    = 1'b0;
        seq_ctrl.s        = 1'b0;
        seq_ctrl.spr_pt   = 1'b1;
        seq_ctrl.addr_inc = 1'b0; // +1
        seq_ctrl.v        = 1'b0;
        seq_ctrl.h        = 1'b0;
        seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_mask               = ppu_ri_ppumask_sequence::type_id::create("so01_seq_mask");
        seq_mask.spr_en        = 1'b1;
        seq_mask.bg_en         = 1'b1;
        seq_mask.spr_show_left = 1'b1;
        seq_mask.bg_show_left  = 1'b1;
        seq_mask.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_stat = ppu_ri_ppustatus_sequence::type_id::create("so01_seq_stat");
        seq_stat.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_oamaddr          = ppu_ri_oamaddr_sequence::type_id::create("so01_seq_oamaddr");
        seq_oamaddr.oam_addr = 8'h20;
        seq_oamaddr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_oamdata          = ppu_ri_oamdata_sequence::type_id::create("so01_seq_oamdata");
        seq_oamdata.oam_data = 8'h5A;
        seq_oamdata.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_addr           = ppu_ri_ppuaddr_sequence::type_id::create("so01_seq_addr");
        seq_addr.vram_addr = 14'h2400;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr          = ppu_ri_ppudata_write_sequence::type_id::create("so01_seq_wr");
        seq_wr.ppu_data = 8'hA6;
        seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_rd = ppu_ri_ppudata_read_sequence::type_id::create("so01_seq_rd");
        seq_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE X: OAMDATA read path ($2004 read)
    //--------------------------------------------------------------------------
    protected task tc_oamdata_read_path();
        ppu_ri_oamdata_read_sequence seq_oam_rd;
        print_case_header(
            "SO01B_OAMDATA_READ",
            "Check $2004 read path by driving known spr_ram_din from testbench"
        );
        if (ppu_ri_vif != null) begin
            ppu_ri_vif.spr_ram_din <= 8'h3A;
        end
        seq_oam_rd = ppu_ri_oamdata_read_sequence::type_id::create("so01b_seq_oam_rd");
        seq_oam_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE X: byte_sel multi-write model on $2005/$2006
    //--------------------------------------------------------------------------
    protected task tc_byte_sel_multiwrite();
        ppu_ri_ppuscroll_sequence seq_scroll;
        ppu_ri_ppuaddr_sequence   seq_addr;
        print_case_header(
            "SO01C_BYTESEL_MULTIWRITE",
            "Exercise $2005/$2006 two-write behavior for stateful scoreboard model"
        );
        seq_scroll = ppu_ri_ppuscroll_sequence::type_id::create("so01c_seq_scroll");
        seq_scroll.scroll_x = 8'h12;
        seq_scroll.scroll_y = 8'h34;
        seq_scroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_addr = ppu_ri_ppuaddr_sequence::type_id::create("so01c_seq_addr");
        seq_addr.vram_addr = 14'h2ABC;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE X: buffered read model on $2007
    //--------------------------------------------------------------------------
    protected task tc_ppudata_buffered_read_model();
        ppu_ri_ppuaddr_sequence      seq_addr;
        ppu_ri_ppudata_read_sequence seq_rd0;
        ppu_ri_ppudata_read_sequence seq_rd1;
        ppu_ri_ppudata_read_sequence seq_rd2;
        print_case_header(
            "SO01D_PPUDATA_BUFFERED_READ",
            "Exercise consecutive $2007 reads to validate buffered-read reference modeling"
        );
        preload_vram_window(14'h2100, 14'h2108);
        seq_addr = ppu_ri_ppuaddr_sequence::type_id::create("so01d_seq_addr");
        seq_addr.vram_addr = 14'h2100;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_rd0 = ppu_ri_ppudata_read_sequence::type_id::create("so01d_seq_rd0");
        seq_rd1 = ppu_ri_ppudata_read_sequence::type_id::create("so01d_seq_rd1");
        seq_rd2 = ppu_ri_ppudata_read_sequence::type_id::create("so01d_seq_rd2");
        seq_rd0.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
        seq_rd1.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
        seq_rd2.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE 2: boundary decode 0x3EFF -> 0x3F00
    //--------------------------------------------------------------------------
    protected task tc_boundary_vram_to_pram();
        ppu_ri_ppuctrl_sequence       seq_ctrl;
        ppu_ri_ppuaddr_sequence       seq_addr;
        ppu_ri_ppudata_write_sequence seq_wr0;
        ppu_ri_ppudata_write_sequence seq_wr1;

        print_case_header(
            "SO02_BOUNDARY_3EFF_3F00",
            "Boundary decode: write at 3EFF then next write crosses into 3F00"
        );

        // Chon increment +1.
        seq_ctrl          = ppu_ri_ppuctrl_sequence::type_id::create("so02_seq_ctrl");
        seq_ctrl.nvbl_en  = 1'b0;
        seq_ctrl.spr_h    = 1'b0;
        seq_ctrl.s        = 1'b0;
        seq_ctrl.spr_pt   = 1'b0;
        seq_ctrl.addr_inc = 1'b0;
        seq_ctrl.v        = 1'b0;
        seq_ctrl.h        = 1'b0;
        seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_addr           = ppu_ri_ppuaddr_sequence::type_id::create("so02_seq_addr");
        seq_addr.vram_addr = 14'h3EFF;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr0          = ppu_ri_ppudata_write_sequence::type_id::create("so02_seq_wr0");
        seq_wr0.ppu_data = 8'h11;
        seq_wr0.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr1          = ppu_ri_ppudata_write_sequence::type_id::create("so02_seq_wr1");
        seq_wr1.ppu_data = 8'h22;
        seq_wr1.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE 3: increment mode +32
    //--------------------------------------------------------------------------
    protected task tc_increment_mode_32();
        ppu_ri_ppuctrl_sequence       seq_ctrl;
        ppu_ri_ppuaddr_sequence       seq_addr;
        ppu_ri_ppudata_write_sequence seq_wr0;
        ppu_ri_ppudata_write_sequence seq_wr1;
        ppu_ri_ppudata_read_sequence  seq_rd0;

        print_case_header(
            "SO03_INCREMENT_PLUS32",
            "Enable addr_inc=+32 and run PPUDATA write/read sequence"
        );

        seq_ctrl          = ppu_ri_ppuctrl_sequence::type_id::create("so03_seq_ctrl");
        seq_ctrl.nvbl_en  = 1'b0;
        seq_ctrl.spr_h    = 1'b0;
        seq_ctrl.s        = 1'b0;
        seq_ctrl.spr_pt   = 1'b0;
        seq_ctrl.addr_inc = 1'b1; // +32
        seq_ctrl.v        = 1'b0;
        seq_ctrl.h        = 1'b1;
        seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_addr           = ppu_ri_ppuaddr_sequence::type_id::create("so03_seq_addr");
        seq_addr.vram_addr = 14'h2004;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr0          = ppu_ri_ppudata_write_sequence::type_id::create("so03_seq_wr0");
        seq_wr0.ppu_data = 8'h33;
        seq_wr0.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_wr1          = ppu_ri_ppudata_write_sequence::type_id::create("so03_seq_wr1");
        seq_wr1.ppu_data = 8'h44;
        seq_wr1.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        seq_rd0 = ppu_ri_ppudata_read_sequence::type_id::create("so03_seq_rd0");
        seq_rd0.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

    //--------------------------------------------------------------------------
    // CASE 4: mode switch stress (+1 <-> +32)
    //--------------------------------------------------------------------------
    protected task tc_mode_switch_stress();
        ppu_ri_ppuctrl_sequence       seq_ctrl;
        ppu_ri_ppuaddr_sequence       seq_addr;
        ppu_ri_ppudata_write_sequence seq_wr;
        ppu_ri_ppudata_read_sequence  seq_rd;
        int i;

        print_case_header(
            "SO04_MODE_SWITCH_STRESS",
            "Toggle addr_inc mode continuously while mixing PPUDATA read/write"
        );

        // Dat dia chi goc.
        seq_addr           = ppu_ri_ppuaddr_sequence::type_id::create("so04_seq_addr_init");
        seq_addr.vram_addr = 14'h23C0;
        seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        for (i = 0; i < 24; i++) begin
            // Dao mode lien tuc: chan = +1, le = +32
            seq_ctrl          = ppu_ri_ppuctrl_sequence::type_id::create($sformatf("so04_seq_ctrl_%0d", i));
            seq_ctrl.nvbl_en  = 1'b0;
            seq_ctrl.spr_h    = 1'b0;
            seq_ctrl.s        = 1'b0;
            seq_ctrl.spr_pt   = 1'b0;
            seq_ctrl.addr_inc = i[0];
            seq_ctrl.v        = 1'b0;
            seq_ctrl.h        = 1'b0;
            seq_ctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

            if ((i % 3) == 0) begin
                seq_rd = ppu_ri_ppudata_read_sequence::type_id::create($sformatf("so04_seq_rd_%0d", i));
                seq_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
            end else begin
                seq_wr = ppu_ri_ppudata_write_sequence::type_id::create($sformatf("so04_seq_wr_%0d", i));
                seq_wr.ppu_data = $urandom_range(0, 255);
                seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // CASE 5: random stress
    //--------------------------------------------------------------------------
    protected task tc_random_stress();
        ppu_ri_write_sequence         seq_wr;
        ppu_ri_read_sequence          seq_rd;
        ppu_ri_ppuaddr_sequence       seq_addr;
        ppu_ri_ppuscroll_sequence     seq_scroll;
        ppu_ri_ppudata_write_sequence seq_data_wr;
        ppu_ri_ppudata_read_sequence  seq_data_rd;
        int unsigned i;
        int unsigned op;

        print_case_header(
            "SO05_RANDOM_STRESS",
            $sformatf("Random stress with %0d mixed operations", random_iters)
        );

        for (i = 0; i < random_iters; i++) begin
            op = $urandom_range(0, 5);
            case (op)
                0: begin
                    seq_wr = ppu_ri_write_sequence::type_id::create($sformatf("so04_seq_wr_%0d", i));
                    if (!seq_wr.randomize()) `uvm_error("SO04", "randomize seq_wr failed")
                    seq_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
                1: begin
                    seq_rd = ppu_ri_read_sequence::type_id::create($sformatf("so04_seq_rd_%0d", i));
                    if (!seq_rd.randomize()) `uvm_error("SO04", "randomize seq_rd failed")
                    seq_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
                2: begin
                    seq_addr = ppu_ri_ppuaddr_sequence::type_id::create($sformatf("so04_seq_addr_%0d", i));
                    if (!seq_addr.randomize()) `uvm_error("SO04", "randomize seq_addr failed")
                    seq_addr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
                3: begin
                    seq_scroll = ppu_ri_ppuscroll_sequence::type_id::create($sformatf("so04_seq_scroll_%0d", i));
                    if (!seq_scroll.randomize()) `uvm_error("SO04", "randomize seq_scroll failed")
                    seq_scroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
                4: begin
                    seq_data_wr = ppu_ri_ppudata_write_sequence::type_id::create($sformatf("so04_seq_data_wr_%0d", i));
                    if (!seq_data_wr.randomize()) `uvm_error("SO04", "randomize seq_data_wr failed")
                    seq_data_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
                default: begin
                    seq_data_rd = ppu_ri_ppudata_read_sequence::type_id::create($sformatf("so04_seq_data_rd_%0d", i));
                    seq_data_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
                end
            endcase
        end
    endtask

endclass

`endif
