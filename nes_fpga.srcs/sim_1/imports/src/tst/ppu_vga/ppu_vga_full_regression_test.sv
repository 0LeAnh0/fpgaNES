class ppu_vga_full_regression_test extends ppu_vga_base_test;
  `uvm_component_utils(ppu_vga_full_regression_test)

  function new(string name = "ppu_vga_full_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    tc_reset();
    tc_palette_visible_area();
    tc_border_color();
    tc_vblank_timing();
    `uvm_info("PPU_VGA_REG", "All PPU VGA regression scenarios completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
