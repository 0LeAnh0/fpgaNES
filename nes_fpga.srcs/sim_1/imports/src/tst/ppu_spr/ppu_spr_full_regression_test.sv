`ifndef PPU_SPR_FULL_REGRESSION_TEST_SV
`define PPU_SPR_FULL_REGRESSION_TEST_SV

class ppu_spr_full_regression_test extends ppu_spr_base_test;
  `uvm_component_utils(ppu_spr_full_regression_test)

  function new(string name = "ppu_spr_full_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_spr_oam_seq      oam_seq      = ppu_spr_oam_seq::type_id::create("oam_seq");
    ppu_spr_eval_seq     eval_seq     = ppu_spr_eval_seq::type_id::create("eval_seq");
    ppu_spr_overflow_seq overflow_seq_8x8  = ppu_spr_overflow_seq::type_id::create("overflow_seq_8x8");
    ppu_spr_overflow_seq overflow_seq_8x16 = ppu_spr_overflow_seq::type_id::create("overflow_seq_8x16");
    ppu_spr_force_seq    force_seq    = ppu_spr_force_seq::type_id::create("force_seq");
    ppu_spr_render_seq   render_seq   = ppu_spr_render_seq::type_id::create("render_seq");
    ppu_spr_complex_seq  complex_seq  = ppu_spr_complex_seq::type_id::create("complex_seq");
    ppu_spr_background_render_seq bg_seq = ppu_spr_background_render_seq::type_id::create("bg_seq");
    ppu_spr_full_frame_seq full_frame_seq = ppu_spr_full_frame_seq::type_id::create("full_frame_seq");

    phase.raise_objection(this);

    // 1. Initial Reset
    reset_dut();

    // 2. OAM Stress - Initialize OAM without active rendering
    oam_seq.start(env.master_agent.sequencer);

    // 3. Eval and overflow coverage
    eval_seq.start(env.master_agent.sequencer);
    overflow_seq_8x8.spr_h_mode  = 1'b0;
    overflow_seq_8x16.spr_h_mode = 1'b1;
    overflow_seq_8x8.start(env.master_agent.sequencer);
    overflow_seq_8x16.start(env.master_agent.sequencer);

    // 4. Dedicated random reset stress with live background traffic
    fork
      bg_seq.start(env.master_agent.sequencer);
      random_reset_stress(5, 100, 1000);
    join_any
    disable fork;

    // Re-sync to a known clean state after random reset pulses.
    reset_dut();

    // 5. Render, force and complex tests
    render_seq.start(env.master_agent.sequencer);
    force_seq.start(env.master_agent.sequencer);
    reset_dut();
    complex_seq.start(env.master_agent.sequencer);

    // 6. Full-frame walk to verify frame-boundary behavior such as overflow clear.
    full_frame_seq.start(env.master_agent.sequencer);

    #100ns;
    phase.drop_objection(this);
  endtask

endclass

`endif
