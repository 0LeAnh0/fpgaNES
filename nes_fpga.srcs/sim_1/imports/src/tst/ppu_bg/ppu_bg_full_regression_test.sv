`ifndef PPU_BG_FULL_REGRESSION_TEST_SV
`define PPU_BG_FULL_REGRESSION_TEST_SV

class ppu_bg_full_regression_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_full_regression_test)

  function new(string name = "ppu_bg_full_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_ri_update_seq ri_seq;
    ppu_bg_render_fetch_seq render_seq;
    ppu_bg_stress_scroll_seq scroll_seq;
    ppu_bg_full_scanline_seq scan_seq;
    ppu_bg_full_scanline_seq pixel_scan_seq;
    ppu_bg_cov_target_seq cov_seq;
    
    phase.raise_objection(this);
    
    // 0. RESET VERIFICATION (Synchronize with RAM/RI standards)
    tc_initial_reset_observe();
    tc_random_reset_stress();

    `uvm_info("REGRESSION", "--- 1. RUNNING RI UPDATE ---", UVM_LOW)
    ri_seq = ppu_bg_ri_update_seq::type_id::create("ri_seq");
    ri_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 2. RUNNING RENDER FETCH ---", UVM_LOW)
    render_seq = ppu_bg_render_fetch_seq::type_id::create("render_seq");
    render_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 3. RUNNING PIXEL ACCURACY SCAN (2 LINES) ---", UVM_LOW)
    pixel_scan_seq = ppu_bg_full_scanline_seq::type_id::create("pixel_scan_seq");
    pixel_scan_seq.num_scanlines = 2;
    pixel_scan_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 4. RUNNING COMPLEX SCROLL STRESS ---", UVM_LOW)
    scroll_seq = ppu_bg_stress_scroll_seq::type_id::create("scroll_seq");
    scroll_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 5. RUNNING FULL SCANLINE (3 LINES) ---", UVM_LOW)
    scan_seq = ppu_bg_full_scanline_seq::type_id::create("scan_seq");
    scan_seq.num_scanlines = 3;
    scan_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 6. RUNNING TARGETED COVERAGE CORNERS ---", UVM_LOW)
    cov_seq = ppu_bg_cov_target_seq::type_id::create("cov_seq");
    cov_seq.start(env.master_agent.sequencer);
    #200ns;

    `uvm_info("REGRESSION", "--- 7. POST-REGRESSION STABILITY CHECK ---", UVM_LOW)
    render_seq = ppu_bg_render_fetch_seq::type_id::create("render_seq_final");
    render_seq.start(env.master_agent.sequencer);

    #200ns;
    `uvm_info("REGRESSION", "ALL TESTS COMPLETED SUCCESSFULLY", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass

`endif
