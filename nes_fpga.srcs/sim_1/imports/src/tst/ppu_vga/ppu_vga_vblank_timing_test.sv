class ppu_vga_vblank_timing_test extends ppu_vga_base_test;
  `uvm_component_utils(ppu_vga_vblank_timing_test)

  function new(string name = "ppu_vga_vblank_timing_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    tc_vblank_timing();
    phase.drop_objection(this);
  endtask
endclass
