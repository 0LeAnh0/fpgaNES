`ifndef PPU_RI_SANITY_TEST_SV
`define PPU_RI_SANITY_TEST_SV

// ===========================================================================
// ppu_ri_sanity_test
// Extends ppu_ri_base_test (dung ppu_ri_env, khong lien quan nes_env).
//
// Test sequence $2000->$2007 theo thu tu, kich hoat ca master + slave checks.
// ===========================================================================
class ppu_ri_sanity_test extends ppu_ri_base_test;
    `uvm_component_utils(ppu_ri_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ppu_ri_ppuctrl_sequence       seq_ppuctrl;
        ppu_ri_ppumask_sequence       seq_ppumask;
        ppu_ri_ppustatus_sequence     seq_ppustatus;
        ppu_ri_oamaddr_sequence       seq_oamaddr;
        ppu_ri_oamdata_sequence       seq_oamdata;
        ppu_ri_ppuscroll_sequence     seq_ppuscroll;
        ppu_ri_ppuaddr_sequence       seq_ppuaddr;
        ppu_ri_ppudata_write_sequence seq_ppudata_wr;
        ppu_ri_ppudata_read_sequence  seq_ppudata_rd;

        phase.raise_objection(this, "Starting PPU RI Sanity Test");
        `uvm_info("TEST", ">>> START: ppu_ri_sanity_test <<<", UVM_NONE)

        #200ns; // Cho reset deassert

        // 1. PPUCTRL $2000 — Enable NMI, addr_inc=+1
        seq_ppuctrl          = ppu_ri_ppuctrl_sequence::type_id::create("seq_ppuctrl");
        seq_ppuctrl.nvbl_en  = 1'b1;
        seq_ppuctrl.spr_h    = 1'b0;
        seq_ppuctrl.s        = 1'b0;
        seq_ppuctrl.spr_pt   = 1'b0;
        seq_ppuctrl.addr_inc = 1'b0;
        seq_ppuctrl.v        = 1'b0;
        seq_ppuctrl.h        = 1'b0;
        seq_ppuctrl.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 2. PPUMASK $2001 — Enable BG + SPR
        seq_ppumask               = ppu_ri_ppumask_sequence::type_id::create("seq_ppumask");
        seq_ppumask.spr_en        = 1'b1;
        seq_ppumask.bg_en         = 1'b1;
        seq_ppumask.spr_show_left = 1'b1;
        seq_ppumask.bg_show_left  = 1'b1;
        seq_ppumask.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 3. PPUSTATUS $2002 — Read (clears vblank)
        seq_ppustatus = ppu_ri_ppustatus_sequence::type_id::create("seq_ppustatus");
        seq_ppustatus.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 4. OAMADDR $2003 = 0x00
        seq_oamaddr          = ppu_ri_oamaddr_sequence::type_id::create("seq_oamaddr");
        seq_oamaddr.oam_addr = 8'h00;
        seq_oamaddr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 5. OAMDATA $2004 = 0xAB — expect spr_ram_wr from Slave Monitor
        seq_oamdata          = ppu_ri_oamdata_sequence::type_id::create("seq_oamdata");
        seq_oamdata.oam_data = 8'hAB;
        seq_oamdata.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 6. PPUSCROLL $2005 — X=0x08, Y=0x10 (2 writes)
        seq_ppuscroll          = ppu_ri_ppuscroll_sequence::type_id::create("seq_ppuscroll");
        seq_ppuscroll.scroll_x = 8'h08;
        seq_ppuscroll.scroll_y = 8'h10;
        seq_ppuscroll.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 7. PPUADDR $2006 = 0x2000 (2 writes: hi=0x20, lo=0x00)
        seq_ppuaddr           = ppu_ri_ppuaddr_sequence::type_id::create("seq_ppuaddr");
        seq_ppuaddr.vram_addr = 14'h2000;
        seq_ppuaddr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 8. PPUDATA $2007 <- 0x55 — expect vram_wr from Slave Monitor
        seq_ppudata_wr          = ppu_ri_ppudata_write_sequence::type_id::create("seq_ppudata_wr");
        seq_ppudata_wr.ppu_data = 8'h55;
        seq_ppudata_wr.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        // 9. PPUDATA $2007 -> READ (buffered)
        seq_ppudata_rd = ppu_ri_ppudata_read_sequence::type_id::create("seq_ppudata_rd");
        seq_ppudata_rd.start(m_ppu_ri_env.m_ppu_ri_mst_agent.ppu_ri_sqr);

        #100ns;
        `uvm_info("TEST", ">>> DONE: ppu_ri_sanity_test <<<", UVM_NONE)
        phase.drop_objection(this, "Finished PPU RI Sanity Test");
    endtask

endclass

`endif
