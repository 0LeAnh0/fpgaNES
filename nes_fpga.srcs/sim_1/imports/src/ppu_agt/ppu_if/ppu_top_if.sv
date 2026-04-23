`ifndef PPU_TOP_IF_SV
`define PPU_TOP_IF_SV

interface ppu_top_if(input logic clk_in, input logic rst_in);
  logic [7:0]  ri_d_out;
  logic        nvbl_out;
  logic [13:0] vram_a_out;
  logic [7:0]  vram_d_out;
  logic        vram_wr_out;

  logic [13:0] bg_vram_a;
  logic [3:0]  bg_palette_idx;
  logic [13:0] spr_vram_a;
  logic        spr_vram_req;
  logic [3:0]  spr_palette_idx;
  logic        spr_primary;
  logic        spr_priority;
  logic        spr_overflow;

  logic [5:0]  vga_sys_palette_idx;
  logic        ri_pram_wr;
  logic [7:0]  ri_vram_dout;
  logic        ri_vblank;
  logic        ri_nvbl_en;

  covergroup cg_top_gui @(posedge clk_in);
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    type_option.merge_instances = 0;

    cp_arbiter_src: coverpoint spr_vram_req {
      bins bg  = {0};
      bins spr = {1};
    }

    cp_pram_wr: coverpoint ri_pram_wr {
      bins idle  = {0};
      bins write = {1};
    }

    cp_vblank: coverpoint ri_vblank {
      bins low  = {0};
      bins high = {1};
    }

    cp_spr_overflow: coverpoint spr_overflow {
      bins not_seen = {0};
      bins seen     = {1};
    }
  endgroup

  clocking mon_cb @(posedge clk_in);
    default input #1step output #1;
    input rst_in;
    input ri_d_out, nvbl_out, vram_a_out, vram_d_out, vram_wr_out;
    input bg_vram_a, bg_palette_idx;
    input spr_vram_a, spr_vram_req, spr_palette_idx, spr_primary, spr_priority, spr_overflow;
    input vga_sys_palette_idx;
    input ri_pram_wr, ri_vram_dout, ri_vblank, ri_nvbl_en;
  endclocking

  modport MONITOR (
    clocking mon_cb,
    input rst_in,
    input ri_d_out, input nvbl_out, input vram_a_out, input vram_d_out, input vram_wr_out,
    input bg_vram_a, input bg_palette_idx,
    input spr_vram_a, input spr_vram_req, input spr_palette_idx, input spr_primary, input spr_priority, input spr_overflow,
    input vga_sys_palette_idx,
    input ri_pram_wr, input ri_vram_dout, input ri_vblank, input ri_nvbl_en
  );

endinterface

`endif
