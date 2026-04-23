`ifndef PPU_RI_IF_SV
`define PPU_RI_IF_SV

// ===========================================================================
// ppu_ri_if
// Interface cho PPU Register Interface — 2 phia giao tiep:
//
//   A. CPU SIDE (Master Agent drives, PPU receives):
//        ri_sel, ri_ncs, ri_r_nw, ri_din -> vao PPU
//        ri_dout <- tu PPU ra CPU
//
//   B. MEMORY SIDE (Slave Agent drives response, PPU drives request):
//        vram_a, vram_dout, vram_wr, pram_wr  <- PPU drives (Slave Monitor observes)
//        spr_ram_a, spr_ram_dout, spr_ram_wr  <- PPU drives (Slave Monitor observes)
//        vram_din -> Slave Driver drives data nguoc lai cho PPU doc ($2007 READ)
// ===========================================================================
interface ppu_ri_if (input logic clk_in);

    //----------------------------------------------------------------------
    // A. CPU SIDE SIGNALS
    //----------------------------------------------------------------------
    logic [2:0] ri_sel;        // Register select (0=$2000 ... 7=$2007)
    logic       ri_ncs;        // Chip select, active-low
    logic       ri_r_nw;       // 1=Read, 0=Write
    logic [7:0] ri_din;        // Data: CPU → PPU
    logic [7:0] ri_dout;       // Data: PPU → CPU

    //----------------------------------------------------------------------
    // B. MEMORY SIDE SIGNALS — PPU drives these (Slave observes)
    //----------------------------------------------------------------------
    logic [13:0] vram_a;        // VRAM address PPU requests
    logic [ 7:0] vram_dout;     // Data PPU writes to VRAM ($2007 write)
    logic        vram_wr;       // PPU VRAM write strobe
    logic        pram_wr;       // PPU Palette RAM write strobe
    logic [ 7:0] spr_ram_a;     // OAM address PPU drives
    logic [ 7:0] spr_ram_dout;  // OAM data PPU writes ($2004 write)
    logic        spr_ram_wr;    // PPU OAM write strobe
    logic        inc_addr;      // PPU yeu cau increment VRAM address sau $2007 access
    logic        upd_cntrs;     // PPU pulse copy regs->counters sau $2006 write #2
    // Scroll/counter outputs for scrolling verification
    logic [ 2:0] fv;            // Fine vertical scroll
    logic [ 4:0] vt;            // Vertical tile index
    logic        v;             // Vertical nametable select
    logic [ 2:0] fh;            // Fine horizontal scroll
    logic [ 4:0] ht;            // Horizontal tile index
    logic        h;             // Horizontal nametable select
    logic        s;             // BG pattern table select
    logic        inc_addr_amt;  // 0:+1, 1:+32

    // Memory → PPU: Slave Driver drives this to respond to PPU reads
    logic [ 7:0] vram_din;      // Data: VRAM/Memory → PPU ($2007 read response)
    logic [ 7:0] spr_ram_din;   // Data: OAM RAM -> PPU ($2004 read response)

    logic [2:0] gui_last_sel;
    logic       gui_last_r_nw;

    always_ff @(posedge clk_in) begin
        gui_last_sel  <= ri_sel;
        gui_last_r_nw <= ri_r_nw;
    end

    covergroup cg_ri_gui @(posedge clk_in);
        option.per_instance = 1;
        option.get_inst_coverage = 1;
        type_option.merge_instances = 0;

        cp_sel: coverpoint ri_sel iff (!ri_ncs) {
            bins PPUCTRL   = {0};
            bins PPUMASK   = {1};
            bins PPUSTATUS = {2};
            bins OAMADDR   = {3};
            bins OAMDATA   = {4};
            bins PPUSCROLL = {5};
            bins PPUADDR   = {6};
            bins PPUDATA   = {7};
        }

        cp_r_nw: coverpoint ri_r_nw iff (!ri_ncs) {
            bins wr = {0};
            bins rd = {1};
        }

        cp_ctrl_nmi: coverpoint ri_din[7] iff (!ri_ncs && (ri_sel == 0) && (ri_r_nw == 0)) {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_mask_bg: coverpoint ri_din[3] iff (!ri_ncs && (ri_sel == 1) && (ri_r_nw == 0)) {
            bins hidden = {0};
            bins shown  = {1};
        }

        cp_status_vblank: coverpoint ri_dout[7] iff (!ri_ncs && (ri_sel == 2) && (ri_r_nw == 1)) {
            bins not_in_vblank = {0};
            bins in_vblank     = {1};
        }

        cp_double_write: coverpoint ri_sel iff (!ri_ncs && (ri_r_nw == 0) && (gui_last_r_nw == 0) && (gui_last_sel == ri_sel)) {
            bins scroll_seq = {5};
            bins addr_seq   = {6};
        }

        cp_cross: cross cp_sel, cp_r_nw;
    endgroup

    //----------------------------------------------------------------------
    // Clocking Block — MASTER (Master Driver uses this)
    //----------------------------------------------------------------------
    clocking master_cb @(posedge clk_in);
        default input #1ns output #1ns;
        output ri_sel;
        output ri_ncs;
        output ri_r_nw;
        output ri_din;
        input  ri_dout;
    endclocking

    //----------------------------------------------------------------------
    // Clocking Block — SLAVE (Slave Driver uses this)
    //----------------------------------------------------------------------
    clocking slave_cb @(posedge clk_in);
        default input #1ns output #1ns;
        // Slave monitors PPU requests
        input  vram_a;
        input  vram_wr;
        input  pram_wr;
        input  spr_ram_a;
        input  spr_ram_wr;
        input  inc_addr;
        input  upd_cntrs;
        input  fv;
        input  vt;
        input  v;
        input  fh;
        input  ht;
        input  h;
        input  s;
        input  inc_addr_amt;
        // Slave drives response data back to PPU
        output vram_din;
        input  spr_ram_din;
    endclocking

    //----------------------------------------------------------------------
    // Clocking Block — MONITOR (ca 2 monitor dung chung)
    //----------------------------------------------------------------------
    clocking monitor_cb @(posedge clk_in);
        default input #1step output #1ns;
        // CPU side
        input ri_sel;
        input ri_ncs;
        input ri_r_nw;
        input ri_din;
        input ri_dout;
        // Memory side - PPU outputs
        input vram_a;
        input vram_dout;
        input vram_wr;
        input pram_wr;
        input spr_ram_a;
        input spr_ram_dout;
        input spr_ram_wr;
        input inc_addr;
        input upd_cntrs;
        input fv;
        input vt;
        input v;
        input fh;
        input ht;
        input h;
        input s;
        input inc_addr_amt;
        // Memory side - Slave driver output
        input vram_din;
        input spr_ram_din;
    endclocking

    // Modports
    modport master_mp  (clocking master_cb,  input clk_in);
    modport slave_mp   (clocking slave_cb,   input clk_in);
    modport monitor_mp (clocking monitor_cb, input clk_in);

endinterface

`endif
