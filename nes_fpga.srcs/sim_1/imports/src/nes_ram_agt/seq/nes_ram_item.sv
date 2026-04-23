`ifndef NES_RAM_ITEM_SV
`define NES_RAM_ITEM_SV

class nes_ram_item extends uvm_sequence_item;
    
    rand logic [15:0] addr;
    rand logic [7:0]  data; 
    rand logic        r_nw; // 1: Read, 0: Write
    logic             is_vram; // 0: WRAM transaction, 1: VRAM transaction
    
    `uvm_object_utils_begin(nes_ram_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(r_nw, UVM_ALL_ON)
        `uvm_field_int(is_vram, UVM_ALL_ON | UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "nes_ram_item");
        super.new(name);
        is_vram = 1'b0;
    endfunction
    
    virtual function string convert2string();
        return $sformatf("%s Addr: %04h, Data: %02h, Mode: %s",
                         (is_vram ? "VRAM" : "WRAM"),
                         addr, data, (r_nw ? "READ" : "WRITE"));
    endfunction
    
endclass

`endif
