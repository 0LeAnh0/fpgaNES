`ifndef PPU_BG_RANDOM_RESET_TEST_SV
`define PPU_BG_RANDOM_RESET_TEST_SV

class ppu_bg_random_reset_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_random_reset_test)

  function new(string name = "ppu_bg_random_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_render_fetch_seq seq;
    phase.raise_objection(this);
    
    // Initial reset wait
    wait(tb_ctrl_vif.rst_req == 1'b0);
    #100ns;

    // Run fetching sequence and inject random reset in parallel
    fork
      begin
        seq = ppu_bg_render_fetch_seq::type_id::create("seq");
        seq.start(env.master_agent.sequencer);
      end
      begin
        // Use the new task provided in tb_ctrl_if
        tb_ctrl_vif.random_reset(50, 200, 50);
        `uvm_info("TEST", "Random Reset triggered via task!", UVM_LOW)
      end
    join
    
    #100ns;
    // Optionally run sequence again after random reset cleared
    seq = ppu_bg_render_fetch_seq::type_id::create("seq_after_rst");
    seq.start(env.master_agent.sequencer);
    
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

`endif
