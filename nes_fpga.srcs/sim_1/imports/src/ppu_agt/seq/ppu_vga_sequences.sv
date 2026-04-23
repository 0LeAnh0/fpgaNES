`ifndef PPU_VGA_SEQUENCES_SV
`define PPU_VGA_SEQUENCES_SV

class ppu_vga_base_seq extends uvm_sequence #(ppu_vga_sequence_item);
  `uvm_object_utils(ppu_vga_base_seq)

  function new(string name = "ppu_vga_base_seq");
    super.new(name);
  endfunction

  protected task drive_palette_idx(bit [5:0] palette_idx, int unsigned cycles = 1);
    repeat (cycles) begin
      `uvm_create(req)
      req.sys_palette_idx_in = palette_idx;
      `uvm_send(req)
    end
  endtask
endclass

class ppu_vga_hold_palette_seq extends ppu_vga_base_seq;
  `uvm_object_utils(ppu_vga_hold_palette_seq)

  bit [5:0] palette_idx;
  int unsigned cycles;

  function new(string name = "ppu_vga_hold_palette_seq");
    super.new(name);
    palette_idx = 6'h00;
    cycles      = 1;
  endfunction

  virtual task body();
    drive_palette_idx(palette_idx, cycles);
  endtask
endclass

class ppu_vga_palette_sweep_seq extends ppu_vga_base_seq;
  `uvm_object_utils(ppu_vga_palette_sweep_seq)

  bit [5:0] start_idx;
  bit [5:0] end_idx;
  int unsigned cycles_per_entry;

  function new(string name = "ppu_vga_palette_sweep_seq");
    super.new(name);
    start_idx        = 6'h00;
    end_idx          = 6'h3f;
    cycles_per_entry = 2;
  endfunction

  virtual task body();
    for (int idx = start_idx; idx <= end_idx; idx++) begin
      drive_palette_idx(idx[5:0], cycles_per_entry);
    end
  endtask
endclass

class ppu_vga_random_palette_seq extends ppu_vga_base_seq;
  `uvm_object_utils(ppu_vga_random_palette_seq)

  int unsigned cycles;

  function new(string name = "ppu_vga_random_palette_seq");
    super.new(name);
    cycles = 16;
  endfunction

  virtual task body();
    repeat (cycles) begin
      `uvm_create(req)
      req.sys_palette_idx_in = $urandom_range(0, 63);
      `uvm_send(req)
    end
  endtask
endclass

`endif
