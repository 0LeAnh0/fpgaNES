`ifndef PPU_RI_SEQUENCES_SV
`define PPU_RI_SEQUENCES_SV

// ===========================================================================
// File: ppu_ri_sequences.sv
// Chua tat ca cac Sequence cho PPU Register Interface.
//
// Cau truc ke thua:
//   uvm_sequence (UVM base)
//     └── ppu_ri_base_sequence         (Base chung, extend tu day)
//           ├── ppu_ri_write_sequence  (Ghi 1 thanh ghi bat ky)
//           ├── ppu_ri_read_sequence   (Doc 1 thanh ghi bat ky)
//           ├── ppu_ri_ppuctrl_seq     (Write $2000 - PPUCTRL)
//           ├── ppu_ri_ppumask_seq     (Write $2001 - PPUMASK)
//           ├── ppu_ri_ppustatus_seq   (Read  $2002 - PPUSTATUS)
//           ├── ppu_ri_oamaddr_seq     (Write $2003 - OAMADDR)
//           ├── ppu_ri_oamdata_seq     (Write $2004 - OAMDATA)
//           ├── ppu_ri_ppuscroll_seq   (Write $2005 twice - PPUSCROLL)
//           ├── ppu_ri_ppuaddr_seq     (Write $2006 twice - PPUADDR)
//           └── ppu_ri_ppudata_seq     (Write/Read $2007 - PPUDATA)
// ===========================================================================


//-----------------------------------------------------------------------------
// BASE SEQUENCE
//-----------------------------------------------------------------------------
class ppu_ri_base_sequence extends uvm_sequence #(ppu_ri_sequence_item);
    `uvm_object_utils(ppu_ri_base_sequence)

    function new(string name = "ppu_ri_base_sequence");
        super.new(name);
    endfunction

    // Tien ich: tao va gui 1 item
    protected task send_item(logic [2:0] sel, logic r_nw, logic [7:0] data = 8'h00);
        ppu_ri_sequence_item item;
        item = ppu_ri_sequence_item::type_id::create("item");
        start_item(item);
        item.sel      = sel;
        item.r_nw     = r_nw;
        item.data_in  = data;
        finish_item(item);
    endtask

endclass


//-----------------------------------------------------------------------------
// GENERIC WRITE SEQUENCE (ghi bat ky thanh ghi nao)
//-----------------------------------------------------------------------------
class ppu_ri_write_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_write_sequence)

    rand logic [2:0] target_sel;
    rand logic [7:0] target_data;

    // Chi cac thanh ghi cho phep ghi
    constraint c_valid_wr { target_sel inside {3'h0, 3'h1, 3'h3, 3'h4, 3'h5, 3'h6, 3'h7}; }

    function new(string name = "ppu_ri_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("WRITE -> $200%0h = %02h", target_sel, target_data), UVM_MEDIUM)
        send_item(target_sel, 1'b0, target_data);
    endtask

endclass


//-----------------------------------------------------------------------------
// GENERIC READ SEQUENCE (doc bat ky thanh ghi nao)
//-----------------------------------------------------------------------------
class ppu_ri_read_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_read_sequence)

    rand logic [2:0] target_sel;

    // Chi cac thanh ghi cho phep doc
    constraint c_valid_rd { target_sel inside {3'h2, 3'h4, 3'h7}; }

    function new(string name = "ppu_ri_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("READ <- $200%0h", target_sel), UVM_MEDIUM)
        send_item(target_sel, 1'b1);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2000 PPUCTRL — Write Only
//   [7] nvbl_en: Enable NMI on VBlank
//   [5] spr_h:   Sprite size (0=8x8, 1=8x16)
//   [4] s:       BG pattern table (0=$0000, 1=$1000)
//   [3] spr_pt:  Sprite pattern table (0=$0000, 1=$1000)
//   [2] addr_inc:VRAM addr increment (0=+1, 1=+32)
//   [1] v:       Vertical nametable
//   [0] h:       Horizontal nametable
//-----------------------------------------------------------------------------
class ppu_ri_ppuctrl_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppuctrl_sequence)

    rand logic nvbl_en;   // bit[7]
    rand logic spr_h;     // bit[5]
    rand logic s;         // bit[4]
    rand logic spr_pt;    // bit[3]
    rand logic addr_inc;  // bit[2]
    rand logic v;         // bit[1]
    rand logic h;         // bit[0]

    function new(string name = "ppu_ri_ppuctrl_sequence");
        super.new(name);
    endfunction

    virtual task body();
        logic [7:0] val = {nvbl_en, 1'b0, spr_h, s, spr_pt, addr_inc, v, h};
        `uvm_info(get_type_name(),
            $sformatf("PPUCTRL $2000 = %08b (nvbl_en=%b addr_inc=%b)", val, nvbl_en, addr_inc),
            UVM_MEDIUM)
        send_item(3'h0, 1'b0, val);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2001 PPUMASK — Write Only
