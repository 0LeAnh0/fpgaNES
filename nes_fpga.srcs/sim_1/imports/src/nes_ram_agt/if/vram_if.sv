`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2026 09:14:05 AM
// Design Name: 
// Module Name: vram_if
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


interface vram_if(input logic clk_in);
    // Cac tin hieu khop voi port cua khoi block_ram.v (suy luan tu BRAM FPGA)
    logic        en_in;      // Tin hieu cho phep (Enable) khoi RAM hoat dong
    logic        r_nw_in;    // Tin hieu chon Doc/Ghi
    logic [15:0] a_in;       // Dia chi 16-bit (Dung de quan ly/test Mirroring dai $2000-$3FFF)
    logic [7:0]  d_in;       // Du lieu ghi vao tu bus cua PPU
    logic [7:0]  d_out;      // Du lieu doc ra tra ve cho PPU

    covergroup cg_vram_gui @(posedge clk_in);
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;

        cp_addr : coverpoint a_in iff (en_in) {
            bins b_phys0 = {[16'h0000:16'h07FF]};
            bins b_phys1 = {[16'h0800:16'h0FFF]};
            bins b_phys2 = {[16'h1000:16'h17FF]};
            bins b_phys3 = {[16'h1800:16'h1FFF]};
            bins b_edges[] = {16'h0000, 16'h07FF, 16'h0800, 16'h0FFF, 16'h1000, 16'h17FF, 16'h1800, 16'h1FFF};
            bins b_low_quadrant  = {[16'h0000:16'h01FF]};
            bins b_mid_quadrant  = {[16'h0200:16'h05FF]};
            bins b_high_quadrant = {[16'h0600:16'h07FF]};
        }

        cp_op : coverpoint r_nw_in iff (en_in) {
            bins rd = {1'b1};
            bins wr = {1'b0};
        }

        cross_addr_op : cross cp_addr, cp_op;
    endgroup

    // Clocking block cho UVM Driver: Dieu khien va tac dong tin hieu dong bo
    clocking drv_cb @(posedge clk_in);
        default input #1ns output #1ns;
        output en_in, r_nw_in, a_in, d_in;
        input  d_out;
    endclocking

    // Clocking block cho UVM Monitor: Giam sat du lieu tren bus dong bo
    clocking mon_cb @(posedge clk_in);
        default input #1ns output #1ns;
        input en_in, r_nw_in, a_in, d_in, d_out;
    endclocking

    // Dinh nghia cac cong ket noi (Modports) cho Driver va Monitor
    modport vram_drv  (clocking drv_cb, input clk_in);
    modport vram_mon  (clocking mon_cb, input clk_in);
endinterface
