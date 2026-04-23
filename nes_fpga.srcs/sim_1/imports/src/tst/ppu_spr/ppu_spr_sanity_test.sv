`ifndef PPU_SPR_SANITY_TEST_SV
`define PPU_SPR_SANITY_TEST_SV

class ppu_spr_sanity_test extends ppu_spr_base_test;
  `uvm_component_utils(ppu_spr_sanity_test)

  function new(string name = "ppu_spr_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_spr_sanity_seq seq;
    seq = ppu_spr_sanity_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.master_agent.sequencer);
    phase.drop_objection(this);
  endtask

endclass

`endif