//   [4] spr_en:       Enable sprite rendering
//   [3] bg_en:        Enable BG rendering
//   [2] !spr_ls_clip: Show sprites in leftmost 8 pixels
//   [1] !bg_ls_clip:  Show BG in leftmost 8 pixels
//-----------------------------------------------------------------------------
class ppu_ri_ppumask_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppumask_sequence)

    rand logic spr_en;
    rand logic bg_en;
    rand logic spr_show_left; // 1 = show, 0 = clip
    rand logic bg_show_left;  // 1 = show, 0 = clip

    function new(string name = "ppu_ri_ppumask_sequence");
        super.new(name);
    endfunction

    virtual task body();
        logic [7:0] val = {3'b000, spr_en, bg_en, spr_show_left, bg_show_left, 1'b0};
        `uvm_info(get_type_name(),
            $sformatf("PPUMASK $2001 = %08b (bg_en=%b spr_en=%b)", val, bg_en, spr_en),
            UVM_MEDIUM)
        send_item(3'h1, 1'b0, val);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2002 PPUSTATUS — Read Only
//   Returns: [7]=vblank, [6]=spr0_hit, [5]=spr_overflow
//   Side effect: clears vblank flag + resets byte_sel latch
//-----------------------------------------------------------------------------
class ppu_ri_ppustatus_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppustatus_sequence)

    function new(string name = "ppu_ri_ppustatus_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "READ PPUSTATUS $2002", UVM_MEDIUM)
        send_item(3'h2, 1'b1);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2003 OAMADDR — Write Only (set OAM address pointer)
//-----------------------------------------------------------------------------
class ppu_ri_oamaddr_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_oamaddr_sequence)

    rand logic [7:0] oam_addr;

    function new(string name = "ppu_ri_oamaddr_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("OAMADDR $2003 = %02h", oam_addr), UVM_MEDIUM)
        send_item(3'h3, 1'b0, oam_addr);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2004 OAMDATA — Write (auto-increments OAM pointer)
//-----------------------------------------------------------------------------
class ppu_ri_oamdata_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_oamdata_sequence)

    rand logic [7:0] oam_data;

    function new(string name = "ppu_ri_oamdata_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("OAMDATA $2004 <- %02h", oam_data), UVM_MEDIUM)
        send_item(3'h4, 1'b0, oam_data);
    endtask

endclass

//-----------------------------------------------------------------------------
// $2004 OAMDATA — Read
//-----------------------------------------------------------------------------
class ppu_ri_oamdata_read_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_oamdata_read_sequence)

    function new(string name = "ppu_ri_oamdata_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "OAMDATA $2004 -> READ", UVM_MEDIUM)
        send_item(3'h4, 1'b1);
    endtask

endclass


//-----------------------------------------------------------------------------
// $2005 PPUSCROLL — Write twice (X then Y)
//   Write 1: fh[2:0] = cpu[2:0], ht[4:0] = cpu[7:3]
//   Write 2: fv[2:0] = cpu[2:0], vt[4:0] = cpu[7:3]
//-----------------------------------------------------------------------------
class ppu_ri_ppuscroll_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppuscroll_sequence)

    rand logic [7:0] scroll_x; // First write
    rand logic [7:0] scroll_y; // Second write

    function new(string name = "ppu_ri_ppuscroll_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("PPUSCROLL $2005 X=%02h Y=%02h", scroll_x, scroll_y), UVM_MEDIUM)
        send_item(3'h5, 1'b0, scroll_x); // Write 1 (X)
        send_item(3'h5, 1'b0, scroll_y); // Write 2 (Y)
    endtask

endclass


//-----------------------------------------------------------------------------
// $2006 PPUADDR — Write twice (high byte then low byte)
//   Write 1: fv[1:0]=cpu[5:4], v=cpu[3], h=cpu[2], vt[4:3]=cpu[1:0]
//   Write 2: vt[2:0]=cpu[7:5], ht[4:0]=cpu[4:0] + triggers upd_cntrs
//-----------------------------------------------------------------------------
class ppu_ri_ppuaddr_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppuaddr_sequence)

    rand logic [13:0] vram_addr; // 14-bit VRAM address to set

    function new(string name = "ppu_ri_ppuaddr_sequence");
        super.new(name);
    endfunction

    virtual task body();
        logic [7:0] hi = {2'b00, vram_addr[13:8]};
        logic [7:0] lo = vram_addr[7:0];
        `uvm_info(get_type_name(),
            $sformatf("PPUADDR $2006 addr=%04h (hi=%02h lo=%02h)", vram_addr, hi, lo), UVM_MEDIUM)
        send_item(3'h6, 1'b0, hi); // Write 1: high byte
        send_item(3'h6, 1'b0, lo); // Write 2: low byte (also triggers counter update)
    endtask

