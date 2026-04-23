`ifndef PPU_RI_SLAVE_AGENT_SV
`define PPU_RI_SLAVE_AGENT_SV

// ===========================================================================
// ppu_ri_slave_agent  [ppu_agt/slave/]
// Slave Agent — dong vai VRAM/Memory bus ben phia PPU output.
//
// Chua:
//   ppu_ri_sequencer      ppu_ri_slv_sqr   — sequencer rieng (co the dung chung)
//   ppu_ri_slave_driver   ppu_ri_slv_drv   — VRAM Memory BFM (drives vram_din)
//   ppu_ri_slave_monitor  ppu_ri_slv_mon   — quan sat PPU output strobes
//
// Expose 1 analysis port ra env:
//   slave_ap → PPU memory-side transactions (vram_wr, pram_wr, spr_ram_wr)
// ===========================================================================
class ppu_ri_slave_agent extends uvm_agent;
    `uvm_component_utils(ppu_ri_slave_agent)

    // Sub-components
    ppu_ri_sequencer     ppu_ri_slv_sqr;
    ppu_ri_slave_driver  ppu_ri_slv_drv;
    ppu_ri_slave_monitor ppu_ri_slv_mon;

    // Analysis port exposed to env
    uvm_analysis_port #(ppu_ri_sequence_item) slave_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        slave_ap = new("slave_ap", this);

        // Monitor: luon active (passive observation)
        ppu_ri_slv_mon = ppu_ri_slave_monitor::type_id::create("ppu_ri_slv_mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            ppu_ri_slv_sqr = ppu_ri_sequencer::type_id::create("ppu_ri_slv_sqr", this);
            ppu_ri_slv_drv = ppu_ri_slave_driver::type_id::create("ppu_ri_slv_drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            // Driver ↔ Sequencer
            ppu_ri_slv_drv.seq_item_port.connect(ppu_ri_slv_sqr.seq_item_export);
        end

        // Slave Monitor → slave_ap
        ppu_ri_slv_mon.slave_mon_ap.connect(slave_ap);
    endfunction

    // Convenience function: pre-load memory model trong slave driver
    function void preload_vram(logic [13:0] addr, logic [7:0] data);
        if (get_is_active() == UVM_ACTIVE)
            ppu_ri_slv_drv.preload_mem(addr, data);
    endfunction

endclass

`endif
