`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2026 04:30:49 PM
// Design Name: 
// Module Name: wram_if
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

interface wram_if(input logic clk_in);
    logic   en_in;          // chip enable
    logic   r_nw_in;        // read/write select
    logic  [15:0] a_in;     // memory address
    logic  [ 7:0] d_in;     // data input
    logic  [ 7:0] d_out;    // data output

    covergroup cg_wram_gui @(posedge clk_in);
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;

        cp_addr : coverpoint a_in iff (en_in) {
            bins b_wram0 = {[16'h0000:16'h07FF]};
            bins b_wram1 = {[16'h0800:16'h0FFF]};
            bins b_wram2 = {[16'h1000:16'h17FF]};
            bins b_wram3 = {[16'h1800:16'h1FFF]};
            bins b_zero_page = {[16'h0000:16'h00FF]};
            bins b_stack     = {[16'h0100:16'h01FF]};
            bins b_edges[]   = {16'h0000, 16'h07FF, 16'h0800, 16'h0FFF, 16'h1000, 16'h17FF, 16'h1800, 16'h1FFF};
        }

        cp_op : coverpoint r_nw_in iff (en_in) {
            bins rd = {1'b1};
            bins wr = {1'b0};
        }

        cross_addr_op : cross cp_addr, cp_op;
    endgroup

//Clocking block for Driver
    clocking drv_cb @(posedge clk_in);
        default input #1ns output #1ns;
        output en_in, r_nw_in, a_in, d_in;
        input d_out;
     endclocking
   
// Clocking block for UVM Monitor
    clocking mon_cb @(posedge clk_in);
        default input #1ns output #1ns;
        input en_in, r_nw_in, a_in, d_in, d_out;
    endclocking
    
// Them modport
    modport wram_drv  (clocking drv_cb, input clk_in);
    modport wram_mon  (clocking mon_cb, input clk_in);

endinterface
