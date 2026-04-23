`ifndef PPU_BG_COMPLEX_SCROLL_TEST_SV
`define PPU_BG_COMPLEX_SCROLL_TEST_SV

class ppu_bg_complex_scroll_test extends ppu_bg_base_test;
  `uvm_component_utils(ppu_bg_complex_scroll_test)

  function new(string name = "ppu_bg_complex_scroll_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    ppu_bg_full_scanline_seq scan_seq;
    ppu_bg_stress_scroll_seq scroll_seq;

    phase.raise_objection(this);
    
    // Wait for reset
    wait(tb_ctrl_vif.rst_req == 1'b0);
    #100ns;

    `uvm_info("TEST", "--- Starting Stress Scroll Sequence ---", UVM_LOW)
    scroll_seq = ppu_bg_stress_scroll_seq::type_id::create("scroll_seq");
    scroll_seq.start(env.master_agent.sequencer);

    `uvm_info("TEST", "--- Starting Full Scanline Sequence (3 lines) ---", UVM_LOW)
    scan_seq = ppu_bg_full_scanline_seq::type_id::create("scan_seq");
    scan_seq.num_scanlines = 3;
    scan_seq.start(env.master_agent.sequencer);

    #500ns;
    phase.drop_objection(this);
  endtask
endclass

`endif
