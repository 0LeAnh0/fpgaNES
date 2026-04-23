`ifndef PPU_VGA_SCOREBOARD_SV
`define PPU_VGA_SCOREBOARD_SV

class ppu_vga_scoreboard extends uvm_subscriber #(ppu_vga_sequence_item);
  `uvm_component_utils(ppu_vga_scoreboard)

  bit [7:0] exp_rgb_pipe;
  bit       exp_hsync_pipe;
  bit       exp_vsync_pipe;
  bit       exp_vblank_pipe;

  int unsigned checks_passed;
  int unsigned checks_failed;

  function new(string name = "ppu_vga_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    reset_model();
  endfunction

  protected function void reset_model();
    exp_rgb_pipe    = 8'h00;
    exp_hsync_pipe  = 1'b0;
    exp_vsync_pipe  = 1'b0;
    exp_vblank_pipe = 1'b0;
    checks_passed   = 0;
    checks_failed   = 0;
  endfunction

  protected function bit [7:0] palette_to_rgb(bit [5:0] idx);
    case (idx)
      6'h00: palette_to_rgb = { 3'h3, 3'h3, 2'h1 };
      6'h01: palette_to_rgb = { 3'h1, 3'h0, 2'h2 };
      6'h02: palette_to_rgb = { 3'h0, 3'h0, 2'h2 };
      6'h03: palette_to_rgb = { 3'h2, 3'h0, 2'h2 };
      6'h04: palette_to_rgb = { 3'h4, 3'h0, 2'h1 };
      6'h05: palette_to_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h06: palette_to_rgb = { 3'h5, 3'h0, 2'h0 };
      6'h07: palette_to_rgb = { 3'h3, 3'h0, 2'h0 };
      6'h08: palette_to_rgb = { 3'h2, 3'h1, 2'h0 };
      6'h09: palette_to_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0a: palette_to_rgb = { 3'h0, 3'h2, 2'h0 };
      6'h0b: palette_to_rgb = { 3'h0, 3'h1, 2'h0 };
      6'h0c: palette_to_rgb = { 3'h0, 3'h1, 2'h1 };
      6'h0d: palette_to_rgb = 8'h00;
      6'h0e: palette_to_rgb = 8'h00;
      6'h0f: palette_to_rgb = 8'h00;
      6'h10: palette_to_rgb = { 3'h5, 3'h5, 2'h2 };
      6'h11: palette_to_rgb = { 3'h0, 3'h3, 2'h3 };
      6'h12: palette_to_rgb = { 3'h1, 3'h1, 2'h3 };
      6'h13: palette_to_rgb = { 3'h4, 3'h0, 2'h3 };
      6'h14: palette_to_rgb = { 3'h5, 3'h0, 2'h2 };
      6'h15: palette_to_rgb = { 3'h7, 3'h0, 2'h1 };
      6'h16: palette_to_rgb = { 3'h6, 3'h1, 2'h0 };
      6'h17: palette_to_rgb = { 3'h6, 3'h2, 2'h0 };
      6'h18: palette_to_rgb = { 3'h4, 3'h3, 2'h0 };
      6'h19: palette_to_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1a: palette_to_rgb = { 3'h0, 3'h5, 2'h0 };
      6'h1b: palette_to_rgb = { 3'h0, 3'h4, 2'h0 };
      6'h1c: palette_to_rgb = { 3'h0, 3'h4, 2'h2 };
      6'h1d: palette_to_rgb = 8'h00;
      6'h1e: palette_to_rgb = 8'h00;
      6'h1f: palette_to_rgb = 8'h00;
      6'h20: palette_to_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h21: palette_to_rgb = { 3'h1, 3'h5, 2'h3 };
      6'h22: palette_to_rgb = { 3'h2, 3'h4, 2'h3 };
      6'h23: palette_to_rgb = { 3'h5, 3'h4, 2'h3 };
      6'h24: palette_to_rgb = { 3'h7, 3'h3, 2'h3 };
      6'h25: palette_to_rgb = { 3'h7, 3'h3, 2'h2 };
      6'h26: palette_to_rgb = { 3'h7, 3'h3, 2'h1 };
      6'h27: palette_to_rgb = { 3'h7, 3'h4, 2'h0 };
      6'h28: palette_to_rgb = { 3'h7, 3'h5, 2'h0 };
      6'h29: palette_to_rgb = { 3'h4, 3'h6, 2'h0 };
      6'h2a: palette_to_rgb = { 3'h2, 3'h6, 2'h1 };
      6'h2b: palette_to_rgb = { 3'h2, 3'h7, 2'h2 };
      6'h2c: palette_to_rgb = { 3'h0, 3'h7, 2'h3 };
      6'h2d: palette_to_rgb = 8'h00;
      6'h2e: palette_to_rgb = 8'h00;
      6'h2f: palette_to_rgb = 8'h00;
      6'h30: palette_to_rgb = { 3'h7, 3'h7, 2'h3 };
      6'h31: palette_to_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h32: palette_to_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h33: palette_to_rgb = { 3'h6, 3'h6, 2'h3 };
      6'h34: palette_to_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h35: palette_to_rgb = { 3'h7, 3'h6, 2'h3 };
      6'h36: palette_to_rgb = { 3'h7, 3'h5, 2'h2 };
      6'h37: palette_to_rgb = { 3'h7, 3'h6, 2'h2 };
      6'h38: palette_to_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h39: palette_to_rgb = { 3'h7, 3'h7, 2'h2 };
      6'h3a: palette_to_rgb = { 3'h5, 3'h7, 2'h2 };
      6'h3b: palette_to_rgb = { 3'h5, 3'h7, 2'h3 };
      6'h3c: palette_to_rgb = { 3'h4, 3'h7, 2'h3 };
      6'h3d: palette_to_rgb = 8'h00;
      6'h3e: palette_to_rgb = 8'h00;
      6'h3f: palette_to_rgb = 8'h00;
      default: palette_to_rgb = 8'h00;
    endcase
  endfunction

  protected function bit [9:0] calc_nes_x(bit [9:0] sync_x);
    bit [9:0] tmp;
    tmp = sync_x - 10'h040;
    calc_nes_x = tmp >> 1;
  endfunction

  protected function bit [9:0] calc_nes_y(bit [9:0] sync_y);
    calc_nes_y = sync_y >> 1;
  endfunction

  protected function bit calc_hsync(bit [9:0] sync_x);
    calc_hsync = (sync_x >= 10'd656) && (sync_x < 10'd752);
  endfunction

  protected function bit calc_vsync(bit [9:0] sync_y);
    calc_vsync = (sync_y >= 10'd490) && (sync_y < 10'd492);
  endfunction

  protected function bit is_border(ppu_vga_sequence_item t);
    bit [9:0] nes_x;
    bit [9:0] nes_y;
    nes_x = calc_nes_x(t.sync_x);
    nes_y = calc_nes_y(t.sync_y);
    is_border = (nes_x >= 10'd256) || (nes_y < 10'd8) || (nes_y >= 10'd232);
  endfunction

  protected function bit [7:0] calc_d_rgb(ppu_vga_sequence_item t);
    if (!t.sync_en)
      calc_d_rgb = 8'h00;
    else if (is_border(t))
      calc_d_rgb = 8'h49;
    else
      calc_d_rgb = palette_to_rgb(t.sys_palette_idx_in);
  endfunction

  protected function bit calc_next_vblank(ppu_vga_sequence_item t);
    if ((t.sync_x == 10'd730) && (t.sync_y == 10'd477))
      calc_next_vblank = 1'b1;
    else if ((t.sync_x == 10'd64) && (t.sync_y == 10'd519))
      calc_next_vblank = 1'b0;
    else
      calc_next_vblank = t.vblank_out;
  endfunction

  protected function void check_bit(string id, string msg, bit exp, bit act);
    if (act !== exp) begin
      checks_failed++;
      `uvm_error(id, {msg, $sformatf(" exp=%0b act=%0b", exp, act)})
    end else begin
      checks_passed++;
    end
  endfunction

  protected function void check_vec(string id, string msg, bit [31:0] exp, bit [31:0] act);
    if (act !== exp) begin
      checks_failed++;
      `uvm_error(id, {msg, $sformatf(" exp=%0h act=%0h", exp, act)})
    end else begin
      checks_passed++;
    end
  endfunction

  virtual function void write(ppu_vga_sequence_item t);
    bit [7:0] actual_rgb;
    bit [7:0] exp_rgb_now;
    bit       exp_vblank_now;
    bit [9:0] exp_nes_x;
    bit [9:0] exp_nes_y;
    bit [9:0] exp_nes_x_next;
    bit [9:0] exp_nes_y_next;
    bit       exp_pix_pulse;

    actual_rgb    = {t.r_out, t.g_out, t.b_out};
    exp_rgb_now   = t.rst_in ? 8'h00 : exp_rgb_pipe;
    exp_vblank_now = t.rst_in ? 1'b0 : exp_vblank_pipe;

    exp_nes_x      = calc_nes_x(t.sync_x);
    exp_nes_y      = calc_nes_y(t.sync_y);
    exp_nes_x_next = calc_nes_x(t.sync_x_next);
    exp_nes_y_next = calc_nes_y(t.sync_y_next);
    exp_pix_pulse  = (exp_nes_x_next != exp_nes_x);

    check_bit("VGA_HSYNC_MISMATCH",
      $sformatf("HSYNC mismatch at sync=(%0d,%0d)", t.sync_x, t.sync_y),
      exp_hsync_pipe, t.hsync_out);
    check_bit("VGA_VSYNC_MISMATCH",
      $sformatf("VSYNC mismatch at sync=(%0d,%0d)", t.sync_x, t.sync_y),
      exp_vsync_pipe, t.vsync_out);
    check_vec("VGA_RGB_MISMATCH",
      $sformatf("RGB mismatch at sync=(%0d,%0d) pal=%02h", t.sync_x, t.sync_y, t.sys_palette_idx_in),
      exp_rgb_now, actual_rgb);
    check_vec("VGA_NESX_MISMATCH",
      $sformatf("NES X mismatch at sync_x=%0d", t.sync_x),
      exp_nes_x, t.nes_x_out);
    check_vec("VGA_NESY_MISMATCH",
      $sformatf("NES Y mismatch at sync_y=%0d", t.sync_y),
      exp_nes_y, t.nes_y_out);
    check_vec("VGA_NESY_NEXT_MISMATCH",
      $sformatf("NES Y NEXT mismatch at sync_y_next=%0d", t.sync_y_next),
      exp_nes_y_next, t.nes_y_next_out);
    check_bit("VGA_PIX_PULSE_MISMATCH",
      $sformatf("PIX_PULSE mismatch at sync=(%0d,%0d)", t.sync_x, t.sync_y),
      exp_pix_pulse, t.pix_pulse_out);
    check_bit("VGA_VBLANK_MISMATCH",
      $sformatf("VBLANK mismatch at sync=(%0d,%0d)", t.sync_x, t.sync_y),
      exp_vblank_now, t.vblank_out);

    exp_hsync_pipe = calc_hsync(t.sync_x);
    exp_vsync_pipe = calc_vsync(t.sync_y);

    if (t.rst_in) begin
      exp_rgb_pipe    = 8'h00;
      exp_vblank_pipe = 1'b0;
    end else begin
      exp_rgb_pipe    = calc_d_rgb(t);
      exp_vblank_pipe = calc_next_vblank(t);
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("VGA_SCB_RPT",
      $sformatf("VGA scoreboard summary: PASS=%0d FAIL=%0d", checks_passed, checks_failed),
      UVM_LOW)
  endfunction

endclass

`endif
