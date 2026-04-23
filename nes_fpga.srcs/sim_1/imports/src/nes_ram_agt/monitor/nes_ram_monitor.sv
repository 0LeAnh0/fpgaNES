`ifndef NES_RAM_MONITOR_SV
`define NES_RAM_MONITOR_SV

class nes_ram_monitor #(type VIF_TYPE = virtual wram_if) extends uvm_monitor;
    `uvm_component_param_utils(nes_ram_monitor#(VIF_TYPE))

    VIF_TYPE vif;
    uvm_analysis_port #(nes_ram_item) item_collected_port;
    bit is_vram_monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(VIF_TYPE)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", $sformatf("Virtual Interface not found for monitor %s", get_full_name()))
        end
        if (!uvm_config_db#(bit)::get(this, "", "is_vram_agent", is_vram_monitor)) begin
            is_vram_monitor = 1'b0;
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        nes_ram_item trans_collected;
        `uvm_info(get_type_name(), "Run phase started", UVM_LOW)
        forever begin
            @(vif.mon_cb);
            
            if (vif.mon_cb.en_in === 1'b1) begin
                trans_collected = nes_ram_item::type_id::create("trans_collected");
                trans_collected.r_nw = vif.mon_cb.r_nw_in;
                trans_collected.addr = vif.mon_cb.a_in;
                trans_collected.is_vram = is_vram_monitor;
                
                if (trans_collected.r_nw == 0) begin // Write
                    trans_collected.data = vif.mon_cb.d_in;
                end else begin // Read
                    @(vif.mon_cb);
                    trans_collected.data = vif.mon_cb.d_out;
                end
                
                `uvm_info(get_type_name(), $sformatf("OBSERVED: %s", trans_collected.convert2string()), UVM_LOW)
                item_collected_port.write(trans_collected);
            end
        end
    endtask
endclass

`endif
