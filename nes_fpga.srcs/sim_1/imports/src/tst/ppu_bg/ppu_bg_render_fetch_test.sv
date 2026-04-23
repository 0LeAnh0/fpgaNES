`ifndef PPU_BG_RENDER_FETCH_TEST_SV
`define PPU_BG_RENDER_FETCH_TEST_SV

class ppu_bg_render_fetch_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_render_fetch_test)

  function new(string name = "ppu_bg_render_fetch_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_render_fetch_seq seq;
    phase.raise_objection(this);
    
    // Wait for initial TB reset to complete
    wait(tb_ctrl_vif.rst_req == 1'b0);
    #100ns;

    seq = ppu_bg_render_fetch_seq::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

`endif
