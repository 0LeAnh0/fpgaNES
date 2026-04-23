class ppu_vga_palette_visible_area_test extends ppu_vga_base_test;
  `uvm_component_utils(ppu_vga_palette_visible_area_test)

  function new(string name = "ppu_vga_palette_visible_area_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    tc_palette_visible_area();
    phase.drop_objection(this);
  endtask
endclass
