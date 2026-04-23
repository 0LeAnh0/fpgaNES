`ifndef NES_RAM_SUBSCRIBER_SV
`define NES_RAM_SUBSCRIBER_SV

class nes_ram_subscriber extends uvm_subscriber #(nes_ram_item);
    `uvm_component_utils(nes_ram_subscriber)

    // Co the them logic Coverage tai day neu can
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void write(nes_ram_item t);
        // Log transaction don gian de giup theo doi TLM
        `uvm_info("RAM_SUB", $sformatf("Observed RAM transaction: Addr=%04h, Data=%02h, R/W=%s", 
                   t.addr, t.data, (t.r_nw ? "READ" : "WRITE")), UVM_DEBUG)
    endfunction
endclass

`endif
