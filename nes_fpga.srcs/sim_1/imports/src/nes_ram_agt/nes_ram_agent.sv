`ifndef NES_RAM_AGENT_SV
`define NES_RAM_AGENT_SV

class nes_ram_agent #(type VIF_TYPE = virtual wram_if) extends uvm_agent;
    `uvm_component_param_utils(nes_ram_agent#(VIF_TYPE))

    // Components
    nes_ram_driver  #(VIF_TYPE) driver;
    nes_ram_monitor #(VIF_TYPE) monitor;
    nes_ram_sequencer sequencer;

    uvm_analysis_port #(nes_ram_item) agent_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_ap = new("agent_ap", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = nes_ram_sequencer::type_id::create("sequencer", this);
            driver    = nes_ram_driver#(VIF_TYPE)::type_id::create("driver", this);
        end
        monitor = nes_ram_monitor#(VIF_TYPE)::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        monitor.item_collected_port.connect(agent_ap);
    endfunction

endclass

`endif
