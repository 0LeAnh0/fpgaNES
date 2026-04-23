`ifndef PPU_BG_SANITY_TEST_SV
`define PPU_BG_SANITY_TEST_SV

class ppu_bg_sanity_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_sanity_test)

  function new(string name = "ppu_bg_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_sanity_sequence seq;
    
    phase.raise_objection(this);
    
    seq = ppu_bg_sanity_sequence::type_id::create("seq");
    seq.start(env.master_agent.sequencer);
    
    #100ns;
    
    phase.drop_objection(this);
  endtask

endclass

`endif
