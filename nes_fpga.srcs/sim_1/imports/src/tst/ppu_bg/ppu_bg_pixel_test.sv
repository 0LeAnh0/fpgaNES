`ifndef PPU_BG_PIXEL_TEST_SV
`define PPU_BG_PIXEL_TEST_SV

class ppu_bg_pixel_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_pixel_test)

  function new(string name = "ppu_bg_pixel_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_ri_update_seq    ri_seq;
    ppu_bg_full_scanline_seq scan_seq;

    phase.raise_objection(this);

    tc_initial_reset_observe();

    ri_seq = ppu_bg_ri_update_seq::type_id::create("ri_seq");
    ri_seq.start(env.master_agent.sequencer);

    scan_seq = ppu_bg_full_scanline_seq::type_id::create("scan_seq");
    scan_seq.num_scanlines = 2;
    scan_seq.start(env.master_agent.sequencer);

    #100ns;
    phase.drop_objection(this);
  endtask
endclass

`endif
