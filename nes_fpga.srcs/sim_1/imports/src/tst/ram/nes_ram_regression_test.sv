`ifndef NES_RAM_REGRESSION_TEST_SV
`define NES_RAM_REGRESSION_TEST_SV

// ===========================================================================
// nes_ram_regression_test
// Bai test tong hop cho WRAM va VRAM (duoc doi ten tu nes_wram_vram_test).
// ===========================================================================
class nes_ram_regression_test extends nes_ram_base_test;
    `uvm_component_utils(nes_ram_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Tang muc do hien thi log de theo doi tien trinh test chi tiet
        uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // Khai bao cac sequences moi
        test_wram_mirror_seq           mirror_seq;
        test_ram_mirror_alias_seq      alias_seq;
        test_ram_data_pattern_seq      pattern_seq;
        test_ram_full_sweep_seq        sweep_seq;
        test_ram_boundary_walk_seq     boundary_seq;
        test_wram_zero_page_stack_seq  stress_seq;
        
        phase.raise_objection(this, "Starting Comprehensive NES Memory Test");
        
        // Dam bao he thong da thoat khoi trang thai Reset
        #150ns;

        tc_initial_reset_observe();
        tc_random_reset_pulses();
        
        // --- PHAN 1: TEST WRAM (CPU RAM) ---
        print_case_header("RAM_TC01_WRAM_FULL", "WRAM mirroring + pattern + full sweep + stress");
        `uvm_info("TEST", ">>> STARTING WRAM VERIFICATION <<<", UVM_NONE)
        
        // 1.1. Test Mirroring (0x0000 -> 0x1FFF)
        print_case_header("RAM_TC01_1_WRAM_MIRROR", "WRAM mirror check: base 0x0000-0x07FF reflected to 0x1FFF");
        mirror_seq = test_wram_mirror_seq::type_id::create("mirror_seq");
        mirror_seq.start(m_env.m_wram_agent.sequencer);

        // 1.2. Test Data Pattern (Walking 1s, 0x55, 0xAA...)
        print_case_header("RAM_TC01_2_WRAM_PATTERN", "WRAM data-pattern check: walking-1 and stripe patterns");
        pattern_seq = test_ram_data_pattern_seq::type_id::create("pattern_seq");
        pattern_seq.start(m_env.m_wram_agent.sequencer);

        // 1.2b. Hit boundaries and alias edges explicitly
        print_case_header("RAM_TC01_2B_WRAM_BOUNDARY", "WRAM boundary walk across zero-page, stack, and mirror edges");
        boundary_seq = test_ram_boundary_walk_seq::type_id::create("boundary_seq");
        boundary_seq.start(m_env.m_wram_agent.sequencer);

        // 1.3. Test Full Sweep (Ghi het 2KB roi moi doc lai)
        print_case_header("RAM_TC01_3_WRAM_SWEEP", "WRAM full sweep: write all then read all");
        sweep_seq = test_ram_full_sweep_seq::type_id::create("sweep_seq");
        sweep_seq.start(m_env.m_wram_agent.sequencer);

        // 1.4. Test Stress (Zero-Page & Stack)
        print_case_header("RAM_TC01_4_WRAM_STRESS", "WRAM stress on zero-page and stack regions");
        stress_seq = test_wram_zero_page_stack_seq::type_id::create("stress_seq");
        stress_seq.start(m_env.m_wram_agent.sequencer);

        // --- PHAN 2: TEST VRAM (PPU Nametables) ---
        print_case_header("RAM_TC02_VRAM_FULL", "VRAM pattern + full sweep with recovery after random reset");
        `uvm_info("TEST", ">>> STARTING VRAM VERIFICATION <<<", UVM_NONE)

        // 2.1. Test Data Pattern cho VRAM
        print_case_header("RAM_TC02_1_VRAM_PATTERN", "VRAM data-pattern check on nametable memory");
        pattern_seq = test_ram_data_pattern_seq::type_id::create("pattern_vram_seq");
        pattern_seq.start(m_env.m_vram_agent.sequencer);

        // 2.1b. Alias/mirror traffic for VRAM direct test interface
        print_case_header("RAM_TC02_1B_VRAM_ALIAS", "VRAM alias check across 2KB mirrored address windows");
        alias_seq = test_ram_mirror_alias_seq::type_id::create("alias_vram_seq");
        alias_seq.start(m_env.m_vram_agent.sequencer);

        // 2.1c. Boundary walk to hit explicit VRAM edge bins
        print_case_header("RAM_TC02_1C_VRAM_BOUNDARY", "VRAM boundary walk across quadrants and edge addresses");
        boundary_seq = test_ram_boundary_walk_seq::type_id::create("boundary_vram_seq");
        boundary_seq.start(m_env.m_vram_agent.sequencer);

        // 2.2. Test Full Sweep cho VRAM
        print_case_header("RAM_TC02_2_VRAM_SWEEP", "VRAM full sweep: write all then read all");
        sweep_seq = test_ram_full_sweep_seq::type_id::create("sweep_vram_seq");
        sweep_seq.start(m_env.m_vram_agent.sequencer);
        
        // Cho mot khoang thoi gian ngan de monitor thu thap het du lieu cuoi cung
        #100ns;
        
        `uvm_info("TEST", ">>> ALL MEMORY TESTS COMPLETED <<<", UVM_NONE)
        phase.drop_objection(this, "Finished Comprehensive NES Memory Test");
    endtask

    // Reset ban dau: check reset pulse va kha nang recovery.
    protected task tc_initial_reset_observe();
        print_case_header("RAM_TC00_INITIAL_RESET", "Assert reset once, release, then continue normal RAM tests");
        apply_reset_pulse(6);
        check_ram_reset_state("RAM_TC00_INITIAL_RESET");
    endtask

    // Random reset nhe truoc workload chinh de test khoi phuc.
    protected task tc_random_reset_pulses();
        int i;
        int hold_cycles;
        print_case_header("RAM_TC00B_RANDOM_RESET", "Inject few random reset pulses before main functional traffic");
        for (i = 0; i < 3; i++) begin
            int unsigned wait_ns;
            wait_ns = 20 + $urandom_range(0, 80);
            `uvm_info("NES_RST", $sformatf("[RANDOM_RST_%0d] wait=%0dns before assert", i, wait_ns), UVM_NONE)
            #(wait_ns*1ns);
            hold_cycles = $urandom_range(2, 8);
            `uvm_info("NES_RST", $sformatf("[RANDOM_RST_%0d] hold_cycles=%0d", i, hold_cycles), UVM_NONE)
            apply_reset_pulse(hold_cycles);
            check_ram_reset_state($sformatf("RAM_TC00B_RANDOM_RESET_%0d", i));
        end
    endtask

endclass

`endif
