`ifndef PPU_SPR_IF_SV
`define PPU_SPR_IF_SV

interface ppu_spr_if (input logic clk_in, input logic rst_in);
  logic        en_in;
  logic        ls_clip_in;
  logic        spr_h_in;
  logic        spr_pt_sel_in;
  logic [ 7:0] oam_a_in;
  logic [ 7:0] oam_d_in;
  logic        oam_wr_in;
  logic [ 9:0] nes_x_in;
  logic [ 9:0] nes_y_in;
  logic [ 9:0] nes_y_next_in;
  logic        pix_pulse_in;
  logic [ 7:0] vram_d_in;
  
  logic [ 7:0] oam_d_out;
  logic        overflow_out;
  logic [ 3:0] palette_idx_out;
  logic        primary_out;
  logic        priority_out;
  logic [13:0] vram_a_out;
  logic        vram_req_out;

  covergroup cg_spr_gui @(posedge clk_in);
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;

    cp_en: coverpoint en_in;
    cp_h_mode: coverpoint spr_h_in {
      bins size_8x8  = {0};
      bins size_8x16 = {1};
    }
    cp_x: coverpoint nes_x_in iff (en_in) {
      bins left_edge  = {0};
      bins right_edge = {255};
      bins visible    = {[1:254]};
      bins hblank     = {[256:340]};
    }
    cp_y: coverpoint nes_y_in iff (en_in) {
      bins top_edge    = {0};
      bins bottom_edge = {239};
      bins visible     = {[1:238]};
      bins post_render = {240};
      bins vblank      = {[241:260]};
      bins pre_render  = {261};
    }
    cp_overflow: coverpoint overflow_out { bins off = {0}; bins on = {1}; }
    cp_primary : coverpoint primary_out;
    cp_prio    : coverpoint priority_out;
    cross_size_overflow: cross cp_h_mode, cp_overflow;
    cross_pos: cross cp_x, cp_y;
  endgroup

  // Clocking block for Driver (Master side - driving inputs to RTL)
  clocking spr_cb @(posedge clk_in);
    default input #1step output #1;
    input  oam_d_out, overflow_out, palette_idx_out, primary_out, priority_out, vram_a_out, vram_req_out;
    input  rst_in;
    output en_in, ls_clip_in, spr_h_in, spr_pt_sel_in, oam_a_in, oam_d_in, oam_wr_in;
    output nes_x_in, nes_y_in, nes_y_next_in, pix_pulse_in, vram_d_in;
  endclocking

  // Clocking block for Monitor (Sampling both inputs and outputs)
  clocking mon_cb @(posedge clk_in);
    default input #1step output #1;
    input rst_in;
    input en_in, ls_clip_in, spr_h_in, spr_pt_sel_in, oam_a_in, oam_d_in, oam_wr_in;
    input nes_x_in, nes_y_in, nes_y_next_in, pix_pulse_in, vram_d_in;
    input oam_d_out, overflow_out, palette_idx_out, primary_out, priority_out, vram_a_out, vram_req_out;
  endclocking

  modport MASTER (
    clocking spr_cb,
    output en_in, output ls_clip_in, output spr_h_in, output spr_pt_sel_in, output oam_a_in, output oam_d_in, output oam_wr_in,
    output nes_x_in, output nes_y_in, output nes_y_next_in, output pix_pulse_in, output vram_d_in
  );
  
  modport MONITOR (
    clocking mon_cb,
    input en_in, input ls_clip_in, input spr_h_in, input spr_pt_sel_in, input oam_a_in, input oam_d_in, input oam_wr_in,
    input nes_x_in, input nes_y_in, input nes_y_next_in, input pix_pulse_in, input vram_d_in,
    input oam_d_out, input overflow_out, input palette_idx_out, input primary_out, input priority_out, input vram_a_out, input vram_req_out,
    input rst_in
  );

endinterface

`endif
