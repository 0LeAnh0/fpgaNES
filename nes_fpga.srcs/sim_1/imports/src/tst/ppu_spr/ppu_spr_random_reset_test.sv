`ifndef PPU_SPR_RANDOM_RESET_TEST_SV
`define PPU_SPR_RANDOM_RESET_TEST_SV

class ppu_spr_random_reset_test extends ppu_spr_base_test;
  `uvm_component_utils(ppu_spr_random_reset_test)

  function new(string name = "ppu_spr_random_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_spr_background_render_seq bg_seq = ppu_spr_background_render_seq::type_id::create("bg_seq");

    phase.raise_objection(this);

    `uvm_info("RESET_TEST", "Starting Random Reset Stress Test...", UVM_LOW)

    // Run background traffic
    fork
      bg_seq.start(env.master_agent.sequencer);
      random_reset_stress(5, 100, 1000);
    join_any
    disable fork;

    `uvm_info("RESET_TEST", "Random Reset Stress Test Completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif
