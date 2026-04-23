`ifndef PPU_TOP_SCOREBOARD_SV
`define PPU_TOP_SCOREBOARD_SV

class ppu_top_scoreboard extends uvm_subscriber #(ppu_top_sequence_item);
  `uvm_component_utils(ppu_top_scoreboard)

  bit [5:0] palette_ram [31:0];
  int unsigned checks_passed;
  int unsigned checks_failed;

  function new(string name = "ppu_top_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    reset_model();
  endfunction

  protected function automatic int unsigned pram_idx(bit [4:0] addr);
    if (addr[1:0] != 2'b00)
      pram_idx = addr;
    else
      pram_idx = (addr & 5'h0f);
  endfunction

  protected function void reset_model();
    foreach (palette_ram[idx]) palette_ram[idx] = 6'h00;
    palette_ram[pram_idx(5'h00)] = 6'h09;
    palette_ram[pram_idx(5'h01)] = 6'h01;
    palette_ram[pram_idx(5'h02)] = 6'h00;
    palette_ram[pram_idx(5'h03)] = 6'h01;
    palette_ram[pram_idx(5'h04)] = 6'h00;
    palette_ram[pram_idx(5'h05)] = 6'h02;
    palette_ram[pram_idx(5'h06)] = 6'h02;
    palette_ram[pram_idx(5'h07)] = 6'h0d;
    palette_ram[pram_idx(5'h08)] = 6'h08;
    palette_ram[pram_idx(5'h09)] = 6'h10;
    palette_ram[pram_idx(5'h0a)] = 6'h08;
    palette_ram[pram_idx(5'h0b)] = 6'h24;
    palette_ram[pram_idx(5'h0c)] = 6'h00;
    palette_ram[pram_idx(5'h0d)] = 6'h00;
    palette_ram[pram_idx(5'h0e)] = 6'h04;
    palette_ram[pram_idx(5'h0f)] = 6'h2c;
    palette_ram[pram_idx(5'h11)] = 6'h01;
    palette_ram[pram_idx(5'h12)] = 6'h34;
    palette_ram[pram_idx(5'h13)] = 6'h03;
    palette_ram[pram_idx(5'h15)] = 6'h04;
    palette_ram[pram_idx(5'h16)] = 6'h00;
    palette_ram[pram_idx(5'h17)] = 6'h14;
    palette_ram[pram_idx(5'h19)] = 6'h3a;
    palette_ram[pram_idx(5'h1a)] = 6'h00;
    palette_ram[pram_idx(5'h1b)] = 6'h02;
    palette_ram[pram_idx(5'h1d)] = 6'h20;
    palette_ram[pram_idx(5'h1e)] = 6'h2c;
    palette_ram[pram_idx(5'h1f)] = 6'h08;
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

  virtual function void write(ppu_top_sequence_item t);
    bit [13:0] exp_vram_a;
    bit        exp_nvbl_out;
    bit [5:0]  exp_sys_palette_idx;
    bit        spr_foreground;
    bit        spr_trans;
    bit        bg_trans;

    if (t.rst_in) begin
      reset_model();
      return;
    end

    exp_vram_a = t.spr_vram_req ? t.spr_vram_a : t.bg_vram_a;
    exp_nvbl_out = ~(t.ri_vblank & t.ri_nvbl_en);

    spr_foreground = ~t.spr_priority;
    spr_trans      = ~|t.spr_palette_idx[1:0];
    bg_trans       = ~|t.bg_palette_idx[1:0];

    if (((spr_foreground || bg_trans) && !spr_trans))
      exp_sys_palette_idx = palette_ram[{1'b1, t.spr_palette_idx}];
    else if (!bg_trans)
      exp_sys_palette_idx = palette_ram[{1'b0, t.bg_palette_idx}];
    else
      exp_sys_palette_idx = palette_ram[5'h00];

    check_vec("PPU_TOP_ARB_MISMATCH",
      "Top-level VRAM address arbiter mismatch",
      exp_vram_a, t.vram_a_out);
    check_bit("PPU_TOP_NVBL_MISMATCH",
      "Top-level /VBL output mismatch",
      exp_nvbl_out, t.nvbl_out);
    check_vec("PPU_TOP_PALETTE_MUX_MISMATCH",
      "Top-level final system palette index mismatch",
      exp_sys_palette_idx, t.vga_sys_palette_idx);

    if (t.ri_pram_wr)
      palette_ram[pram_idx(t.vram_a_out[4:0])] = t.ri_vram_dout[5:0];
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("PPU_TOP_SCB_RPT",
      $sformatf("PPU top scoreboard summary: PASS=%0d FAIL=%0d", checks_passed, checks_failed),
      UVM_LOW)
  endfunction
endclass

`endif
