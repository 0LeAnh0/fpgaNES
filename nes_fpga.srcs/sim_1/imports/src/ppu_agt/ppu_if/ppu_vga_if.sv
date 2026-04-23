`ifndef PPU_VGA_IF_SV
`define PPU_VGA_IF_SV

interface ppu_vga_if(input logic clk_in, input logic rst_in);
  logic [5:0] sys_palette_idx_in;

  logic       hsync_out;
  logic       vsync_out;
  logic [2:0] r_out;
  logic [2:0] g_out;
  logic [1:0] b_out;
  logic [9:0] nes_x_out;
  logic [9:0] nes_y_out;
  logic [9:0] nes_y_next_out;
  logic       pix_pulse_out;
  logic       vblank_out;

  // Internal sniffed timing signals from DUT for cycle-accurate checking.
  logic       sync_en;
  logic [9:0] sync_x;
  logic [9:0] sync_y;
  logic [9:0] sync_x_next;
  logic [9:0] sync_y_next;

  function automatic int unsigned classify_area();
    if (!sync_en)
      return 0;
    if (nes_y_out < 10'd8)
      return 1;
    if (nes_y_out >= 10'd232)
      return 4;
    if (nes_x_out >= 10'd256)
      return 3;
    return 2;
  endfunction

  covergroup cg_vga_gui @(posedge clk_in);
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;

    cp_area: coverpoint classify_area() {
      bins blank_region  = {0};
      bins top_border    = {1};
      bins visible_area  = {2};
      bins right_border  = {3};
      bins bottom_border = {4};
    }

    cp_palette_visible: coverpoint sys_palette_idx_in iff (classify_area() == 2) {
      bins all_idx[] = {[0:63]};
    }

    cp_vblank: coverpoint vblank_out {
      bins inactive = {0};
      bins active   = {1};
    }

    cp_pix_pulse: coverpoint pix_pulse_out {
      bins low  = {0};
      bins high = {1};
    }
  endgroup

  clocking vga_cb @(posedge clk_in);
    default input #1step output #1;
    input rst_in;
    input hsync_out, vsync_out, r_out, g_out, b_out;
    input nes_x_out, nes_y_out, nes_y_next_out, pix_pulse_out, vblank_out;
    input sync_en, sync_x, sync_y, sync_x_next, sync_y_next;
    output sys_palette_idx_in;
  endclocking

  clocking mon_cb @(posedge clk_in);
    default input #1step output #1;
    input rst_in;
    input sys_palette_idx_in;
    input hsync_out, vsync_out, r_out, g_out, b_out;
    input nes_x_out, nes_y_out, nes_y_next_out, pix_pulse_out, vblank_out;
    input sync_en, sync_x, sync_y, sync_x_next, sync_y_next;
  endclocking

  modport MASTER (
    clocking vga_cb,
    output sys_palette_idx_in
  );

  modport MONITOR (
    clocking mon_cb,
    input rst_in,
    input sys_palette_idx_in,
    input hsync_out, input vsync_out,
    input r_out, input g_out, input b_out,
    input nes_x_out, input nes_y_out, input nes_y_next_out,
    input pix_pulse_out, input vblank_out,
    input sync_en, input sync_x, input sync_y, input sync_x_next, input sync_y_next
  );

endinterface

`endif
