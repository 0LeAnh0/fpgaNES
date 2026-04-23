`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top-level UVM testbench cho NES FPGA.
//
// Packages:
//   nes_ram_pkg  — RAM Verification (WRAM + VRAM)
//   ppu_ri_pkg   — PPU RI Verification ($2000-$2007)
//
// Virtual Interfaces:
//   wram_if    — WRAM direct access
//   vram_if    — VRAM direct access
//   ppu_ri_if  — PPU RI:
//                  Master side: Agent drives CPU bus → PPU
//                  Slave  side: Agent drives vram_din ← to PPU (VRAM BFM)
//                               Agent monitors vram_wr/pram_wr/spr_ram_wr
//
// Chạy test (Vivado Simulation Arguments):
//   +UVM_TESTNAME=nes_ram_regression_test   RAM baseline
//   +UVM_TESTNAME=ppu_ri_sanity_test   PPU RI sanity
//////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
`include "uvm_macros.svh"

// Interfaces and Packages are compiled separately via filelist.f and imported below.

import nes_ram_pkg::*;
import ppu_ri_pkg::*;
import ppu_bg_pkg::*;
import ppu_spr_pkg::*;
import ppu_vga_pkg::*;
import ppu_top_pkg::*;

module tb_top;

    // -------------------------------------------------------------------------
    // 1. Local Signals
    // -------------------------------------------------------------------------
    logic        CLK_100MHZ;
    logic        BTN_SOUTH;
    logic        BTN_EAST;
    logic        NES_JOYPAD_DATA1;
    logic        NES_JOYPAD_CLK;
    logic        NES_JOYPAD_LATCH;
    logic        VGA_HSYNC;
    logic        VGA_VSYNC;
    logic [2:0]  VGA_RED;
    logic [2:0]  VGA_GREEN;
    logic [1:0]  VGA_BLUE;
    logic        AUDIO;
    logic        RXD;
    logic        TXD;

    // -------------------------------------------------------------------------
    // 2. Virtual Interface Instantiation
    // -------------------------------------------------------------------------
    wram_if    wram_vif   (.clk_in(CLK_100MHZ));
    vram_if    vram_vif   (.clk_in(CLK_100MHZ));
    ppu_ri_if  ppu_ri_vif (.clk_in(CLK_100MHZ));
    ppu_bg_if  ppu_bg_vif (.clk_in(CLK_100MHZ), .rst_in(tb_ctrl_vif.rst_req));
    ppu_spr_if ppu_spr_vif(.clk_in(CLK_100MHZ), .rst_in(tb_ctrl_vif.rst_req));
    ppu_vga_if ppu_vga_vif(.clk_in(CLK_100MHZ), .rst_in(tb_ctrl_vif.rst_req));
    ppu_top_if ppu_top_vif(.clk_in(CLK_100MHZ), .rst_in(tb_ctrl_vif.rst_req));
    tb_ctrl_if tb_ctrl_vif(.clk_in(CLK_100MHZ));

    // -------------------------------------------------------------------------
    // 3. DUT Instantiation
    // -------------------------------------------------------------------------
    nes_top dut (
        .CLK_100MHZ       (CLK_100MHZ),
        .BTN_SOUTH        (BTN_SOUTH),
        .BTN_EAST         (BTN_EAST),
        .NES_JOYPAD_DATA1 (NES_JOYPAD_DATA1),
        .NES_JOYPAD_CLK   (NES_JOYPAD_CLK),
        .NES_JOYPAD_LATCH (NES_JOYPAD_LATCH),
        .VGA_HSYNC        (VGA_HSYNC),
        .VGA_VSYNC        (VGA_VSYNC),
        .VGA_RED          (VGA_RED),
        .VGA_GREEN        (VGA_GREEN),
        .VGA_BLUE         (VGA_BLUE),
        .AUDIO            (AUDIO),
        .RXD              (RXD),
        .TXD              (TXD),
        .NES_JOYPAD_DATA2 (1'b1),
        .SW               (4'h0)
    );

    // Testbench reset control: drive DUT reset button from tb_ctrl_if.
    assign BTN_SOUTH = tb_ctrl_vif.rst_req;

    // -------------------------------------------------------------------------
    // 4A. WRAM Interface Connections
    // -------------------------------------------------------------------------
    assign wram_vif.d_out = dut.wram_blk.d_out;

    initial begin
        force dut.wram_blk.en_in   = wram_vif.en_in;
        force dut.wram_blk.r_nw_in = wram_vif.r_nw_in;
        force dut.wram_blk.a_in    = wram_vif.a_in[10:0];
        force dut.wram_blk.d_in    = wram_vif.d_in;
    end

    // -------------------------------------------------------------------------
    // 4B. VRAM Interface Connections
    // -------------------------------------------------------------------------
    assign vram_vif.d_out = dut.vram_blk.d_out;

    initial begin
        force dut.vram_blk.en_in   = vram_vif.en_in;
        force dut.vram_blk.r_nw_in = vram_vif.r_nw_in;
        force dut.vram_blk.a_in    = vram_vif.a_in[10:0];
        force dut.vram_blk.d_in    = vram_vif.d_in;
    end

    // -------------------------------------------------------------------------
    // 4C. PPU RI Interface Connections
    // -------------------------------------------------------------------------

    initial begin
        string testname;
        if ($value$plusargs("UVM_TESTNAME=%s", testname) &&
            (testname == "ppu_ri_sanity_test" ||
             testname == "ppu_ri_full_regression_test" ||
             testname == "ppu_ri_signoff_test" ||
             testname == "ppu_ri_scroll_signoff_test" ||
             testname == "ppu_full_integration_test")) begin
            forever begin
                @(negedge CLK_100MHZ);
                force dut.ppu_blk.ppu_ri_blk.sel_in         = ppu_ri_vif.ri_sel;
                force dut.ppu_blk.ppu_ri_blk.ncs_in         = ppu_ri_vif.ri_ncs;
                force dut.ppu_blk.ppu_ri_blk.r_nw_in        = ppu_ri_vif.ri_r_nw;
                force dut.ppu_blk.ppu_ri_blk.cpu_d_in       = ppu_ri_vif.ri_din;
                force dut.ppu_blk.vram_d_in                 = ppu_ri_vif.vram_din;
                force dut.ppu_blk.ppu_ri_blk.spr_ram_d_in   = ppu_ri_vif.spr_ram_din;
            end
        end else begin
            force ppu_ri_vif.ri_sel       = dut.ppu_blk.ri_sel_in;
            force ppu_ri_vif.ri_ncs       = dut.ppu_blk.ri_ncs_in;
            force ppu_ri_vif.ri_r_nw      = dut.ppu_blk.ri_r_nw_in;
            force ppu_ri_vif.ri_din       = dut.ppu_blk.ri_d_in;
            force ppu_ri_vif.vram_din     = dut.ppu_blk.vram_d_in;
            force ppu_ri_vif.spr_ram_din  = dut.ppu_blk.ppu_ri_blk.spr_ram_d_in;
        end
    end

    // Master monitor reads cpu_d_out từ ppu_ri_blk
    assign ppu_ri_vif.ri_dout = dut.ppu_blk.ppu_ri_blk.cpu_d_out;

    // --- SLAVE SIDE: Monitor observes PPU output strobes ---
    // Use direct assign for outputs so we constantly see their state.
    assign ppu_ri_vif.vram_a       = dut.ppu_blk.ppu_ri_blk.vram_a_in;
    assign ppu_ri_vif.vram_dout    = dut.ppu_blk.ppu_ri_blk.vram_d_out;
    assign ppu_ri_vif.vram_wr      = dut.ppu_blk.ppu_ri_blk.vram_wr_out;
    assign ppu_ri_vif.pram_wr      = dut.ppu_blk.ppu_ri_blk.pram_wr_out;
    assign ppu_ri_vif.spr_ram_a    = dut.ppu_blk.ppu_ri_blk.spr_ram_a_out;
    assign ppu_ri_vif.spr_ram_dout = dut.ppu_blk.ppu_ri_blk.spr_ram_d_out;
    assign ppu_ri_vif.spr_ram_wr   = dut.ppu_blk.ppu_ri_blk.spr_ram_wr_out;
    assign ppu_ri_vif.inc_addr     = dut.ppu_blk.ppu_ri_blk.inc_addr_out;
    assign ppu_ri_vif.upd_cntrs    = dut.ppu_blk.ppu_ri_blk.upd_cntrs_out;
    // Scroll state outputs - sniff directly from PPU block
    assign ppu_ri_vif.fv           = dut.ppu_blk.ppu_ri_blk.fv_out;
    assign ppu_ri_vif.vt           = dut.ppu_blk.ppu_ri_blk.vt_out;
    assign ppu_ri_vif.v            = dut.ppu_blk.ppu_ri_blk.v_out;
    assign ppu_ri_vif.fh           = dut.ppu_blk.ppu_ri_blk.fh_out;
    assign ppu_ri_vif.ht           = dut.ppu_blk.ppu_ri_blk.ht_out;
    assign ppu_ri_vif.h            = dut.ppu_blk.ppu_ri_blk.h_out;
    assign ppu_ri_vif.s            = dut.ppu_blk.ppu_ri_blk.s_out;
    assign ppu_ri_vif.inc_addr_amt = dut.ppu_blk.ppu_ri_blk.inc_addr_amt_out;

    // -------------------------------------------------------------------------
    // 4D. PPU BG Interface Connections
    // -------------------------------------------------------------------------
    assign ppu_bg_vif.vram_a_out      = dut.ppu_blk.ppu_bg_blk.vram_a_out;
    assign ppu_bg_vif.palette_idx_out = dut.ppu_blk.ppu_bg_blk.palette_idx_out;

    // Monitor internal signals: Ép các biến trong Interface phải đi theo tín hiệu thực trong DUT.
    // Không được dùng "assign" vì sẽ xung đột driver với UVM Agent nếu Agent đó đang active.
    initial begin
        string testname;
        if ($value$plusargs("UVM_TESTNAME=%s", testname) &&
            (testname == "ppu_bg_sanity_test" ||
             testname == "ppu_bg_ri_update_test" ||
             testname == "ppu_bg_render_fetch_test" ||
             testname == "ppu_bg_random_reset_test" ||
             testname == "ppu_bg_full_regression_test" ||
             testname == "ppu_bg_complex_scroll_test" ||
             testname == "ppu_bg_pixel_test")) begin
            force dut.ppu_blk.ppu_bg_blk.en_in              = ppu_bg_vif.en_in;
            force dut.ppu_blk.ppu_bg_blk.ls_clip_in         = ppu_bg_vif.ls_clip_in;
            force dut.ppu_blk.ppu_bg_blk.fv_in              = ppu_bg_vif.fv_in;
            force dut.ppu_blk.ppu_bg_blk.vt_in              = ppu_bg_vif.vt_in;
            force dut.ppu_blk.ppu_bg_blk.v_in               = ppu_bg_vif.v_in;
            force dut.ppu_blk.ppu_bg_blk.fh_in              = ppu_bg_vif.fh_in;
            force dut.ppu_blk.ppu_bg_blk.ht_in              = ppu_bg_vif.ht_in;
            force dut.ppu_blk.ppu_bg_blk.h_in               = ppu_bg_vif.h_in;
            force dut.ppu_blk.ppu_bg_blk.s_in               = ppu_bg_vif.s_in;
            force dut.ppu_blk.ppu_bg_blk.nes_x_in           = ppu_bg_vif.nes_x_in;
            force dut.ppu_blk.ppu_bg_blk.nes_y_in           = ppu_bg_vif.nes_y_in;
            force dut.ppu_blk.ppu_bg_blk.nes_y_next_in      = ppu_bg_vif.nes_y_next_in;
            force dut.ppu_blk.ppu_bg_blk.pix_pulse_in       = ppu_bg_vif.pix_pulse_in;
            force dut.ppu_blk.vram_d_in                     = ppu_bg_vif.vram_d_in;
            force dut.ppu_blk.ppu_bg_blk.ri_upd_cntrs_in    = ppu_bg_vif.ri_upd_cntrs_in;
            force dut.ppu_blk.ppu_bg_blk.ri_inc_addr_in     = ppu_bg_vif.ri_inc_addr_in;
            force dut.ppu_blk.ppu_bg_blk.ri_inc_addr_amt_in = ppu_bg_vif.ri_inc_addr_amt_in;
        end else begin
            force ppu_bg_vif.en_in              = dut.ppu_blk.ppu_bg_blk.en_in;
            force ppu_bg_vif.ls_clip_in         = dut.ppu_blk.ppu_bg_blk.ls_clip_in;
            force ppu_bg_vif.fv_in              = dut.ppu_blk.ppu_bg_blk.fv_in;
            force ppu_bg_vif.vt_in              = dut.ppu_blk.ppu_bg_blk.vt_in;
            force ppu_bg_vif.v_in               = dut.ppu_blk.ppu_bg_blk.v_in;
            force ppu_bg_vif.fh_in              = dut.ppu_blk.ppu_bg_blk.fh_in;
            force ppu_bg_vif.ht_in              = dut.ppu_blk.ppu_bg_blk.ht_in;
            force ppu_bg_vif.h_in               = dut.ppu_blk.ppu_bg_blk.h_in;
            force ppu_bg_vif.s_in               = dut.ppu_blk.ppu_bg_blk.s_in;
            force ppu_bg_vif.nes_x_in           = dut.ppu_blk.ppu_bg_blk.nes_x_in;
            force ppu_bg_vif.nes_y_in           = dut.ppu_blk.ppu_bg_blk.nes_y_in;
            force ppu_bg_vif.nes_y_next_in      = dut.ppu_blk.ppu_bg_blk.nes_y_next_in;
            force ppu_bg_vif.pix_pulse_in       = dut.ppu_blk.ppu_bg_blk.pix_pulse_in;
            force ppu_bg_vif.vram_d_in          = dut.ppu_blk.ppu_bg_blk.vram_d_in;
            force ppu_bg_vif.ri_upd_cntrs_in    = dut.ppu_blk.ppu_bg_blk.ri_upd_cntrs_in;
            force ppu_bg_vif.ri_inc_addr_in     = dut.ppu_blk.ppu_bg_blk.ri_inc_addr_in;
            force ppu_bg_vif.ri_inc_addr_amt_in = dut.ppu_blk.ppu_bg_blk.ri_inc_addr_amt_in;
        end
    end

    // -------------------------------------------------------------------------
    // 4E. PPU SPR Interface Connections
    // -------------------------------------------------------------------------
    assign ppu_spr_vif.oam_d_out       = dut.ppu_blk.ppu_spr_blk.oam_d_out;
    assign ppu_spr_vif.overflow_out    = dut.ppu_blk.ppu_spr_blk.overflow_out;
    assign ppu_spr_vif.palette_idx_out = dut.ppu_blk.ppu_spr_blk.palette_idx_out;
    assign ppu_spr_vif.primary_out     = dut.ppu_blk.ppu_spr_blk.primary_out;
    assign ppu_spr_vif.priority_out    = dut.ppu_blk.ppu_spr_blk.priority_out;
    assign ppu_spr_vif.vram_a_out      = dut.ppu_blk.ppu_spr_blk.vram_a_out;
    assign ppu_spr_vif.vram_req_out    = dut.ppu_blk.ppu_spr_blk.vram_req_out;

    initial begin
        string testname;
        if ($value$plusargs("UVM_TESTNAME=%s", testname) && 
            (testname == "ppu_spr_sanity_test" || testname == "ppu_spr_render_test" || 
             testname == "ppu_spr_full_regression_test" || testname == "ppu_spr_eval_test" ||
             testname == "ppu_spr_overflow_test" || testname == "ppu_spr_oam_test" ||
             testname == "ppu_spr_random_reset_test" || testname == "ppu_spr_full_frame_test")) begin
            
            // ACTIVE MODE: UVM Agent drives the DUT
            force dut.ppu_blk.ppu_spr_blk.en_in         = ppu_spr_vif.en_in;
            force dut.ppu_blk.ppu_spr_blk.ls_clip_in    = ppu_spr_vif.ls_clip_in;
            force dut.ppu_blk.ppu_spr_blk.spr_h_in      = ppu_spr_vif.spr_h_in;
            force dut.ppu_blk.ppu_spr_blk.spr_pt_sel_in = ppu_spr_vif.spr_pt_sel_in;
            force dut.ppu_blk.ppu_spr_blk.oam_a_in      = ppu_spr_vif.oam_a_in;
            force dut.ppu_blk.ppu_spr_blk.oam_d_in      = ppu_spr_vif.oam_d_in;
            force dut.ppu_blk.ppu_spr_blk.oam_wr_in     = ppu_spr_vif.oam_wr_in;
            force dut.ppu_blk.ppu_spr_blk.nes_x_in      = ppu_spr_vif.nes_x_in;
            force dut.ppu_blk.ppu_spr_blk.nes_y_in      = ppu_spr_vif.nes_y_in;
            force dut.ppu_blk.ppu_spr_blk.nes_y_next_in = ppu_spr_vif.nes_y_next_in;
            force dut.ppu_blk.ppu_spr_blk.pix_pulse_in  = ppu_spr_vif.pix_pulse_in;
            force dut.ppu_blk.vram_d_in                 = ppu_spr_vif.vram_d_in;

        end else begin
            // PASSIVE MODE: Interface sniffs the DUT (driven by nes_top)
            force ppu_spr_vif.en_in         = dut.ppu_blk.ppu_spr_blk.en_in;
            force ppu_spr_vif.ls_clip_in    = dut.ppu_blk.ppu_spr_blk.ls_clip_in;
            force ppu_spr_vif.spr_h_in      = dut.ppu_blk.ppu_spr_blk.spr_h_in;
            force ppu_spr_vif.spr_pt_sel_in = dut.ppu_blk.ppu_spr_blk.spr_pt_sel_in;
            force ppu_spr_vif.oam_a_in      = dut.ppu_blk.ppu_spr_blk.oam_a_in;
            force ppu_spr_vif.oam_d_in      = dut.ppu_blk.ppu_spr_blk.oam_d_in;
            force ppu_spr_vif.oam_wr_in     = dut.ppu_blk.ppu_spr_blk.oam_wr_in;
            force ppu_spr_vif.nes_x_in      = dut.ppu_blk.ppu_spr_blk.nes_x_in;
            force ppu_spr_vif.nes_y_in      = dut.ppu_blk.ppu_spr_blk.nes_y_in;
            force ppu_spr_vif.nes_y_next_in = dut.ppu_blk.ppu_spr_blk.nes_y_next_in;
            force ppu_spr_vif.pix_pulse_in  = dut.ppu_blk.ppu_spr_blk.pix_pulse_in;
            force ppu_spr_vif.vram_d_in     = dut.ppu_blk.ppu_spr_blk.vram_d_in;
        end
    end

    // -------------------------------------------------------------------------
    // 4F. PPU VGA Interface Connections
    // -------------------------------------------------------------------------
    assign ppu_vga_vif.hsync_out      = dut.ppu_blk.ppu_vga_blk.hsync_out;
    assign ppu_vga_vif.vsync_out      = dut.ppu_blk.ppu_vga_blk.vsync_out;
    assign ppu_vga_vif.r_out          = dut.ppu_blk.ppu_vga_blk.r_out;
    assign ppu_vga_vif.g_out          = dut.ppu_blk.ppu_vga_blk.g_out;
    assign ppu_vga_vif.b_out          = dut.ppu_blk.ppu_vga_blk.b_out;
    assign ppu_vga_vif.nes_x_out      = dut.ppu_blk.ppu_vga_blk.nes_x_out;
    assign ppu_vga_vif.nes_y_out      = dut.ppu_blk.ppu_vga_blk.nes_y_out;
    assign ppu_vga_vif.nes_y_next_out = dut.ppu_blk.ppu_vga_blk.nes_y_next_out;
    assign ppu_vga_vif.pix_pulse_out  = dut.ppu_blk.ppu_vga_blk.pix_pulse_out;
    assign ppu_vga_vif.vblank_out     = dut.ppu_blk.ppu_vga_blk.vblank_out;
    assign ppu_vga_vif.sync_en        = dut.ppu_blk.ppu_vga_blk.sync_en;
    assign ppu_vga_vif.sync_x         = dut.ppu_blk.ppu_vga_blk.sync_x;
    assign ppu_vga_vif.sync_y         = dut.ppu_blk.ppu_vga_blk.sync_y;
    assign ppu_vga_vif.sync_x_next    = dut.ppu_blk.ppu_vga_blk.sync_x_next;
    assign ppu_vga_vif.sync_y_next    = dut.ppu_blk.ppu_vga_blk.sync_y_next;

    initial begin
        string testname;
        if ($value$plusargs("UVM_TESTNAME=%s", testname) &&
            (testname == "ppu_vga_reset_test" ||
             testname == "ppu_vga_palette_visible_area_test" ||
             testname == "ppu_vga_border_color_test" ||
             testname == "ppu_vga_vblank_timing_test" ||
             testname == "ppu_vga_full_regression_test")) begin
            force dut.ppu_blk.ppu_vga_blk.sys_palette_idx_in = ppu_vga_vif.sys_palette_idx_in;
        end else begin
            force ppu_vga_vif.sys_palette_idx_in = dut.ppu_blk.ppu_vga_blk.sys_palette_idx_in;
        end
    end

    // -------------------------------------------------------------------------
    // 4G. PPU TOP Interface Connections
    // -------------------------------------------------------------------------
    assign ppu_top_vif.ri_d_out           = dut.ppu_blk.ri_d_out;
    assign ppu_top_vif.nvbl_out           = dut.ppu_blk.nvbl_out;
    assign ppu_top_vif.vram_a_out         = dut.ppu_blk.vram_a_out;
    assign ppu_top_vif.vram_d_out         = dut.ppu_blk.vram_d_out;
    assign ppu_top_vif.vram_wr_out        = dut.ppu_blk.vram_wr_out;
    assign ppu_top_vif.bg_vram_a          = dut.ppu_blk.bg_vram_a;
    assign ppu_top_vif.bg_palette_idx     = dut.ppu_blk.bg_palette_idx;
    assign ppu_top_vif.spr_vram_a         = dut.ppu_blk.spr_vram_a;
    assign ppu_top_vif.spr_vram_req       = dut.ppu_blk.spr_vram_req;
    assign ppu_top_vif.spr_palette_idx    = dut.ppu_blk.spr_palette_idx;
    assign ppu_top_vif.spr_primary        = dut.ppu_blk.spr_primary;
    assign ppu_top_vif.spr_priority       = dut.ppu_blk.spr_priority;
    assign ppu_top_vif.spr_overflow       = dut.ppu_blk.ri_spr_overflow;
    assign ppu_top_vif.vga_sys_palette_idx = dut.ppu_blk.vga_sys_palette_idx;
    assign ppu_top_vif.ri_pram_wr         = dut.ppu_blk.ri_pram_wr;
    assign ppu_top_vif.ri_vram_dout       = dut.ppu_blk.ri_vram_dout;
    assign ppu_top_vif.ri_vblank          = dut.ppu_blk.ri_vblank;
    assign ppu_top_vif.ri_nvbl_en         = dut.ppu_blk.ri_nvbl_en;

    // -------------------------------------------------------------------------
    // 5. Clock Generation — 100 MHz
    // -------------------------------------------------------------------------
    initial begin
        CLK_100MHZ = 1'b0;
        forever #5ns CLK_100MHZ = ~CLK_100MHZ;
    end

    always @(posedge tb_ctrl_vif.rst_req) begin
        for (int i = 0; i < 8; i++) begin
            dut.ppu_blk.ppu_spr_blk.m_stm[i] = 25'h0;
            dut.ppu_blk.ppu_spr_blk.m_sbm[i] = 28'h0;
        end
    end

    // -------------------------------------------------------------------------
    // 6. UVM Simulation Control
    // -------------------------------------------------------------------------
    initial begin
        string testname;
        int debug_file;
        bit enable_diag_log;
        
        enable_diag_log = 1'b0;
        void'($value$plusargs("TB_DIAG_LOG=%0d", enable_diag_log));
        debug_file = 0;
        if (enable_diag_log)
            debug_file = $fopen("sim_diag.log", "w");
        
        // Monitor: Dùng force để Interface luôn lấy giá trị THỰC từ khối BG
        force ppu_bg_vif.vram_a_out = dut.ppu_blk.ppu_bg_blk.vram_a_out;
        
        // Khối Diagnostic gộp chung vào đây
        if (enable_diag_log && (debug_file != 0)) begin
            fork
                begin
                    #110ns;
                    for (int i=0; i<100; i++) begin
                        @(posedge CLK_100MHZ);
                        $fdisplay(debug_file, "@%0t | NCS=%0b SEL=%0d BG_A=%0h VRAM_A=%0h", 
                            $time, dut.ppu_blk.ri_ncs_in, dut.ppu_blk.ri_sel_in, 
                            dut.ppu_blk.ppu_bg_blk.vram_a_out, dut.ppu_blk.vram_a_out);
                    end
                    $fclose(debug_file);
                end
            join_none
        end
        // Memory Initialization
        for (int i = 0; i < 2048; i++) begin
            dut.wram_blk.wram_bram.ram[i] = 8'h00;
            dut.vram_blk.vram_bram.ram[i] = 8'h00;
        end

        tb_ctrl_vif.rst_req = 1'b1;
        BTN_EAST         = 1'b0;
        RXD              = 1'b1;
        NES_JOYPAD_DATA1 = 1'b1;


        // Config DB: RAM Agents (nes_ram_pkg)
        uvm_config_db #(virtual wram_if)::set(
            null, "uvm_test_top.*m_wram_agent.*", "vif", wram_vif);
        uvm_config_db #(virtual vram_if)::set(
            null, "uvm_test_top.*m_vram_agent.*", "vif", vram_vif);
        // Config DB: PPU RI Master/Slave Agents (ppu_ri_pkg)
        uvm_config_db #(virtual ppu_ri_if)::set(
            null, "uvm_test_top.*m_ppu_ri_mst_agent.*", "ppu_ri_vif", ppu_ri_vif);
        uvm_config_db #(virtual ppu_ri_if)::set(
            null, "uvm_test_top.*m_ppu_ri_slv_agent.*", "ppu_ri_vif", ppu_ri_vif);
        uvm_config_db #(virtual ppu_ri_if)::set(
            null, "uvm_test_top", "ppu_ri_vif", ppu_ri_vif);
        
        // Config DB: PPU BG
        uvm_config_db #(virtual ppu_bg_if.MASTER)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_bg_vif);
        uvm_config_db #(virtual ppu_bg_if.SLAVE)::set(null, "uvm_test_top.*slave_agent.*", "vif", ppu_bg_vif);
        uvm_config_db #(virtual ppu_bg_if.MONITOR)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_bg_vif);
        uvm_config_db #(virtual ppu_bg_if.MONITOR)::set(null, "uvm_test_top.*slave_agent.*", "vif", ppu_bg_vif);
        // Config DB: PPU SPR
        uvm_config_db #(virtual ppu_spr_if.MASTER)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_spr_vif);
        uvm_config_db #(virtual ppu_spr_if.MONITOR)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_spr_vif);
        // Config DB: PPU VGA
        uvm_config_db #(virtual ppu_vga_if.MASTER)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_vga_vif);
        uvm_config_db #(virtual ppu_vga_if.MONITOR)::set(null, "uvm_test_top.*master_agent.*", "vif", ppu_vga_vif);
        uvm_config_db #(virtual ppu_vga_if)::set(null, "uvm_test_top", "vga_vif", ppu_vga_vif);
        // Config DB: PPU TOP
        uvm_config_db #(virtual ppu_top_if.MONITOR)::set(null, "uvm_test_top.*m_ppu_top_monitor*", "vif", ppu_top_vif);
        uvm_config_db #(virtual ppu_top_if)::set(null, "uvm_test_top", "ppu_top_vif", ppu_top_vif);
        uvm_config_db #(virtual ppu_bg_if)::set(null, "uvm_test_top", "bg_vif", ppu_bg_vif);
        uvm_config_db #(virtual ppu_spr_if)::set(null, "uvm_test_top", "spr_vif", ppu_spr_vif);

        uvm_config_db #(virtual tb_ctrl_if)::set(
            null, "uvm_test_top", "tb_ctrl_vif", tb_ctrl_vif);

        // Release reset after 100ns
        fork
            begin
                // Force vga_sync registers to 0 to avoid X propagation (since RTL lacks reset)
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_hcnt = 10'h000;
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_vcnt = 10'h000;
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_mod4_cnt = 2'h0;
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_hsync = 1'b0;
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_vsync = 1'b0;
                force dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_en    = 1'b0;

                #100ns;
                tb_ctrl_vif.rst_req = 1'b0;

                // Release after some time to let RTL take over
                #10ns;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_hcnt;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_vcnt;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_mod4_cnt;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_hsync;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_vsync;
                release dut.ppu_blk.ppu_vga_blk.vga_sync_blk.q_en;

                repeat(10) @(posedge CLK_100MHZ);
                `uvm_info("TB_TOP", "Reset deasserted", UVM_LOW)
            end
        join_none

        // Fallback test selection
         if (!$value$plusargs("UVM_TESTNAME=%s", testname)) begin
            testname = "ppu_ri_full_regression_test";
            run_test(testname);
        end else begin
            run_test();
        end 
    end
endmodule
