`ifndef PPU_RI_FULL_REGRESSION_TEST_SV
`define PPU_RI_FULL_REGRESSION_TEST_SV

// ===========================================================================
// ppu_ri_full_regression_test
// Aggregated master regression for PPU Register Interface ($2000-$2007).
//
// Strategy:
//  1) Reuse the broader signoff-style directed/random RI scenarios.
//  2) Keep explicit scroll stress in the full regression so it stays a true
//     block-level "all major cases" run instead of only a baseline smoke set.
// ===========================================================================
class ppu_ri_full_regression_test extends ppu_ri_signoff_test;
    `uvm_component_utils(ppu_ri_full_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        // Keep full regression broad, but slightly lighter than signoff by default.
        random_iters = 80;
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting PPU RI full regression");
        `uvm_info("TEST", ">>> START: ppu_ri_full_regression_test <<<", UVM_NONE)

        // Let tb_top release power-up reset first.
        #220ns;

        // Preload a readable VRAM window so random/read-side checks are meaningful.
        preload_vram_window(14'h2000, 14'h20FF);

        // Reset and recovery verification.
        tc_initial_reset_observe();
        tc_random_reset_stress();

        // Directed RI register-path coverage.
        tc_directed_baseline();
        tc_oamdata_read_path();
        tc_byte_sel_multiwrite();
        tc_ppudata_buffered_read_model();
        tc_boundary_vram_to_pram();
        tc_increment_mode_32();
        tc_mode_switch_stress();

        // Explicit scroll sequence retained from the original full regression.
        tc_scroll_stress_test();

        // Mixed random traffic across RI register set.
        tc_random_stress();

        #300ns;
        `uvm_info("TEST", ">>> DONE: ppu_ri_full_regression_test <<<", UVM_NONE)
        phase.drop_objection(this, "Finished PPU RI full regression");
    endtask

    protected task tc_scroll_stress_test();
        ppu_ri_scroll_sequence seq_scroll;

        print_case_header(
            "FR08_SCROLL_STRESS",
            "Random mixed writes to $2000, $2005, $2006 for scroll verification"
        );

        seq_scroll = ppu_ri_scroll_sequence::type_id::create("tc06_seq_scroll");
        // Slightly broader than the legacy full regression, still lighter than signoff stress.
        if (!$value$plusargs("PPU_RI_RANDOM_ITERS=%d", seq_scroll.num_iters)) begin
            seq_scroll.num_iters = 60; 
        end
        seq_scroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);
    endtask

endclass

`endif
