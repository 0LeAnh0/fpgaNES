`ifndef PPU_RI_SEQUENCE_ITEM_SV
`define PPU_RI_SEQUENCE_ITEM_SV

// ===========================================================================
// ppu_ri_sequence_item
// Transaction item mo ta 1 chu ky giao tiep tren bus Register Interface.
//   - Bao gom ca CPU-side transaction (write/read thanh ghi)
//   - Va PPU-side output (VRAM/OAM access ket qua tu transaction do)
// ===========================================================================
class ppu_ri_sequence_item extends uvm_sequence_item;

    //----------------------------------------------------------------------
    // A. CPU-SIDE STIMULUS FIELDS (Master drives)
    //----------------------------------------------------------------------
    rand logic [2:0] sel;       // Register select: 0=$2000 ... 7=$2007
    rand logic       r_nw;      // 1=Read, 0=Write
    rand logic [7:0] data_in;   // Data CPU writes to PPU

    // Captured response
    logic [7:0] data_out;       // Data PPU returns to CPU on READ

    //----------------------------------------------------------------------
    // B. PPU OUTPUT OBSERVATION FIELDS (Slave Monitor captures)
    //    Populated by the slave monitor after the CPU transaction
    //----------------------------------------------------------------------
    logic [13:0] obs_vram_a;    // VRAM address driven by PPU
    logic [ 7:0] obs_vram_dout; // Data PPU writes to VRAM
    logic        obs_vram_wr;   // VRAM write strobe from PPU
    logic        obs_pram_wr;   // Palette RAM write strobe from PPU
    logic [ 7:0] obs_spr_a;     // OAM address driven by PPU
    logic [ 7:0] obs_spr_dout;  // Data PPU writes to OAM
    logic        obs_spr_wr;    // OAM write strobe from PPU
    logic        obs_inc_addr;  // Address increment pulse from PPU (sau $2007 read/write)
    logic [ 7:0] obs_vram_din;  // Data sampled from VRAM -> PPU on read
    logic [ 7:0] obs_spr_din;   // Data sampled from OAM -> PPU on $2004 read
    logic        obs_upd_cntrs; // Pulse for counter update after $2006 write #2
    logic [ 2:0] obs_fv;        // Scroll state observation
    logic [ 4:0] obs_vt;
    logic        obs_v;
    logic [ 2:0] obs_fh;
    logic [ 4:0] obs_ht;
    logic        obs_h;
    logic        obs_s;
    logic        obs_inc_addr_amt;

    //----------------------------------------------------------------------
    // UVM Factory Registration
    //----------------------------------------------------------------------
    `uvm_object_utils_begin(ppu_ri_sequence_item)
        `uvm_field_int(sel,          UVM_ALL_ON)
        `uvm_field_int(r_nw,         UVM_ALL_ON)
        `uvm_field_int(data_in,      UVM_ALL_ON)
        `uvm_field_int(data_out,     UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_vram_a,   UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_vram_dout,UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_vram_wr,  UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_pram_wr,  UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_spr_a,    UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_spr_dout, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_spr_wr,   UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_inc_addr, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_vram_din, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_spr_din,  UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_upd_cntrs,UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_fv,       UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_vt,       UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_v,        UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_fh,       UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_ht,       UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_h,        UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_s,        UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(obs_inc_addr_amt, UVM_ALL_ON | UVM_NOPACK)
    `uvm_object_utils_end

    //----------------------------------------------------------------------
    // Constraints
    //----------------------------------------------------------------------
    // Chi cho phep write-only tren cac thanh ghi write-only
    // $2000, $2001, $2003, $2005, $2006 chi duoc ghi (r_nw=0)
    // $2002 chi duoc doc (r_nw=1), $2004 $2007 doc/ghi
    constraint c_ro_regs {
        if (sel == 3'h2) r_nw == 1;      // $2002 PPUSTATUS: Read-Only
        if (sel inside {3'h0, 3'h1, 3'h3, 3'h5, 3'h6}) r_nw == 0; // Write-Only
    }

    function new(string name = "ppu_ri_sequence_item");
        super.new(name);
        sel              = 3'h0;
        r_nw             = 1'b0;
        data_in          = 8'h00;
        data_out         = 8'h00;
        obs_vram_a       = 14'h0000;
        obs_vram_dout    = 8'h00;
        obs_vram_wr      = 1'b0;
        obs_pram_wr      = 1'b0;
        obs_spr_a        = 8'h00;
        obs_spr_dout     = 8'h00;
        obs_spr_wr       = 1'b0;
        obs_inc_addr     = 1'b0;
        obs_vram_din     = 8'h00;
        obs_spr_din      = 8'h00;
        obs_upd_cntrs    = 1'b0;
        obs_fv           = 3'h0;
        obs_vt           = 5'h00;
        obs_v            = 1'b0;
        obs_fh           = 3'h0;
        obs_ht           = 5'h00;
        obs_h            = 1'b0;
        obs_s            = 1'b0;
        obs_inc_addr_amt = 1'b0;
    endfunction

    // Pretty-print de de debug tren log
    virtual function string convert2string();
        string s;
        s = $sformatf(
            "[PPU_RI] SEL=%0d ($200%0h) | %s | DIN=%02h DOUT=%02h | VRAM_A=%04h VRAM_WR=%b PRAM_WR=%b OAM_WR=%b INC_ADDR=%b | SCROLL fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d s=%0d inc_amt=%0d",
            sel, sel,
            (r_nw ? "RD" : "WR"),
            data_in, data_out,
            obs_vram_a, obs_vram_wr, obs_pram_wr, obs_spr_wr, obs_inc_addr,
            obs_fv, obs_vt, obs_v, obs_fh, obs_ht, obs_h, obs_s, obs_inc_addr_amt
        );
        return s;
    endfunction

endclass

`endif