endclass


//-----------------------------------------------------------------------------
// $2007 PPUDATA — Write (VRAM/PRAM access) or Read (buffered)
//   After each access, VRAM address auto-increments by 1 or 32
//-----------------------------------------------------------------------------
class ppu_ri_ppudata_write_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppudata_write_sequence)

    rand logic [7:0] ppu_data;

    function new(string name = "ppu_ri_ppudata_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(),
            $sformatf("PPUDATA $2007 <- %02h", ppu_data), UVM_MEDIUM)
        send_item(3'h7, 1'b0, ppu_data);
    endtask

endclass


class ppu_ri_ppudata_read_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_ppudata_read_sequence)

    function new(string name = "ppu_ri_ppudata_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "PPUDATA $2007 -> READ", UVM_MEDIUM)
        send_item(3'h7, 1'b1);
    endtask

endclass

//-----------------------------------------------------------------------------
// SCROLL STRESS SEQUENCE (Mix $2000, $2005, $2006)
//-----------------------------------------------------------------------------
class ppu_ri_scroll_sequence extends ppu_ri_base_sequence;
    `uvm_object_utils(ppu_ri_scroll_sequence)

    rand int num_iters;
    constraint c_iters { num_iters inside {[20:100]}; }

    function new(string name = "ppu_ri_scroll_sequence");
        super.new(name);
    endfunction

    virtual task body();
        ppu_ri_ppuscroll_sequence seq_scroll;
        ppu_ri_ppuaddr_sequence   seq_addr;
        ppu_ri_ppuctrl_sequence   seq_ctrl;

        `uvm_info(get_type_name(), $sformatf("Starting Scroll Stress with %0d iterations", num_iters), UVM_LOW)

        for (int i = 0; i < num_iters; i++) begin
            int op = $urandom_range(0, 2);
            case (op)
                0: begin
                    seq_scroll = ppu_ri_ppuscroll_sequence::type_id::create("seq_scroll");
                    seq_scroll.randomize();
                    seq_scroll.start(m_sequencer);
                end
                1: begin
                    seq_addr = ppu_ri_ppuaddr_sequence::type_id::create("seq_addr");
                    seq_addr.randomize();
                    seq_addr.start(m_sequencer);
                end
                2: begin
                    seq_ctrl = ppu_ri_ppuctrl_sequence::type_id::create("seq_ctrl");
                    seq_ctrl.randomize();
                    seq_ctrl.start(m_sequencer);
                end
            endcase
        end
    endtask
endclass

`endif
