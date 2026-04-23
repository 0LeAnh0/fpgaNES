// ===========================================================================
// ppu_ri_scoreboard.sv
// ===========================================================================

`ifndef PPU_RI_SCOREBOARD_SV
`define PPU_RI_SCOREBOARD_SV

`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)

class ppu_ri_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ppu_ri_scoreboard)

    uvm_analysis_imp_master #(ppu_ri_sequence_item, ppu_ri_scoreboard) master_export;
    uvm_analysis_imp_slave  #(ppu_ri_sequence_item, ppu_ri_scoreboard) slave_export;

    // --- State ---
    logic [4:0] t_ht = 0;
    logic [4:0] t_vt = 0;
    logic [2:0] t_fv = 0;
    logic [2:0] t_fh = 0;
    logic       t_nt_h = 0;
    logic       t_nt_v = 0;
    logic [7:0] ref_spr_ram_a = 0;
    logic       ref_vblank, ref_nvbl_en, ref_spr_h, ref_s, ref_spr_pt, ref_addr_inc;
    logic       ref_bg_en, ref_spr_en;
    bit         ref_byte_sel = 0;
    
    // --- Stats ---
    int ppu_ri_pass = 0, ppu_ri_fail = 0;
    int exp_spr_wr = 0, obs_spr_wr = 0;
    int exp_upd_cntrs = 0, obs_upd_cntrs = 0;
    int exp_ppudata_rd = 0, exp_ppudata_wr = 0;

    // --- Side-effects Sync ---
    logic [ 7:0] rd_sidefx_vdin_q[$];
    logic [13:0] rd_sidefx_addr_q[$];
    logic [ 7:0] rd_master_dout_q[$];
    static logic [7:0] ref_read_buffer = 8'h00;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        master_export = new("master_export", this);
        slave_export  = new("slave_export", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ref_byte_sel = 0;
        ref_vblank = 0;
    endfunction

    // Slave port side-effects
    virtual function void write_slave(ppu_ri_sequence_item tr);
        if (tr.obs_spr_wr) obs_spr_wr++; // Fixed field name
        if (tr.obs_upd_cntrs) obs_upd_cntrs++;
        if (tr.obs_inc_addr && !tr.obs_vram_wr && !tr.obs_pram_wr) begin
            rd_sidefx_addr_q.push_back(tr.obs_vram_a);
            rd_sidefx_vdin_q.push_back(tr.obs_vram_din);
            drain_ppudata_pairs();
        end
    endfunction

    local function void clear_ppudata_tracking(bit reset_read_buffer = 0);
        rd_sidefx_vdin_q.delete();
        rd_sidefx_addr_q.delete();
        rd_master_dout_q.delete();
        if (reset_read_buffer) begin
            ref_read_buffer = 8'h00;
        end
    endfunction

    local function void drain_ppudata_pairs();
        while ((rd_master_dout_q.size() > 0) && (rd_sidefx_addr_q.size() > 0)) begin
            process_ppudata_read_pair(
                rd_master_dout_q.pop_front(),
                rd_sidefx_addr_q.pop_front(),
                rd_sidefx_vdin_q.pop_front()
            );
        end
    endfunction

    // Master port CPU register access
    virtual function void write_master(ppu_ri_sequence_item tr);
        if (tr.r_nw == 1'b0) begin // WRITE
            case (tr.sel)
                3'h0: begin // PPUCTRL
                    ref_nvbl_en=tr.data_in[7]; ref_spr_h=tr.data_in[5]; ref_addr_inc=tr.data_in[2];
                    t_nt_v=tr.data_in[1]; t_nt_h=tr.data_in[0]; ppu_ri_pass++;
                end
                3'h1: begin ref_spr_en=tr.data_in[4]; ref_bg_en=tr.data_in[3]; ppu_ri_pass++; end
                3'h3: begin ref_spr_ram_a=tr.data_in; ppu_ri_pass++; end
                3'h4: begin exp_spr_wr++; ppu_ri_pass++; end
                3'h5: begin // PPUSCROLL
                    if (ref_byte_sel == 1'b0) begin
                        t_fh=tr.data_in[2:0]; t_ht=tr.data_in[7:3]; ref_byte_sel=1'b1;
                    end else begin
                        t_fv=tr.data_in[2:0]; t_vt=tr.data_in[7:3]; ref_byte_sel=1'b0;
                        check_scroll_state("PPUSCROLL", tr);
                    end
                    ppu_ri_pass++;
                end
                3'h6: begin // PPUADDR
                    if (ref_byte_sel == 1'b0) begin
                        t_fv={1'b0, tr.data_in[5:4]}; t_nt_v=tr.data_in[3]; t_nt_h=tr.data_in[2]; t_vt[4:3]=tr.data_in[1:0]; ref_byte_sel=1'b1;
                    end else begin
                        t_vt[2:0]=tr.data_in[7:5]; t_ht=tr.data_in[4:0];
                        ref_byte_sel=1'b0; check_scroll_state("PPUADDR", tr); exp_upd_cntrs++;
                        // $2006 rewrites the VRAM address, but the DUT keeps the buffered $2007
                        // read data intact. Only clear pending bookkeeping, not the read buffer.
                        clear_ppudata_tracking(1'b0);
                    end
                    ppu_ri_pass++;
                end
                3'h7: begin exp_ppudata_wr++; ppu_ri_pass++; end
            endcase
        end else begin // READ
            case (tr.sel)
                3'h2: check_ppustatus_read(tr);
                3'h7: begin
                    exp_ppudata_rd++;
                    rd_master_dout_q.push_back(tr.data_out);
                    drain_ppudata_pairs();
                end
            endcase
        end
    endfunction

    local function void check_scroll_state(string label, ppu_ri_sequence_item tr);
        if (tr.obs_fv !== t_fv || tr.obs_vt !== t_vt || tr.obs_h !== t_nt_h || tr.obs_v !== t_nt_v || tr.obs_ht !== t_ht || tr.obs_fh !== t_fh) begin
            ppu_ri_fail++;
            `uvm_error("SCB_PPU_RI", $sformatf("%s mismatch: exp(fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d) obs(fv=%0d vt=%0d v=%0d fh=%0d ht=%0d h=%0d)",
                label, t_fv, t_vt, t_nt_v, t_fh, t_ht, t_nt_h,
                tr.obs_fv, tr.obs_vt, tr.obs_v, tr.obs_fh, tr.obs_ht, tr.obs_h))
        end else ppu_ri_pass++;
    endfunction

    local function void check_ppustatus_read(ppu_ri_sequence_item tr);
        if (tr.data_out[7] !== ref_vblank && !$isunknown(tr.data_out[7])) begin
            ppu_ri_fail++; `uvm_error("SCB_PPU_RI", "PPUSTATUS vblank mismatch")
        end
        ref_vblank=0; ref_byte_sel=0; ppu_ri_pass++;
    endfunction

    local function void process_ppudata_read_pair(logic [7:0] master_dout, logic [13:0] addr, logic [7:0] vdin);
        if (addr < 14'h3F00) begin
            if (master_dout !== ref_read_buffer) begin
                ppu_ri_fail++; `uvm_error("SCB_PPU_RI", $sformatf("PPUDATA mismatch: exp=%02h obs=%02h at vram_a=%04h", ref_read_buffer, master_dout, addr))
            end else ppu_ri_pass++;
        end else begin
            if (master_dout !== vdin) begin
                ppu_ri_fail++; `uvm_error("SCB_PPU_RI", $sformatf("PPUDATA Palette mismatch: exp=%02h obs=%02h at vram_a=%04h", vdin, master_dout, addr))
            end else ppu_ri_pass++;
        end
        // RTL rearms q_rd_buf from vram_d_in one cycle after every $2007 read,
        // including palette-space reads where cpu_d_out bypasses to pram_d_in.
        ref_read_buffer = vdin;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        if (exp_upd_cntrs != obs_upd_cntrs && exp_upd_cntrs != (obs_upd_cntrs/2)) begin
            `uvm_error("SCB_RPT", $sformatf("Upd counters mismatch: exp=%0d obs=%0d", exp_upd_cntrs, obs_upd_cntrs))
        end
        if ((rd_master_dout_q.size() != 0) || (rd_sidefx_addr_q.size() != 0) || (rd_sidefx_vdin_q.size() != 0)) begin
            ppu_ri_fail++;
            `uvm_error("SCB_RPT",
                $sformatf("Unmatched PPUDATA bookkeeping: master_q=%0d sidefx_addr_q=%0d sidefx_vdin_q=%0d",
                    rd_master_dout_q.size(), rd_sidefx_addr_q.size(), rd_sidefx_vdin_q.size()))
        end
        `uvm_info("SCB_RPT", $sformatf("FINAL: PASS=%0d FAIL=%0d", ppu_ri_pass, ppu_ri_fail), UVM_LOW)
    endfunction
endclass

`endif
