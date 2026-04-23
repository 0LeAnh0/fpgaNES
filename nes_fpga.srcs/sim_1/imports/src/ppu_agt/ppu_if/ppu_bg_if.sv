`ifndef PPU_BG_IF_SV
`define PPU_BG_IF_SV

interface ppu_bg_if (input logic clk_in, input logic rst_in);
  logic        en_in;
  logic        ls_clip_in;
  logic [ 2:0] fv_in;
  logic [ 4:0] vt_in;
  logic        v_in;
  logic [ 2:0] fh_in;
  logic [ 4:0] ht_in;
  logic        h_in;
  logic        s_in;
  logic [ 9:0] nes_x_in;
  logic [ 9:0] nes_y_in;
  logic [ 9:0] nes_y_next_in;
  logic        pix_pulse_in;
  logic [ 7:0] vram_d_in;
  logic        ri_upd_cntrs_in;
  logic        ri_inc_addr_in;
  logic        ri_inc_addr_amt_in;
  
  logic [13:0] vram_a_out;
  logic [ 3:0] palette_idx_out;

  covergroup cg_bg_gui @(posedge clk_in);
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;

    cp_en: coverpoint en_in;
    cp_x:  coverpoint nes_x_in iff (en_in) {
      bins visible = {[0:255]};
      bins fetch   = {[256:319]};
      bins hblank  = {[320:340]};
    }
    cp_y:  coverpoint nes_y_in iff (en_in) {
      bins visible    = {[0:239]};
      bins vblank     = {[240:260]};
      bins pre_render = {261};
    }
    cp_fh: coverpoint fh_in iff (en_in) { bins values[] = {[0:7]}; }
    cp_fv: coverpoint fv_in iff (en_in) { bins values[] = {[0:7]}; }
    cp_nt: coverpoint {v_in, h_in} iff (en_in) {
      bins nt_0 = {2'b00};
      bins nt_1 = {2'b01};
      bins nt_2 = {2'b10};
      bins nt_3 = {2'b11};
    }
    cp_palette: coverpoint palette_idx_out iff (en_in) {
      bins transparent = {4'h0};
      bins non_zero[]  = {[4'h1:4'hF]};
    }
    cross_pos_en: cross cp_x, cp_y, cp_en;
  endgroup

  // Clocking block for Driver
  clocking bg_cb @(posedge clk_in);
    default input #1step output #1;
    input vram_a_out;
    input palette_idx_out;
    input rst_in;
    output en_in, ls_clip_in, fv_in, vt_in, v_in, fh_in, ht_in, h_in, s_in;
    output nes_x_in, nes_y_in, nes_y_next_in, pix_pulse_in, vram_d_in;
    output ri_upd_cntrs_in, ri_inc_addr_in, ri_inc_addr_amt_in;
  endclocking

  // Clocking block for Monitor
  clocking mon_cb @(posedge clk_in);
    default input #1step output #1;
    input rst_in;
    input en_in, ls_clip_in, fv_in, vt_in, v_in, fh_in, ht_in, h_in, s_in;
    input nes_x_in, nes_y_in, nes_y_next_in, pix_pulse_in, vram_d_in;
    input ri_upd_cntrs_in, ri_inc_addr_in, ri_inc_addr_amt_in;
    input vram_a_out, palette_idx_out;
  endclocking

  modport MASTER (
    clocking bg_cb,
    output en_in, output ls_clip_in, output fv_in, output vt_in, output v_in, output fh_in, output ht_in, output h_in, output s_in, output nes_x_in, output nes_y_in, output nes_y_next_in, output pix_pulse_in, output vram_d_in, output ri_upd_cntrs_in, output ri_inc_addr_in, output ri_inc_addr_amt_in
  );
  
  modport SLAVE (
    clocking bg_cb,
    output vram_a_out, output palette_idx_out
  );
  
  modport MONITOR (
    clocking mon_cb,
    input en_in, input ls_clip_in, input fv_in, input vt_in, input v_in, input fh_in, input ht_in, input h_in, input s_in, input nes_x_in, input nes_y_in, input nes_y_next_in, input pix_pulse_in, input vram_d_in, input ri_upd_cntrs_in, input ri_inc_addr_in, input ri_inc_addr_amt_in, input vram_a_out, input palette_idx_out, input rst_in
  );

endinterface

`endif
