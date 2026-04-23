`ifndef PPU_RI_MASTER_AGENT_SV
`define PPU_RI_MASTER_AGENT_SV

// ===========================================================================
// ppu_ri_master_agent  [ppu_agt/master/]
// Master Agent — dong vai CPU, lai cac tin hieu $2000-$2007 vao PPU.
//
// Chua:
//   ppu_ri_sequencer      ppu_ri_sqr      — quan ly luong sequence
//   ppu_ri_master_driver  ppu_ri_mst_drv  — drive CPU-side bus vao PPU
//   ppu_ri_master_monitor ppu_ri_mst_mon  — quan sat CPU-side bus
//
// Slave Monitor da tach sang ppu_ri_slave_agent (slave/).
//
// Expose 1 analysis port ra env:
//   master_ap → CPU-side transactions
// ===========================================================================
class ppu_ri_master_agent extends uvm_agent;
    `uvm_component_utils(ppu_ri_master_agent)

    // Sub-components
    ppu_ri_sequencer      ppu_ri_sqr;
    ppu_ri_master_driver  ppu_ri_mst_drv;
    ppu_ri_master_monitor ppu_ri_mst_mon;

    // Analysis port exposed to env
    uvm_analysis_port #(ppu_ri_sequence_item) master_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_ap = new("master_ap", this);

        if (get_is_active() == UVM_ACTIVE) begin
            ppu_ri_sqr     = ppu_ri_sequencer::type_id::create("ppu_ri_sqr",     this);
            ppu_ri_mst_drv = ppu_ri_master_driver::type_id::create("ppu_ri_mst_drv", this);
            ppu_ri_mst_mon = ppu_ri_master_monitor::type_id::create("ppu_ri_mst_mon", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            // Driver ↔ Sequencer
            ppu_ri_mst_drv.seq_item_port.connect(ppu_ri_sqr.seq_item_export);
            // Master Monitor → master_ap
            ppu_ri_mst_mon.master_mon_ap.connect(master_ap);
        end
    endfunction

endclass

`endif
